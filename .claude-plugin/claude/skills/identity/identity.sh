#!/bin/bash
# identity.sh - Verify identity across development tooling
# Shows who operations will be attributed to before commits, pushes, PRs, etc.

set -uo pipefail

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  BOLD='\033[1m'
  DIM='\033[2m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  RED='\033[31m'
  RESET='\033[0m'
else
  BOLD='' DIM='' GREEN='' YELLOW='' RED='' RESET=''
fi

# Usage
usage() {
  echo "Usage: identity.sh [COMMAND] [DOMAIN...]"
  echo ""
  echo "Commands:"
  echo "  (none)          Check identity (default)"
  echo "  sync            Sync git config from GitHub"
  echo ""
  echo "Domains: git, gh, oci, ecr, k8s, aws, cloudflare, gcp, azure, npm"
  echo "         (default: git gh)"
  echo ""
  echo "Examples:"
  echo "  identity.sh              # Check git and GitHub"
  echo "  identity.sh git          # Check git only"
  echo "  identity.sh oci ecr      # Check OCI registries and ECR"
  echo "  identity.sh k8s aws      # Check Kubernetes and AWS"
  echo "  identity.sh all          # Check all domains"
  echo "  identity.sh sync         # Set git user.name/email from GitHub"
}

# Check git identity
check_git() {
  echo -e "${BOLD}Git${RESET}"
  local name email
  name=$(git config user.name 2>/dev/null || echo "")
  email=$(git config user.email 2>/dev/null || echo "")

  if [[ -n "$name" && -n "$email" ]]; then
    echo -e "  ${GREEN}✓${RESET} Commits as: $name <$email>"
  elif [[ -z "$name" && -z "$email" ]]; then
    echo -e "  ${RED}✗${RESET} Not configured"
  else
    [[ -n "$name" ]] && echo -e "  ${DIM}Name:${RESET} $name"
    [[ -n "$email" ]] && echo -e "  ${DIM}Email:${RESET} $email"
    echo -e "  ${YELLOW}⚠${RESET} Incomplete configuration"
  fi
}

# Check GitHub CLI
check_gh() {
  echo -e "${BOLD}GitHub (gh)${RESET}"

  if ! command -v gh &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  local status login
  if ! gh auth status &>/dev/null; then
    echo -e "  ${RED}✗${RESET} Not authenticated"
    return
  fi

  login=$(gh api user -q '.login' 2>/dev/null || echo "")
  if [[ -n "$login" ]]; then
    echo -e "  ${GREEN}✓${RESET} Authenticated as: $login"

    # Check scopes (informational)
    local scopes
    scopes=$(gh auth status 2>&1 | grep -i "token scopes" | sed 's/.*: //' || echo "")
    [[ -n "$scopes" ]] && echo -e "  ${DIM}Scopes: $scopes${RESET}"
  else
    echo -e "  ${YELLOW}⚠${RESET} Authenticated but unable to query user"
  fi
}

# Check OCI container registries (podman)
check_oci() {
  echo -e "${BOLD}OCI Registry (podman)${RESET}"

  if ! command -v podman &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  # Podman auth config locations (in order of precedence)
  local config_file=""
  if [[ -n "${XDG_RUNTIME_DIR:-}" && -f "${XDG_RUNTIME_DIR}/containers/auth.json" ]]; then
    config_file="${XDG_RUNTIME_DIR}/containers/auth.json"
  elif [[ -f "$HOME/.config/containers/auth.json" ]]; then
    config_file="$HOME/.config/containers/auth.json"
  elif [[ -f "$HOME/.docker/config.json" ]]; then
    # Podman can also read Docker's config
    config_file="$HOME/.docker/config.json"
  fi

  if [[ -z "$config_file" ]]; then
    echo -e "  ${DIM}No config file${RESET}"
    return
  fi

  # Check common registries
  local found=0
  for registry in "ghcr.io" "docker.io" "index.docker.io"; do
    if grep -q "$registry" "$config_file" 2>/dev/null; then
      echo -e "  ${GREEN}✓${RESET} Authenticated to: $registry"
      found=1
    fi
  done

  [[ $found -eq 0 ]] && echo -e "  ${DIM}No registry auth found${RESET}"
}

# Check AWS
check_aws() {
  echo -e "${BOLD}AWS${RESET}"

  if ! command -v aws &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  # Show active profile
  local profile="${AWS_PROFILE:-default}"

  # Try to get caller identity
  local error_msg
  error_msg=$(aws sts get-caller-identity 2>&1)

  if [[ $? -eq 0 ]]; then
    local account arn
    account=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null || echo "")
    arn=$(aws sts get-caller-identity --query "Arn" --output text 2>/dev/null || echo "")

    echo -e "  ${GREEN}✓${RESET} Account: $account"
    echo -e "  ${DIM}Profile: $profile${RESET}"
    [[ -n "$arn" ]] && echo -e "  ${DIM}ARN: $arn${RESET}"
    return
  fi

  # Not authenticated - show helpful info
  if [[ "$error_msg" == *"SSO session"*"expired"* ]]; then
    echo -e "  ${YELLOW}⚠${RESET} SSO session expired"
    echo -e "  ${DIM}Run: aws sso login --profile $profile${RESET}"
  elif [[ "$error_msg" == *"credentials"* || "$error_msg" == *"Unable to locate"* ]]; then
    echo -e "  ${RED}✗${RESET} No credentials configured"
  else
    echo -e "  ${RED}✗${RESET} Not authenticated"
  fi

  # List available profiles
  local config_file="$HOME/.aws/config"
  if [[ -f "$config_file" ]]; then
    local profiles
    profiles=$(grep -E '^\[profile |^\[default\]' "$config_file" 2>/dev/null | \
               sed 's/\[profile //' | sed 's/\[//' | sed 's/\]//' | paste -sd ',' - | sed 's/,$//')
    if [[ -n "$profiles" ]]; then
      echo -e "  ${DIM}Profiles: $profiles${RESET}"
    fi
  fi
}

