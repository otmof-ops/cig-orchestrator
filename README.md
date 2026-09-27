# cig-orchestrator

**Every language in the project, one chain, no glue script.**

Most projects are several languages in a row. A Python step makes the data, a
Go service and a Rust worker build against it, a TypeScript front end renders
it, a Dockerfile packages it and a bash script ships it. Each language brings
its own tool (`uv`, `go`, `cargo`, `pnpm`, `docker`), and the chain between
them ends up in one more language: a `Makefile` or a `release.sh` whose only
job is to call the others in order, scrape one tool's output with `jq` or
`sed`, export it for the next, and hope nothing fails halfway.

`cigo` is that glue, done once, in [CigScript](https://github.com/otmof-ops/CigScript).
It knows the standard workflow of 60 toolchains, finds every language in the
project, runs one stage across all of them in dependency order, and passes
values between them as data. The project's tools and scripts do not change,
and none of them need to know CigScript exists. What the chain gains is
everything `cig` gives a script:

| what you get | how |
|---|---|
| one command per stage, every language | `cigo run test` runs `uv run pytest`, `go test`, `cargo test` and `pnpm run test`, each in its own directory |
| values across languages | Python's JSON becomes Node's environment and bash's arguments as `{{stats.total}}`, with no parsing in between |
| a dry run | `cigo --dry-run run release` plans every task and executes none |
| rollback | files the tasks create inside the project are journaled; when a later task fails, the run puts them back, newest first |
| an undo for next week | `cig unburn <run>` undoes a whole run that succeeded |
| an undo for what cig cannot see | a task's `undo` (a deploy's teardown, say) runs on rollback and on `cig unburn` |
| nothing done twice | a task with `inputs` is skipped while its files, and the values it was handed, are unchanged |
| checked first | `cigo check` finds loops, typos, unknown toolchains, missing programs and broken templates before anything runs |
| the tools themselves | `cigo doctor` finds each toolchain's tools and versions and compares them with the project's pins |

## Thirty seconds

```
cd your-project
cigo adopt                 # every language, task runner and script folder it finds
cigo adopt --write         # saved as cig-tasks.json
cigo check
cigo --dry-run run ci      # the plan, nothing executed
cigo run ci                # format-check, lint, check, build and test, in every language
cig unburn <run>           # changed your mind: everything back
```

In a repository with a Go API, a Rust worker, a pnpm front end, a uv project,
Terraform and the old `Makefile` that used to hold it together, `adopt` says:

```
info: found 8 components:
info:   make        make            .                 build test +1 more
info:   scripts     scripts         .                 no stages +1 more
info:   infra       terraform       infra             setup format format-check check +1 more
info:   ml          python-uv       ml                setup format format-check lint test
info:   api         go              services/api      setup format format-check check build test run clean
info:   api-docker  docker          services/api      lint package
info:   worker      rust-cargo      services/worker   setup format format-check lint check build test package run clean
info:   web         node-pnpm       web               setup lint check build test +3 more
info: make, scripts: at the root of a project with components below it, these usually chain the others, which the stage groups now do; their targets stay available as <name>:<target>
```

and `cigo run test` runs:

```
shop: ml:setup > ml:test > api:setup > api:test > worker:setup > worker:test > web:setup > web:test
[1/8] ml:setup: uv sync --locked   (in ml)
[2/8] ml:test: uv run --locked pytest   (in ml)
[3/8] api:setup: go mod download   (in services/api)
[4/8] api:test: go test ./...   (in services/api)
[5/8] worker:setup: cargo fetch --locked   (in services/worker)
[6/8] worker:test: cargo test --workspace --locked   (in services/worker)
[7/8] web:setup: pnpm install --frozen-lockfile   (in web)
[8/8] web:test: pnpm run test   (in web)
```

`adopt` looks three levels down (`--depth=N` changes it). It skips
dependency and build folders, test data (`fixtures`, `testdata`, `corpus`,
`golden`, snapshots) and a component's own test folders, and counts a folder
of scripts only at the root or beside a language's manifest. A workspace
is one component: JavaScript workspaces, Deno, uv, Cargo, `go.work`, Gradle,
Maven modules, a .NET solution and a Mix umbrella. A Bazel, Buck2 or Pants
tree is one component for the whole tree.

