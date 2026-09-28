# How it works

cigo is one CigScript file, `orchestrate.cig`, and it uses the language the
way any script would. If you know CigScript's
[lexicon](https://github.com/otmof-ops/CigScript/blob/main/docs/LEXICON.md),
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
   A task with an `undo` runs inside `burn (s) { ... } unburn { ... }`, so
   the undo is journaled with the state it needs.
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

## The launcher

`bin/cigo` is a few lines of `sh`: it finds the tool, walks up to the
project root (except for `adopt`, `toolchains`, `help` and `version`), and
hands cig the flags that are cig's own. `install.sh` copies the tool and a
launcher that points at it.

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

```sh
cig run tests/run.cig                   # every test
cig run tests/run.cig -- monorepo       # the tests whose name contains "monorepo"
cig run --no-rollback tests/run.cig     # keep .test-work/ to look around after a failure
cigo run ci                             # cig check, shellcheck, then the suite
```

## When the language is the problem

Building cigo turns up things about CigScript itself. Those go in
[FINDINGS.md](../FINDINGS.md), and the fixes land in CigScript with a test
named after what broke, so every tool built on it gets the benefit.
