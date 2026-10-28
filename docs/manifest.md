# The manifest: cig-tasks.json

One JSON file at the project root. `cigo adopt --write` writes the first one;
after that it's yours, and `cigo check` reads it over before anything runs.

```json
{
  "project": "shop",
  "defaults": {"timeout_ms": 600000},
  "toolchains": {
    "python-uv": {"stages": {"test": [["uv", "run", "pytest", "-x"]]}}
  },
  "components": {
    "ml":  {"path": "ml", "toolchain": "python-uv"},
    "api": {"path": "services/api", "toolchain": "go", "after": ["ml"]},
    "web": {"path": "web", "toolchain": "node-pnpm", "env_file": ".env",
            "stages": {"lint": false, "build": {"shell": "pnpm run build && pnpm run size"}}}
  },
  "tasks": {
    "version": {"cmd": ["cat", "VERSION"], "capture": "text"},
    "deploy":  {"cmd": ["bash", "scripts/deploy.sh", "{{version}}"], "needs": ["build"],
                "undo": ["bash", "scripts/undeploy.sh", "{{version}}"]},
    "release": {"needs": ["ci", "deploy"]}
  }
}
```

## The top level

| key | meaning |
|---|---|
| `project` | the project's name, in the run's first line and as `{{project}}`; the directory's name when absent |
| `cig` | the cig this project is written for, as cig reads a pin: `1.2` (any 1.2.x), `1.2.0` (exactly), `>=1.2.0`; every command warns when the installed cig does not satisfy it (`.cig-version` at the root says the same to cig itself) |
| `versions` | what to do when a toolchain's installed version disagrees with the project's pin: `ask`, `always`, `never` or `off` ([running on the pinned version](commands.md#running-on-the-pinned-version)) |
| `defaults` | `timeout_ms`, `retries`, `retry_delay_ms`, `inputs_limit` and `box` for every task that doesn't set its own |
| `toolchains` | this project's changes to built-in toolchains, and toolchains of its own ([your own toolchains](custom-toolchains.md)) |
| `components` | a directory and the toolchain that builds it, one entry each |
| `tasks` | commands of the project's own: the chain, the deploy, anything else |

A manifest needs `components` or `tasks`, or both. A manifest from cigo 0.1,
with only `tasks`, works unchanged.

## Components

Each component becomes one task per stage it has, named `component:stage`
(`api:build`), plus one per extra target (`web:storybook`, `make:deploy`).

| key | meaning |
|---|---|
| `path` | the directory, relative to the project root; `.` for the root |
| `toolchain` | one of [TOOLCHAINS.md](../TOOLCHAINS.md), or one defined under `toolchains` |
| `after` | components whose stages run first, stage by stage: `api:build` waits for `ml:build` |
| `stages` | per stage or target: changes to what the toolchain would run (below) |
| `groups` | `false` keeps the component out of the stage groups; its tasks still run by name |
| `env` | variables for every task of the component |
| `env_file` | a `.env` file (or a list of them), relative to `path` |
| `timeout_ms`, `retries`, `retry_delay_ms` | for every task of the component |
| `desc` | one line for `cigo list` |

### Stage overrides

| you write | it means |
|---|---|
| `"lint": false` | the component has no lint stage |
| `"build": ["make", "build"]` or `"build": "make build"` | build runs this instead |
| `"build": {"shell": "pnpm run build && pnpm run size", "timeout_ms": 900000}` | build runs this, with these options |
| `"test": {"timeout_ms": 1200000, "retries": 1}` | the toolchain's test, with these options |
| `"storybook": {"cmd": ["pnpm", "run", "storybook", "--ci"]}` | a task that isn't a stage, `web:storybook` |
| `"format": {"touches": ["src/**"]}` | the toolchain's format, with these files kept in the tin first (below) |

A command in an override can use the toolchain's vars (`{component}`,
`{dir}`, `{locked}`...). Options on a stage the toolchain doesn't have are an
error: give it `cmd` or `shell`.

### Stages and their order

| stage | what it is for | inside a component, it runs after |
|---|---|---|
| `setup` | install dependencies, from the lockfile | |
| `format` | rewrite files into shape | setup |
| `format-check` | fail if anything is out of shape | setup |
| `lint` | the linter | setup |
| `check` | the type checker or compiler check | setup |
| `build` | build it | setup |
| `test` | run the tests | setup |
| `package` | the artifact: a wheel, a crate, an image | build |
| `run` | start it (per component only; it may not end) | build |
| `clean` | remove what builds made | |

`cigo run <stage>` runs that stage in every component that has it (a *stage
group*), and `ci` runs format-check, lint, check, build and test everywhere.
`run` is never a group.

## Tasks

| key | meaning |
|---|---|
| `cmd` | what to run, as a list (`["bash", "scripts/build.sh"]`) or a string split on spaces; never a shell |
| `shell` | a command line for `sh -c`, for pipes, globs and `&&`; on Windows it runs under `sh` when one is on PATH (Git for Windows, MSYS2) and under `cmd /d /s /c` only without one, so write it for `sh` |
| `needs` | tasks that run first; each runs once however many need it |
| `desc` | one line for `cigo list` |
| `cwd` | the directory to run in, relative to the project root |
| `env` | variables for this task |
| `env_file` | a `.env` file (or a list), relative to `cwd` |
| `capture` | keep stdout as a value: `text`, `json`, `lines` or `kv` |
| `stdin` | text for standard input (templates work) |
| `stdin_from` | another task's stdout, as standard input |
| `inputs` | files, directories or globs; unchanged since the last success, with the same command and values, means the task is skipped. A fingerprint reads at most `inputs_limit` files (20,000); past that the task always runs and says so on its run line, in `cigo plan` and in `cigo show` |
| `inputs_limit` | how many files `inputs` may cover before the task gives up on skipping; raise it for a large asset tree, or narrow `inputs` |
| `produces` | paths or globs the task must leave behind, or it failed |
| `timeout_ms` | how long before the task and everything it started are killed (the process group on Unix, a Job Object on Windows); ten minutes by default |
| `retries`, `retry_delay_ms` | attempts after the first, and the pause between them |
| `ok` | exit codes that count as success, `[0]` by default; `grep`'s 1 is an answer, not a failure |
| `undo`, `undo_shell` | how to take the task back, as `cmd` or `shell`; runs on rollback and on `cig unburn`, only for a task that succeeded |
| `touches` | a glob or a list of globs, relative to the task's directory, of the files the task may change (`"*"` the directory's own files, `"**"` everything under it, `"src/**"`, `"package.json"`). cig keeps each existing file under them in the tin before the task runs, so a file the task modifies or deletes comes back on rollback, byte for byte, where it would otherwise be listed as irreversible. A glob written `?yarn.lock` may match nothing without a word, for a file the project does not have yet; the built-in lists a toolchain brings are all of that kind. A format stage gets its language's source files and a setup stage its lockfiles from the knowledge base without being told; a toolchain of your own sets `touches: {format: [...], setup: [...]}`. In the box (below) every change comes back whether or not `touches` named it; the globs still say what to keep sealed and what to copy first where the box is off |
| `touches_sealed` | globs, as `touches`, of files whose before-bytes are kept sealed (encrypted at rest) in the tin and in the run's record: a database with customer rows, a config with a token. Files with secret-shaped names (`.env`, `*.pem`, `id_rsa`...) are sealed without being named |
| `box` | `true` or `false`: whether the task runs in cig's box, over a copy-on-write layer on the project. In the box a task that cannot start or is killed leaves nothing behind, and every change a task that ran made is journaled with its before-bytes and comes back on rollback, `touches` or not; the build and dependency trees (`target`, `node_modules`, `.venv`...) pass through untouched, as they always did. Linux only (unprivileged user namespaces and overlayfs); elsewhere cig runs the task on the tin and says so. The default is `defaults.box`, else `CIGO_BOX`, else on for Linux and off elsewhere; `cigo run --box` and `--no-box` decide for one run. The box does not nest: a task that itself runs cig with boxed hops (a nested `cigo`, a suite of cig scripts) wants `box: false`, or those inner hops fall back to the tin and say so; the same holds for a project whose files sit on an overlay filesystem already, such as a container's layer |
| `encoding` | how the task's output is read: `lossy` (the default: bad bytes replaced, so a Windows console code page or a Latin-1 path never fails a task that exited 0), `utf-8` (strict), `utf-16`, `latin1` |
| `cmds` | several commands in a row, each a list, no shell between them; the first failure ends the task (`cmd`, `cmds`, `rm` and `shell` are alternatives, keep one) |
| `each` | with `cmd`: run it once per file the globs name, `{file}` standing for each; a list of globs, or `{"files": [...], "skip": [...]}` |
| `rm` | paths inside the project to remove through cig itself, journaled, so a rollback or `cig unburn` puts them back |
| `fail_on_output` | `true` makes any output a failure, for checks like `gofmt -l` that print what they would change and exit 0 |

