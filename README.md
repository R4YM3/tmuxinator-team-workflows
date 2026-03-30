# tmuxinator-team-workflows

Run your entire team's development environment with one command.

`twf` standardizes how developers start, run, and customize development workflows — without sacrificing personal flexibility.

`twf` is not about terminal tooling. It is about making your team faster, more consistent, and easier to onboard.

---

## ⚡ Try it in 30 seconds

```bash
cd my-project
twf add        # create workflow
twf start      # run everything
```

That’s it.
Your full development environment is running.

---

## ❌ Without `twf`

* Open 5 terminals
* Run commands manually
* Forget dependencies
* Ask teammates
* Waste time daily

---

## ✅ With `twf`

```bash
twf start
```

* Everything runs
* Same setup for everyone
* Zero guesswork

---

## 🧠 How it works

`twf` introduces two simple concepts:

### Projects

A **project** is a runnable development workflow.

### Services

A **service** is a reusable unit of work (e.g. `web`, `api`, `worker`, `redis`).

---

### Model

* A project = a composition of services
* Services are defined once and reused across projects (DRY)
* Projects can add project-specific behavior

---

### Example

```yaml
services:
  web:
    command: npm run dev
  api:
    command: npm run server
  redis:
    command: redis-server
```

---

## 👥 Team + Personal, without conflict

`twf` separates shared and personal workflows:

* Shared team config lives in a central workflow root
* Personal tweaks live in your project

```text
.twf/project.yml
.twf/developer.yml
```

👉 You can customize freely without breaking the team setup.

---

## 🚀 Quickstart

Install globally:

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/tmuxinator-team-workflows/main/scripts/bootstrap.sh" | bash && exec "$SHELL" -l
```

Create your first workflow:

```bash
twf add
twf service add web
twf service add api
twf service install
twf start
```

## 🧠 Smart detection

`twf` automatically detects your project type and suggests services:

* Node -> web/api
* Python -> app/worker
* Containers -> docker-based services

👉 Less setup, more running.

Built-in services include:

* web / api
* databases (`redis`, `postgres`)
* language runtimes (`node`, `python`, and more)

---

## 🎯 Demo

Try a working setup instantly:

```bash
twf demo
```

This creates a demo workspace with:

* Next.js web service
* Simple API service
* Pre-configured workflow

Start it:

```bash
twf service install --project twf-demo
twf start twf-demo
```

---

## 🧩 Service-first workflows

Reuse services across projects:

```bash
twf service add web
twf service add api
twf service add worker
twf service add redis
twf service add redis --project other-project
```

👉 Define once, reuse everywhere.

---

## 🔍 Status & health

```bash
twf status
```

See:

* running workflows
* service readiness
* missing dependencies

👉 Quickly spot what’s broken or missing.

---

## 🧭 When to use `twf`

Use `twf` when:

* your project has multiple services
* your team needs consistent workflows
* onboarding takes too long
* developers run things differently

## 💼 Why this matters

* Faster onboarding
* Fewer setup mistakes
* Consistent environments
* Less time wasted on setup

---

## ⚙️ Commands

**💡 Commands automatically detect your current project.**

Most commands infer the current project when you run them inside a linked repo (`.twf/project.yml`).
Use `--project <name>` only when targeting another project.

### Projects

* `twf add`
* `twf remove`

### Services

* `twf service add`
* `twf service remove`
* `twf service list`
* `twf service install`

### Run

* `twf start`
* `twf stop`
* `twf status`

### Other

* `twf demo`
* `twf validate`
* `twf doctor` (`--project`, `--global`, `--fix`)
* `twf list`
* `twf update`
* `twf uninstall`
* `twf version`

---

## 🏗 Workflow structure

```text
<team-workflows-root>/
├── project-a/
│   ├── project.yml
│   └── developer.yml
```

---

## 🧪 Technical details

Under the hood, `twf` uses tmuxinator.

---

## 📦 Requirements

* git
* tmux
* tmuxinator
* ruby

---

## 📄 License

MIT
