#!/usr/bin/env bash
set -euo pipefail

SERVICE_VERSION="1"

check_service() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

install_service() {
  if check_service; then
    echo "[ok] container runtime already ready"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    echo "[info] Installing docker desktop with Homebrew"
    brew install --cask docker
    echo "[warn] Start Docker Desktop once, then rerun checks"
    return 0
  fi

  echo "[error] Could not install container runtime automatically" >&2
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
  echo "Usage: containers.sh <version|check|install>" >&2
  exit 1
  ;;
esac