The commands are the ones each ecosystem documents: lockfile-respecting
installs (`--locked`, `--frozen-lockfile`, `npm ci`), the package manager the
lockfile or `packageManager` field names, `package.json` scripts where the
project has them, the formatter and linter the project configures (Ruff or
Black, Biome or Prettier and ESLint, golangci-lint when it has a config).
[TOOLCHAINS.md](TOOLCHAINS.md) lists all 60.

## The chain: values between languages

The glue script this replaces usually looks like this:

```bash
#!/usr/bin/env bash
set -euo pipefail
(cd data && python3 -m unittest -q)
(cd web && node --test)
version=$(cat VERSION)
stats=$(cd data && python3 stats.py sales.csv)
export TOTAL=$(echo "$stats" | jq -r .total) ORDERS=$(echo "$stats" | jq -r .orders)
page=$(cd web && node build.mjs --version "$version" | sed -n 's/^built \(.*\) (.*/\1/p')
bash deploy/deploy.sh "$page" "$version"
# if anything after this fails, the deploy stays out there
```

In `cig-tasks.json` the same chain is data, and every link in it is checked,
planned, logged and undoable:

```json
"tasks": {
  "version": {"cmd": ["cat", "VERSION"], "capture": "text"},
  "stats":   {"cmd": ["python3", "stats.py", "sales.csv"], "cwd": "data", "capture": "json"},
  "site": {
    "cmd": ["node", "build.mjs", "--version", "{{version}}"], "cwd": "web",
    "env": {"TOTAL": "{{stats.total}}", "ORDERS": "{{stats.orders}}"},
    "inputs": ["*.mjs"], "produces": ["dist/index.html"]
  },
  "deploy": {
    "cmd": ["bash", "deploy/deploy.sh", "{{site.page}}", "{{version}}"],
    "undo": ["bash", "deploy/undeploy.sh", "{{version}}"],
    "needs": ["test"]
  },
  "release": {"needs": ["ci", "deploy"]}
}
```

`site` never declares that it needs `version` and `stats`: using their output
is the dependency. `build.mjs` hands on the page's path by writing `page=...`
to `$CIG_OUTPUT`, the way a GitHub Actions step writes to `$GITHUB_OUTPUT`.
[`examples/polyglot`](examples/polyglot) is this project, runnable with Python
3 and Node 18 and nothing to install.

| a task hands on | how | read later as |
|---|---|---|
| its stdout, as text | `"capture": "text"` | `{{task}}` |
| its stdout, parsed | `"capture": "json"`, `"lines"` or `"kv"` | `{{task.path.to.field}}`, `{{task.0}}` |
| named values, from any language | `name=value` lines appended to the file `$CIG_OUTPUT` names; `name<<END` ... `END` for several lines | `{{task.name}}` |
| everything so far | the JSON file `$CIG_OUTPUTS` names, for a program that wants to read it itself | |
| its raw stdout, as input | `"stdin_from": "task"` on the task that reads it | |

A template works in `cmd`, `shell`, `env`, `stdin`, `cwd`, `undo` and
`undo_shell`. `{{task|json}}` is the value as JSON text, for a program that
parses its argument; `{{env.NAME}}`, `{{root}}` and `{{project}}` are the
orchestrator's environment, the project directory and its name.

In a `shell` line a template is pasted in as it is, so a value that holds
`;` or `$(...)` would run as shell. `{{task|sh}}` quotes it as one word (a
list, as one word per item); `cmd` and `env` never go through a shell and
need no quoting. A `cmd` word
that is only a template naming a list (a `lines` capture) becomes one argument
per item. A task that captures and writes named values exposes both:
`{{task.value}}` and `{{task.name}}`. `cigo outputs [<task>]` shows what the
last run handed on, and a dry run keeps templates as `{{...}}` in its plan,
since nothing ran to fill them.

## The manifest

`cig-tasks.json`, in the project root. `cigo adopt --write` writes the first
one; everything in it can be edited, and `adopt --force` later finds new
components without losing what was changed.

