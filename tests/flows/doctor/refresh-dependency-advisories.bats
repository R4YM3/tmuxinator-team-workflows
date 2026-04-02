#!/usr/bin/env bats

setup() {
  source tests/helpers/common.bash
  setup_test_env
  export TEAM_ROOT="$TEST_ROOT/team-workflows"
  configure_workflow_root "$TEAM_ROOT"

  local repo="$TEST_ROOT/repos/refresh-advisory-workflow"
  create_git_repo "$repo"
  touch "$repo/package.json"
  cd "$repo"
  run_oo add
  [ "$status" -eq 0 ]

  cat >"$TEAM_ROOT/refresh-advisory-workflow/override.yaml" <<'EOF'
services:
  enabled: []
  config: {}
EOF
}

@test "oo doctor --refresh-deps refreshes npm advisory snapshot" {
  local mock_bin="$TEST_ROOT/bin"
  create_mock_command "$mock_bin" "npm" 'if [[ "$1" == "audit" ]]; then
cat <<"EOF"
{"metadata":{"vulnerabilities":{"info":0,"low":1,"moderate":0,"high":1,"critical":0,"total":2}}}
EOF
exit 1
fi'

  cd "$TEST_ROOT/repos/refresh-advisory-workflow"
  run_oo_with_path "$mock_bin" doctor --refresh-deps
  [ "$status" -eq 0 ]
  assert_output_contains "Dependency advisories"
  assert_output_contains "2 vulnerabilities reported (1 low, 1 high)"
  assert_output_contains "Details: npm audit"
}
