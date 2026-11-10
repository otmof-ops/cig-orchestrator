# How it works

cigo is one CigScript file, `orchestrate.cig`, and it uses the language the
way any script would. If you know CigScript's
[lexicon](https://github.com/otmof-ops/cig-script/blob/main/docs/LEXICON.md),
the whole tool reads as ordinary code; if you don't, this page is the map.

## The shape of a run

1. **The pack.** The file opens with `pack { "." }`: the project is the
   scope. Every file a task creates inside it is journaled, so it can be put
   back.
2. **The graph.** The manifest is read, each component is resolved against
   its toolchain (stages, extras, overrides, vars), and the tasks, stage
   groups and `ci` become one graph. A template naming another task's output
   adds that task as a need.
3. **The chain.** The tasks to run, dependencies first, become the steps of
   a chain built at run time and lit with `light(steps, {names, quiet})`.
4. **Each task is a hop.** Its command goes through `proc.run` (never a
   shell) or `proc.shell` (by name), with its environment, stdin and timeout.
   On Linux the hop is boxed (`{box: true}`): it writes into a copy-on-write
   layer over the project, which cig applies as journaled burns when the
   task has run and drops when it could not start or was killed. A task with
   an `undo` runs inside `burn (s) { ... } unburn { ... }`, so the undo is
   journaled with the state it needs.
5. **A failure is a cough.** When a step fails, cigo coughs, and cig rolls
   the run back newest first: created files removed, compensations run. That
   is the rollback nobody wrote.

After the run, the journal lives in cig's run record, so `cig unburn <id>`
can do the same thing days later.

## The map of orchestrate.cig

| section | what's in it |
|---|---|
| stages | the stage names, which ones form groups and `ci`, the in-component order, the names projects give stage scripts, what the walk skips, script interpreters |
| the toolchains | the knowledge base: 60 toolchains as data, with the helpers that build the Python and JavaScript families |
| the command line | the command, its flags, its task names, and what follows `--` |
| small helpers | usage errors, quoting, suggestions by edit distance |
| looking at a directory | the condition language (`file:`, `grep:`...), choosing an alternative, vars |
| task runners and script folders | reading Makefiles, justfiles, Taskfiles, Rakefiles, Earthfiles and script folders into targets |
| the toolchains a project uses | merging the manifest's `toolchains` with the built-ins, and detecting toolchains in a directory |
| one component | a component's stages and extras: the toolchain's, then its script table, then its runner's targets, then the manifest's overrides |
| the manifest | loading and naming tasks |
| templates | `{{...}}`: finding references, looking values up, rendering |
| the task graph | components and tasks into one graph; resolving an order; loops |
| running one task | the hop's options, each attempt, fingerprints, captures and named values, compensations, the run itself |
| adopt | walking the project, and merging a new proposal with an existing manifest |
| looking at the graph | `list`, `show`, `plan` and `check` |
| doctor | tools, versions and pins |
| the toolchains, listed | `cigo toolchains`, and TOOLCHAINS.md |
| dispatch | which command runs |

## The knowledge base

Each toolchain is a map: how to recognize it (`detect`), which family it
belongs to and how strongly (`family`, `priority`), and per stage a list of
alternatives whose `when` conditions choose one. It's the same shape a
project writes under `toolchains`, so [your own
toolchains](custom-toolchains.md) is also the reference for the built-ins.
`cigo toolchains <name>` prints any of them.

## Versions, crashes, releases

Three sections before the dispatch carry the parity with cig itself.
*Versions* (`version_findings`, `warn_versions`) reads every cig pin the
project carries as cig reads them (`cig_pin_ok`), asks each pinned tool its
version once per command (`probe_version`, a hop, so only `run`, `check` and
`__doctor` ask), and reports on stderr; `--strict` turns the report into a
stop. *Crash reports* wrap the dispatch in a `try`: a runtime or type error
inside the tool is written as a report through a hop outside the pack
(`write_outside`), so the rollback that follows leaves it, and the error is
coughed on so cig rolls the run back; `cigo crash` and `cigo config` manage
the reports and `~/.cig-orchestrator/config`. *Update, uninstall and doctor* are stubs: one function
(`hand_to_installer`) finds ciginstaller (on `PATH`, then
`$CIGSCRIPT_HOME/bin`, then `~/.cigscript/bin`), runs it with the mapped
arguments and passes its exit code through, or says how to get it and exits
127. The installer's `doctor --tools` reads cigo through the hidden
`cigo __doctor --json`, which builds the findings (`doctor_findings`) and
never calls the installer back.

## The launcher

`bin/cigo` is a few lines of `sh`: it finds the tool, walks up to the
project root (except for `adopt`, `toolchains`, `help` and `version`), and
hands cig the flags that are cig's own. ciginstaller copies the tool and a
launcher that points at it; `install.sh` is a redirect to it.

## The tests

`tests/run.cig` is CigScript too. Each test copies a fixture into
`.test-work/`, runs the tool there as a child `cig` with its own
`CIGSCRIPT_HOME` (so nothing reaches your run history), and checks what it
printed and what it left on disk.

`tests/fixtures/stub-bin` stands in for every toolchain: one POSIX script,
linked under 82 names (`npm`, `cargo`, `go`, `uv`...), that records each call
as `name args @directory` in `$STUB_LOG`, prints a version when asked, and
fails on the argument `fail-please`. That's how the suite checks what every
language would run, and where, without installing any of them.

`tests/fixtures/detection` is the guard's detection corpus (#88): 26 inert
attacks, 29 benign tasks people really run and 4 grey ones (an official
installer piped to `sh`, `sudo apt-get install`), each a task that exits
before its first line and is only ever read. Every sample's header carries
its label, its ATT&CK technique and the rating it gets today
(`label: attack | technique: T1027 | expect: medium | target: critical`).
The suite holds each rating exactly, so a lost detection fails, and so does
an improvement until its label is raised in the same change. No benign task
may be flagged at medium or above, and every address an attack names,
decoded or not, is in a documentation range (RFC 5737) or under `.invalid`
(RFC 2606). Today: every benign task `none`, and 25 of 26 attacks at high
or above, 22 of them critical; m15 (wiping shell history) waits on its
error code.

```sh
cig run tests/run.cig                   # every test
cig run tests/run.cig -- monorepo       # the tests whose name contains "monorepo"
cig run tests/run.cig -- corpus         # the detection corpus
cig run --no-rollback tests/run.cig     # keep .test-work/ to look around after a failure
cigo run ci                             # cig check, shellcheck, then the suite
```

## Where a start goes (#90)

Every cigo command is `cig run orchestrate.cig`, so each one pays the same
floor before it does anything. Measured on Linux (cig 1.16.1, median of 9),
`cigo --version` takes about 44 ms:

| part | ms |
|---|---|
| cig itself starting | about 4 |
| parsing orchestrate.cig's 12,700 lines | about 32 |
| `cig check` of it | about 5 |
| the top level and the command's dispatch | 2 to 3 |

A command the guard reads costs more: its first read compiles the rules'
regular expressions, 11 ms for the 33 rules on the static Linux release (5 ms
where cig links glibc, whose allocator is quicker), and a read of a short
command is about 15 ms in all.

The agent hook runs twice for each command an agent runs: once as
`cigo agent hook` and once as the `cigo agent run` it wraps the command in.
Both are written with `--no-check`. orchestrate.cig is checked in CI, so
the check at every start buys nothing, and skipping it saves its 5 ms each
time (an error in the script is still an error: it is still parsed). Lazy
tables would save about 3 ms. A verdict cache would save the read's 15 ms
on a repeated command, but each new command would cost a write, and in
CigScript a write is a burn: a journal entry for every command an agent
types. What moves the floor itself is parsing less: a small separate hook
program, or a compiled cigo (cig-compile's stage B).

## When the language is the problem

Building cigo turns up things about CigScript itself. Those go in
[FINDINGS.md](../FINDINGS.md), and the fixes land in CigScript with a test
named after what broke, so every tool built on it gets the benefit.
