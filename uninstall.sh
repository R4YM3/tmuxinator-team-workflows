#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVELOPER_DIR="$REPO_DIR/developer"
DEVELOPER_PROJECTS_DIR="$DEVELOPER_DIR/projects"
INTERNAL_DIR="$REPO_DIR/.internal"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TMUXINATOR_DIR="$CONFIG_HOME/tmuxinator"

ENV_FILE="$INTERNAL_DIR/env.sh"
MANIFEST_FILE="$INTERNAL_DIR/install-manifest.txt"
INFO_FILE="$INTERNAL_DIR/INFO.md"

ASSUME_YES=false

REMOVED_COUNT=0
SKIPPED_COUNT=0

info() { printf "\033[1;34m[info]\033[0m %s\n" "$1"; }
ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$1"; }

usage() {
  cat <<'EOF'
Usage: bash uninstall.sh [options]

Options:
  --yes       Non-interactive mode
  -h, --help  Show this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --yes)
      ASSUME_YES=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      warn "Unknown option: $1"
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

remove_source_block() {
  local rc_file="$1"

  [[ -n "$rc_file" ]] || return 0
  [[ -f "$rc_file" ]] || return 0

  sed -i.bak '/# >>> tmuxinator team workflows >>>/,/# <<< tmuxinator team workflows <<</d' "$rc_file"
  rm -f "$rc_file.bak"

  ok "Removed shell block from $rc_file if present"
}

remove_link_file() {
  local link_file="$1"

  if [[ -L "$link_file" ]]; then
    rm -f "$link_file"
    ok "Removed symlink: $link_file"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
  elif [[ -e "$link_file" ]]; then
    warn "Skipped non-symlink file in tmuxinator dir: $link_file"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
  fi
}

remove_internal_file() {
  local file_path="$1"
  local label="$2"

  if [[ -e "$file_path" ]]; then
    rm -f "$file_path"
    ok "Removed $label: $file_path"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
  fi
}

remove_installed_files() {
  local rc_file_from_manifest=""
  local path=""

  if [[ -f "$MANIFEST_FILE" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue

      case "$line" in
      LINK_FILE=*)
        path="${line#LINK_FILE=}"
        remove_link_file "$path"
        ;;
      ENV_FILE=*)
        path="${line#ENV_FILE=}"
        remove_internal_file "$path" "env file"
        ;;
      INFO_FILE=*)
        path="${line#INFO_FILE=}"
        remove_internal_file "$path" "info file"
        ;;
      RC_FILE=*)
        rc_file_from_manifest="${line#RC_FILE=}"
        ;;
      esac
    done <"$MANIFEST_FILE"

    rm -f "$MANIFEST_FILE"
    ok "Removed manifest: $MANIFEST_FILE"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
  else
    warn "Manifest not found, falling back to internal file cleanup only"
    remove_internal_file "$ENV_FILE" "env file"
    remove_internal_file "$INFO_FILE" "info file"
  fi

  if [[ -n "$rc_file_from_manifest" ]]; then
    remove_source_block "$rc_file_from_manifest"
  else
    local detected_rc_file
    detected_rc_file="$(detect_shell_rc)"
    remove_source_block "$detected_rc_file"
  fi

  rmdir "$INTERNAL_DIR" 2>/dev/null || true
}

remove_developer_overrides() {
  if [[ ! -d "$DEVELOPER_PROJECTS_DIR" ]]; then
    return 0
  fi

  local override_files=()
  shopt -s nullglob
  override_files=("$DEVELOPER_PROJECTS_DIR"/*.override.yml)
  shopt -u nullglob

  if [[ ${#override_files[@]} -eq 0 ]]; then
    return 0
  fi

  echo
  warn "Developer override files found in $DEVELOPER_PROJECTS_DIR"
  local confirm_remove_overrides="N"
  if [[ "$ASSUME_YES" == true ]]; then
    confirm_remove_overrides="Y"
  else
    read -r -p "Remove these override files as well? [y/N]: " confirm_remove_overrides
  fi

  if [[ ! "${confirm_remove_overrides:-N}" =~ ^[Yy]$ ]]; then
    warn "Keeping developer override files"
    SKIPPED_COUNT=$((SKIPPED_COUNT + ${#override_files[@]}))
    return 0
  fi

  local override_file
  for override_file in "${override_files[@]}"; do
    rm -f "$override_file"
    ok "Removed override file: $override_file"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
  done
}

main() {
  parse_args "$@"
  remove_installed_files
  remove_developer_overrides

  echo
  ok "Uninstall complete"
  printf "Removed files: %d\n" "$REMOVED_COUNT"
  printf "Kept developer files: %d\n" "$SKIPPED_COUNT"
}

main "$@"
