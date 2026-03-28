# tmuxinator-team-workflows

`twf` is a lightweight workflow layer on top of tmuxinator.

Install `twf` once globally, then create one dedicated workflow repository (outside app repos) to manage templates and personal overrides for all development environments.

## Problem this solves

Teams that use tmux/tmuxinator often hit the same issues:

- Everyone starts services differently (different panes, commands, startup order).
- New teammates need tribal knowledge to get a full session running.
- Shared changes and personal tweaks get mixed together.
- Project aliases in `~/.config/tmuxinator` drift across machines.

`twf` solves this by using one workflow repository as the shared source of truth and creating project aliases consistently.

## Core idea

- `tmuxinator` is still the runtime.
- `twf` helps you scaffold, validate, and manage workflow projects.
- Workflow repos are separate from application code repositories.

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
It also tries to add `~/.local/bin` to your shell rc file automatically.

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/tmuxinator-team-workflows/main/scripts/bootstrap.sh" | bash
```

Optional bootstrap overrides:

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/tmuxinator-team-workflows/main/scripts/bootstrap.sh" | TWF_REPO_URL="https://github.com/R4YM3/tmuxinator-team-workflows.git" TWF_INSTALL_ROOT="$HOME/.local/share/twf" TWF_BIN_DIR="$HOME/.local/bin" bash
```

Bootstrap does **not** create a workflow repo.

## Create a workflow repo

Create an empty directory dedicated to workflows and add your first project:

```bash
mkdir -p "$HOME/code/team-workflows"
cd "$HOME/code/team-workflows"
twf add my-workflow
```

Optional: scaffold with demo content:

```bash
twf add my-workflow --with-demo
```

This creates a workflow repo in the current directory with:

- `README.md`
- `.gitignore`
- `templates/`
- `developer/`

Then it adds project files for `my-workflow` and creates a tmuxinator alias symlink.

Important: do not run `twf add` inside an application repository.

## Add more projects

Inside an existing workflow repo:

```bash
twf add project-two
```

If a tmuxinator alias already exists, `twf add` prompts:

- rename the project name, or
- replace the existing alias (with confirmation)

With `--dry-run`, rename/replace is still prompted, but no files are written and no replacement confirmation is asked.
With `--with-demo`, the new project uses demo template/override content instead of the minimal starter.

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

Install configured plugins for all projects in this workflow repo:

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

- `twf add <project-name> [--dry-run] [--with-demo]`
- `twf remove <project-name> [--yes]`
- `twf plugin add <plugin> --project <project>`
- `twf plugin remove <plugin> --project <project>`
- `twf plugin list [--project <project> | --global]`
- `twf plugin install --project <project> [--yes]`
- `twf plugin install --global [--yes]`
- `twf validate`
- `twf doctor`
- `twf list`
- `twf start <project> [args...]`
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

## Validate and diagnose

Run from inside your workflow repo:

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

`twf remove` always removes:

- `${XDG_CONFIG_HOME:-$HOME/.config}/tmuxinator/<project>.yml`

Then it optionally removes (if present in current workflow repo):

- `templates/projects/<project>.yml`
- `developer/projects/<project>.override.yml`

## Uninstall CLI

Remove global CLI/runtime install:

```bash
twf uninstall
```

This removes:

- `~/.local/bin/twf`
- `~/.local/share/twf` (when confirmed, or with `--yes`)

It does not remove tmuxinator aliases or workflow repositories.

## Workflow repo layout

Only workflow content should be visible in your repo:

```text
.
├── README.md
├── .gitignore
├── templates/
│   ├── partials/
│   └── projects/
└── developer/
    └── projects/
```

Runtime internals (CLI scripts, helper plumbing, and plugin implementations) stay in `~/.local/share/twf`.

## Notes on customization

- Day-to-day customization should happen in:
  - `templates/projects/`
  - `templates/partials/`
  - `developer/projects/*.override.yml`
- Avoid editing runtime internals in `~/.local/share/twf` unless you are maintaining the framework itself.

## Requirements

- tmux
- tmuxinator
- ruby (for ERB/YAML validation)

## License

MIT

## References

- tmux: https://github.com/tmux/tmux
- tmuxinator: https://github.com/tmuxinator/tmuxinator
