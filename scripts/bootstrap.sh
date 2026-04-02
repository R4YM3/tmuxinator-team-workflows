#!/usr/bin/env bash
set -euo pipefail

OO_REPO_URL="${OO_REPO_URL:-https://github.com/R4YM3/loop.git}"
OO_INSTALL_ROOT="${OO_INSTALL_ROOT:-$HOME/.local/share/oo}"
OO_BIN_DIR="${OO_BIN_DIR:-$HOME/.local/bin}"
VERBOSE=false
OO_PATH_PERSISTED=false

RAW_BOOTSTRAP_URL="https://raw.githubusercontent.com/R4YM3/loop/main/scripts/bootstrap.sh"

failure_block() {
  local code="$1"
  local reason="$2"

  echo "✖ Installation failed ($code)"
  echo
  echo "Reason"
  echo "  $reason"
  echo
  echo "What you can do"
  echo "  • Check your internet connection"
  echo "  • Retry: curl -fsSL \"$RAW_BOOTSTRAP_URL\" | bash"
  echo "  • Run with debug: curl -fsSL \"$RAW_BOOTSTRAP_URL\" | bash -s -- --verbose"
}

confirm_install() {
  local prompt="$1"
  local response=""

  if [[ -t 0 ]]; then
    read -r -p "$prompt [Y/n]: " response
  elif [[ -r /dev/tty ]]; then
    read -r -p "$prompt [Y/n]: " response </dev/tty
  else
    return 1
  fi

  [[ -z "${response:-}" || "${response:-}" =~ ^[Yy]$ ]]
}

can_prompt_user() {
  [[ -t 0 && -t 1 ]] || [[ -r /dev/tty ]]
}

spinner_should_render() {
  [[ "$VERBOSE" != true && -t 1 ]]
}

spinner_start() {
  local label="$1"
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  (
    local i=0
    while :; do
      printf "\r  %s %s" "${frames[$((i % ${#frames[@]}))]}" "$label"
      sleep 0.1
      i=$((i + 1))
    done
  ) &
  BOOTSTRAP_SPINNER_PID=$!
  BOOTSTRAP_SPINNER_LABEL="$label"
}

spinner_stop() {
  local status="$1"
  local label="${2:-$BOOTSTRAP_SPINNER_LABEL}"
  if [[ -n "${BOOTSTRAP_SPINNER_PID:-}" ]]; then
    kill "$BOOTSTRAP_SPINNER_PID" >/dev/null 2>&1 || true
    wait "$BOOTSTRAP_SPINNER_PID" 2>/dev/null || true
    BOOTSTRAP_SPINNER_PID=""
  fi

  if [[ "$status" -eq 0 ]]; then
    printf "\r  ✓ %s\n" "$label"
  else
    printf "\r  ✖ %s\n" "$label"
  fi
}

run_step() {
  local label="$1"
  shift

  if spinner_should_render; then
    spinner_start "$label"
    set +e
    "$@"
    local rc=$?
    set -e
    spinner_stop "$rc" "$label"
    return "$rc"
  fi

  if [[ "$VERBOSE" == true ]]; then
    echo "  ... $label"
  fi
  "$@"
}

run_git() {
  if [[ "$VERBOSE" == true ]]; then
    git "$@"
  else
    git "$@" >/dev/null 2>&1
  fi
}

detect_package_manager() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt-get"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo ""
  fi
}

install_requirements() {
  local manager
  manager="$(detect_package_manager)"

  case "$manager" in
  brew)
    brew install tmux tmuxinator
    ;;
  apt-get)
    sudo apt-get update
    sudo apt-get install -y tmux ruby-full
    sudo gem install tmuxinator
    ;;
  dnf)
    sudo dnf install -y tmux ruby rubygems
    sudo gem install tmuxinator
    ;;
  pacman)
    sudo pacman -Sy --noconfirm tmux ruby
    sudo gem install tmuxinator
    ;;
  *)
    return 1
    ;;
  esac
}

ensure_required_dependencies() {
  local missing=()
  command -v tmux >/dev/null 2>&1 || missing+=("tmux")
  command -v tmuxinator >/dev/null 2>&1 || missing+=("tmuxinator")

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "  ✓ Required tools available (tmux, tmuxinator)"
    return 0
  fi

  echo "  ! Missing required tools: ${missing[*]}"

  if ! can_prompt_user; then
    failure_block "BST-002" "Missing required tools and no interactive prompt is available."
    return 1
  fi

  if ! confirm_install "Install missing required tools now?"; then
    failure_block "BST-003" "Required tools are missing and installation was canceled."
    return 1
  fi

  if ! run_step "Installing missing tools" install_requirements; then
    failure_block "BST-004" "Could not install required tools with a supported package manager."
    return 1
  fi

  command -v tmux >/dev/null 2>&1 || {
    failure_block "BST-005" "tmux is still missing after installation."
    return 1
  }
  command -v tmuxinator >/dev/null 2>&1 || {
    failure_block "BST-006" "tmuxinator is still missing after installation."
    return 1
  }

  echo "  ✓ Required tools installed (tmux, tmuxinator)"
}

