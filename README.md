# tmuxinator-team-workflows

`twf` is a lightweight workflow layer on top of tmuxinator.

Install `twf` once globally, then create one dedicated workflow repository (outside app repos) where you manage templates and personal overrides for all development environments.

## Core idea

- `tmuxinator` is still the runtime.
- `twf` helps you scaffold, validate, and manage workflow projects.
- Workflow repos are separate from application code repositories.

## Global install (CLI only)

Bootstrap installs runtime files in `~/.local/share/twf` and the CLI symlink in `~/.local/bin/twf`.

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

## Commands

Run `twf help` for latest command text.

- `twf add <project-name> [--dry-run]`
- `twf remove <project-name> [--yes]`
- `twf validate` (`twf check` alias)
- `twf doctor`
- `twf list`
- `twf start <project> [args...]`
- `twf update`
- `twf uninstall [--yes]`
- `twf version`

## Start workflows

Start via twf:

```bash
twf start my-workflow
```

or directly via tmuxinator (because `twf add` links aliases):

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

Runtime internals (CLI scripts and helper plumbing) stay in `~/.local/share/twf`.

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