A task with `needs` and nothing to run is a group: `"release": {"needs":
["ci", "deploy"]}`. A task with the name of a generated one (`api:test`,
`build`) replaces it.

### What every task gets

| variable | holds |
|---|---|
| `CIG_TASK` | the task's name |
| `CIG_PROJECT_ROOT` | the project root, absolute |
| `CIG_COMPONENT` | the component's name, for a component's task |
| `CIG_OUTPUT` | a file to append `name=value` lines to, handed on as `{{task.name}}` |
| `CIG_OUTPUTS` | a JSON file of everything handed on so far |

Plus the task's `env` and `env_file` values, over the environment cigo was
started in.

### env files

```sh
# comments and blank lines are skipped
export API_URL=https://staging.example.com
TOKEN_FILE="~/.config/shop/token"
```

`KEY=value` lines, `export` allowed, one pair of surrounding quotes removed.
Nothing is expanded.

### Templates

`{{home}}` is the home directory on every platform (`HOME` is not set under cmd or PowerShell; `USERPROFILE` is).

`{{task}}`, `{{task.field}}`, `{{task.list.0}}`, `{{task|json}}`,
`{{task|sh}}`, `{{env.NAME}}`, `{{root}}` and `{{project}}` work in `cmd`,
`shell`, `env`, `stdin`, `cwd`, `undo` and `undo_shell`. Using a task's
output makes it a dependency. [Chaining languages](chaining-languages.md)
has the whole story.

