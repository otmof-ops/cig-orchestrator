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
cigo run build --no-box        # on the tin instead of in the box, this once
```

A failure stops the run and puts back what it changed (see [cig's
flags](#cigs-own-flags) to keep it instead). On Linux each task runs in
cig's box: over a copy-on-write layer on the project, so a task that cannot
start or is killed leaves nothing behind, and every change a task that ran
made comes back on rollback whether or not `touches` named it. `--no-box`
runs the tasks on the tin instead (`--box` asks for the box where the
default is off); a task's `box`, the manifest's `defaults.box` and
`CIGO_BOX` set the same thing more lastingly ([the
manifest](manifest.md#tasks)). With `--only`, a task that
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

**`cigo crash`** is cigo's own crash reports: `list`, `show <id>`, `send
<id>` (through cig), `delete <id>` (or `--all`). See [crash
reports](#crash-reports).

**`cigo report <run> [--send]`** bundles a run for an issue: cig's own
report for it (plan, journal, diagnostic, doctor's diagnosis, every path a
placeholder) with the manifest's shape beside it: a placeholder for the
project and for every component and task (`<project>`, `c1`, `t1`), the keys
each uses when the manifest's vocabulary has them, the toolchains cigo
knows; never a name, a value, a command, an argument, a path or a glob. A
task the run's error names in backticks gets the same placeholder. Written
under `~/.cig-orchestrator/reports/<run>.json`; `--send` files it through
cig's ashtray as a report on `issues_repo`.

**`cigo config`** is every setting, read through layers, each later one
winning: the built-in default, the preset, the administrator's
`/etc/cigscript/cigo.conf`, your `~/.cig-orchestrator/config`, the project's
`settings` in `cig-tasks.json`, and `CIGO_<KEY>` in the environment. Three
rules hold: a setting that matters for safety has its values on a scale from
loosest to tightest and **a project may only tighten** (a looser project
value is ignored and `cigo check` says so); the environment loosens a
setting only at a terminal, never under CI, where the `ci` preset applies on
its own; and `key = value !locked` in the administrator's file is final.
`cigo config` lists every setting with where it was set (`--json` for the
layers whole), `cigo config <key>` prints one, `cigo config <key> <value>`
sets it in your file, `--unset` removes it, `cigo config explain <key>` says
what it does, its default, its scale, its presets and its floor, `cigo
config diff` shows what differs from the preset, and `cigo config preset
chill|balanced|strict|paranoid|ci|agent-heavy|research` chooses the bundle
every setting starts from (a looser one is chosen at a terminal). The
settings today: `versions` (`off` < `never` < `ask` < `always`; floored),
`install` (`never` < `ask` < `always`), `crash_reports` (`always` < `ask` <
`never`), `update_channel` (`prerelease` < `stable`), `issues_repo`, and
`preset`.

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

### The guard: `cigo audit`, `cigo trust`, and what `cigo run` does first

Before a task runs, the guard reads what it is about to run: the command as
written, the scripts it names, and for a setup stage the install hooks of
the packages installed here, against patterns real attacks use. Each hit
is a finding with a code (`cig explain E873`), the place and the matching
text, scored per category into a risk: `none`, `low`, `medium`, `high`,
`critical`.

Shell text is read twice: as written, and as the shell would join it, with
the simple assignments made earlier in the same text folded in and the
quotes that join pieces taken out, so `d="$HOME/.s""sh"` reads `~/.ssh` and
a host built from parts reads as its address. A network command whose host
the read still cannot see is a finding of its own (`E872`, low; medium for an
upload of a local file), and a hidden folder from the home packed up before
a network command is high. Whatever a decoder is fed (`base64 -d`, `xxd
-r`, `printf '\x…'`, Python's `b64decode`, Node's `Buffer.from(…,
'base64')`, PowerShell's `FromBase64String`) is decoded and read the same
way, three levels deep and within a size cap, and its findings name both
places (`decoded from scripts/x.sh:4`). All of it is text: nothing runs.

```
cigo audit [<task>...] [--json]        the read, with nothing run
cigo trust <task>                      approve a task as it is now (never critical)
cigo trust list | show <task> | revoke <task> | revoke --all
cigo run <task> --accept-risk[=<task>] run a held task once (high needs its name) and approve it
cigo run <task> --run-untrusted=<task> run a refused task anyway, at a terminal
cigo run <task> --no-guard             skip the read (and the rehearsal) for one run
cigo rehearse <package>                check a package before it touches anything (below)
```

What a verdict does depends on `security`: `standard` (the default) refuses
critical, holds medium and high at a terminal until approved, and runs them
with the report unattended; `strict` (the default under CI) also fails high
unattended; `report` says it and runs; `off` does not look. An approval is
the task as it is (command, environment names, scripts, lockfiles) hashed
into one key and signed with `cig tin mac` under a subkey of the tin's key:
one lookup per run, checked again when a byte changes, and a record that
does not verify is a forged approval (`E889`), ignored and said. Nothing a
task runs can sign one: in cig's box the key folder is empty.

### The rehearsal: the dry run is the real run

On Linux with cig 1.12.0, a stage that runs code the project did not write
(an install and its hooks, a build that runs its dependencies' build
scripts), or that the read above flagged, runs once, for real, in cig's
contained box: everything it writes is a layer cig reads, the rest of the
machine is read-only to it, it opens no Unix socket, and its only way out is
the registries its toolchain's footprint names. Then cigo judges what it did
against that footprint:

- what it wrote within the footprint is applied as it is, journaled like any
  task, so there is no second run;
- what it did beyond it is the verdict's evidence, with the same friction:
  a write to a shell's startup file, a git hook or an autostart entry is
  `E873` (high), a changed credential file `E871`, a set-id file `E878`, a
  link into your home or a folder it hid `E880`, many removals `E877`, a host
  the box refused `E872` (high for a raw address);
- a rehearsal that stayed within its footprint approves the task as it is,
  so the next run pays one lookup.

```
rehearse = auto     (default) stages that run third-party code, and what the read flags
rehearse = always   every task not approved (the paranoid preset)
rehearse = never    read only (the chill preset)
```

Each toolchain's footprint (what its setup and build stages write, read,
fetch and run, from the tools' own documentation) is in the knowledge base;
`cigo toolchains <name>` prints it, and a task adds to it with `footprint`
in the manifest. A project pointing its tools at another registry
(`npm_config_registry`, `PIP_INDEX_URL`, `GOPROXY`, …) has that host joined
to the footprint at run time. Task runners (`make`, `just`, `scripts`, …)
run the project's own code and have no footprint of their own; a container
build happens in the container daemon, which the box cannot see.

**`cigo rehearse <package>`** checks a package before it touches anything:
it installs it (and, for npm, requires it once) in a scratch project inside
the box, applies none of it, and says what it did beyond the ecosystem's
footprint. No project needed.

```
cigo rehearse npm:name[@version]       npm install, then require it once
cigo rehearse pypi:name[==version]     pip install in a scratch venv
cigo rehearse crates:name[@version]    cargo build of a scratch crate
cigo rehearse ./install.sh             a script you were told to run
              [--json] [--keep]        the full evidence; keep the layer to read (cig box list)