# Check GCP
check_gcp() {
  echo -e "${BOLD}GCP${RESET}"

  if ! command -v gcloud &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  local account
  account=$(gcloud config get-value account 2>/dev/null || echo "")

  if [[ -z "$account" || "$account" == "(unset)" ]]; then
    echo -e "  ${RED}✗${RESET} Not authenticated"
    return
  fi

  echo -e "  ${GREEN}✓${RESET} Account: $account"

  local project
  project=$(gcloud config get-value project 2>/dev/null || echo "")
  [[ -n "$project" && "$project" != "(unset)" ]] && echo -e "  ${DIM}Project: $project${RESET}"
}

# Check Azure
check_azure() {
  echo -e "${BOLD}Azure${RESET}"

  if ! command -v az &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  local account
  account=$(az account show 2>/dev/null || echo "")

  if [[ -z "$account" ]]; then
    echo -e "  ${RED}✗${RESET} Not authenticated"
    echo -e "  ${DIM}Run: az login${RESET}"
    return
  fi

  local user sub
  user=$(az account show --query "user.name" -o tsv 2>/dev/null || echo "")
  sub=$(az account show --query "name" -o tsv 2>/dev/null || echo "")

  if [[ -n "$user" ]]; then
    echo -e "  ${GREEN}✓${RESET} User: $user"
    [[ -n "$sub" ]] && echo -e "  ${DIM}Subscription: $sub${RESET}"
  else
    echo -e "  ${GREEN}✓${RESET} Authenticated"
    [[ -n "$sub" ]] && echo -e "  ${DIM}Subscription: $sub${RESET}"
  fi
}

# Check npm
check_npm() {
  echo -e "${BOLD}npm${RESET}"

  if ! command -v npm &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  local whoami
  whoami=$(npm whoami 2>/dev/null || echo "")

  if [[ -z "$whoami" ]]; then
    echo -e "  ${DIM}Not authenticated (optional for most operations)${RESET}"
    return
  fi

  echo -e "  ${GREEN}✓${RESET} Logged in as: $whoami"
}

