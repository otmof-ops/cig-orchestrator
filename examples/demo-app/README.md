# demo-app

A stand-in for any project with a folder of scripts: a Python lint, a bash
build and test, a flaky script, a packager, a deploy with its undo, and a
notifier that exits 1 on purpose. None of them know CigScript exists.
`cig-tasks.json` says what depends on what; `cigo` does the rest.

```
cd examples/demo-app
cigo list
cigo --dry-run run deploy     # the whole plan, nothing executed
cigo run deploy               # for real; the deploy lands in $DEMO_REMOTE (default /tmp/demo-app-remote)
cig unburn <run>              # everything back: build outputs removed, the deploy undone by scripts/undeploy.sh
```

Break it to see a rollback: put a tab in `src/greeting.txt` (the lint fails) or
change its greeting (the test fails), then `cigo run deploy`.
