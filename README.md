# tmuxinator-team-workflows

Share tmuxinator workflows across teams 🤝  
Allow developers to customize their local development environment and start complex setups with a single command 🚀  
Less terminal juggling, faster onboarding, and smoother context switching ⚡

This project adds a lightweight collaboration layer on top of tmuxinator. Teams can share workflow setups, while developers can extend them locally.

tmuxinator itself is intentionally not abstracted away. Developers still use tmuxinator directly and keep access to the full power of tmux and tmuxinator.

---

# What this is (and is not)

**What this is:**

- a team workflow sharing layer on top of tmuxinator
- a way to version and distribute shared tmux workflows
- a clean model for team defaults (`templates/`) + personal overrides (`developer/`)

**What this is not:**

- not a replacement for tmuxinator
- not another tmux session schema like tmuxp or teamocil
- not a generic container/dev-environment orchestrator

In short: tmuxinator runs sessions; this project helps teams collaborate on those sessions.

---

# The problem

Modern development environments often require starting multiple services:

- backend APIs
- frontend dev servers
- workers
- logs
- build tools

Developers usually start these manually across multiple terminals.  
This leads to inconsistent setups, slower onboarding, and repetitive work.

---

# The solution

**tmuxinator-team-workflows** lets teams version‑control and share tmuxinator workflows.

- teams define shared workflows
- developers install them once
- developers customize locally without modifying team templates

Start a full environment with:

```bash
tmuxinator start example-includes
```

**Less hassle, more action.**

---

# Quick start

Clone the repository and install the CLI:

```bash
./twf install --yes
```

Add a new project in an empty directory:

```bash
mkdir my-workflow && cd my-workflow
twf add my-workflow
```

Validate templates anytime:

```bash
twf validate
```

Run a quick environment health check:

```bash
twf doctor
```

List available workflows:

```bash
twf list
```

Start one:

```bash
twf start my-workflow
```

Remove an installed alias later:

```bash
twf remove my-workflow
```

---

# Remote bootstrap (TODO URL)

The bootstrap script supports an env override for the repository URL so you can test before publishing:

```bash
curl -fsSL <TODO_GITHUB_RAW_BOOTSTRAP_URL> | TWF_REPO_URL="https://github.com/<org>/tmuxinator-team-workflows.git" bash
```

Local equivalent:

```bash
TWF_REPO_URL="https://github.com/<org>/tmuxinator-team-workflows.git" bash scripts/bootstrap.sh
```

Until the public URL is finalized, `scripts/bootstrap.sh` hard-fails unless `TWF_REPO_URL` is set.

---

# How it works

Shared workflows and personal customization are separated.

| Folder | Purpose |
|------|------|
| templates/projects/ | Team‑maintained project workflows |
| templates/partials/ | Reusable shared workflow blocks |
| templates/helpers/ | Shared ERB helper methods |
| developer/projects/ | Developer override files |
| .internal/ | Installer metadata |

Installation flow:

