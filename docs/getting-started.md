# Getting started

Five minutes: install, try the example, then run your own project's tests in
every language with one command.

## 1. Install cig and cigo

cigo is written in [CigScript](https://github.com/otmof-ops/CigScript), so it
needs the `cig` runtime, 1.1.1 or newer:

```sh
# Review, then run (pinned to a release; never asks for sudo)
curl -fsSL https://raw.githubusercontent.com/otmof-ops/CigScript/v1.1.1/install.sh -o install.sh
less install.sh && sh install.sh
cig --version
```

Then cigo itself:

```sh
git clone https://github.com/otmof-ops/cig-orchestrator && cd cig-orchestrator
./install.sh      # cigo into ~/.local/bin, the tool into ~/.local/share/cig-orchestrator
cigo version
```

cigo runs the tools your project already uses (`npm`, `cargo`, `uv`,
`go`...), so those need to be installed as they are today. `cigo doctor`
tells you which ones it can't find.

## 2. Try the example

[`examples/polyglot`](../examples/polyglot) chains Python, Node and bash.
It needs Python 3 and Node 18, nothing else:

```sh
cd examples/polyglot
cigo list                      # two components, their stage groups, the chain's tasks
cigo --dry-run run release     # the plan: every task, nothing executed
cigo run release               # lint and test both languages, then the chain
cigo outputs stats             # the numbers Python handed on, as JSON
```

The last line of the run is cig's receipt, with the run id:

```
burned 32 ops (8 irreversible), run 20260927T230519-c665fd
```

`cig unburn <that id>` takes the whole release back: the deploy's undo runs,
and the files the tasks created are removed. That's the part no Makefile
does.

## 3. Your own project

From the root of a repository you work on:

```sh
cigo adopt
```

adopt reads the project and prints a report on stderr and the proposed
manifest on stdout. It writes nothing yet. The report lists each
*component*, a directory and the toolchain that builds it, with the stages it
found. For a repository with a Go API, a pnpm front end and the Makefile that
used to tie them together:

```
info: found 3 components:
info:   make  make            .                 build test +1 more
info:   api   go              services/api      setup format format-check check build test run clean
info:   web   node-pnpm       web               setup lint check build test +2 more
info: make: at the root of a project with components below it, these usually chain the others, which the stage groups now do; their targets stay available as <name>:<target>
```

`+1 more` and `+2 more` count the other tasks a component brings, such as
`make:deploy` and `web:dev`; `cigo list --all` shows them. Read the notes:
they say which task runners stay out of the stage groups, and why. When it
looks right, save it:

```sh
cigo adopt --write     # cig-tasks.json
cigo check             # nothing runs; problems and warnings, each with what to do
cigo doctor            # each toolchain: found or not, which version, against your pins
```

A warning that a tool is not on `PATH` only matters for the stages that use
it. Now run something everywhere:

```sh
cigo plan test         # the order, and each command, before anything runs
cigo run test          # every component's tests, each in its own directory
```

## 4. Reading a run

```
[2/4] api:test: go test ./...   (in services/api)
    ok      shop/api    0.412s
    ok, 1.2 s
```

Each task prints its number, its name (`component:stage`), the command and
the directory, then its output when it finishes, then `ok` and the time. A
task that hands something on says so: `ok, 18 ms; output: {...}`. The run ends
with `done:` and cig's receipt.

When a task fails, the run stops there:

```
stopped at web:test; cig puts back what this run changed, newest first
Don't see any cigarettes.
error[E600 cough]: task `web:test` failed: pnpm run test exited 1
```

Everything the earlier tasks created inside the project is put back, and any
`undo` a finished task declared runs. The failing task's full output is in
`.cig-orchestrator/logs/web-test.log`. To keep what the finished tasks made
(like make does), put `--no-rollback` before the command:
`cigo --no-rollback run test`.

## 5. Keep it

Commit `cig-tasks.json`; it is the project's, and you can edit anything in
it. Add `.cig-orchestrator/` to `.gitignore`: it holds logs, reports and the
values tasks handed on.

## Next

- [Adopting a project](adopting-a-project.md) tunes what adopt found and
  moves your glue script's steps into the chain.
- [Chaining languages](chaining-languages.md) passes values between tasks.
- [cigo in CI](ci.md) runs the same thing on every pull request.