A program with templates of its own (`go list -f`, `docker --format`,
`gh --template`, goreleaser, Helm) gets its braces by doubling them:
`{{{{.ImportPath}}}}` reaches the program as `{{.ImportPath}}`, and the two
kinds mix in one word, `"{{{{.ID}}}} {{project}}"`. `cigo check` says so when
it meets a `{{...}}` that names no task.

## When check says no

`cigo check` reads the manifest against the project before anything runs.
It exits 1 when it finds an error, and prints each problem after the name of
the component or task it's about:

```
cig-tasks.json: 1 component(s), 2 task(s), 3 error(s), 1 warning(s)
  error: api: toolchain `rustt` is not one this knows; did you mean rust-cargo?
  error: deploy: `deploy.sh` does not exist
  error: deploy: {{relase.tag}} names no task; tasks here: build, deploy, ci
  warning: build: unknown key `need`, ignored; did you mean `needs`?
```

It catches unknown keys (with the key you probably meant), unknown
toolchains and components, loops, missing programs and scripts, broken
templates and filters, `stdin_from` a task that doesn't exist, stage
overrides or toolchain vars that would leave a task with nothing to run,
tools that aren't on `PATH`, and, in a toolchain of your own, conditions it
can't read, alternatives with nothing to run and stage names that aren't
stages.
