# Coming from make, just, npm scripts and friends

You don't have to leave anything behind: cigo reads the tools below and runs
them as they are. This page says what you keep, what cigo adds, and, just as
plainly, what it doesn't do yet.

## What cigo adds to all of them

- **One stage across every language.** `cigo run test` runs Python's,
  Go's, Rust's and Node's tests, each with its own tool, in its own
  directory, after its own setup. No rules to write.
- **Values between languages as data.** A task captures JSON or writes
  `name=value` lines; the next reads `{{task.field}}`. No `$(shell ...)`, no
  `jq` in the middle.
- **A dry run that runs nothing.** `cigo --dry-run run release` plans every
  task. (`make -n` still runs `$(MAKE)` lines and every `$(shell ...)`.)
- **Rollback and undo.** A failure halfway puts back what the run created, a
  deploy's `undo` runs, and `cig unburn` takes back a run that succeeded, days
  later.
- **Retries, timeouts, exit-code contracts and a log per task**, written
  once in the manifest instead of in each script.

## What it doesn't do (yet)

- **Run tasks in parallel.** One at a time, in dependency order.
- **Cache outputs across machines**, or hash contents: `inputs` compares
  sizes and modification times, plus the command and the values it was given.
- **Stream output.** A task's output shows when it finishes.
- **Watch files** and re-run on change.

Each of these is on the [roadmap](roadmap.md). Where you need one today, keep
the tool that does it and let cigo call it.

## make

**You keep** the Makefile. Its targets are tasks, `make:build`,
`make:deploy` (the `.PHONY` ones, when it declares any), described by a `##`
comment on the rule or the comment above it. A rule for several targets gives
each of them.

**Where they meet.** A root Makefile that calls each component's build is the
glue cigo replaces, so adopt keeps it out of the stage groups and its
targets stay runnable by name. A Makefile that *is* a component's build (a C
project, say) is that component: its `build` and `test` targets are its
stages.

**Keep make for** file-level incremental builds and `-j`. cigo's up-to-date
check is per task, and it runs one task at a time.

## just

**You keep** the justfile. Recipes are tasks, `just:release`; a recipe's
parameters show in its description and are passed after `--`:
`cigo run just:release -- 2.0`. Recipes starting with `_` stay private.

**cigo adds** what just leaves out on purpose: stages across languages,
values between recipes, dry run and rollback.

## Task (Taskfile.yml)

**You keep** the Taskfile; its tasks are `task:<name>`. Task's own
`sources` and `generates` keep working inside it. cigo's `inputs` and
`produces` are the same idea one level up, across languages.

## npm, pnpm, Yarn and Bun scripts

**You keep** `package.json`. The package manager comes from the lockfile or
the `packageManager` field, and setup installs from the lockfile without
changing it (`npm ci`, `--frozen-lockfile`, `--immutable`). Scripts with
stage names become stages (`build`, `test`, `lint`, `typecheck`, `format`
and the usual variants); the others are tasks, `web:storybook`. Lifecycle
scripts (`prepare`, `postinstall`, `pretest`) stay with the package manager,
which runs them itself. `dev`, `start`, `serve` and `watch` never end, so
they are never part of a stage.

## Turborepo, Nx and other monorepo runners

They cache and parallelize tasks across a JavaScript workspace, and they're
good at it. cigo spans languages instead, and it doesn't cache or parallelize
yet. They combine well: point the workspace component's stages at the runner
(`"stages": {"build": ["npx", "turbo", "run", "build"]}`), and cigo chains it
with the Python, Go and deploy steps around it.

## tox and nox

A Python component's test stage is `tox` when the project has a `tox.ini`
(or tox in `pyproject.toml`), and `nox` when it has a `noxfile.py`. Their
environments work as they do today.

## Gradle, Maven, sbt and other multi-project builds

The root (with its `settings.gradle`, its `<modules>`, its `build.sbt`) is
one component, and the build tool handles its own modules. cigo adds the
languages around it: the front end, the scripts, the deploy.

## Bazel, Buck2 and Pants

These own the whole tree, so the tree is one component, and cigo runs their
commands as its stages (`bazel build //...`, `bazel test //...`). Their
hermetic caching stays theirs. cigo chains them with what lives outside the
build graph: release notes, a deploy, a notification.

## A folder of scripts

`scripts/`, `script/`, `bin/` and `tools/` are read as they are: each script
is a task, run with its shebang's interpreter. What they gain is order
(`needs`), retries, timeouts, a log each, a dry run, rollback of the files
they create, and an `undo` for the ones that reach outside.

## CI YAML

A CI job that runs ten steps in sequence is often the real glue script.
With the chain in `cig-tasks.json`, the job becomes `cigo run ci`, and the
same chain runs on your laptop. [cigo in CI](ci.md) has the workflow.

Missing something your tool does better? [Tell
me](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=qol-request.yml);
quality-of-life requests are read, and the good ones land.
