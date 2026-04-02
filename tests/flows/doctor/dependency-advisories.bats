#!/usr/bin/env bats

setup() {
  source tests/helpers/common.bash
  setup_test_env
  export TEAM_ROOT="$TEST_ROOT/team-workflows"
  configure_workflow_root "$TEAM_ROOT"

  local repo="$TEST_ROOT/repos/advisory-workflow"
  create_git_repo "$repo"
  touch "$repo/package.json"
  cd "$repo"
  run_oo add
  [ "$status" -eq 0 ]

  cat >"$TEAM_ROOT/advisory-workflow/override.yaml" <<'EOF'
services:
  enabled: []
  config: {}
EOF
}

@test "oo doctor shows dependency advisories from last install snapshot" {
  local mock_bin="$TEST_ROOT/bin"
  create_mock_command "$mock_bin" "npm" 'if [[ "$1" == "install" ]]; then
cat <<"EOF"
npm WARN config cache-min This option is deprecated and invalid
added 500 packages in 1s
16 vulnerabilities (7 low, 2 moderate, 5 high, 2 critical)
EOF
fi'

  cd "$TEST_ROOT/repos/advisory-workflow"
  run_oo_with_path "$mock_bin" install --yes
  [ "$status" -eq 0 ]

  run_oo_with_path "$mock_bin" doctor
  [ "$status" -eq 0 ]
  assert_output_contains "Dependencies"
  assert_output_contains "npm config contains deprecated or invalid settings"
  assert_output_contains "16 vulnerabilities reported (7 low, 2 moderate, 5 high, 2 critical)"
  assert_output_contains "Details: npm audit"
}
