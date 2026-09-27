# Changelog

## 0.2.0 — 2026-09-28

Every language in the project, one chain, no glue script.

- **Toolchains.** A knowledge base of 60 toolchains, each with the standard
  workflow its ecosystem documents, as the stages setup, format,
  format-check, lint, check, build, test, package, run and clean:
  JavaScript and TypeScript (npm, pnpm, Yarn, Bun, Deno), Python (uv,
  Poetry, PDM, Hatch, Pipenv, pip), Rust, Go, the JVM (Gradle for Java,
  Kotlin and Android, Maven, sbt, Mill, Leiningen, the Clojure CLI), .NET,
  C and C++ (CMake, Meson), Bazel, Buck2, Pants, Ruby, PHP, Elixir, Erlang,
  Gleam, Swift (SwiftPM, Xcode), Dart, Flutter, Zig, Haskell (Stack, Cabal),
  OCaml, Julia, R, Fortran, Lua, Perl, Nim, Crystal, Solidity (Foundry),
  PowerShell, shell and CigScript; Terraform and OpenTofu, Docker, Compose
  and Helm; make, just, Task, Rake, Earthly and script folders. Commands are
  chosen by what the directory holds: the lockfile, the `packageManager`
  field, the formatter and linter the project configures.
  `cigo toolchains` lists them, TOOLCHAINS.md is written from them.
- **Components.** `cig-tasks.json` gains `components` (a directory and a
  toolchain) and `toolchains` (a project's changes to a built-in one, or its
  own). Each stage becomes a task (`api:build`), a stage name runs it in
  every component (`cigo run test`), `ci` runs format-check, lint, check,
  build and test everywhere, and `after` orders components stage by stage.
  Stage overrides remove, replace or add options to any stage.
- **Values between tasks.** `capture` (text, json, lines, kv), named values
  written to `$CIG_OUTPUT` (with `name<<END` for several lines), every
  output so far in `$CIG_OUTPUTS`, and `stdin_from`. Templates
  (`{{task}}`, `{{task.field}}`, `{{task|json}}`, `{{task|sh}}` quoted
  for a shell line, `{{env.NAME}}`, `{{root}}`, `{{project}}`) fill
  arguments, environment, stdin, the working directory and the undo; using
  a task's output is a dependency on it, and a list splices into
  arguments. `cigo outputs` shows them.
- **Up to date.** `inputs` (files, directories, globs) skips a task whose
  sources, command and values are unchanged since it last succeeded;
  `--force` runs it anyway. `produces` (paths or globs) fails a task that
  did not make what it promised.
- `env_file` for components and tasks.
- `adopt` finds every language in the project, down to `--depth` (3),
  with workspaces counted once and Bazel, Buck2 and Pants trees claimed
  whole; test data and a component's own test folders are not searched, and
  a folder of scripts counts at the root or beside a language. A task
  runner at the root of a multi-component project, or beside
  a language's own commands, stays out of the stage groups, and only one
  runner per directory joins them. `adopt --force` keeps the names and
  settings of components it finds again, the ones written by hand, and the
  manifest's tasks, toolchains and defaults, and follows a component that
  moved to another package manager (npm to pnpm, pip to uv).
- `doctor`: each toolchain's tools and versions against the project's pins
  (`.nvmrc`, `.python-version`, `.tool-versions`, `mise.toml`,
  `rust-toolchain.toml`, `global.json` and others; `go.mod` and
  `build.zig.zon` as minimums). `show` explains one task.
- `check` also finds unknown toolchains and components, broken templates
  and filters, `stdin_from` a task that does not exist, bad `capture`
  kinds, and stage overrides or toolchain vars that would leave a task
  with nothing to run; suggestions are by edit distance (`rustt`: did you
  mean rust-cargo?).
- `list` orders each component's tasks by stage and shortens long command
  lines; `show` has the whole of it.
- `examples/polyglot`: Python, Node and bash in one chain with an undo.
- 53 tests, with a stub toolchain that records what every language would
  run and where.

## 0.1.0 — 2026-09-28

The first version as a tool rather than a sandbox.

- `adopt` finds a project's scripts (`script/`, `scripts/`, `bin/`, `tools/`,
  `*.sh` at the root), `Makefile` targets (the `.PHONY` ones when there are
  any), `package.json` scripts through the package manager the lockfile names,
  and `justfile` recipes; the shebang or the extension says how to run each,
  the first comment describes it. `--write` saves `cig-tasks.json`.
- `list`, `check`, `plan` and `run`: dependencies resolved once each, loops
  and typos caught before anything runs, `--only`, arguments after `--` passed
  to the last task named.
- Per task: `cmd` (never a shell) or `shell` (by name), `cwd`, `env`,
  `timeout_ms`, `retries`, `retry_delay_ms`, `ok`, and `undo` or `undo_shell`
  as a compensation.
- Logs per task and a report per run under `.cig-orchestrator/`.
- `bin/cigo`, a launcher that finds the project from any subdirectory and
  passes `cig`'s own flags through; `install.sh`.
- 24 tests, written in CigScript, run by the tool on itself.
- The sandbox project is now `examples/demo-app`; its deploy lands outside the
  project, which is what makes its undo necessary.
