# cig-orchestrator

A chill little orchestrator, written in [CigScript](https://github.com/otmof-ops/CigScript)
to see how the language holds up when it is used for what it is for: calling
the automation scripts developers already have, in order, under one journal.

The scripts in `scripts/` are the kind of thing any project accumulates
(a build, a test, a lint, a packager, a deploy, a notifier, one flaky
script). `tasks.json` says what depends on what. `orchestrate.cig` reads
that, works out the order, runs the scripts as hops, keeps `logs/<task>.log`
and `reports/<run>.json`, and leaves the rest to `cig`:

```
cig run orchestrate.cig -- list              # the tasks and their dependencies
cig run orchestrate.cig -- plan deploy       # the order the closure would run in
cig run --dry-run orchestrate.cig -- run deploy   # the plan, nothing executed
cig run orchestrate.cig -- run deploy        # the real thing
cig runs                                     # every run, with its journal
cig unburn <run>                             # undo it: files removed, deploy undone
```

`deploy` carries an `undo` in the manifest, which the orchestrator turns into
a compensation (`burn (s) { } unburn { }`), so a failure later in the run, or
an `unburn` weeks later, runs `scripts/undeploy.sh` with the state it had.
A task with `retries` is attempted again on a bad exit code; `ok` widens the
exit-code contract (the notifier's 1 means "no channel configured").

## Running it

`cig` 1.1.x: `curl -fsSL https://raw.githubusercontent.com/otmof-ops/CigScript/main/install.sh | sh`
or `cargo install --git https://github.com/otmof-ops/CigScript cigscript`. Run
from this directory; the pack roots and `tasks.json` are relative to it.

What the exercise found, and what it exercised, is in [FINDINGS.md](FINDINGS.md).
