#!/usr/bin/env bash
set -euo pipefail

SERVICE_VERSION="1"

ok() { printf "[ok] %s\n" "$1"; }
info() { printf "[info] %s\n" "$1"; }
warn() { printf "[warn] %s\n" "$1"; }
error() { printf "[error] %s\n" "$1" >&2; }

check_service() {
  if command -v dotnet >/dev/null 2>&1; then
    ok "dotnet found"
    return 0
  fi

  warn "dotnet missing"
  return 1
}

install_service() {
  if command -v dotnet >/dev/null 2>&1; then
    ok "dotnet already installed"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Installing dotnet-sdk with Homebrew"
    brew install --cask dotnet-sdk
    return 0
  fi

  if command -v curl >/dev/null 2>&1; then
    info "Installing .NET SDK with dotnet-install script"
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    bash /tmp/dotnet-install.sh --channel LTS
    rm -f /tmp/dotnet-install.sh

    export PATH="$HOME/.dotnet:$PATH"
    if command -v dotnet >/dev/null 2>&1; then
      ok "dotnet installed to $HOME/.dotnet"
      warn "Add this to your shell rc file: export PATH=\"$HOME/.dotnet:\$PATH\""
      return 0
    fi
  fi

  error "Could not install dotnet automatically"
  return 1
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
    echo "Usage: dotnet.sh <version|check|install>" >&2
    exit 1
    ;;
  esac
}

main "$@"
