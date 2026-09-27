# cig-orchestrator

**Keep the scripts you have. Run them through CigScript.**

Adopting a new language usually means rewriting the build first. This is the
opposite. `cigo` is one program, written in [CigScript](https://github.com/otmof-ops/CigScript),
that runs the automation a project already has: the bash scripts in `scripts/`,
the Python helpers in `tools/`, the `Makefile` targets, the `package.json`
scripts, the `justfile` recipes. None of them change. None of them need to know
CigScript exists. What they get is everything `cig` gives a script:

| what you get | how |
|---|---|
| a dry run | `cigo --dry-run run deploy` plans every task, executes none, and prints the plan |
| rollback | every file a task creates inside the project is journaled; when a later task fails, the run puts them back, newest first |
| an undo for next week | `cig unburn <run>` undoes a whole run that succeeded |
| an undo for what cig cannot see | a task's `undo` (a deploy's teardown, say) becomes a compensation: it runs on rollback and on `cig unburn`, with the state it had |
| retries, timeouts, exit-code contracts | `retries`, `timeout_ms`, `ok`, per task |
| one plan, checked first | `cigo check` finds loops, typos, missing programs and missing scripts before anything runs |
| a record | `.cig-orchestrator/logs/<task>.log`, a report per run, and `cig runs` |

## Thirty seconds

```
cd your-project
cigo adopt                 # what it found: scripts/, script/, bin/, tools/, *.sh, Makefile, package.json, justfile
cigo adopt --write         # saved as cig-tasks.json
cigo check
cigo --dry-run run test    # the plan, nothing executed
cigo run test
cig unburn <run>           # changed your mind: everything back
```

`adopt` reads a script's shebang to know how to run it (else its extension),
and its first comment as the description. It proposes the tasks; the order is
yours to add, as `needs`.

The demo in [`examples/demo-app`](examples/demo-app) is a project with a lint
in Python, a bash build and test, a flaky script, a packager, a deploy with an
undo, and a notifier that exits 1 on purpose. `cd examples/demo-app && cigo run deploy`.

## The manifest

`cig-tasks.json`, in the project root:

```json
{
  "project": "demo-app",
  "defaults": {"timeout_ms": 600000},
  "tasks": {
    "build":  {"cmd": ["bash", "scripts/build.sh"], "needs": ["lint"]},
    "lint":   {"cmd": ["python3", "scripts/lint.py", "src"]},
    "deploy": {"cmd": ["bash", "scripts/deploy.sh"], "needs": ["build"],
               "undo": ["bash", "scripts/undeploy.sh"]},
    "logs":   {"shell": "grep -c ERROR logs/*.log", "ok": [0, 1]}
  }
}
```

| key | meaning |
|---|---|
| `cmd` | what to run, as a list (`["bash", "scripts/build.sh"]`) or a plain string split on spaces. Never goes through a shell |
| `shell` | a command line for `sh -c`, by name, when you need pipes, globs or `&&` |
| `needs` | tasks that run first; each runs once however many need it |
| `desc` | one line for `cigo list` |
| `cwd` | the directory to run in, relative to the project |
| `env` | variables added for this task; every task also gets `CIG_TASK` |
| `timeout_ms` | how long before the task is killed with its whole process group; ten minutes by default |
| `retries`, `retry_delay_ms` | attempts after the first, and the pause between them |
| `ok` | exit codes that count as success, `[0]` by default; `grep`'s 1 is an answer, not a failure |
| `undo`, `undo_shell` | how to take the task back, as `cmd` or `shell`; runs on rollback and `cig unburn`, only for a task that succeeded |
| `source` | where `adopt` found it; informational |

`defaults` sets `timeout_ms`, `retries` and `retry_delay_ms` for every task.

## Commands

```
cigo adopt [--write] [--force]    propose cig-tasks.json from what the project already has
cigo list                         the tasks, what they run, what they need
cigo check                        loops, unknown needs, typos, missing programs and scripts
cigo plan [<task>...] [--only]    the order a run would take (all tasks when none are named)
cigo run <task>... [--only] [-- <args>]
                                  run them, dependencies first; --only skips the dependencies;
                                  arguments after -- go to the last task named
```

`cig`'s own flags go before the command: `--dry-run`, `--no-rollback` (keep what
the finished tasks made when a later one fails), `--no-check`, `--max-steps`,
`--plain`, `--json`, `--no-color`, `--no-doctor`. `cigo` finds the project from
any subdirectory, the way `git` does.

## Install

Needs `cig` 1.1.1 or newer on `PATH`.

```
git clone https://github.com/otmof-ops/cig-orchestrator && cd cig-orchestrator
./install.sh      # orchestrate.cig into ~/.local/share/cig-orchestrator, cigo into ~/.local/bin
```

`PREFIX=/opt/cig ./install.sh` installs elsewhere; `CIGO_NAME=orch ./install.sh`
names the command something else. Without the launcher, the tool is one file:
`cig run path/to/orchestrate.cig -- run deploy`.

## How it is built

`orchestrate.cig` is the whole tool, and it is ordinary CigScript: the tasks
become the steps of a chain built at run time (`light`), each command is a hop
(`proc.run`, or `proc.shell` by name), the project is the pack (`pack { "." }`)
so the files a script creates are journaled, and a task's `undo` is a
compensation (`burn (s) { } unburn { }`). `bin/cigo` is fifteen lines of `sh`
that find the tool and the project root.

The tests are CigScript too: `tests/run.cig` copies fixtures into `.test-work/`,
runs the tool as a child `cig` with its own run history, and checks the output
and the disk. This repository runs them through itself:

```
cigo run test        # cig's checker over the tool and the tests, shellcheck, then the suite
```

## Limits, honestly

- A task's output is shown when the task finishes, not as it runs: hops capture
  their output. Long builds are quiet until they are done.
- Tasks run one at a time.
- Files a task *creates* inside the project are undone; files it *modifies* or
  deletes are listed as irreversible, with the detail. Hop watching skips
  `.git`, `node_modules` and `target`.
- A task cannot change the environment of the tasks after it.
- With cig 1.1.1, directories a script creates are left behind, empty, after
  a rollback; [CigScript #16](https://github.com/otmof-ops/CigScript/pull/16)
  removes them too.

What building this turned up in CigScript itself is in [FINDINGS.md](FINDINGS.md).
