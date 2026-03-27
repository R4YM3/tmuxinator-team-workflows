#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${TWF_WORKFLOW_REPO:-$RUNTIME_DIR}"
TEMPLATES_DIR="$REPO_DIR/templates/projects"
DEVELOPER_DIR="$REPO_DIR/developer"
DEVELOPER_PROJECTS_DIR="$DEVELOPER_DIR/projects"
INTERNAL_DIR="$REPO_DIR/.internal"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TMUXINATOR_DIR="$CONFIG_HOME/tmuxinator"

ENV_FILE="$INTERNAL_DIR/env.sh"
MANIFEST_FILE="$INTERNAL_DIR/install-manifest.txt"
TMP_MANIFEST_FILE="$INTERNAL_DIR/.install-manifest.tmp"
INFO_FILE="$INTERNAL_DIR/INFO.md"

LINKED_COUNT=0

ASSUME_YES=false
SKIP_SHELL_RC=false
CHECK_ONLY=false
REPOSITORIES_ROOT_INPUT=""

info() { printf "\033[1;34m[info]\033[0m %s\n" "$1"; }
ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1" >&2; }

usage() {
  cat <<'EOF'
Usage: bash install.sh [options]

Install tmuxinator team workflows into ~/.config/tmuxinator using symlinks
from templates/projects and configure environment loading.

Options:
  --yes              Non-interactive mode; accepts safe defaults
  --repos-root PATH  Set REPOSITORIES_ROOT without prompting
  --no-shell-rc      Do not add env loader block to shell rc file
  --check            Validate templates only; do not write files/symlinks
  -h, --help         Show this help

Examples:
  bash install.sh
  bash install.sh --yes --repos-root "$HOME/code"
  bash install.sh --check --repos-root "$HOME/code"

What install writes:
  - .internal/env.sh
  - .internal/install-manifest.txt
  - .internal/INFO.md
  - symlinks in ~/.config/tmuxinator/*.yml

Required at runtime (rendering templates):
  REPOSITORIES_ROOT
  TEAM_WORKFLOWS_REPO_DIR
  TEAM_WORKFLOWS_HELPER_FILE
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --yes)
      ASSUME_YES=true
      shift
      ;;
    --repos-root)
      [[ $# -ge 2 ]] || {
        error "--repos-root requires a path"
        exit 1
      }
      REPOSITORIES_ROOT_INPUT="$2"
      shift 2
      ;;
    --no-shell-rc)
      SKIP_SHELL_RC=true
      shift
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
    esac
  done
}

detect_shell_rc() {
  case "${SHELL:-}" in
  */zsh) echo "$HOME/.zshrc" ;;
  */bash) echo "$HOME/.bashrc" ;;
  */fish) echo "$HOME/.config/fish/config.fish" ;;
  *) echo "" ;;
  esac
}

check_tmux() {
  if command -v tmux >/dev/null 2>&1; then
    ok "tmux is installed"
    return 0
  fi

  warn "tmux is required but not installed."

  if command -v brew >/dev/null 2>&1; then
    if [[ "$ASSUME_YES" == true ]]; then
      confirm_tmux="Y"
    else
      read -r -p "Install tmux with Homebrew? [Y/n]: " confirm_tmux
    fi
    if [[ ! "${confirm_tmux:-Y}" =~ ^[Nn]$ ]]; then
      brew install tmux
      if command -v tmux >/dev/null 2>&1; then
        ok "tmux installed via Homebrew"
        return 0
      fi
    fi
    info "Install tmux manually with:"
    echo "  brew install tmux"
  elif command -v apt >/dev/null 2>&1; then
    if [[ "$ASSUME_YES" == true ]]; then
      confirm_tmux="Y"
    else
      read -r -p "Install tmux with apt? [Y/n]: " confirm_tmux
    fi
    if [[ ! "${confirm_tmux:-Y}" =~ ^[Nn]$ ]]; then
      sudo apt update
      sudo apt install -y tmux
      if command -v tmux >/dev/null 2>&1; then
        ok "tmux installed via apt"
        return 0
      fi
    fi
    info "Install tmux manually with:"
    echo "  sudo apt install tmux"
  else
    info "Please install tmux manually."
  fi

  exit 1
}

