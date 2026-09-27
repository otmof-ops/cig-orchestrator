# Commands

```
cigo adopt [--write] [--force] [--depth=N]
cigo list [--all]
cigo run <task>... [--only] [--force] [-- <args for the last task named>]
cigo plan [<task>...] [--only]
cigo show <task>
cigo check
cigo doctor
cigo outputs [<task>...]
cigo toolchains [<name>] [--markdown]
cigo version
cigo help
```

cigo finds the project the way git does: from any subdirectory, it walks up
to the nearest directory with a `cig-tasks.json` and runs there. `adopt`,
`toolchains`, `help` and `version` work anywhere.

## The commands

**`cigo adopt`** finds every language, task runner and script folder in the
project and prints the manifest it would write (stdout) with a report on what
it found (stderr). `--write` saves it as `cig-tasks.json`; `--force` writes
over an existing one, keeping component names and settings, hand-written
components, and the manifest's tasks, toolchains and defaults. `--depth=N`
looks further down than the default of 3. See [adopting a
project](adopting-a-project.md).

**`cigo list`** shows the components, the stage groups and the tasks, each
with what it runs. `--all` adds the tasks that aren't stages: the rest of a
`package.json`'s scripts, a Makefile's other targets, a script folder's
scripts.

**`cigo run`** runs tasks, dependencies first, each once:

```sh
cigo run test                  # a stage group: every component's test
cigo run api:test web:build    # particular tasks
cigo run ci                    # format-check, lint, check, build and test, everywhere
cigo run release --force       # run tasks that are up to date as well
cigo run --only deploy         # just deploy: its dependencies don't run, so it can't read their values
cigo run scripts:seed -- --count 50    # arguments after -- go to the last task named
```

A failure stops the run and puts back what it changed (see [cig's
flags](#cigs-own-flags) to keep it instead). With `--only`, a task that
reads another's output (`{{site.page}}`) needs that task named too, since
values come from the tasks in this run.

**`cigo plan`** prints the order a run would take and each command, and runs
nothing. With no task names, it plans every task.

**`cigo show <task>`** explains one task: where it came from (a toolchain, a
`package.json` script, the manifest), the command, the directory, what it
needs, whose output it uses, and its options.

**`cigo check`** reads the manifest against the project: unknown keys,
toolchains and components, loops, missing programs and scripts, broken
templates, stage overrides that leave a task with nothing to run, and the
conditions, alternatives and vars of the project's own toolchains. It
changes nothing.

**`cigo doctor`** looks at each toolchain the project uses: whether its tools
are on `PATH`, which versions they are, and whether those match the pins the
project keeps (`.nvmrc`, `.python-version`, `.tool-versions`, `mise.toml`,
`rust-toolchain.toml`, `global.json`, and the minimums in `go.mod` and
`build.zig.zon`, among others). It exits 1 when a tool is missing.

**`cigo outputs`** shows what the last run's tasks handed on; `cigo outputs
stats` shows one task's, as JSON.

**`cigo toolchains`** lists the toolchains cigo knows; `cigo toolchains
rust-cargo` prints one in full (every stage, its alternatives and the
conditions that choose them); `--markdown` writes the table in
[TOOLCHAINS.md](../TOOLCHAINS.md).

## cig's own flags

Flags for the `cig` runtime go before the command, and the launcher passes
them through:

| flag | effect |
|---|---|
| `--dry-run` | plan every task, execute none; values from earlier tasks show as `{{...}}` |
| `--no-rollback` | when a task fails, keep what the finished tasks made (the way make does) |
| `--no-check` | skip cig's static check of the tool before it runs |
| `--max-steps N` | cig's step budget |
| `--plain` | the same messages without the catchphrases |
| `--json` | machine-readable output where cig supports it |
| `--no-color`, `--no-doctor` | no color codes; no automatic diagnosis under errors |

```sh
cigo --dry-run run release
cigo --no-rollback run build
```

After a run, cig's own commands take over: `cig runs` lists runs, `cig runs
<id>` shows one with its journal, and `cig unburn <id>` undoes one, including
every task's `undo`.

## Exit codes

| code | when |
|---|---|
| 0 | the run succeeded; check found no errors; doctor found every tool |
| 1 | a task failed and the run was put back; check found errors; doctor found a tool missing |
| 2 | the command can't start: an unknown command, task or flag, a manifest that doesn't parse, a task that can't run as written |

## What cigo keeps

Everything goes in `.cig-orchestrator/` at the project root; add it to
`.gitignore`.

| path | holds |
|---|---|
| `logs/<task>.log` | every attempt of a task: the command, its full output, its exit code and time |
| `reports/<time>.json` | one per successful run: the order, each task's result and time, and what was handed on |
| `run/outputs.json` | what the last run's tasks handed on (`cigo outputs` reads it) |
| `run/<task>.out` | the `$CIG_OUTPUT` file a task wrote |
| `state/<task>.json` | a task's inputs fingerprint and values, for skipping it when up to date |

cig keeps its own run records (the journal and snapshots) under
`~/.cigscript/runs/`.

## Environment

| variable | effect |
|---|---|
| `NO_COLOR` | no color codes |
| `CIG_PLAIN=1` | the same as `--plain` |
| `CIG_DOCTOR=0` | the same as `--no-doctor` |
| `CIGSCRIPT_HOME` | where cig keeps run records, instead of `~/.cigscript` |

## Without the launcher

`cigo` is a small `sh` script. The tool itself is one CigScript file, so this
works anywhere cig does:

```sh
cig run path/to/orchestrate.cig -- run ci
cig run --dry-run path/to/orchestrate.cig -- run release
```