```
Team workflow
   │
   ▼
templates/projects/
   │
install.sh
~/.config/tmuxinator
   │
   ▼
tmuxinator start <project>

Developer overrides are read from `developer/projects/*.override.yml` when present.
```

---

# Repository structure

```
.
├── twf
├── install.sh
├── uninstall.sh
├── scripts/
│   ├── bootstrap.sh
│   ├── validate-workflows.sh
│   ├── doctor.sh
│   └── new-workflow.sh
├── templates/
│   ├── helpers/
│   │   └── workflow.rb
│   ├── projects/
│   │   └── example-includes.yml
│   └── partials/
│       └── ...
├── developer/
│   └── projects/
│       └── example-includes.override.yml
├── .gitignore
└── README.md
```

During installation an internal folder is created:

```
.internal/
  env.sh
  install-manifest.txt
  INFO.md
```

This folder stores metadata used by the installer.

---

# Installation

Run:

```bash
bash install.sh
```

Non-interactive install:

```bash
bash install.sh --yes --repos-root "${HOME}/code"
```

Validate only (no file writes):

```bash
bash install.sh --check --repos-root "${HOME}/code"
```

The installer:

- checks if **tmux** is installed
- checks if **tmuxinator** is installed
- installs missing dependencies when possible
- asks for your `REPOSITORIES_ROOT`
- keeps workflows in `templates/projects/` as the source of truth
- creates symlinks in `~/.config/tmuxinator` that point to templates
- prepares `developer/projects/` for personal overrides
- exports helper env vars used by template includes

```
~/.config/tmuxinator
```

---

# Using REPOSITORIES_ROOT

Templates should reference repositories using:

```yaml
root: <%= ENV.fetch("REPOSITORIES_ROOT") %>/example-includes
```

This allows each developer to keep repositories in different local directories.

---

# Customization model

## Team workflows

Team changes belong in:

```
templates/projects/
```

Reusable shared blocks belong in:

```
templates/partials/
```

Shared helper methods for concise project templates live in:

```
templates/helpers/
```

Examples:

- adding services
- changing layouts
- shared commands

---

## Developer customization

Developers keep personal overrides in:

```
developer/projects/
```

Examples:

- add personal tools/windows
- add personal pane commands
- tweak startup behavior

If a change benefits the team, move it back into `templates/projects/` or `templates/partials/`.

---

## Optional overrides

Developers can add optional override files such as:

```
developer/projects/example-includes.override.yml
```

Then start your project:

```bash
tmuxinator start example-includes
```

Overrides are best for **adding personal tools or panes**.  
For deeper shared changes, update files in `templates/projects/` or `templates/partials/`.

For projects that use shared partials, override files can customize only what you need (for example `editor_cmd`) while keeping partial defaults for everything else:

```yaml
partials:
  landing-frontend:
    editor_cmd: "nvim"
```

`partials` keys map to partial filenames (for example `landing-frontend`, `cc-backend-headless-cms`, `videoland-titles`).

Project templates should stay mostly YAML and use helper includes, for example:

```yaml
<% Kernel.load ENV.fetch("TEAM_WORKFLOWS_HELPER_FILE") %>

pre_window: >-
  bash -lc '<%= include_pre_window("node-nvm-use") %>'

windows:
<%= include_window("landing-frontend", folder: "./landing-frontend", overrides: partial_override(override_data, "landing-frontend")) %>
```

---

# Updating workflows

```bash
twf update
```

The installer keeps templates as the source of truth and refreshes tmuxinator symlinks.

---

# Runtime requirements

These environment variables must be available when tmuxinator renders templates:

- `REPOSITORIES_ROOT`
- `TEAM_WORKFLOWS_REPO_DIR`
- `TEAM_WORKFLOWS_HELPER_FILE`

`install.sh` writes them to `.internal/env.sh` and can add a source block to your shell rc file.

---

# Troubleshooting

If `tmuxinator start <project>` fails with parse errors:

```bash
source .internal/env.sh
twf validate
```

If symlinks look wrong:

```bash
twf install
```

---

# Creating new projects

Run this in an empty directory:

```bash
twf add my-workflow
```

`twf add` rules:

- project name is required
- `root:` is scaffolded as `.`
- hard-fails if `~/.config/tmuxinator/my-workflow.yml` already exists
- hard-fails when destination files already exist
- supports `--dry-run` to preview generated files

---

# Removing projects

Remove the tmuxinator alias:

```bash
twf remove my-workflow
```

With `twf remove`, the alias is removed first, then you are prompted to optionally remove:

- `developer/projects/my-workflow.override.yml`
- `templates/projects/my-workflow.yml`

Use non-interactive mode to remove all three in one command:

```bash
twf remove my-workflow --yes
```

---

# Uninstall

```bash
twf uninstall
```

Removes:

- global CLI symlink (default `~/.local/bin/twf`)
- install root (default `~/.local/share/twf`) when confirmed

`twf uninstall` does not remove project aliases in tmuxinator. Use `twf remove <project>` for that.

---

# Smoke test checklist

```bash
bash -n twf
bash -n scripts/bootstrap.sh
./twf help
./twf version
./twf validate
./twf check
./twf add demo --dry-run
```

Expected failure checks:

- `twf add demo` fails when `~/.config/tmuxinator/demo.yml` already exists
- `scripts/bootstrap.sh` fails when `TWF_REPO_URL` is unset (placeholder mode)

---

# Requirements

The installer ensures:

- tmux
- tmuxinator

---

# .gitignore

```gitignore
/developer/**
!/developer/.gitkeep
!/developer/projects/
!/developer/projects/.gitkeep
!/developer/projects/*.override.yml
/.internal/
```

---

# License

MIT License

---

# References

tmuxinator  
https://github.com/tmuxinator/tmuxinator

tmux  
https://github.com/tmux/tmux
