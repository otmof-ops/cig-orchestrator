# Changelog

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
