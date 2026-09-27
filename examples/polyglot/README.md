# polyglot

Three languages in one chain, and no glue script at the end of it.

- **Python** (`data/stats.py`) totals a sales CSV and prints the result as
  JSON.
- **Node** (`web/build.mjs`) builds `web/dist/index.html` from those numbers,
  which reach it as environment variables, and hands on the page's path by
  writing `page=...` to `$CIG_OUTPUT`.
- **bash** (`deploy/deploy.sh`) publishes the page under the release number,
  with `deploy/undeploy.sh` as its undo, and **Python** again
  (`deploy/announce.py`) reports where it went.

Each language keeps its own tests (`python3 -m unittest`, `node --test`) as
components, so `cigo run test` runs both, and `release` runs every language's
lint and tests before the chain. Nothing to install beyond Python 3 and
Node 18.

```
cd examples/polyglot
cigo list
cigo --dry-run run release    # the plan; templates stay {{...}} since nothing ran
cigo run release              # lint and test both languages, then version > stats > site > deploy > announce
cigo outputs stats            # the numbers Python handed on, as JSON
cigo run site                 # up to date: same sources, same numbers
echo "south,500.00" >> data/sales.csv
cigo run site                 # rebuilt: Python's numbers changed, so Node's page did
cig unburn <run>              # the release taken back: the deploy's undo runs, the page goes
```

`DEPLOY_TO=/somewhere/else cigo run release` publishes outside the project,
where only the undo can reach it. Break a test (`data/test_stats.py` or
`web/render.test.mjs`) to watch the chain stop before anything is deployed.
