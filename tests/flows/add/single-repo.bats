#!/usr/bin/env bats

setup() {
  source tests/helpers/common.bash
  setup_test_env
  export TEAM_ROOT="$TEST_ROOT/team-workflows"
  configure_workflow_root "$TEAM_ROOT"
}

@test "twf add creates single project workflow and links" {
  local repo="$TEST_ROOT/repos/my-project"
  create_git_repo "$repo"
  touch "$repo/package.json"

  cd "$repo"
  run_twf add
  [ "$status" -eq 0 ]

  assert_file_exists "$TEAM_ROOT/my-project/project.yml"
  assert_file_exists "$TEAM_ROOT/my-project/developer.yml"
  run grep -q -- "- node" "$TEAM_ROOT/my-project/developer.yml"
  [ "$status" -eq 0 ]

  assert_symlink_points_to "$XDG_CONFIG_HOME/tmuxinator/my-project.yml" "$TEAM_ROOT/my-project/project.yml"
  assert_symlink_points_to "$repo/.twf/project.yml" "$TEAM_ROOT/my-project/project.yml"
  assert_symlink_points_to "$repo/.twf/developer.yml" "$TEAM_ROOT/my-project/developer.yml"
}
