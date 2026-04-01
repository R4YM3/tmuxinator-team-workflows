# Tests

This test suite is organized by product behavior, not internals.
It serves as both validation and living documentation for twf business logic.

## Run locally

```bash
tests/scripts/test-flow
tests/scripts/test-services
tests/scripts/test-docker
tests/scripts/test-all
tests/scripts/test-changed
tests/scripts/test-act
```

## Run GitHub workflows locally with act

```bash
brew install act
tests/scripts/test-act
```

- `test-act` runs Linux CI coverage locally with stable defaults:
  - `act` simulation for `.github/workflows/flow-tests.yml` (Ubuntu matrix)
  - `act` simulation for `.github/workflows/service-contract-tests.yml` (Ubuntu matrix)
  - native `tests/scripts/test-docker` for docker integration
- `wsl-smoke` is `windows-latest` and is not run via `act`.

## Structure

- `tests/flows/`: end-to-end CLI behavior
- `tests/services/contract/`: one-file-per-service contract tests
- `tests/integration/docker/`: clean-environment integration tests
- `tests/helpers/`: shared setup and assertions
- `tests/fixtures/`: reusable fixture templates

## Business rules mapped to flow tests

- `twf add` single repo flow -> `tests/flows/add/single-repo.bats`
- `twf add` workspace auto-detect -> `tests/flows/add/workspace-auto-detect.bats`
- `twf add --dry-run` writes nothing -> `tests/flows/add/dry-run.bats`
- `twf start` project inference -> `tests/flows/start/infer-project.bats`
- `twf start --strict` behavior -> `tests/flows/start/strict-mode.bats`
- `twf service` inferred context -> `tests/flows/service/inferred-project-context.bats`
- `twf doctor` runtime/project checks -> `tests/flows/doctor/runtime-and-project.bats`
- `twf status` output -> `tests/flows/status/sessions-and-health.bats`
- `twf stop` flow -> `tests/flows/stop/stop-session.bats`