print_gem_path_help() {
  local gem_bin=""
  gem_bin="$(ruby -r rubygems -e 'puts Gem.user_dir + "/bin"' 2>/dev/null || true)"

  if [[ -n "$gem_bin" ]]; then
    warn "tmuxinator may have been installed, but is not yet available on PATH."
    info "You may need to add this directory to your PATH:"
    printf "  %s\n" "$gem_bin"
    echo
    echo "Example:"
    printf '  export PATH="$PATH:%s"\n' "$gem_bin"
    echo
    echo "Then restart your shell or reload your shell config."
  fi
}

check_tmuxinator() {
  if command -v tmuxinator >/dev/null 2>&1; then
    ok "tmuxinator is already installed"
    return 0
  fi

  warn "tmuxinator is not installed."

  if [[ "${OSTYPE:-}" == "darwin"* ]] && ! command -v brew >/dev/null 2>&1; then
    info "On macOS, Homebrew is the preferred install method when available."
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Preferred install method on macOS: Homebrew"
    if [[ "$ASSUME_YES" == true ]]; then
      confirm_brew="Y"
    else
      read -r -p "Install tmuxinator with Homebrew? [Y/n]: " confirm_brew
    fi
    if [[ ! "${confirm_brew:-Y}" =~ ^[Nn]$ ]]; then
      brew install tmuxinator
      if command -v tmuxinator >/dev/null 2>&1; then
        ok "tmuxinator installed via Homebrew"
        return 0
      fi
      error "tmuxinator install via Homebrew appears to have failed"
      exit 1
    fi
  fi

  if command -v gem >/dev/null 2>&1; then
    if [[ "$ASSUME_YES" == true ]]; then
      confirm_gem="Y"
    else
      read -r -p "Install tmuxinator with RubyGems? [Y/n]: " confirm_gem
    fi
    if [[ ! "${confirm_gem:-Y}" =~ ^[Nn]$ ]]; then
      gem install tmuxinator
      if command -v tmuxinator >/dev/null 2>&1; then
        ok "tmuxinator installed via RubyGems"
        return 0
      fi

      print_gem_path_help
      error "tmuxinator install via RubyGems appears to have failed or is not yet on PATH"
      exit 1
    fi
  fi

  warn "tmuxinator was not installed automatically."
  echo "Manual install options:"
  echo "  brew install tmuxinator"
  echo "  gem install tmuxinator"
  exit 1
}

ensure_internal_dir() {
  mkdir -p "$INTERNAL_DIR"
}

check_existing_install() {
  if [[ "$CHECK_ONLY" == true ]]; then
    return 0
  fi

  if [[ -f "$MANIFEST_FILE" ]]; then
    echo
    info "Existing installation detected."
    echo
    echo "This installer will:"
    echo "  - keep templates as the source of truth in $TEMPLATES_DIR"
    echo "  - keep developer overrides in $DEVELOPER_PROJECTS_DIR"
    echo "  - update symlinks in $TMUXINATOR_DIR"
    echo "  - refresh internal metadata in $INTERNAL_DIR"
    echo
    if [[ "$ASSUME_YES" == true ]]; then
      confirm_install="Y"
    else
      read -r -p "Continue installation? [Y/n]: " confirm_install
    fi
    if [[ "${confirm_install:-Y}" =~ ^[Nn]$ ]]; then
      info "Installation cancelled."
      exit 0
    fi
  else
    echo
    info "Fresh installation detected."
    echo "This installer will set up shared workflows, developer override folders, and tmuxinator symlinks."
  fi
}

write_info_file() {
  ensure_internal_dir

  cat >"$INFO_FILE" <<'EOF'
# Internal installer state

This directory is created by the **tmuxinator-team-workflows installer**.

It stores metadata used by the installation and uninstall scripts.

Files stored here:

- `env.sh` — environment variables used by tmuxinator templates
- `install-manifest.txt` — tracks installed files and symlinks
- `INFO.md` — this explanation

You normally **do not need to modify anything in this folder**.

⚠️ Editing or deleting files here may break the installation or prevent the uninstall script from working correctly.

This folder is managed automatically by:

- `install.sh`
- `uninstall.sh`
EOF

  ok "Wrote info file: $INFO_FILE"
}

install_env_file() {
  local repositories_root="$1"

  ensure_internal_dir

  cat >"$ENV_FILE" <<EOF
#!/usr/bin/env bash
export REPOSITORIES_ROOT="$repositories_root"
export TEAM_WORKFLOWS_REPO_DIR="$REPO_DIR"
export TEAM_WORKFLOWS_HELPER_FILE="$RUNTIME_DIR/templates/helpers/workflow.rb"
EOF

  chmod +x "$ENV_FILE"
  ok "Wrote env file: $ENV_FILE"
}

