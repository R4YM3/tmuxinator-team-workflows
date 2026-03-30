# tmuxinator-team-workflows

Run your entire team's development environment with one command.

`twf` helps teams define shared development workflows as reusable building blocks called **services**, then compose those services into project workflows.

## Problem vs Solution

Without a team workflow system:

- Developers open many terminals and start everything by hand.
- Startup order and commands differ per person.
- Onboarding depends on tribal knowledge.
- Personal tweaks collide with team conventions.

With `twf`:

- One command starts the full project workflow.
- Teams share a consistent baseline setup.
- New developers get productive faster.
- Personal machine setup and team setup stay separate.

## Core Concepts

- `project`: a runnable development workflow for one codebase or workspace.
- `service`: a reusable workflow unit (for example `web`, `api`, `worker`, `redis`).
- `team workflow root`: shared folder where all project workflow files live.
- `developer override`: project-level personal/custom config without changing shared templates.

Model:

- A project is a composition of services.
- Services are defined once and reused across projects (DRY).
- Projects can still add project-specific behavior where needed.

## Shared + Personal, Without Conflict

`twf` keeps shared team workflow files in one place and also creates local links in each project repo:

- `.twf/project.yml`
- `.twf/developer.yml`

This lets developers edit workflow files from inside their project while keeping shared workflow ownership centralized.

## Quickstart

Install globally:

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/tmuxinator-team-workflows/main/scripts/bootstrap.sh" | bash && exec "$SHELL" -l
```

Bootstrap behavior:

- installs `twf` runtime into `~/.local/share/twf`
- links CLI at `~/.local/bin/twf`
- updates shell PATH config
- if `tmux` or `tmuxinator` is missing, prompts before installing required dependencies

Create your first project workflow (run inside your codebase):

```bash
twf add
twf service add web --project my-project
twf service add api --project my-project
twf service install --project my-project
twf start my-project
```

## Demo Flow

See value quickly with a working demo:

```bash
twf demo
```

This creates a demo workspace with:

- Next.js web service
- simple API service
- ready-to-start workflow composition

Then run:

```bash
twf service install --project twf-demo
twf start twf-demo
```

## Service-First Workflow

Manage reusable services:

```bash
twf service list
twf service add web --project my-project
twf service add api --project my-project
twf service add worker --project my-project
twf service add redis --project my-project
twf service install --project my-project
```

Services are machine-local to install, project-local to configure, and reusable across all projects.

## Status & Discoverability

Check what is running and what needs setup:

```bash
twf status
```

`twf status` shows:

- running project sessions
- project-by-project service readiness
- which services still need installation

## Commands

Run `twf help` for latest details.

- `twf add [project-name] [--dry-run]`
- `twf remove <project-name> [--yes]`
- `twf service add <service> --project <project>`
- `twf service remove <service> --project <project>`
- `twf service list [--project <project> | --global]`
- `twf service install --project <project> [--yes]`
- `twf service install --global [--yes]`
- `twf demo [target-dir]`
- `twf status`
- `twf start <project> [args...]`
- `twf stop <project>`
- `twf list`
- `twf validate`
- `twf doctor`
- `twf update`
- `twf uninstall [--yes]`
- `twf version`

## Team Workflow Root Layout

```text
<team-workflows-root>/
├── README.md
├── project-a/
│   ├── project.yml
│   └── developer.yml
└── project-b/
    ├── project.yml
    └── developer.yml
```

## Technical Details (Implementation)

Implementation details are intentionally secondary:

- `twf` uses tmuxinator as runtime engine.
- tmux sessions/windows/panes are generated from project workflow files.
- runtime scripts and service implementations live in `~/.local/share/twf`.

## Foundation for UI

The project/service model is designed to support a future Tauri app:

- projects and services have predictable file-based configuration
- service health and session state are queryable (`twf status`)
- team and developer concerns are cleanly separated

## Requirements

- git
- tmux
- tmuxinator
- ruby

## License

MIT