# Check Kubernetes
check_k8s() {
  echo -e "${BOLD}Kubernetes${RESET}"

  if ! command -v kubectl &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  local context
  context=$(kubectl config current-context 2>/dev/null || echo "")

  if [[ -z "$context" ]]; then
    echo -e "  ${RED}✗${RESET} No context configured"
    return
  fi

  echo -e "  ${GREEN}✓${RESET} Context: $context"

  local cluster user namespace
  cluster=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' 2>/dev/null || echo "")
  user=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.user}' 2>/dev/null || echo "")
  namespace=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || echo "")

  [[ -n "$cluster" ]] && echo -e "  ${DIM}Cluster: $cluster${RESET}"
  [[ -n "$user" ]] && echo -e "  ${DIM}User: $user${RESET}"
  [[ -n "$namespace" ]] && echo -e "  ${DIM}Namespace: $namespace${RESET}"

  if kubectl auth whoami --request-timeout=2s &>/dev/null 2>&1; then
    local whoami
    whoami=$(kubectl auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null || echo "")
    [[ -n "$whoami" ]] && echo -e "  ${DIM}Authenticated as: $whoami${RESET}"
  fi
}

# Check AWS ECR
check_ecr() {
  echo -e "${BOLD}AWS ECR${RESET}"

  if ! command -v aws &>/dev/null; then
    echo -e "  ${DIM}AWS CLI not installed${RESET}"
    return
  fi

  if ! command -v podman &>/dev/null; then
    echo -e "  ${DIM}Podman not installed${RESET}"
    return
  fi

  local account
  account=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null || echo "")

  if [[ -z "$account" ]]; then
    echo -e "  ${YELLOW}⚠${RESET} AWS not authenticated (required for ECR)"
    return
  fi

  local config_file=""
  if [[ -n "${XDG_RUNTIME_DIR:-}" && -f "${XDG_RUNTIME_DIR}/containers/auth.json" ]]; then
    config_file="${XDG_RUNTIME_DIR}/containers/auth.json"
  elif [[ -f "$HOME/.config/containers/auth.json" ]]; then
    config_file="$HOME/.config/containers/auth.json"
  elif [[ -f "$HOME/.docker/config.json" ]]; then
    config_file="$HOME/.docker/config.json"
  fi

  local found=0
  if [[ -n "$config_file" ]]; then
    local ecr_registries
    ecr_registries=$(grep -oE '[0-9]+\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com' "$config_file" 2>/dev/null | sort -u)

    if [[ -n "$ecr_registries" ]]; then
      while IFS= read -r registry; do
        echo -e "  ${GREEN}✓${RESET} Authenticated to: $registry"
        found=1
      done <<< "$ecr_registries"
    fi
  fi

  if [[ $found -eq 0 ]]; then
    echo -e "  ${DIM}No ECR auth found${RESET}"
    echo -e "  ${DIM}AWS Account: $account${RESET}"

    local region="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
    echo -e "  ${DIM}Login with: aws ecr get-login-password --region $region | podman login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com${RESET}"
  fi
}

# Check Cloudflare
check_cloudflare() {
  echo -e "${BOLD}Cloudflare${RESET}"

  if ! command -v cloudflared &>/dev/null; then
    echo -e "  ${DIM}Not installed${RESET}"
    return
  fi

  local cert_file="$HOME/.cloudflared/cert.pem"
  if [[ ! -f "$cert_file" ]]; then
    echo -e "  ${RED}✗${RESET} Not authenticated"
    echo -e "  ${DIM}Run: cloudflared login${RESET}"
    return
  fi

  local tunnel_output
  tunnel_output=$(cloudflared tunnel list 2>&1)

  if [[ $? -ne 0 ]]; then
    if [[ "$tunnel_output" == *"expired"* || "$tunnel_output" == *"unauthorized"* ]]; then
      echo -e "  ${YELLOW}⚠${RESET} Auth expired"
    else
      echo -e "  ${RED}✗${RESET} Auth error"
    fi
    echo -e "  ${DIM}Run: cloudflared login${RESET}"
    return
  fi

  echo -e "  ${GREEN}✓${RESET} Authenticated"

  local tunnel_count
  tunnel_count=$(echo "$tunnel_output" | grep -c "^[a-f0-9-]\{36\}" 2>/dev/null || echo "0")
  if [[ "$tunnel_count" -gt 0 ]]; then
    echo -e "  ${DIM}Tunnels: $tunnel_count${RESET}"
  fi
}

