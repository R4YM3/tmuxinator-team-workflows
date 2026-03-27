#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_REPO_DIR="${TWF_WORKFLOW_REPO:-$RUNTIME_DIR}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TMUXINATOR_DIR="$CONFIG_HOME/tmuxinator"
INTERNAL_ENV="$WORKFLOW_REPO_DIR/.internal/env.sh"

ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1"; }

command -v tmux >/dev/null 2>&1 && ok "tmux found" || error "tmux not found"
command -v tmuxinator >/dev/null 2>&1 && ok "tmuxinator found" || error "tmuxinator not found"

if [[ -f "$INTERNAL_ENV" ]]; then
  ok "Internal env file exists: $INTERNAL_ENV"
else
  warn "Internal env file missing: $INTERNAL_ENV"
fi

if [[ -n "${REPOSITORIES_ROOT:-}" ]]; then
  ok "REPOSITORIES_ROOT is set"
else
  warn "REPOSITORIES_ROOT is not set in current shell"
fi

if [[ -n "${TEAM_WORKFLOWS_REPO_DIR:-}" ]]; then
  ok "TEAM_WORKFLOWS_REPO_DIR is set"
else
  warn "TEAM_WORKFLOWS_REPO_DIR is not set in current shell"
fi

if [[ -n "${TEAM_WORKFLOWS_HELPER_FILE:-}" ]]; then
  if [[ -f "$TEAM_WORKFLOWS_HELPER_FILE" ]]; then
    ok "TEAM_WORKFLOWS_HELPER_FILE points to a file"
  else
    warn "TEAM_WORKFLOWS_HELPER_FILE points to missing file: $TEAM_WORKFLOWS_HELPER_FILE"
  fi
else
  warn "TEAM_WORKFLOWS_HELPER_FILE is not set in current shell"
fi

if [[ -d "$TMUXINATOR_DIR" ]]; then
  ok "Tmuxinator config dir exists: $TMUXINATOR_DIR"
else
  warn "Tmuxinator config dir missing: $TMUXINATOR_DIR"
fi

TWF_WORKFLOW_REPO="$WORKFLOW_REPO_DIR" bash "$RUNTIME_DIR/scripts/validate-workflows.sh"
