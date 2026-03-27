#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="${1:-}"

if [[ -z "$NAME" ]]; then
  echo "Usage: bash scripts/new-workflow.sh <workflow-name>"
  exit 1
fi

PROJECT_FILE="$REPO_DIR/templates/projects/$NAME.yml"
OVERRIDE_FILE="$REPO_DIR/developer/projects/$NAME.override.yml"
WINDOW_PARTIAL_FILE="$REPO_DIR/templates/partials/windows/$NAME.yml.erb"

mkdir -p "$REPO_DIR/templates/projects" "$REPO_DIR/developer/projects" "$REPO_DIR/templates/partials/windows"

if [[ -e "$PROJECT_FILE" || -e "$OVERRIDE_FILE" || -e "$WINDOW_PARTIAL_FILE" ]]; then
  echo "[error] One or more files already exist for '$NAME'"
  exit 1
fi

cat >"$PROJECT_FILE" <<EOF
name: $NAME
root: <%= ENV.fetch("REPOSITORIES_ROOT") %>/$NAME

startup_window: app

<%
Kernel.load ENV.fetch("TEAM_WORKFLOWS_HELPER_FILE")
override_data = load_project_override("$NAME")
%>

pre_window: >-
  bash -lc '<%= include_pre_window("node-nvm-use") %>'

windows:
<%= include_window("$NAME", folder: ".", overrides: partial_override(override_data, "$NAME")) %>

<%= render_extra_windows(override_data) %>
EOF

cat >"$WINDOW_PARTIAL_FILE" <<'EOF'
<%
editor_cmd = overrides["editor_cmd"] if overrides.is_a?(Hash)
editor_cmd = nil unless editor_cmd.is_a?(String) && !editor_cmd.strip.empty?
%>

  - app:
      root: <%= folder %>
      layout: main-vertical
      panes:
<% if editor_cmd %>
        - editor: '<%= editor_cmd %>'
<% end %>
        - server: 'npm run dev || zsh -l'
EOF

cat >"$OVERRIDE_FILE" <<EOF
partials:
  $NAME:
    editor_cmd: "nvim"

windows:
  - shell:
      panes:
        - "zsh -l"
EOF

echo "[ok] Created: $PROJECT_FILE"
echo "[ok] Created: $WINDOW_PARTIAL_FILE"
echo "[ok] Created: $OVERRIDE_FILE"
echo
echo "Next steps:"
echo "  1) Review and adjust generated files"
echo "  2) Run: bash scripts/validate-workflows.sh"
echo "  3) Run: bash install.sh"
echo "  4) Start: tmuxinator start $NAME"