# Sync git config from GitHub
sync_from_gh() {
  echo -e "${BOLD}Syncing git config from GitHub${RESET}"
  echo ""

  if ! command -v gh &>/dev/null; then
    echo -e "  ${RED}✗${RESET} gh CLI not installed"
    return 1
  fi

  if ! gh auth status &>/dev/null; then
    echo -e "  ${RED}✗${RESET} gh not authenticated (run: gh auth login)"
    return 1
  fi

  local login name email user_id

  login=$(gh api user -q '.login' 2>/dev/null || echo "")
  if [[ -z "$login" ]]; then
    echo -e "  ${RED}✗${RESET} Could not fetch GitHub user info"
    return 1
  fi

  name=$(gh api user -q '.name // empty' 2>/dev/null || echo "")
  email=$(gh api user -q '.email // empty' 2>/dev/null || echo "")
  user_id=$(gh api user -q '.id' 2>/dev/null || echo "")

  if [[ -z "$name" ]]; then
    name="$login"
    echo -e "  ${DIM}No display name set, using login${RESET}"
  fi

  if [[ -z "$email" ]]; then
    if [[ -n "$user_id" ]]; then
      email="${user_id}+${login}@users.noreply.github.com"
      echo -e "  ${DIM}No public email, using noreply address${RESET}"
    else
      echo -e "  ${RED}✗${RESET} Could not determine email address"
      return 1
    fi
  fi

  echo -e "  ${DIM}Name:${RESET}  $name"
  echo -e "  ${DIM}Email:${RESET} $email"
  echo ""

  local current_name current_email
  current_name=$(git config --global user.name 2>/dev/null || echo "")
  current_email=$(git config --global user.email 2>/dev/null || echo "")

  if [[ "$current_name" == "$name" && "$current_email" == "$email" ]]; then
    echo -e "  ${GREEN}✓${RESET} Already configured"
    return 0
  fi

  git config --global user.name "$name"
  git config --global user.email "$email"

  echo -e "  ${GREEN}✓${RESET} Git config updated"

  if gh auth setup-git 2>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} Git credential helper configured"
  fi

  echo ""
  echo -e "${BOLD}Verification:${RESET}"
  check_git
}

# Main
main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ "${1:-}" == "sync" ]]; then
    sync_from_gh
    exit $?
  fi

  local domains=("$@")

  if [[ ${#domains[@]} -eq 0 ]]; then
    domains=("git" "gh")
  fi

  if [[ "${domains[0]}" == "all" ]]; then
    domains=("git" "gh" "oci" "ecr" "k8s" "aws" "cloudflare" "gcp" "azure" "npm")
  fi

  echo -e "${BOLD}IDENTITY CHECK${RESET}"
  echo ""

  for domain in "${domains[@]}"; do
    case "$domain" in
      git)           check_git ;;
      gh)            check_gh ;;
      oci|docker)    check_oci ;;
      ecr)           check_ecr ;;
      k8s|kubernetes) check_k8s ;;
      aws)           check_aws ;;
      cloudflare|cf) check_cloudflare ;;
      gcp)           check_gcp ;;
      azure)         check_azure ;;
      npm)           check_npm ;;
      *)             echo -e "${YELLOW}Unknown domain: $domain${RESET}" ;;
    esac
    echo ""
  done
}

main "$@"
