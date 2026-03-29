# tmuxinator-team-workflows

`twf` is a lightweight workflow layer on top of tmuxinator.

Start your entire dev workflow with one command — together as a team.

Install `twf` once globally, then configure one team workflow root (outside app repos) to manage per-project workflow files for all development environments.

## Problem this solves

Teams that use tmux/tmuxinator often hit the same issues:

- Everyone starts services differently (different panes, commands, startup order).
- New teammates need tribal knowledge to get a full session running.
- Shared changes and personal tweaks get mixed together.
- Project aliases in `~/.config/tmuxinator` drift across machines.

`twf` solves this by using one team workflow root as the shared source of truth and creating project aliases consistently.

## Core idea

- `tmuxinator` is still the runtime.
- `twf` helps you scaffold, validate, and manage workflow projects.
- Workflow files are stored in a dedicated team workflow root, separate from application code repositories.

## Why use `twf` (and why not)

Use `twf` when:

- You have multiple services/windows and want repeatable startup.
- A team needs shared defaults plus personal overrides.
- You want to version-control tmuxinator workflows as a dedicated asset.

You may not need `twf` when:

- You only run one simple tmux session manually.
- You are working solo and do not need shared workflow conventions.
- Plain `tmuxinator` files in one local repo already fit your needs.

`twf` is intentionally a thin layer. It does not replace tmuxinator or hide tmux; it standardizes collaboration around them.

## Global install (CLI only)

Bootstrap installs runtime files in `~/.local/share/twf` and the CLI symlink in `~/.local/bin/twf`.
It also adds `~/.local/bin` to common shell rc files automatically (zsh, bash, fish, plus `~/.profile` fallback).
If `tmux` and/or `tmuxinator` are missing, bootstrap prompts to install them before continuing.
After bootstrap, restart your shell once (for example `exec "$SHELL" -l`).

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/tmuxinator-team-workflows/main/scripts/bootstrap.sh" | bash && exec "$SHELL" -l
```

Optional bootstrap overrides:

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/tmuxinator-team-workflows/main/scripts/bootstrap.sh" | TWF_REPO_URL="https://github.com/R4YM3/tmuxinator-team-workflows.git" TWF_INSTALL_ROOT="$HOME/.local/share/twf" TWF_BIN_DIR="$HOME/.local/bin" bash && exec "$SHELL" -l
```

## Add your first project

Run `twf add` from your project directory:

```bash
cd /path/to/project-a
twf add
```

On first run, `twf` asks where your team workflow root should live (default: `../team-workflows`) and saves it in `~/.config/twf/config.yml`.

Then it creates:

- `<team-workflows-root>/project-a/project.yml`
- `<team-workflows-root>/project-a/developer.yml`
- tmuxinator alias: `${XDG_CONFIG_HOME:-$HOME/.config}/tmuxinator/project-a.yml`
- local edit links in your repo:
  - `.twf/project.yml`
  - `.twf/developer.yml`

`twf start` refreshes these local links automatically, so they stay in sync with the team workflow files.

## Add more projects

From any codebase directory:

```bash
cd /path/to/project-b
twf add
```

Or explicit name:

```bash
twf add project-b
```

If a tmuxinator alias already exists, `twf add` prompts:

- rename the project name, or
- replace the existing alias (with confirmation)

With `--dry-run`, rename/replace is still prompted, but no files are written and no replacement confirmation is asked.

## Plugins per project

Plugins are configured per project and installed per machine.

Add plugins to a project configuration:

```bash
twf plugin add node --project my-workflow
twf plugin add dotnet --project my-workflow
```

Install configured plugins for one project:

```bash
twf plugin install --project my-workflow
```

Install configured plugins for all projects in the team workflow root:

```bash
twf plugin install --global
```

List plugins:

```bash
twf plugin list --project my-workflow
twf plugin list --global
```

Remove plugin config from a project:

```bash
twf plugin remove node --project my-workflow
```

Notes:

- `twf plugin add/remove` updates project config only.
- `twf plugin install` performs machine-local setup.
- `twf start <project>` checks plugin install markers and asks for `twf plugin install --project <project>` when missing/outdated.

## Commands

Run `twf help` for the latest command text.

- `twf add [project-name] [--dry-run]`
- `twf remove <project-name> [--yes]`
- `twf plugin add <plugin> --project <project>`
- `twf plugin remove <plugin> --project <project>`
- `twf plugin list [--project <project> | --global]`
- `twf plugin install --project <project> [--yes]`
- `twf plugin install --global [--yes]`
- `twf validate`
- `twf doctor`
- `twf list`
- `twf start <project> [args...]` (or `twf start` to infer from current directory)
- `twf stop <project>` (or `twf stop` to infer from current directory)
- `twf update`
- `twf uninstall [--yes]`
- `twf version`

## Start workflows

Start via twf:

```bash
twf plugin install --project my-workflow
twf start my-workflow
```

Or directly via tmuxinator (because `twf add` links aliases):

```bash
tmuxinator start my-workflow
```

Stop a running workflow session:

```bash
twf stop my-workflow
```

Tip: edit workflow files directly from your project repo via `.twf/project.yml` and `.twf/developer.yml`.

## Validate and diagnose

Run from anywhere after your team workflow root is configured:

```bash
twf validate
twf doctor
```

## Remove workflows

Remove alias and optionally local files:

```bash
twf remove my-workflow
```

Non-interactive:

```bash
twf remove my-workflow --yes
```

`twf remove` removes:

- `${XDG_CONFIG_HOME:-$HOME/.config}/tmuxinator/<project>.yml`
- `<team-workflows-root>/<project>/` (with confirmation, or immediately with `--yes`)

## Uninstall CLI

Remove global CLI/runtime install:

```bash
twf uninstall
```

This removes:

- `~/.local/bin/twf`
- `~/.local/share/twf` (when confirmed, or with `--yes`)

It does not remove team workflow projects or tmuxinator aliases.

## Workflow repo layout

Workflow content is stored per project in your team workflow root:

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

Runtime internals (CLI scripts, helper plumbing, and plugin implementations) stay in `~/.local/share/twf`.

## Notes on customization

- Day-to-day customization should happen in each project folder:
  - `<team-workflows-root>/<project>/project.yml`
  - `<team-workflows-root>/<project>/developer.yml`
- Avoid editing runtime internals in `~/.local/share/twf` unless you are maintaining the framework itself.

## Requirements

- git
- tmux
- tmuxinator
- ruby (for ERB/YAML validation)

`tmux` and `tmuxinator` are required. During bootstrap, if either is missing, `twf` asks for confirmation and can install them automatically on supported package managers.

## License

MIT

## References

- tmux: https://github.com/tmux/tmux
- tmuxinator: https://github.com/tmuxinator/tmuxinator
