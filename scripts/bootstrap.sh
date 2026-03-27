#!/usr/bin/env bash
set -euo pipefail

TWF_REPO_URL="${TWF_REPO_URL:-TODO_GITHUB_REPO_URL}"
TWF_INSTALL_ROOT="${TWF_INSTALL_ROOT:-$HOME/.local/share/twf}"
TWF_BIN_DIR="${TWF_BIN_DIR:-$HOME/.local/bin}"

ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$1"; }
info() { printf "\033[1;34m[info]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1" >&2; }

if [[ "$TWF_REPO_URL" == "TODO_GITHUB_REPO_URL" ]]; then
  error "Bootstrap repository URL is not configured yet."
  info "Set TWF_REPO_URL and rerun, for example:"
  echo "  TWF_REPO_URL='https://github.com/your-org/tmuxinator-team-workflows.git' bash scripts/bootstrap.sh"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  error "git is required for bootstrap"
  exit 1
fi

mkdir -p "$(dirname "$TWF_INSTALL_ROOT")"

if [[ -d "$TWF_INSTALL_ROOT/.git" ]]; then
  info "Updating existing installation at $TWF_INSTALL_ROOT"
  git -C "$TWF_INSTALL_ROOT" pull --ff-only
elif [[ -e "$TWF_INSTALL_ROOT" ]]; then
  error "Install root exists and is not a git checkout: $TWF_INSTALL_ROOT"
  info "Remove it manually or choose another location with TWF_INSTALL_ROOT"
  exit 1
else
  info "Cloning twf repository into $TWF_INSTALL_ROOT"
  git clone "$TWF_REPO_URL" "$TWF_INSTALL_ROOT"
fi

mkdir -p "$TWF_BIN_DIR"
ln -sfn "$TWF_INSTALL_ROOT/twf" "$TWF_BIN_DIR/twf"
chmod +x "$TWF_INSTALL_ROOT/twf"
ok "Installed CLI symlink: $TWF_BIN_DIR/twf"

case ":$PATH:" in
*":$TWF_BIN_DIR:"*)
  ok "$TWF_BIN_DIR is on PATH"
  ;;
*)
  warn "$TWF_BIN_DIR is not on PATH"
  info "Add this line to your shell rc file:"
  printf '  export PATH="%s:$PATH"\n' "$TWF_BIN_DIR"
  ;;
esac

info "Running twf install"
"$TWF_INSTALL_ROOT/twf" install --yes "$@"
ok "Bootstrap complete"
