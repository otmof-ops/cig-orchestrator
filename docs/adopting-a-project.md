# Adopting a project

The deal is simple: **you don't rewrite anything.** Your scripts, your
Makefile, your `package.json` and your toolchains stay exactly as they are.
cigo reads them, runs them, and chains them. This guide takes an existing
repository from `cigo adopt` to a chain you'd trust in CI, and ends by
retiring the glue script.

## What adopt finds

`cigo adopt` walks the project and proposes one *component* per directory and
toolchain it recognizes. Three kinds of thing count:

- **Languages and build tools**: a `go.mod`, a `Cargo.toml`, a
  `package.json` with its lockfile, a `pyproject.toml`, and the rest of the
  [60 toolchains](../TOOLCHAINS.md). Each brings its ecosystem's own
  commands for each stage, chosen by what the directory holds: the lockfile
  picks the package manager, a `ruff.toml` or `[tool.ruff]` picks Ruff, a
  `tsconfig.json` adds a type check.
- **Task runners you already have**: a `Makefile` (its `.PHONY` targets when
  it declares any), a `justfile`, a Taskfile, a Rakefile, an Earthfile. Every
  target becomes a task named `make:<target>`, `just:<recipe>` and so on.
- **Script folders**: `script/`, `scripts/`, `bin/` and `tools/`, and loose
  `*.sh` and `*.bash` files, at the project root or beside a language's
  manifest. Each script is a task named after its file (`gen_docs.sh`
  becomes `scripts:gen-docs`), run with the interpreter its shebang names or,
  without one, the one its extension implies (`.py` with `python3`, `.js`
  with `node`, `.ps1` with `pwsh`, `.cig` with `cig run`). Its first comment
  is its description. Hidden files and files with neither a shebang nor a
  known extension are left alone.

Where it looks, and where it doesn't:

- Three levels down; `cigo adopt --depth=5` goes further.
- Never into dependency and build folders (`node_modules`, `target`, `dist`,
  `build`, `vendor`, `venv`...), test data (`fixtures`, `testdata`, `corpus`,
  `golden`, snapshots), or a component's own `tests`, `spec` and `benches`
  folders.
- A workspace is one component: JavaScript workspaces, Deno, uv, Cargo,
  `go.work`, Gradle, Maven modules, a .NET solution, a Mix umbrella. A Bazel,
  Buck2 or Pants tree is one component for the whole tree.

Names follow the directory: a component at the root takes its toolchain's
short name (`node`, `rust`, `make`); one in a subdirectory takes the
directory's name (`services/api` gives `api`); a second toolchain in the same
directory adds its own (`api-docker`).

## Reading the report

```sh
cigo adopt            # the report on stderr, the proposed cig-tasks.json on stdout
```

The notes under the component list explain two decisions adopt makes for you:

- **A task runner at the root of a project with components below it** stays
  out of the stage groups. Its `build` and `test` targets usually call the
  components' own builds and tests, which the stage groups now do directly,
  so running both would do everything twice. Its targets stay runnable by
  name: `cigo run make:deploy`.
- **A task runner beside a language's own commands** stays out for the same
  reason, and when two runners share a directory with no language, only the
  first joins the groups.

Either can be turned around with `"groups": true` on the component. Nothing
is decided for good: the report is a proposal, and the file it writes is
yours.

```sh
cigo adopt --write    # cig-tasks.json
cigo check            # the manifest, checked before anything runs
cigo doctor           # the tools each toolchain needs, their versions, your pins
```

## Tuning what it found

Everything below goes in `cig-tasks.json`; the [manifest
reference](manifest.md) has every key.

**A stage your project runs differently.** `stages` on a component replaces,
removes or adjusts one stage and leaves the rest alone:

```json
"web": {
  "path": "web", "toolchain": "node-pnpm",
  "stages": {
    "lint": false,
    "build": {"shell": "pnpm run build && pnpm run size"},
    "test": {"timeout_ms": 1200000, "retries": 1}
  }
}
```

`false` removes a stage, a list or a string replaces its command, a map with
`cmd` or `shell` replaces it with options, and a map without either adds
options to the stage that's there. A command can use the toolchain's vars,
like `{component}`.

**Order between components.** `after` makes one component's stages wait for
another's, stage by stage, so `api:build` runs after `ml:build`:

```json
"api": {"path": "services/api", "toolchain": "go", "after": ["ml"]}
```

**Settings for a whole component.** `env`, `env_file` (a `.env` file,
relative to the component), `timeout_ms`, `retries` and `retry_delay_ms`
apply to every task the component has.

**Your Makefile, first-class.** If you'd rather the stage groups ran your
Makefile's targets than the toolchains' commands, set `"groups": true` on the
`make` component and `"groups": false` on the others, or point one stage at
it: `"stages": {"build": ["make", "build"]}`.

## Retiring the glue script

This is what the tool is for. A typical glue script:

```bash
#!/usr/bin/env bash
set -euo pipefail
(cd data && python3 -m unittest -q)
(cd web && node --test)
version=$(cat VERSION)
stats=$(cd data && python3 stats.py sales.csv)
export TOTAL=$(echo "$stats" | jq -r .total) ORDERS=$(echo "$stats" | jq -r .orders)
page=$(cd web && node build.mjs --version "$version" | sed -n 's/^built \(.*\) (.*/\1/p')
bash deploy/deploy.sh "$page" "$version"
```

Move it one line at a time, keeping each program exactly as it is:

1. **The tests are already stages.** With `data` and `web` as components,
   `cigo run test` runs both. Nothing to write.
2. **A value becomes a capture.** `version=$(cat VERSION)` is a task that
   captures its output:
   `"version": {"cmd": ["cat", "VERSION"], "capture": "text"}`.
3. **Parsed output becomes a JSON capture.** `stats | jq` is
   `"capture": "json"` on the stats task, and `{{stats.total}}` wherever the
   number is needed.
4. **Scraped output becomes a named value.** Instead of `sed` pulling a path
   out of a log line, the program writes `page=web/dist/index.html` to the
   file `$CIG_OUTPUT` names, and the next task reads `{{site.page}}`. That's
   a one-line change in any language; [chaining
   languages](chaining-languages.md) has the recipes.
5. **The side effect gets its undo.** The deploy task declares
   `"undo": ["bash", "deploy/undeploy.sh", "{{version}}"]`, so a failure
   after it, or `cig unburn` next week, takes it back.
6. **The order falls out.** A task that uses another's output waits for it;
   `needs` covers the rest (`"needs": ["test"]` on the deploy).

The result is [`examples/polyglot`](../examples/polyglot/cig-tasks.json).
Delete the script when the chain has done its job for a while; nothing else
changes.

## Adopting again later

Projects grow. `cigo adopt --write --force` finds the project again without
throwing away what you told it:

- components it finds again keep their names and every setting you gave
  them;
- a component that moved to another package manager (npm to pnpm, pip to uv)
  follows it, with a note saying so;
- components you wrote by hand stay while their directory does;
- your `tasks`, `toolchains` and `defaults` are kept as they are;
- the notes say what's new and what was dropped.

Run `cigo adopt` without `--write` first to see the result.

## What to commit

Commit `cig-tasks.json`. Add `.cig-orchestrator/` to `.gitignore`: it holds
per-task logs, a report per run, the values tasks handed on, and the
fingerprints that let a task be skipped as up to date.

Then put it in CI: [cigo in CI](ci.md).
