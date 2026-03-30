#!/usr/bin/env bash
set -euo pipefail

SERVICE_VERSION="1"

check_service() {
  command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1
}

install_service() {
  if check_service; then
    echo "[ok] web runtime already installed"
    return 0
  fi

if command -v brew >/dev/null 2>&1; then
    echo "[info] Installing node with Homebrew"
    brew install node
    return 0
  fi

  echo "[error] Could not install web runtime automatically" >&2
  return 1
}

case "${1:-}" in
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
  echo "Usage: web.sh <version|check|install>" >&2
  exit 1
  ;;
esac