```

It exits by risk: `0` none or low, `1` medium, `2` high, `3` critical. Off
Linux, or with an older cig, it says so and does nothing.

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
cig reports its own: a report is saved under `~/.cig-orchestrator/crashes/`,
the run is rolled back as any failed run is, and the report is handed to
cig's ashtray (`cig crash submit --origin cig-orchestrator`). From there it
is cig's: cig's `reports` setting (`cig config reports ask|always|never`;
ask once and remember, never under CI with nothing set) says whether it
goes; cig redacts it again, files one issue per bug on cigo's `issues_repo`
with a live stats block, waits out a lost network, and tells you on `cig
update --check` when a release fixed it. cigo's own `crash_reports` keeps
one word: `never` keeps the report on this machine and never hands it over;
`always` asks cig to send it in this process. `cigo crash show <id>` is what
cigo saved; `cig crash show <id>` is exactly what travels.

The report holds cigo's and cig's versions, OS and architecture, the command
line (token-, secret-, URL- and path-looking values redacted), the project
directory relative to your home, a timestamp, the error and its line in
`orchestrate.cig`, and the id of the run. It does not hold your manifest,
environment variable values, or file contents.

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
| `CIGO_BOX=0`, `CIGO_BOX=1` | tasks on the tin, or in the box, where the manifest and the task say nothing (the default is the box on Linux and the tin elsewhere) |
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
