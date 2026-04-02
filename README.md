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

- detects your project
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
- Workspace-aware
  - Handles multi-repo setups automatically.

## 🧩 The problem

Most teams don't struggle with code.
They struggle with everything around it:

- setup instructions go stale
- environments drift
- debugging startup becomes guesswork

## ✅ The fix

Loop makes your workflow:

- explicit
- repeatable
- diagnosable

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

## 🧱 How it works

A workflow is a runnable dev environment:

- services -> web, api, worker, redis
- commands -> what runs
- requirements -> what's needed

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

## 📣 Output you can actually read

```text
◆ Starting services
✓ ready
! warning
✖ blocking error
```

## 🎯 What Loop is

- local workflow engine
- team consistency layer
- CLI-first dev tool

## 🚫 What it's not

- not a deployment tool
- not production orchestration
- not a package manager

## 🧪 Testing

```bash
tests/scripts/test-flow
tests/scripts/test-services
tests/scripts/test-docker
```

## 🪪 License

MIT

## 💬 Final thought

Every project has a workflow.

Most teams just don't control it.

Loop does.
