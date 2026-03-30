#!/usr/bin/env bash
set -euo pipefail

SERVICE_VERSION="1"

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

check_service() {
  load_nvm

  local missing=0
  if command -v nvm >/dev/null 2>&1; then
    ok "nvm found"
  else
    warn "nvm missing"
    missing=1
  fi

  if command -v node >/dev/null 2>&1; then
    ok "node found"
  else
    warn "node missing"
    missing=1
  fi

  if command -v npm >/dev/null 2>&1; then
    ok "npm found"
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
