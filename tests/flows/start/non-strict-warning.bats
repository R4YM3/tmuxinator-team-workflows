#!/usr/bin/env bats

setup() {
  source tests/helpers/common.bash
  setup_test_env
  export TEAM_ROOT="$TEST_ROOT/team-workflows"
  configure_workflow_root "$TEAM_ROOT"

  local repo="$TEST_ROOT/repos/start-warning"
  create_git_repo "$repo"
  touch "$repo/package.json"
  cd "$repo"
  run_twf add
  [ "$status" -eq 0 ]

  run_twf service add containers
  [ "$status" -eq 0 ]
}

@test "twf start warns when requirements are missing in non-strict mode" {
  cd "$TEST_ROOT/repos/start-warning"

  run_twf start --no-attach
  [ "$status" -eq 0 ]
  assert_output_contains "RUNTIME-401"
  assert_output_contains "Project may not work as expected"
}
