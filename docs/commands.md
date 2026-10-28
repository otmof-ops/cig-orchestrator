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
values come from the tasks in this run. Before anything starts, a value that
reaches a `shell` or `undo_shell` line unquoted is said, as `cigo check` says
it; `--strict`, or CI, stops the run on it, and a value holding shell syntax
is refused unquoted at substitution either way ([shell lines and
quoting](chaining-languages.md#shell-lines-and-quoting)).

**`cigo plan`** prints the order a run would take and each command, and runs
nothing. With no task names, it plans every task.

**`cigo show <task>`** explains one task: where it came from (a toolchain, a
`package.json` script, the manifest), the command, the directory, what it
needs, whose output it uses, and its options.

**`cigo check`** reads the manifest against the project: unknown keys,
toolchains and components, loops, missing programs and scripts, broken
templates, stage overrides that leave a task with nothing to run, the shape
of each task's `touches`, the conditions, alternatives and vars of the
project's own toolchains, and every version disagreement (below) as a
warning. `--strict` makes a disagreement an error. It changes nothing.

**`cigo doctor`** looks at each toolchain the project uses: whether its tools
are on `PATH`, which versions they are, and whether those match the pins the
project keeps (`.nvmrc`, `.python-version`, `.tool-versions`, `mise.toml`,
`rust-toolchain.toml`, `global.json`, and the minimums in `go.mod` and
`build.zig.zon`, among others), naming the version manager that would run
tasks on a pinned version; then the cig this runs under against the range
cigo supports and every cig pin the project carries. It exits 1 when a tool
is missing, and with `--strict` when a version disagrees.

**`cigo versions`** lists each language's pin against this machine: the
pinned version and where it is pinned, the installed one, and the version
manager that would run tasks on the pinned one. `cigo versions switch` says
yes for this project (tasks run on the pinned versions), `cigo versions keep`
says no, both remembered until a pin changes; `cigo versions install` prints
the manager's install command for each pinned version it lacks, and `--yes`
runs them. See [version checks](#version-checks-on-every-command).

**`cigo version`** prints this cigo and the cig it runs on; `--json` adds
the range of cig it supports, whether the installed cig is inside it, and
where the tool is installed.

**`cigo update`** installs the newest release over this one: it reads the
releases, downloads `cig-orchestrator-vX.Y.Z.tar.gz` and its `.sha256`,
refuses a checksum that does not match, checks the build attestation when
`gh` is installed, and runs the release's own `install.sh` into the same
prefix. `--check` only says whether there is one. `--to=X.Y.Z` installs that
version, a yanked one included (`cigo update` on its own never picks a
version listed in the repository's `YANKED` file). A cigo running from a git
checkout is updated with `git pull` instead, and `update` says so.

**`cigo crash`** is the crash reports: `list`, `show <id>`, `send <id>`,
`delete <id>` (or `--all`). See [crash reports](#crash-reports).

**`cigo config`** reads and writes `~/.cig-orchestrator/config`:
`crash_reports` (`ask`, `always`, `never`), `issues_repo`, `update_channel`
(`stable`, `prerelease`), `versions` (`ask`, `always`, `never`, `off`) and
`install` (`ask`, `always`, `never`). `cigo config` lists them,
`cigo config <key>` prints one, `cigo config <key> <value>` sets it,
`--unset` removes it.

**`cigo outputs`** shows what the last run's tasks handed on; `cigo outputs
stats` shows one task's, as JSON.

**`cigo toolchains`** lists the toolchains cigo knows; `cigo toolchains
rust-cargo` prints one in full (every stage, its alternatives and the
conditions that choose them); `--markdown` writes the table in
[TOOLCHAINS.md](../TOOLCHAINS.md).

## Version checks, on every command

Every command that opens a project looks at the versions it depends on and
says, on stderr, where they disagree:

- the cig this runs under against the range cigo supports (`cigo version
  --json` shows both), and against the cig on `PATH` when they differ, since
  that one runs the tasks that call `cig`;
- the cig against every cig pin the project carries: `.cig-version` at the
  root, `"cig"` in the manifest, and the `# cig` header of each script a task
  hands to `cig run` or a CigScript component holds (written as cig reads
  them: `1.2` is any 1.2.x, `1.2.0` exactly that, `>=1.2.0` that or newer);
- each toolchain's installed version against the pins the project keeps
  (`.nvmrc`, `.python-version`, `go.mod`, `rust-toolchain.toml` and the rest
  of the list under `cigo doctor`).

The cig pins are files, so `list`, `plan` and `show` read them on every call.
Asking a tool its version is a process, which cig journals as a hop, so
`run` (for the components about to run), `check` and `doctor` ask; `list`,
`plan` and `show` do not. An answer is kept in
`.cig-orchestrator/state/versions.json` with the program's path, size and
time, so a tool is asked again only when it changed and an unchanged project
opens without a hop. `--strict` on `run`, `check` and `doctor` turns a
disagreement into a stop; `CIGO_VERSIONS=0` keeps the warnings quiet.

### Running on the pinned version

When a toolchain's installed version disagrees with the project's pin, cigo
can run the task on the pinned one through a version manager already on the
machine, per task and never by changing anyone's default (no `mise use`, no
`rustup default`, no shell profile edited). The first manager found wins:

| manager | how the task runs | covers |
|---|---|---|
| **mise** | `mise exec <tool>@<version> -- <command>` | whatever `mise.toml` names: node, python, ruby, go, java, bun, deno, rust, zig... |
| **asdf** | `ASDF_<TOOL>_VERSION=<version>` in the task's environment (the shims read it) | whatever `.tool-versions` names |
| **rustup** | `RUSTUP_TOOLCHAIN=<version>` (the proxies read it) | rust |
| **uv** | `UV_PYTHON=<version>` | python |
| **pyenv** | `PYENV_VERSION=<version>` | python |
| **fnm** | `fnm exec --using <version> -- <command>` | node |
| **volta** | `volta run --node <version> <command>` (volta fetches a version it lacks itself) | node |
| **rbenv** | `RBENV_VERSION=<version>` | ruby |
| **go** | `GOTOOLCHAIN=go<version>` (Go fetches the toolchain itself the first time) | go |

What happens on a disagreement is the `versions` setting: `--versions=` on
the command, the manifest's `"versions"`, `cigo config versions`, in that
order; with nothing set it is `ask`, or `never` when `CI` is set.

| value | on a disagreement |
|---|---|
| `ask` | prints the question with the two commands that answer it (`cigo versions switch`, `cigo versions keep`), since a script cannot wait at a prompt, and runs on the installed versions meanwhile; asked once per set of pins, and again when a pin changes |
| `always` | switches without asking and says so in one line: `switching: node 22.11.0 (web/.nvmrc) via mise` |
| `never` | warns only (what 0.4.0 did) |
| `off` | does not look (the same as `CIGO_VERSIONS=0`) |

A version the manager lacks is a separate question, because it downloads:
`install` (`cigo config install`, or `--install=`) is `ask` (print the
command; `cigo versions install --yes` runs them all), `always` or `never`.
Each switched task's run line ends `on node 22.11.0 via mise (web/.nvmrc)`,
the run's record in `.cig-orchestrator/reports/` carries the same, and
`--strict` passes when the switch made the versions agree. A project with no
manager hears which one to install (`mise`, or the one language's own) and
carries on as today.

## Crash reports

A task failing is cigo doing its job. cigo itself failing, a runtime or type
error inside `orchestrate.cig`, is a bug in cigo, and it is reported the way
cig reports its own crashes: a report is saved under
`~/.cig-orchestrator/crashes/`, the run is rolled back as any failed run is,
and nothing is sent anywhere unless you say so.

The report holds cigo's and cig's versions, OS and architecture, the command
line (token-, secret-, URL- and path-looking values redacted), the project
directory relative to your home, a timestamp, the error and its line in
`orchestrate.cig`, and the id of the run. It does not hold your manifest,
environment variable values, or file contents. `cigo crash show <id>` is
exactly what `cigo crash send <id>` would file as a public issue on
`issues_repo`, one issue per fingerprint, with a comment when the same crash
is seen again. `crash_reports = always` sends without asking; `never` keeps
every report local; `ask`, the default, prints the two commands and leaves it
with you (cigo runs under cig, which owns the terminal, so it does not
prompt). `CIGO_INTERNAL_PANIC=<command>` raises one on purpose, for the suite.

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
| `state/versions.json` | the version each tool answered (with its program's path, size and time), and the answer to the versions question, per set of pins |

cig keeps its own run records (the journal, the snapshots, and the tin that
holds the before-bytes of what a task's `touches` named) under
`~/.cigscript/`. cigo keeps its own, outside any project, under
`~/.cig-orchestrator/` (`CIGO_HOME`):

| path | holds |
|---|---|
| `config` | `crash_reports`, `issues_repo`, `update_channel`, `versions`, `install` (`cigo config`) |
| `crashes/<id>.json` | crash reports, yours until you send them (`cigo crash`) |
| `update/<tag>/` | the last release `cigo update` downloaded and verified |

## Environment

| variable | effect |
|---|---|
| `NO_COLOR` | no color codes |
| `CIG_PLAIN=1` | the same as `--plain` |
| `CIG_DOCTOR=0` | the same as `--no-doctor` |
| `CIGSCRIPT_HOME` | where cig keeps run records, instead of `~/.cigscript` |
| `CIGO_HOME` | where cigo keeps its config, crash reports and downloads, instead of `~/.cig-orchestrator` |
| `CIGO_PREFIX`, `CIGO_NAME` | for `install.sh`: the install root (`~/.local`) and the command's name (`cigo`); `install.ps1` takes `-Prefix` and `-Name` |
| `CIGO_VERSIONS=0` | no version warnings |
| `CIGO_UPDATE_MANIFEST`, `CIGO_YANKED_FILE` | a local releases list and YANKED file for `cigo update`, instead of GitHub's (the suite uses them) |
| `CIGO_INTERNAL_PANIC=<command>` | crash on purpose at that command (`mid-run` for inside a run), for the suite |

## On Windows

`bin/cigo.cmd` is what `cigo` resolves to, at a cmd prompt and a PowerShell
one alike; it runs `bin/cigo.launch.ps1` beside it (through `pwsh` when it
is installed, else Windows PowerShell, with the execution policy bypassed),
which splits cig's flags, walks up to the manifest and checks the cig it
hands the tool to, the same as the `sh` launcher. The launcher is not named
`cigo.ps1` on purpose: PowerShell would run that in-process before the shim
and eat the task's `--`. `install.ps1` installs both with the tool into
`%LOCALAPPDATA%\cig-orchestrator` (`-Prefix`, `-Name`) and adds its `bin`
to the user PATH. Under Git Bash and
MSYS2 the `sh` launcher works too, and keeps a task's arguments as typed
(`MSYS2_ARG_CONV_EXCL`). The checkout carries a `.gitattributes`, so scripts
are LF and the Windows files CRLF whatever `core.autocrlf` says.

## Without the launcher

`cigo` is a small `sh` script. The tool itself is one CigScript file, so this
works anywhere cig does:

```sh
cig run path/to/orchestrate.cig -- run ci
cig run --dry-run path/to/orchestrate.cig -- run release
```
