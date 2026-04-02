#!/usr/bin/env bats

setup() {
  source tests/helpers/common.bash
  setup_test_env
  export TEAM_ROOT="$TEST_ROOT/team-workflows"
  configure_workflow_root "$TEAM_ROOT"

  local repo="$TEST_ROOT/repos/nuget-advisory-workflow"
  create_git_repo "$repo"
  cat >"$repo/sample.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
EOF
  cd "$repo"
  run_oo add
  [ "$status" -eq 0 ]

  cat >"$TEAM_ROOT/nuget-advisory-workflow/override.yaml" <<'EOF'
services:
  enabled: []
  config: {}
EOF
}

@test "oo doctor shows nuget advisories from last install snapshot" {
  local mock_bin="$TEST_ROOT/bin"
  create_mock_command "$mock_bin" "dotnet" 'if [[ "$1" == "restore" ]]; then
cat <<"EOF"
warning NU1903: Detected package version with a known high severity vulnerability.
warning NU1904: Detected package version with a known critical severity vulnerability.
EOF
fi'

  cd "$TEST_ROOT/repos/nuget-advisory-workflow"
  run_oo_with_path "$mock_bin" install --yes
  [ "$status" -eq 0 ]

  run_oo_with_path "$mock_bin" doctor
  [ "$status" -eq 0 ]
  assert_output_contains "Dependencies"
  assert_output_contains "nuget reported 2 vulnerabilities (1 high, 1 critical)"
  assert_output_contains "dotnet list package --vulnerable"
}
