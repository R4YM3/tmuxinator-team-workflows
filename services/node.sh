#!/usr/bin/env bash
set -euo pipefail

SERVICE_VERSION="1"
REQUIRED_NODE_MAJOR="${TWF_NODE_REQUIRED_MAJOR:-20}"
REQUIRED_NVM_VERSION="${TWF_NVM_REQUIRED_VERSION:-0.40.0}"

ok() { printf "[ok] %s\n" "$1"; }
info() { printf "[info] %s\n" "$1"; }
warn() { printf "[warn] %s\n" "$1"; }
error() { printf "[error] %s\n" "$1" >&2; }

load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    . "$NVM_DIR/nvm.sh"
  elif command -v brew >/dev/null 2>&1 && [[ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]]; then
    . "$(brew --prefix nvm 2>/dev/null)/nvm.sh"
  fi
}

nvm_installation_exists() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  [[ -s "$NVM_DIR/nvm.sh" ]] && return 0
  [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]] && return 0
  [[ -s "/usr/local/opt/nvm/nvm.sh" ]] && return 0
  return 1
}

node_major_from_version() {
  local version="$1"
  version="${version#v}"
  echo "${version%%.*}"
}

check_service() {
  local missing=0
  if command -v nvm >/dev/null 2>&1; then
    local nvm_version
    nvm_version="$(nvm --version 2>/dev/null || true)"
    if [[ -n "$nvm_version" ]]; then
      ok "nvm found ($nvm_version, required >= $REQUIRED_NVM_VERSION)"
    else
      ok "nvm found (required >= $REQUIRED_NVM_VERSION)"
    fi
  elif nvm_installation_exists; then
    ok "nvm installation found (required >= $REQUIRED_NVM_VERSION)"
  else
    warn "nvm missing (required >= $REQUIRED_NVM_VERSION)"
    missing=1
  fi

  if command -v node >/dev/null 2>&1; then
    local node_version
    node_version="$(node --version 2>/dev/null || true)"
    if [[ -n "$node_version" ]]; then
      local node_major
      node_major="$(node_major_from_version "$node_version")"
      if [[ "$node_major" =~ ^[0-9]+$ ]] && [[ "$node_major" -ge "$REQUIRED_NODE_MAJOR" ]]; then
        ok "node found ($node_version, required >= v$REQUIRED_NODE_MAJOR)"
      else
        warn "node version too old ($node_version, required >= v$REQUIRED_NODE_MAJOR)"
        missing=1
      fi
    else
      ok "node found (required >= v$REQUIRED_NODE_MAJOR)"
    fi
  else
    warn "node missing (required >= v$REQUIRED_NODE_MAJOR)"
    missing=1
  fi

  if command -v npm >/dev/null 2>&1; then
    local npm_version
    npm_version="$(npm --version 2>/dev/null || true)"
    if [[ -n "$npm_version" ]]; then
      ok "npm found ($npm_version)"
    else
      ok "npm found"
    fi
  else
    warn "npm missing"
    missing=1
  fi

  [[ "$missing" -eq 0 ]]
}

install_nvm() {
  if command -v brew >/dev/null 2>&1; then
    info "Installing nvm with Homebrew"
    brew install nvm
    return 0
  fi

  if command -v curl >/dev/null 2>&1; then
    info "Installing nvm with official install script"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    info "Installing nvm with official install script"
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    return 0
  fi

  error "Cannot install nvm automatically (requires brew, curl, or wget)"
  return 1
}

install_service() {
  load_nvm

  if ! command -v nvm >/dev/null 2>&1; then
    install_nvm
    load_nvm
  fi

  if ! command -v nvm >/dev/null 2>&1; then
    error "nvm is still missing after installation attempt"
    return 1
  fi

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    info "Installing Node LTS via nvm"
    nvm install --lts
  fi

  nvm use --lts >/dev/null 2>&1 || true
}

main() {
  local command="${1:-}"
  case "$command" in
  version)
    echo "$SERVICE_VERSION"
    ;;
  check)
    check_service
    ;;
  install)
    install_service
    ;;
  *)
    echo "Usage: node.sh <version|check|install>" >&2
    exit 1
    ;;
  esac
}

main "$@"
