#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_REPO_DIR="${TWF_WORKFLOW_REPO:-}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TMUXINATOR_DIR="$CONFIG_HOME/tmuxinator"
TEMPLATES_DIR="$WORKFLOW_REPO_DIR/templates/projects"
DEVELOPER_DIR="$WORKFLOW_REPO_DIR/developer/projects"

ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1"; }

[[ -n "$WORKFLOW_REPO_DIR" ]] || {
  error "TWF_WORKFLOW_REPO is required"
  exit 1
}

command -v tmux >/dev/null 2>&1 && ok "tmux found" || error "tmux not found"
command -v tmuxinator >/dev/null 2>&1 && ok "tmuxinator found" || error "tmuxinator not found"

if [[ -d "$TEMPLATES_DIR" ]]; then
  ok "Workflow templates dir exists: $TEMPLATES_DIR"
else
  error "Workflow templates dir missing: $TEMPLATES_DIR"
  exit 1
fi

if [[ -d "$DEVELOPER_DIR" ]]; then
  ok "Developer overrides dir exists: $DEVELOPER_DIR"
else
  error "Developer overrides dir missing: $DEVELOPER_DIR"
  exit 1
fi

if [[ -d "$TMUXINATOR_DIR" ]]; then
  ok "Tmuxinator config dir exists: $TMUXINATOR_DIR"
else
  warn "Tmuxinator config dir missing: $TMUXINATOR_DIR"
fi

shopt -s nullglob
project_files=("$TEMPLATES_DIR"/*.yml)
shopt -u nullglob

if [[ ${#project_files[@]} -eq 0 ]]; then
  warn "No workflow project templates found in $TEMPLATES_DIR"
else
  ok "Found ${#project_files[@]} project template(s)"
fi

project_file=""
for project_file in "${project_files[@]}"; do
  project_name="$(basename "${project_file%.yml}")"
  alias_file="$TMUXINATOR_DIR/$project_name.yml"

  if [[ ! -e "$alias_file" ]]; then
    warn "Missing alias for '$project_name': $alias_file"
    continue
  fi

  if [[ -L "$alias_file" ]]; then
    alias_target="$(readlink "$alias_file")"
    if [[ "$alias_target" == "$project_file" ]]; then
      ok "Alias linked for '$project_name'"
    else
      warn "Alias target differs for '$project_name': $alias_target"
    fi
  elif [[ -f "$alias_file" ]]; then
    warn "Alias exists as regular file for '$project_name': $alias_file"
  else
    warn "Alias path is not a file for '$project_name': $alias_file"
  fi
done

TWF_WORKFLOW_REPO="$WORKFLOW_REPO_DIR" bash "$RUNTIME_DIR/scripts/validate-workflows.sh"
