#!/usr/bin/env bash

setup_test_env() {
  export REPO_ROOT
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  export TWF_BIN="$REPO_ROOT/twf"

  export TEST_ROOT="$BATS_TEST_TMPDIR/work"
  export HOME="$TEST_ROOT/home"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$HOME/.local/share"
  export PATH="/usr/bin:/bin:/opt/homebrew/bin:$PATH"

  mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
}

configure_workflow_root() {
  local root="$1"
  mkdir -p "$root" "$XDG_CONFIG_HOME/twf"
  cat >"$XDG_CONFIG_HOME/twf/config.yml" <<EOF
team_workflows_root: "$root"
EOF
}

create_git_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
}

run_twf() {
  run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_DATA_HOME="$XDG_DATA_HOME" "$TWF_BIN" "$@"
}

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]]
}

assert_dir_exists() {
  local path="$1"
  [[ -d "$path" ]]
}

assert_symlink_points_to() {
  local link_path="$1"
  local expected="$2"
  [[ -L "$link_path" ]]
  local target
  target="$(readlink "$link_path")"
  [[ "$target" == "$expected" ]]
}

assert_output_contains() {
  local needle="$1"
  [[ "$output" == *"$needle"* ]]
}