detect_shell_rc_files() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
  zsh)
    printf '%s\n' "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.profile"
    ;;
  bash)
    printf '%s\n' "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"
    ;;
  fish)
    printf '%s\n' "$HOME/.config/fish/config.fish"
    ;;
  ksh)
    printf '%s\n' "$HOME/.kshrc" "$HOME/.profile"
    ;;
  sh | dash)
    printf '%s\n' "$HOME/.profile"
    ;;
  *)
    printf '%s\n' "$HOME/.profile"
    ;;
  esac
}

ensure_path_block_in_file() {
  local bin_dir="$1"
  local rc_file="$2"
  local start_marker="# >>> oo path >>>"
  local end_marker="# <<< oo path <<<"

  mkdir -p "$(dirname "$rc_file")"
  [[ -f "$rc_file" ]] || touch "$rc_file"

  if grep -qF "$start_marker" "$rc_file"; then
    return 0
  fi

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
}

ensure_path_persisted() {
  local bin_dir="$1"
  local rc_files=()
  local rc_file

  while IFS= read -r rc_file; do
    [[ -n "$rc_file" ]] || continue
    rc_files+=("$rc_file")
  done < <(detect_shell_rc_files)

  if [[ ${#rc_files[@]} -eq 0 ]]; then
    OO_PATH_PERSISTED=false
    return 0
  fi

  for rc_file in "${rc_files[@]}"; do
    ensure_path_block_in_file "$bin_dir" "$rc_file"
  done

  OO_PATH_PERSISTED=true
}

configure_cli_step() {
  mkdir -p "$OO_BIN_DIR"
  ln -sfn "$OO_INSTALL_ROOT/oo" "$OO_BIN_DIR/oo"
  chmod +x "$OO_INSTALL_ROOT/oo"
  ensure_path_persisted "$OO_BIN_DIR"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --verbose)
    VERBOSE=true
    shift
    ;;
  -h | --help)
    cat <<EOF
Usage: bash scripts/bootstrap.sh [--verbose]

Installs or updates oo and configures your shell PATH.
EOF
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

if [[ -z "$OO_REPO_URL" ]]; then
  failure_block "BST-001" "OO_REPO_URL is empty."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  failure_block "BST-007" "git is required for installation."
  exit 1
fi

echo "◆ Installing oo"
echo

echo "Checking system"
ensure_required_dependencies || exit 1
echo

echo "Preparing installation"
echo "  Location: ${OO_INSTALL_ROOT/#$HOME/~}"

mkdir -p "$(dirname "$OO_INSTALL_ROOT")"

before_rev=""
after_rev=""

if [[ -d "$OO_INSTALL_ROOT/.git" ]]; then
  before_rev="$(git -C "$OO_INSTALL_ROOT" rev-parse --short HEAD 2>/dev/null || true)"
  echo "  ✓ Existing installation found"
elif [[ -e "$OO_INSTALL_ROOT" ]]; then
  failure_block "BST-008" "Install location exists but is not a git checkout."
  exit 1
else
  echo "  ✓ Creating installation directory"
fi
echo

echo "Updating runtime"
if [[ -d "$OO_INSTALL_ROOT/.git" ]]; then
  if ! run_step "Checking for updates" run_git -C "$OO_INSTALL_ROOT" pull --ff-only; then
    failure_block "BST-009" "Could not fetch runtime from repository."
    exit 1
  fi
else
  if ! run_step "Cloning runtime" run_git clone "$OO_REPO_URL" "$OO_INSTALL_ROOT"; then
    failure_block "BST-010" "Could not clone runtime repository."
    exit 1
  fi
fi

after_rev="$(git -C "$OO_INSTALL_ROOT" rev-parse --short HEAD 2>/dev/null || true)"
if [[ -n "$before_rev" && "$before_rev" == "$after_rev" ]]; then
  echo "  ✓ Already up to date ($after_rev)"
elif [[ -n "$before_rev" ]]; then
  echo "  ✓ Updated to latest version ($after_rev)"
else
  echo "  ✓ Installed runtime ($after_rev)"
fi
echo

echo "Configuring CLI"
if ! run_step "Configuring CLI" configure_cli_step; then
  failure_block "BST-011" "Failed to configure CLI symlink or PATH."
  exit 1
fi

if [[ "$OO_PATH_PERSISTED" == true ]]; then
  echo "  ✓ CLI symlink installed"
  echo "  ✓ PATH configured"
else
  echo "  ✓ CLI symlink installed"
  echo "  ! PATH was not configured automatically"
fi
echo

echo "✓ Installation complete"
echo
echo "Next:"
echo "  1. Restart your shell → exec \"\$SHELL\" -l"
echo "  2. Open your workflow repo → cd /path/to/your/codebase"
echo "  3. Initialize → oo add"
