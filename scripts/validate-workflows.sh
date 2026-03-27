#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_REPO_DIR="${TWF_WORKFLOW_REPO:-$RUNTIME_DIR}"

TEMPLATES_DIR="$WORKFLOW_REPO_DIR/templates/projects"
HELPER_FILE="$RUNTIME_DIR/templates/helpers/workflow.rb"

REPOSITORIES_ROOT="${REPOSITORIES_ROOT:-$WORKFLOW_REPO_DIR}"
TEAM_WORKFLOWS_REPO_DIR="${TEAM_WORKFLOWS_REPO_DIR:-$WORKFLOW_REPO_DIR}"
TEAM_WORKFLOWS_HELPER_FILE="${TEAM_WORKFLOWS_HELPER_FILE:-$HELPER_FILE}"

[[ -d "$TEMPLATES_DIR" ]] || {
  echo "[error] Missing templates directory: $TEMPLATES_DIR" >&2
  exit 1
}

[[ -f "$TEAM_WORKFLOWS_HELPER_FILE" ]] || {
  echo "[error] Missing helper file: $TEAM_WORKFLOWS_HELPER_FILE" >&2
  exit 1
}

shopt -s nullglob
files=("$TEMPLATES_DIR"/*.yml)
shopt -u nullglob

[[ ${#files[@]} -gt 0 ]] || {
  echo "[error] No project templates found in $TEMPLATES_DIR" >&2
  exit 1
}

echo "[info] Validating ${#files[@]} workflow template(s)..."

for file in "${files[@]}"; do
  if ! REPOSITORIES_ROOT="$REPOSITORIES_ROOT" TEAM_WORKFLOWS_REPO_DIR="$TEAM_WORKFLOWS_REPO_DIR" TEAM_WORKFLOWS_HELPER_FILE="$TEAM_WORKFLOWS_HELPER_FILE" ruby -rerubi -e 'file=ARGV[0]; content=File.read(file); out=eval(Erubi::Engine.new(content).src); require "yaml"; YAML.safe_load(out, aliases: true)' "$file"; then
    echo "[error] Validation failed: $file" >&2
    exit 1
  fi
  echo "[ok] $file"
done

echo "[ok] All workflow templates are valid"
