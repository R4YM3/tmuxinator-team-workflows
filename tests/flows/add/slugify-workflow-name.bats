#!/usr/bin/env bats

setup() {
  source tests/helpers/common.bash
  setup_test_env
  export TEAM_ROOT="$TEST_ROOT/team-workflows"
  configure_workflow_root "$TEAM_ROOT"
}

@test "oo add slugifies invalid workflow names" {
  local repo="$TEST_ROOT/repos/Buienradar.FrontendV2"
  create_git_repo "$repo"
  touch "$repo/package.json"

  cd "$repo"
  run_oo add --no-install
  [ "$status" -eq 0 ]

  assert_file_exists "$TEAM_ROOT/buienradar-frontendv2/workflow.yaml"
  assert_file_exists "$TEAM_ROOT/buienradar-frontendv2/override.yaml"
}
