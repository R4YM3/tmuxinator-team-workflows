# Loop (oo)

Run your workflow. Not your setup.

Loop (Launch Once, Operate Predictably) is a CLI for starting development environments in seconds-with zero setup friction.

No docs.
No drift.
No "works on my machine".

## ⚡ Get running in 30 seconds

```bash
oo add
oo start
```

Done.

## 🧠 What just happened?

Loop:

- detects your project or workspace
- creates a workflow
- installs what's missing automatically
- starts your services

## 🚀 Why Loop

- Instant onboarding -> new devs run in minutes
- Consistent environments -> same workflow, every machine
- Zero daily friction -> one command to start
- Safe flexibility -> customize locally without breaking the team

## ✨ What makes Loop different

- Auto setup (no checklist needed)
  - Loop detects what your project needs and installs it for you.
- Smart dependency detection
  - Works out of the box with npm, pip, bundler, go, and more.
- Built-in diagnostics (`oo doctor`)
  - See exactly what's wrong and how to fix it-instantly.
- Runs even when imperfect
  - Start working while Loop surfaces issues in the background.
- Strict mode when it matters
  - Enforce a fully ready environment when consistency is critical.
- Team workflow + personal overrides ⭐
  - A shared workflow defines how the project runs.
  - You can safely override it locally-without changing the team setup.
- Calm by default, detailed when you need it
  - Minimal output by default. Use `--verbose` to see everything.
- Workspace-aware
  - Handles multi-repo setups automatically.

## 🧩 What Loop does

Loop is used to:

- define runnable workflows
- prepare local environments
- manage reusable services
- run and diagnose workflows

## 🧱 Core concepts

- workflow -> runnable development workflow
- service -> reusable unit (web, api, worker, redis)
- command -> executable run instruction
- requirements -> what must be installed
- environment setup -> preparing machine + workflow prerequisites
- runtime -> executing the workflow

## ⚙️ Install

```bash
curl -fsSL "https://raw.githubusercontent.com/R4YM3/loop/main/scripts/bootstrap.sh" | bash && exec "$SHELL" -l
oo version
```

## 🔄 Your new daily flow

```bash
oo start
```

That's it.

## 🛠 Basic commands

```bash
oo add        # create workflow
oo install    # install requirements
oo start      # run everything
oo stop       # stop everything
oo doctor     # diagnose your environment in seconds
```

## 🩺 Diagnose your setup instantly

```bash
oo doctor
```

See exactly what's wrong:

- missing dependencies
- incomplete setup
- misconfigured services

With clear next steps to fix it.

## 📣 Output you can actually read

Loop keeps output calm and focused by default:

```text
◆ Starting services
✓ ready
! warning
✖ blocking error
```

No noise. Just what matters.

Need more detail?

```bash
oo install --verbose
oo doctor --verbose
```

Quiet when you want flow.
Verbose when you need answers.

## 🧪 Config

```text
.oo/workflow.yaml   # shared team workflow
.oo/override.yaml   # your local adjustments
```

- `workflow.yaml` defines how the project runs
- `override.yaml` lets you tweak it locally

No conflicts. No breaking the team setup.

## 🧭 Workspace support

Multiple repositories?

```bash
oo add
```

Loop creates a workspace automatically.

## 🔍 Smart install behavior

`oo install` handles both:

- machine requirements
- workflow dependencies

Supports:

- `--yes` -> non-interactive
- `--plan` -> preview before installing
- `--no-workflow-deps` -> setup only

## ⚡ Common flows

First-time setup:

```bash
oo add
oo start
```

Controlled setup:

```bash
oo add --dry-run
oo add
oo install --workflow <name>
oo doctor
oo start <name>
```

Non-interactive setup:

```bash
oo add
oo install --yes
oo start
```

Add a service:

```bash
oo service add redis
oo install
oo start
```

## 🎯 What Loop is

- local workflow engine
- team consistency layer
- CLI-first dev tool

## 🚫 What it's not

- not a deployment tool
- not production orchestration
- not a package manager

## 💬 Final thought

Every project has a workflow.

Most teams just don't control it.

Loop does.

## 🧠 Why this version is better

- keeps the hook strong
- adds credibility (real features)
- surfaces power features (install, doctor, overrides)
- avoids turning into a wall of text