```json
{
  "project": "shop",
  "defaults": {"timeout_ms": 600000},
  "toolchains": {
    "python-uv": {"stages": {"test": [["uv", "run", "pytest", "-x"]]}}
  },
  "components": {
    "ml":  {"path": "ml", "toolchain": "python-uv"},
    "api": {"path": "services/api", "toolchain": "go", "after": ["ml"]},
    "web": {"path": "web", "toolchain": "node-pnpm", "env_file": ".env",
            "stages": {"lint": false, "build": {"shell": "pnpm run build && pnpm run size"}}}
  },
  "tasks": {
    "deploy": {"cmd": ["bash", "scripts/deploy.sh"], "needs": ["build"], "undo": ["bash", "scripts/undeploy.sh"]}
  }
}
```

**Components** are a directory and a toolchain. Each becomes one task per
stage it has, named `component:stage` (`api:build`), and a stage name run on
its own runs it in every component: `cigo run build`. `ci` is format-check,
lint, check, build and test. `run` stays per component (`cigo run api:run`),
since a server does not end on its own.

| component key | meaning |
|---|---|
| `path` | the directory, relative to the project |
| `toolchain` | one of [TOOLCHAINS.md](TOOLCHAINS.md), or one defined under `toolchains` |
| `after` | components whose stages run first, stage by stage: `api:build` waits for `ml:build` |
| `stages` | per stage: `false` removes it, a list or string replaces the command, `{"cmd"}` or `{"shell"}` replaces it with options, any other map adds options (`env`, `timeout_ms`, `inputs`...) |
| `groups` | `false` keeps its stages out of the stage groups; they still run by name |
| `env`, `env_file` | variables for every task of the component; `env_file` is a `.env` file, relative to `path` |
| `timeout_ms`, `retries`, `retry_delay_ms` | for every task of the component |
| `desc` | one line for `cigo list` |

Within a component the stages keep the order a developer runs them in: setup
before everything, format before format-check, lint and check before build,
build before test and package. Stages the toolchain has but the component's
`package.json`, `composer.json` or `deno.json` also defines (`test`, `lint`,
`build`) come from the project's own scripts, and the rest of its scripts and
its task runner's targets are tasks too (`web:storybook`, `make:deploy`):
`cigo list --all` shows them.

**Toolchains** under `toolchains` change a built-in one for this project
(`stages` and `vars` merge, anything else replaces), or add a new one:
`{"extends": "go", "stages": {"build": [{"shell": "go generate ./... && go build ./..."}]}}`
is Go with a generate step, and a toolchain with no `extends` stands on its
own (`language`, `short`, `tools`, `versions`, `stages`).

**Tasks** under `tasks` are commands of the project's own. A task with the
name of a generated one replaces it; a task with only `needs` is a group.

| task key | meaning |
|---|---|
| `cmd` | what to run, as a list (`["bash", "scripts/build.sh"]`) or a string split on spaces; never a shell |
| `shell` | a command line for `sh -c`, by name, for pipes, globs and `&&` |
| `needs` | tasks that run first; each runs once however many need it |
| `cwd` | the directory to run in, relative to the project |
| `env`, `env_file` | variables for this task; every task also gets `CIG_TASK`, `CIG_PROJECT_ROOT`, `CIG_OUTPUT`, `CIG_OUTPUTS`, and `CIG_COMPONENT` for a component's |
| `capture` | keep its stdout as a value: `text`, `json`, `lines` or `kv` |
| `stdin`, `stdin_from` | text for its standard input, or another task's stdout |
| `inputs` | files, directories or globs (`src/**/*.ts`); unchanged since its last success, with the same command and values, means it is skipped |
| `produces` | paths or globs it must leave behind, or it failed |
| `timeout_ms` | how long before the task is killed with its whole process group; ten minutes by default |
| `retries`, `retry_delay_ms` | attempts after the first, and the pause between them |
| `ok` | exit codes that count as success, `[0]` by default; `grep`'s 1 is an answer, not a failure |
| `undo`, `undo_shell` | how to take the task back, as `cmd` or `shell`; runs on rollback and `cig unburn`, only for a task that succeeded |
| `desc` | one line for `cigo list` |

`defaults` sets `timeout_ms`, `retries` and `retry_delay_ms` for every task.
A manifest from 0.1, only `tasks`, works unchanged.