append_source_block_if_missing() {
  local rc_file="$1"
  local source_cmd="$2"

  mkdir -p "$(dirname "$rc_file")"
  touch "$rc_file"

  if grep -Fqs "# >>> tmuxinator team workflows >>>" "$rc_file"; then
    ok "Shell block already present in $rc_file"
    return 0
  fi

  cat >>"$rc_file" <<EOF

# >>> tmuxinator team workflows >>>
$source_cmd
# <<< tmuxinator team workflows <<<
EOF

  ok "Added shell block to $rc_file"
}

add_manifest_entry() {
  local entry="$1"

  touch "$TMP_MANIFEST_FILE"

  if ! grep -Fqx "$entry" "$TMP_MANIFEST_FILE" 2>/dev/null; then
    printf "%s\n" "$entry" >>"$TMP_MANIFEST_FILE"
  fi
}

prepare_manifest() {
  ensure_internal_dir
  : >"$TMP_MANIFEST_FILE"
}

cleanup_previous_links() {
  [[ -f "$MANIFEST_FILE" ]] || return 0

  local line
  local path
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    case "$line" in
    LINK_FILE=*)
      path="${line#LINK_FILE=}"
      if [[ -L "$path" ]]; then
        rm -f "$path"
        info "Removed previous managed symlink: $path"
      fi
      ;;
    esac
  done <"$MANIFEST_FILE"
}

finalize_manifest() {
  mv "$TMP_MANIFEST_FILE" "$MANIFEST_FILE"
  ok "Wrote manifest: $MANIFEST_FILE"
}

create_symlink() {
  local source_file="$1"
  local symlink_path="$2"

  mkdir -p "$(dirname "$symlink_path")"

  if [[ -L "$symlink_path" ]]; then
    local current_target=""
    current_target="$(readlink "$symlink_path")"
    if [[ "$current_target" == "$source_file" ]]; then
      info "Symlink already correct: $symlink_path"
      return 0
    fi
    rm -f "$symlink_path"
  elif [[ -e "$symlink_path" ]]; then
    warn "Existing non-symlink file found at $symlink_path"
    read -r -p "Replace it with a symlink? [y/N]: " confirm_replace
    if [[ ! "${confirm_replace:-N}" =~ ^[Yy]$ ]]; then
      warn "Skipped symlink: $symlink_path"
      return 1
    fi
    rm -f "$symlink_path"
  fi

  ln -s "$source_file" "$symlink_path"
  ok "Linked: $symlink_path -> $source_file"
  LINKED_COUNT=$((LINKED_COUNT + 1))
}

