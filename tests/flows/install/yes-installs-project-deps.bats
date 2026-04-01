#!/usr/bin/env bats

setup() {
  source tests/helpers/common.bash
  setup_test_env
  export TEAM_ROOT="$TEST_ROOT/team-workflows"
  configure_workflow_root "$TEAM_ROOT"

  local repo="$TEST_ROOT/repos/install-project"
  create_git_repo "$repo"
  touch "$repo/package.json"
  cd "$repo"
  run_twf add
  [ "$status" -eq 0 ]

  cat >"$TEAM_ROOT/install-project/developer.yml" <<'EOF'
services:
  enabled: []
  config: {}
EOF
}

@test "twf install --yes installs project dependencies" {
  local mock_bin="$TEST_ROOT/bin"
  create_mock_command "$mock_bin" "npm" 'touch "$TEST_ROOT/npm.called"'

  cd "$TEST_ROOT/repos/install-project"
  run_twf_with_path "$mock_bin" install --yes

  [ "$status" -eq 0 ]
  assert_output_contains "Install scope: machine readiness + project dependencies"
  assert_output_contains "Project dependencies installed"
  assert_file_exists "$TEST_ROOT/npm.called"
}