## Commands

```
cigo adopt [--write] [--force] [--depth=N]
                              find every language, task runner and script folder; propose cig-tasks.json
cigo list [--all]             components, stage groups and tasks
cigo run <task>... [--only] [--force] [-- <args for the last task named>]
                              run them, dependencies first; --only skips the dependencies,
                              --force runs tasks that are up to date
cigo plan [<task>...] [--only]
                              the order a run would take
cigo show <task>              where a task comes from and everything it will do
cigo check                    the manifest, checked before anything runs
cigo doctor                   each toolchain: installed, which version, against the project's pins
cigo outputs [<task>...]      what the last run's tasks handed on
cigo toolchains [<name>] [--markdown]
                              the toolchains this knows, or one in full
```

`cig`'s own flags go before the command: `--dry-run`, `--no-rollback` (keep
what the finished tasks made when a later one fails), `--no-check`,
`--max-steps`, `--plain`, `--json`, `--no-color`, `--no-doctor`. `cigo` finds
the project from any subdirectory, the way `git` does.

`doctor` reads the pins a project already keeps (`.nvmrc`, `.node-version`,
`.python-version`, `.ruby-version`, `.tool-versions`, `mise.toml`,
`rust-toolchain.toml`, `global.json`, `.sdkmanrc` and `.terraform-version`
among them) and treats the versions in `go.mod` and `build.zig.zon` as the
minimums they are.

## Install

Needs `cig` 1.1.1 or newer on `PATH`.

```
git clone https://github.com/otmof-ops/cig-orchestrator && cd cig-orchestrator
./install.sh      # orchestrate.cig into ~/.local/share/cig-orchestrator, cigo into ~/.local/bin
```

`PREFIX=/opt/cig ./install.sh` installs elsewhere; `CIGO_NAME=orch ./install.sh`
names the command something else. Without the launcher, the tool is one file:
`cig run path/to/orchestrate.cig -- run ci`.

## How it is built

`orchestrate.cig` is the whole tool, and it is ordinary CigScript. The
knowledge base is a map of toolchains, each a set of detection conditions
(`file:`, `dir:`, `glob:`, `grep:`, `json:`, `tool:`, `not:`) and stages whose
commands are chosen by the same conditions. The tasks become the steps of a
chain built at run time (`light`); each command is a hop (`proc.run`, or
`proc.shell` by name); the project is the pack (`pack { "." }`), so the files a
task creates are journaled; a task's `undo` is a compensation
(`burn (s) { } unburn { }`). `bin/cigo` is a few lines of `sh` that find the
tool and the project root.

The tests are CigScript too: `tests/run.cig` copies fixtures into
`.test-work/`, runs the tool as a child `cig` with its own run history, and
checks the output and the disk. A stub toolchain (`tests/fixtures/stub-bin`)
stands in for npm, cargo, go, uv and the rest, recording each command and the
directory it ran in, so the suite checks what every language would run
without installing any of them. This repository runs its own checks through
itself:

```
cigo run ci          # cig check over every .cig file, shellcheck, then the suite
```

## Limits, honestly

- A task's output is shown when the task finishes, not as it runs: hops
  capture their output. Long builds are quiet until they are done.
- Tasks run one at a time.
- Files a task *creates* inside the project are undone; files it *modifies*
  or deletes are listed as irreversible, with the detail. Hop watching skips
  `.git`, `node_modules` and `target`, so what a task puts there stays, and it
  journals everything else, so a setup that fills `.venv` with thousands of
  files takes longer than it would outside cig.
- A task changes what later tasks see only through its output
  (`capture`, `$CIG_OUTPUT`), never by changing the environment around it.
- With cig 1.1.1, directories a task creates are left behind, empty, after a
  rollback; [CigScript #16](https://github.com/otmof-ops/CigScript/pull/16)
  removes them too.
- The knowledge base holds each ecosystem's documented defaults. A project
  whose build needs an argument (an Xcode scheme, a Flutter platform, one
  solution out of several) says so in a stage override, and
  [TOOLCHAINS.md](TOOLCHAINS.md) notes which ones.

What building this turned up in CigScript itself is in [FINDINGS.md](FINDINGS.md).
