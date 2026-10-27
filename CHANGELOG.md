# Changelog

All notable changes to cig-orchestrator. The format follows Keep a Changelog;
the project follows semantic versioning, and from 0.3.0 every version is a
tag `vX.Y.Z` with a release `cigo update` can install. `YANKED` at the
repository root lists versions it must not pick.

## Unreleased

- **A Windows launcher and installer.** `bin/cigo.ps1` for PowerShell and
  `bin/cigo.cmd` for cmd, with the same flag split, walk-up and cig check as
  the `sh` launcher; `install.ps1` installs them with the tool into
  `%LOCALAPPDATA%\cig-orchestrator` and adds its `bin` to the user PATH.
  A `.gitattributes` keeps scripts LF and the Windows files CRLF, so a
  Windows checkout runs under Git Bash and WSL. The release tarball ships
  all three. (#22)
- **Launcher and installer fixes.** `--max-steps` with no number is an
  error instead of an endless loop under `bash --posix`, and `--max-steps=N`
  is accepted; the walk-up stops when `dirname` stops changing (`//` on
  MSYS); `CDPATH` cannot corrupt the tool's path; Git Bash keeps a task's
  arguments as typed (`MSYS2_ARG_CONV_EXCL`); `install.sh` takes
  `CIGO_PREFIX` and honours `PREFIX` except under Termux, writes the
  launcher through `awk` so a quote, an ampersand or a bar in the path
  survives, prints the exact PATH line for your shell, and points at
  CigScript's install docs instead of a pinned command. (#23)

- **Programs and paths on every machine.** A program with a backslash in
  its name is a path for `check` too; a nested `cig.exe run` is seen as a
  nested cig run; globs are built with forward slashes; `file:` matches the
  exact name on every filesystem (so `file:Dockerfile` means the same thing
  on macOS as on Linux); `adopt --force` recognises an old component's path
  written with other separators or case; a task named `nul`, `con` or
  `com1` keeps its log and state under a safe name; `{{home}}` is the home
  directory where `HOME` is not set. Program lookup itself (`npm.cmd`, Git's
  bash, a relative program against the task's directory) comes from
  CigScript 1.3's resolver. (#21, #28)
- **Interpreters that exist here.** An absolute shebang this machine does
  not have falls back to the same program on `PATH`; a `.sh` without a
  shebang runs with `sh`; `.py` runs with `python3`, `python` or `py -3`,
  `.ps1` with `pwsh` or Windows PowerShell, whichever is installed; `.bat`
  and `.cmd` are adopted on Windows. (#26)
- **Encodings.** A byte-order mark in `cig-tasks.json`, a `.env` file or a
  script is not part of it; `$CIG_OUTPUT` written as UTF-16 is named as the
  reason nothing arrived; a task's output is read with bad bytes replaced
  unless the task sets `encoding` (`utf-8`, `utf-16`, `latin1`), so a
  Windows console code page never fails a task that exited 0; a `text`
  capture has no stray `\r`. (#27)

## 0.3.0 — 2026-10-27

Needs cig 1.2.1: the tin, the pin and `cig.version()` come with 1.2.0, and 1.2.1 snapshots a read-only file (a tin object) like any other, which the suite relies on.

- **Version checks on every command.** Every command that opens a project
  says, on stderr, where versions disagree: the installed cig against the
  range cigo supports and against the project's pins (`.cig-version`, the
  manifest's new `cig` key, the `# cig` header of each script a task hands
  to cig or a CigScript component holds), the cig on `PATH` against the one
  running cigo, and each toolchain's version against the pins the project
  keeps (`.nvmrc`, `go.mod`, `rust-toolchain.toml`...). `check` lists them
  as warnings, `doctor` prints every version side by side, and `--strict`
  on `run`, `check` and `doctor` stops on a disagreement. `CIGO_VERSIONS=0`
  keeps them quiet. (#18, step 11, and the versioning parity with CigScript)
- **The tin: what a task rewrites comes back.** A task's `touches` (a glob
  or a list, relative to its directory) names the files it may change; cig
  1.2 keeps them before the task runs and puts a modified or deleted one
  back on rollback, where it was listed as irreversible before. Format stages
  carry their language's source files and setup stages their lockfiles from
  the knowledge base, so an adopted project gets this without a line of
  config; a toolchain's `touches` map or a stage override sets its own.
  `cigo check` refuses an absolute or climbing glob; `cigo show` and `cigo
  plan` print them. (#18, step 11)
- **Crash reports, the same deal as cig's.** A runtime or type error inside
  `orchestrate.cig` is a bug in cigo: a report (versions, OS, the redacted
  command line, the error and its line, the run id; never your manifest,
  environment or files) is saved under `~/.cig-orchestrator/crashes/` by a
  hop outside the project, so the rollback that follows the crash leaves it
  in place, and nothing is sent unless you say so. `cigo crash
  list|show|send|delete`; `crash_reports`, `issues_repo` and
  `update_channel` in `~/.cig-orchestrator/config` through `cigo config`.
  `CIGO_INTERNAL_PANIC` raises one on purpose, for the suite.
- **Releases, and `cigo update`.** A tag `vX.Y.Z` builds
  `cig-orchestrator-vX.Y.Z.tar.gz`, its `.sha256` and a build attestation,
  with the licence beside them. `cigo update` installs the newest release the
  channel allows over the installed one, refusing a checksum that does not
  match and checking the attestation when `gh` is installed; `--check` only
  looks, `--to=X.Y.Z` names one. `cigo version --json` names this cigo, the
  cig it runs on, the range it supports and where it is installed.
- **The launcher checks cig first.** `cigo` refuses a cig older than 1.2.1
  with the version and the remedy, before the tool runs; `orchestrate.cig`
  carries `# cig >=1.2.1`, which cig 1.2 enforces on its own. `install.sh`
  says the same.
- **CI** installs cig 1.2.1 and installs cigo from the release tarball.

The changes below were on main before 0.3.0 and ship with it.

- **A `.cig` script runs as its own cig run and is now undone with it.** A
  task whose command is `cig run <file>` (how the `scripts` toolchain adopts
  a `.cig` file) gets `cig unburn <id>` as its undo, the id read from the
  hop's "burned … run <id>" line, so a later failure in this run or a `cig
  unburn` of it reverses the inner run at its place; hop watching has nothing
  left to remove for that task and the inner journal stays true. `cigo adopt`
  says so beside such a script. Lighting the file's chain in the same run (one
  journal) is CigScript's to add; this closes the gap until then.
- **Troubleshooting** says where a running task's output is landing and why
  nothing streams yet.
- **CI** installs cig 1.1.2.
- **Four braces are two.** `{{{{.ImportPath}}}}` in a task's `cmd`, `shell`,
  `env`, `stdin`, `cwd` or `undo` reaches the program as `{{.ImportPath}}`,
  so `go list -f`, `docker --format` and `gh --template` can be called
  without a script around them; `cigo check` points to it when a `{{...}}`
  names no task.
- **Adopting.** The guide says where CigScript scripts of your own belong:
  a `.cig` file adopted through the `scripts` toolchain runs as a nested
  `cig run` whose compensations the outer rollback cannot reach.
- **Licensing.** The code is Apache-2.0, the documentation CC BY 4.0 and the
  examples CC0 1.0, the same split as CigScript. `LICENSE`, `NOTICE`,
  `LICENSES/` and `REUSE.toml` carry it; the README says it in plain words
  and CONTRIBUTING says what it means for a contribution.

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
  kinds, stage overrides or toolchain vars that would leave a task with
  nothing to run, and a project toolchain's unknown keys, conditions,
  alternatives and vars; suggestions are by edit distance, a swapped pair
  of letters counting as one (`rustt`: did you mean rust-cargo?).
- `list` orders each component's tasks by stage and shortens long command
  lines; `show` has the whole of it.
- `examples/polyglot`: Python, Node and bash in one chain with an undo;
  the paths it hands on are relative to the project, so its output reads
  the same wherever it's cloned.
- **Docs.** A new README with diagrams and a real terminal run, and guides
  under `docs/`: getting started, adopting a project, chaining languages,
  coming from make and friends, the manifest, commands, your own
  toolchains, CI, troubleshooting, how it works, and the roadmap. Also
  CONTRIBUTING, SUPPORT and SECURITY, issue forms for bugs, toolchain,
  quality-of-life and guidance requests, and a pull request template.
- 56 tests, with a stub toolchain that records what every language would
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
