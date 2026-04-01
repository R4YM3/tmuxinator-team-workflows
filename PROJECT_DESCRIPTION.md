# twf Project Description

## Product Summary

`twf` is a terminal-first CLI for defining and running team development workflows.

It is used to:

- create project/workspace workflow config,
- prepare local environment setup,
- manage reusable services,
- run and diagnose project workflows.

Target platform: macOS + Linux (WSL counts as Linux context).

## Core Terminology

- **project** = runnable development workflow
- **service** = reusable workflow unit (e.g. web, api, worker, redis)
- **command** = executable run instruction
- **requirements** = what must be installed to support project/services
- **environment setup** = install machine/project prerequisites
- **runtime** = workflow execution

Important: command sources (like `package.json` scripts) are command sources, not services.

## Installation

Global install:

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/tmuxinator-team-workflows/main/scripts/bootstrap.sh" | bash && exec "$SHELL" -l
```

What install does (high level):

- installs/updates `twf` runtime locally,
- creates CLI symlink (`twf`) in user bin path,
- ensures shell can resolve `twf`,
- prepares baseline prerequisites for using the CLI.

Verify install:

```bash
twf version
twf help
```

Uninstall:

```bash
twf uninstall
```

## CLI Surface

Top-level commands:

- `twf add [project-name] [--dry-run]`
- `twf remove <project-name> [--yes]`
- `twf install [--project <project>] [--yes]`
- `twf service add <service> [--project <project>]`
- `twf service remove <service> [--project <project>]`
- `twf service list [--project <project> | --global]`
- `twf service install [--project <project>] [--yes] | --global [--yes]`
- `twf start <project> [args...] [--strict]`
- `twf stop <project>`
- `twf status`
- `twf doctor [--project <project> | --global] [--fix] [--yes]`
- `twf validate`
- `twf list`
- `twf demo [target-dir]`
- `twf update`
- `twf uninstall [--yes]`
- `twf version`
- `twf help`

Most commands can infer project context when run inside a linked repository.

## Output and Return Behavior

`twf` uses human-readable CLI output with status labels and actionable next steps.

Common labels:

- `[ok]` success
- `[info]` informational
- `[warn]` non-blocking issue
- `[error]` blocking issue
- `[plan]` setup/install plan
- `[install]` install progress

Exit behavior:

- `0` on success
- non-zero on blocking failures

Examples:

- `twf add`
  - creates config and links,
  - prints next steps,
  - in interactive mode asks: `Run environment setup now? [Y/n]`
- `twf install`
  - prints requirements plan,
  - installs selected/all missing machine requirements,
  - installs project dependencies,
  - prints completion summary
- `twf start`
  - starts workflow,
  - warns in non-strict mode if requirements are missing,
  - fails in strict mode if requirements are missing
- `twf doctor`
  - prints diagnostics and fix suggestions

## Main Developer Flows

### Flow A: First-Time Setup

1. `twf add`
2. confirm setup prompt (or run `twf install`)
3. `twf start`

### Flow B: Controlled Setup

1. `twf add --dry-run`
2. `twf add`
3. `twf install --project <name>`
4. `twf doctor`
5. `twf start <name>`

### Flow C: Non-Interactive Setup

1. `twf add`
2. `twf install --yes`
3. `twf start`

### Flow D: Existing Project Service Update

1. `twf service add redis`
2. `twf install` (or `twf service install`)
3. `twf start`

## Install Behavior Details

`twf install` does both:

1. machine readiness requirements
2. project dependencies

Interactive behavior:

- default is “install all missing”,
- optional custom selection via checkbox-style selector,
- supports `--yes` for non-interactive full install.

Project dependency installers are detected from project root:

- `package.json` -> `npm install`
- `requirements.txt` -> `pip3 install -r requirements.txt`
- `Gemfile` -> `bundle install`
- `go.mod` -> `go mod download`

## Runtime and Readiness Behavior

- `twf` tracks per-project service install state/version/config hash.
- `twf start` checks readiness before starting.
- Non-strict mode:
  - warns when requirements are missing,
  - still starts runtime.
- Strict mode (`--strict`):
  - fails when required readiness is missing.

## Config and Workspace Model

`twf` separates shared and personal config:

- `.twf/project.yml`
- `.twf/developer.yml`

Workflow root stores per-project config:

- `<team-workflows-root>/<project>/project.yml`
- `<team-workflows-root>/<project>/developer.yml`

Workspace mode:

- if `twf add` runs in a directory with multiple direct child codebases, it can create one workspace workflow automatically.

## Responsibility Boundaries

`twf` is responsible for:

- project/workspace detection,
- service selection/management,
- requirements intent,
- install/start UX and diagnostics.

`twf` is not:

- a deployment tool,
- a production orchestrator,
- a replacement for app package managers.

## README Generation Notes

Use this document as source material when generating a public README.

Desired README qualities:

- clear and practical,
- concept-first,
- focused on real developer usage,
- includes install + quickstart + command reference + flows,
- consistent terminology.
