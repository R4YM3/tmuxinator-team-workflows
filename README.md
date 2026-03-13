# tmuxinator-team-workflows

Share **tmuxinator workflows across teams** while allowing developers to customize their own local development environment.

This project adds a lightweight collaboration layer on top of **tmuxinator**. Teams can share workflow setups, while developers can extend them locally.

tmuxinator itself is **intentionally not abstracted away**. Developers still use tmuxinator directly and keep access to the full power of **tmux** and **tmuxinator**.

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

**tmuxinator-team-workflows** lets teams version-control and share tmuxinator workflows.

- teams define shared workflows
- developers install them once
- developers customize locally without modifying team templates

Start a full environment with:

```bash
tmuxinator start example-project
```

**Less hassle, more action.**

---

# Quick start

Clone the repository and install:

```bash
bash install.sh
```

List available workflows:

```bash
tmuxinator list
```

Start one:

```bash
tmuxinator start example-project
```

---

# How it works

Shared workflows and personal customization are separated.

| Folder | Purpose |
|------|------|
| templates/ | Team-maintained workflows |
| developer/ | Developer-specific copies |
| .internal/ | Installer metadata |

Installation flow:

```text
Team workflow
   │
   ▼
templates/
   │
install.sh
   │
   ▼
developer/  → personal customization
   │
   ▼
~/.config/tmuxinator
   │
   ▼
tmuxinator start <project>
```

---

# Repository structure

```text
.
├── install.sh
├── uninstall.sh
├── templates/
│   └── example-project.yml
├── developer/
│   └── example-project.override.example.yml
├── .gitignore
└── README.md
```

During installation an internal folder is created:

```text
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

The installer:

- checks if **tmux** is installed
- checks if **tmuxinator** is installed
- installs missing dependencies when possible
- asks for your `REPOSITORIES_ROOT`
- copies workflows from `templates/` to `developer/`
- creates symlinks in:

```text
~/.config/tmuxinator
```

---

# Using REPOSITORIES_ROOT

Templates should reference repositories using:

```yaml
root: <%= ENV.fetch("REPOSITORIES_ROOT") %>/example-project
```

This allows each developer to keep repositories in different local directories.

---

# Customization model

## Team workflows

Team changes belong in:

```text
templates/
```

Examples:

- adding services
- changing layouts
- shared commands

---

## Developer customization

Developers modify their own copy in:

```text
developer/
```

Examples:

- open editor automatically
- add personal commands
- adjust panes

If a change benefits the team, move it back into `templates/`.

---

## Optional overrides

Developers can add optional override files such as:

```text
developer/example-project.override.yml
```

Try the example:

```bash
cp developer/example-project.override.example.yml developer/example-project.override.yml
tmuxinator start example-project
```

Overrides are best for **adding personal tools or panes**.  
For deeper changes, edit the copied workflow directly.

---

# Updating workflows

```bash
git pull
bash install.sh
```

The installer syncs templates without overwriting local changes unless confirmed.

---

# Uninstall

```bash
bash uninstall.sh
```

Removes:

- tmuxinator symlinks
- shell configuration added by install
- `.internal` installer metadata

Developer files are only removed if confirmed.

---

# Requirements

The installer ensures:

- tmux
- tmuxinator

---

# .gitignore

```gitignore
/developer/*
!/developer/example-project.override.example.yml
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
