# Troubleshooting

Every message cigo prints ends with what to try next. This page has the
longer version for the ones people meet most, grouped by when they show up.
Nobody's on trial: most of these are one line in the manifest.

## Before anything runs

**`no cig-tasks.json in /path/to/dir`**

cigo looks for the manifest in the current directory and every directory
above it. Run `cigo adopt` in the project root to make one, or `cd` into
the project.

**`cigo: cig is not on PATH`** (exit 127)

The launcher needs the CigScript runtime. [Install
CigScript](https://github.com/otmof-ops/CigScript#install), then check
`cig --version`.

**`` `uv` is not on PATH, so python-uv tasks cannot run here ``**, a warning from `cigo check`

Only the stages that use that tool are affected. Install it (the message
says where from), remove the component, or turn its stages off with
`"stages": {"test": false}`. `cigo doctor` lists every tool at once.

**`` toolchain `rustt` is not one this knows; did you mean rust-cargo? ``**

Use the suggested name. `cigo toolchains` lists them all.

**`` api: stages.lint adds options, but go has no lint stage here; give it `cmd` or `shell` ``**

A map without `cmd` or `shell` changes a stage that exists. Go's lint stage
only exists when the project has a golangci-lint config, so this one needs
its own command: `"lint": {"cmd": ["golangci-lint", "run"], "timeout_ms": 600000}`.

**`` task `worker:setup` cannot run: {locked} has no value in services/worker ``**

A toolchain var has no alternative that applies here, usually after a
project override replaced the var's list. Give the var a last alternative
without `when`: `{"value": []}`.

**`dependency loop: build > package > build`**

Two tasks need each other, directly or through others. The message spells
the loop out; remove one `needs`.

## While it runs

**`` task `web:test` failed: pnpm run test exited 1 ``**

The task's own output is printed above the error, and in full in
`.cig-orchestrator/logs/web-test.log`. Run just that task again with
`cigo run --only web:test`.

**`ran longer than 600000 ms`**, then `exited -1`

The task hit its timeout (ten minutes by default) and was killed with its
whole process group. Raise `timeout_ms` on the task or component, or in
`defaults`.

**`` {{stats.total}} in task `site`: no task by that name has produced output in this run ``**

`site` reads a value `stats` never handed on. Give `stats` a `capture`, or
have it write `total=...` to `$CIG_OUTPUT`. With `--only`, the task that
hands the value on didn't run.

**`` the output of `stats` has no `totl`; it is {...} ``**

The field name is wrong; the message shows what the output does have.

**`` task `stats` captures json, and its stdout is not JSON: ... ``**

The program printed something else on stdout: progress, a banner, a
warning. Send those to stderr, use its quiet flag, or capture `text` and
hand on named values through `$CIG_OUTPUT` instead.

**`` task `site` exited 0 but did not produce dist/index.html ``**

`produces` paths are relative to the task's `cwd`. Check the path, or the
build.

**`` up to date; `--force` runs it anyway ``**, when you expected a rebuild

None of the task's `inputs`, its command, its environment or its stdin
changed. Add what changed to `inputs`, or pass `--force`.

**`` arguments after `--` go to one task, and `release` is a group ``**

Name the task that should get them: `cigo run deploy -- --tag v2`.

**Nothing prints for a while**

Output shows when a task finishes, not as it runs. Streaming is on the
[roadmap](roadmap.md).

## After a run

**Where do I see what happened?**

`.cig-orchestrator/logs/<task>.log` for each task's output,
`.cig-orchestrator/reports/` for a JSON report per successful run, `cigo
outputs` for what the tasks handed on, and `cig runs <id>` for cig's
journal of every file the run touched.

**Empty directories after a rollback**

With cig 1.1.1, the files a task created are removed but the directories
it created stay, empty. The next CigScript release removes them too;
until then, delete them by hand.

**`cig unburn` refuses with `E704`**

A file the run touched has changed since, so restoring it would overwrite
newer work. `cig unburn <id> --dry-run` shows which; `--force` restores
anyway, if the old content is what you want.

## Still stuck

Open a [guidance
request](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=guidance-request.yml)
with the command, what it printed, and `cigo version` and `cig --version`. If
it looks like a bug, a [bug
report](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=bug-report.yml)
gets it fixed, with a test so it stays fixed.