install_tmuxinator_projects() {
  [[ "$CHECK_ONLY" == true ]] && return 0

  mkdir -p "$TMUXINATOR_DIR"
  mkdir -p "$DEVELOPER_PROJECTS_DIR"

  local files=()
  shopt -s nullglob
  files=("$TEMPLATES_DIR"/*.yml)
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    error "No tmuxinator project files found in: $TEMPLATES_DIR"
    exit 1
  fi

  local template_file filename tmuxinator_link
  for template_file in "${files[@]}"; do
    filename="$(basename "$template_file")"
    tmuxinator_link="$TMUXINATOR_DIR/$filename"

    add_manifest_entry "LINK_FILE=$tmuxinator_link"
    create_symlink "$template_file" "$tmuxinator_link" || true
  done

  add_manifest_entry "ENV_FILE=$ENV_FILE"
  add_manifest_entry "INFO_FILE=$INFO_FILE"
}

validate_templates() {
  local helper_file="$RUNTIME_DIR/templates/helpers/workflow.rb"
  local project_file

  [[ -f "$helper_file" ]] || {
    error "Helper file not found: $helper_file"
    exit 1
  }

  shopt -s nullglob
  local files=("$TEMPLATES_DIR"/*.yml)
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    error "No tmuxinator project files found in: $TEMPLATES_DIR"
    exit 1
  fi

  for project_file in "${files[@]}"; do
    if ! REPOSITORIES_ROOT="$REPOSITORIES_ROOT" TEAM_WORKFLOWS_REPO_DIR="$REPO_DIR" TEAM_WORKFLOWS_HELPER_FILE="$helper_file" ruby -rerubi -e 'file=ARGV[0]; content=File.read(file); out=eval(Erubi::Engine.new(content).src); require "yaml"; YAML.safe_load(out, aliases: true)' "$project_file"; then
      error "Template validation failed: $project_file"
      exit 1
    fi
  done

  ok "Validated ${#files[@]} template(s)"
}

main() {
  parse_args "$@"

  if [[ "$CHECK_ONLY" != true ]]; then
    check_tmux
    check_tmuxinator
  fi

  if [[ ! -d "$TEMPLATES_DIR" ]]; then
    error "Templates directory not found: $TEMPLATES_DIR"
    exit 1
  fi

  local default_root
  default_root="$(cd "$REPO_DIR/.." && pwd)"

  local repositories_root="$REPOSITORIES_ROOT_INPUT"
  if [[ -z "$repositories_root" ]]; then
    if [[ "$ASSUME_YES" == true ]]; then
      repositories_root="$default_root"
    else
      read -r -p "Enter your repositories root path [$default_root]: " repositories_root
      repositories_root="${repositories_root:-$default_root}"
    fi
  fi

  case "$repositories_root" in
  "~") repositories_root="$HOME" ;;
  "~/"*) repositories_root="$HOME/${repositories_root#~/}" ;;
  esac

  if [[ ! -d "$repositories_root" ]]; then
    warn "Path does not exist: $repositories_root"
    if [[ "$ASSUME_YES" == true ]]; then
      confirm_continue="N"
    else
      read -r -p "Continue anyway? [y/N]: " confirm_continue
    fi
    [[ "${confirm_continue:-N}" =~ ^[Yy]$ ]] || exit 1
  fi

  export REPOSITORIES_ROOT="$repositories_root"

  if [[ "$CHECK_ONLY" == true ]]; then
    validate_templates
    ok "Check complete"
    exit 0
  fi

  check_existing_install
  cleanup_previous_links
  prepare_manifest
  write_info_file
  install_env_file "$repositories_root"
  # Load all workflow env vars into the current installer process.
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  ok "Loaded workflow env vars for this install session"

  local rc_file source_cmd
  rc_file="$(detect_shell_rc)"

  if [[ "$SKIP_SHELL_RC" == true ]]; then
    warn "Skipped shell config update (--no-shell-rc)"
  elif [[ -n "$rc_file" ]]; then
    if [[ "$rc_file" == *"/config.fish" ]]; then
      source_cmd="test -f \"$ENV_FILE\"; and source \"$ENV_FILE\""
    else
      source_cmd="[ -f \"$ENV_FILE\" ] && source \"$ENV_FILE\""
    fi

    if [[ "$ASSUME_YES" == true ]]; then
      confirm_rc="Y"
    else
      read -r -p "Add REPOSITORIES_ROOT loader to $rc_file? [Y/n]: " confirm_rc
    fi
    if [[ ! "${confirm_rc:-Y}" =~ ^[Nn]$ ]]; then
      append_source_block_if_missing "$rc_file" "$source_cmd"
      add_manifest_entry "RC_FILE=$rc_file"
    else
      warn "Skipped shell config update"
    fi
  else
    warn "Could not detect supported shell from SHELL=${SHELL:-unknown}"
  fi

  install_tmuxinator_projects
  finalize_manifest

  echo
  ok "Installation complete"
  printf "REPOSITORIES_ROOT=%s\n" "$REPOSITORIES_ROOT"
  printf "Shared templates dir: %s\n" "$TEMPLATES_DIR"
  printf "Developer dir: %s\n" "$DEVELOPER_DIR"
  printf "Developer projects dir: %s\n" "$DEVELOPER_PROJECTS_DIR"
  printf "Internal dir: %s\n" "$INTERNAL_DIR"
  printf "Tmuxinator config dir: %s\n" "$TMUXINATOR_DIR"
  printf "Symlinks created/updated: %d\n" "$LINKED_COUNT"

  echo
  info "Developers can add personal overrides here:"
  printf "  %s\n" "$DEVELOPER_PROJECTS_DIR"

  if [[ -n "${rc_file:-}" ]]; then
    info "Open a new shell or run:"
    printf "  source \"%s\"\n" "$rc_file"
  else
    info "Manually source this file from your shell config:"
    printf '  [ -f "%s" ] && source "%s"\n' "$ENV_FILE" "$ENV_FILE"
  fi

  echo
  echo "Next steps:"
  echo "  tmuxinator list"
  echo "  tmuxinator start <project-name>"
}

main "$@"
