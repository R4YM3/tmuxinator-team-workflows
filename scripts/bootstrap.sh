#!/usr/bin/env bash
set -euo pipefail

TWF_REPO_URL="${TWF_REPO_URL:-https://github.com/R4YM3/tmuxinator-team-workflows.git}"
TWF_INSTALL_ROOT="${TWF_INSTALL_ROOT:-$HOME/.local/share/twf}"
TWF_BIN_DIR="${TWF_BIN_DIR:-$HOME/.local/bin}"

ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$1"; }
info() { printf "\033[1;34m[info]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1" >&2; }

detect_shell_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
  zsh)
    echo "$HOME/.zshrc"
    ;;
  bash)
    if [[ -f "$HOME/.bash_profile" ]]; then
      echo "$HOME/.bash_profile"
    else
      echo "$HOME/.bashrc"
    fi
    ;;
  fish)
    echo "$HOME/.config/fish/config.fish"
    ;;
  *)
    echo ""
    ;;
  esac
}

ensure_path_persisted() {
  local bin_dir="$1"
  local rc_file
  rc_file="$(detect_shell_rc)"

  if [[ -z "$rc_file" ]]; then
    warn "Could not detect shell rc file from SHELL=${SHELL:-unknown}"
    return 0
  fi

  mkdir -p "$(dirname "$rc_file")"
  [[ -f "$rc_file" ]] || touch "$rc_file"

  local start_marker="# >>> twf path >>>"
  local end_marker="# <<< twf path <<<"

  if grep -qF "$start_marker" "$rc_file"; then
    ok "PATH block already present in $rc_file"
  else
    if [[ "$rc_file" == *"/config.fish" ]]; then
      {
        printf '\n%s\n' "$start_marker"
        printf 'if not contains "%s" $PATH\n' "$bin_dir"
        printf '  set -gx PATH "%s" $PATH\n' "$bin_dir"
        printf 'end\n'
        printf '%s\n' "$end_marker"
      } >>"$rc_file"
    else
      {
        printf '\n%s\n' "$start_marker"
        printf 'export PATH="%s:$PATH"\n' "$bin_dir"
        printf '%s\n' "$end_marker"
      } >>"$rc_file"
    fi
    ok "Added twf PATH block to $rc_file"
  fi
}

if [[ -z "$TWF_REPO_URL" ]]; then
  error "TWF_REPO_URL is empty."
  info "Set TWF_REPO_URL and rerun, for example:"
  echo "  TWF_REPO_URL='https://github.com/R4YM3/tmuxinator-team-workflows.git' bash scripts/bootstrap.sh"
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

ensure_path_persisted "$TWF_BIN_DIR"

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

ok "Bootstrap complete"
echo
info "Next steps:"
echo "  export PATH=\"$TWF_BIN_DIR:\$PATH\""
echo "  mkdir -p \"$HOME/code/team-workflows\" && cd \"$HOME/code/team-workflows\""
echo "  twf add my-workflow"
echo "  twf validate"
echo "  twf start my-workflow"
