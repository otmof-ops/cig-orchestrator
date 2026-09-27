# Your own toolchains

cigo's knowledge base holds each ecosystem's documented defaults. Your
project isn't obliged to be the default. This guide changes a built-in
toolchain for one project, makes a variant of one, and teaches cigo a tool
it doesn't know. All of it lives under `toolchains` in `cig-tasks.json`, and
`cigo toolchains <name>` shows the result.

## Change a built-in, for this project

Give the toolchain's id and only what differs. `stages` and `vars` merge one
entry at a time; anything else replaces:

```json
"toolchains": {
  "python-uv": {"stages": {"test": [["uv", "run", "pytest", "-x", "-q"]]}},
  "rust-cargo": {"stages": {"lint": [["cargo", "clippy", "--all-targets", "--", "-D", "warnings", "-W", "clippy::pedantic"]]}}
}
```

Every component on those toolchains picks the change up. For one component
only, use its `stages` instead ([the manifest](manifest.md#stage-overrides)).

## A variant of a built-in

`extends` starts from another toolchain and changes what you say:

```json
"toolchains": {
  "go-generate": {
    "extends": "go",
    "language": "Go, with go generate",
    "stages": {"build": [{"shell": "go generate ./... && go build ./..."}]}
  }
},
"components": {
  "api": {"path": "services/api", "toolchain": "go-generate"}
}
```

A variant shares its base's detection, and adopt keeps choosing the built-in
unless the variant's `priority` is higher (Go's is 20). Naming it on a
component is the direct way, and `adopt --force` keeps a toolchain of your
own where you put it.

## A tool cigo doesn't know

A whole toolchain, here for [mdBook](https://rust-lang.github.io/mdBook/)
documentation, so the docs build and test with everything else:

```json
"toolchains": {
  "mdbook": {
    "language": "mdBook documentation",
    "short": "book",
    "detect": ["file:book.toml"],
    "tools": ["mdbook"],
    "versions": {"mdbook": ["mdbook", "--version"]},
    "install": "https://rust-lang.github.io/mdBook/guide/installation.html",
    "stages": {
      "build": [["mdbook", "build"]],
      "test": [["mdbook", "test"]],
      "clean": [["mdbook", "clean"]]
    },
    "extras": {"serve": [["mdbook", "serve"]]}
  }
}
```

Because it has `detect`, `cigo adopt` now finds every `book.toml` in the
project on its own. `cigo run build` builds the book with everything else,
`cigo run docs:serve` serves it, and `cigo doctor` checks `mdbook` is
installed.

## Everything a toolchain can say

| key | meaning |
|---|---|
| `language` | what it's for, in `cigo toolchains` and adopt's report |
| `short` | the component's name when it sits at the project root |
| `extends` | start from this toolchain (manifest only) |
| `detect` | conditions that all hold in a directory the toolchain builds |
| `family` | toolchains that are alternatives (npm, pnpm, Yarn); a directory gets the one with the highest `priority` |
| `priority` | which of a family wins; higher wins |
| `auto` | `false`: never detected, only named on a component |
| `workspace` | conditions for a workspace root: nothing of the same family is looked for below it |
| `claims_subtree` | `true`: nothing at all is looked for below it (Bazel, Buck2, Pants) |
| `stages` | per stage, a list of alternatives (below) |
| `extras` | tasks that aren't stages, in the same form |
| `order` | changes which stages wait for which, inside a component: `{"test": ["build"]}` |
| `vars` | values for `{name}` in commands (below) |
| `scripts` | a script table to read, like `{"file": "package.json", "key": "scripts", "run": ["npm", "run"]}` |
| `targets` | a task runner's file to read: `make`, `just`, `taskfile`, `rake`, `earthly` or `scripts` |
| `targets_run` | how to run a target, `{target}` marking where its name goes |
| `tools` | programs `cigo check` and `cigo doctor` look for on `PATH` |
| `versions` | per tool, the command that prints its version |
| `pins` | per tool, where the project keeps the version it wants (below) |
| `install` | where to get the tools, printed when one is missing |
| `note` | one line `cigo doctor` and TOOLCHAINS.md show |

### Conditions

`detect`, `workspace` and every `when` are lists of conditions that must all
hold, checked in the component's directory. A list inside the list means
"any of these".

| condition | holds when |
|---|---|
| `file:package-lock.json` | the file exists |
| `dir:tests` | the directory exists |
| `glob:*.csproj` | a file in the directory matches |
| `grep:pyproject.toml:(?m)^\[tool\.ruff` | the file's text matches the regular expression; the file may be a glob (`requirements*.txt`) or a path |
| `json:package.json:workspaces` | the JSON file has that key (a dotted path) |
| `tool:golangci-lint` | the program is on `PATH` |
| `not:file:Gemfile` | the condition after `not:` doesn't hold |

```json
"detect": ["file:package.json", ["file:pnpm-lock.yaml", "grep:package.json:\"packageManager\"\\s*:\\s*\"pnpm@"]]
```

reads: a `package.json`, and either a pnpm lockfile or a `packageManager`
field naming pnpm.

### Stages and their alternatives

A stage is a list of alternatives; the first whose `when` holds is the one
that runs, and a stage with none that holds isn't there:

```json
"lint": [
  {"when": [["file:biome.json", "file:biome.jsonc"]], "cmd": ["npm", "exec", "--no", "--", "biome", "lint", "."]},
  {"when": [["file:eslint.config.js", "file:.eslintrc.json"]], "cmd": ["npm", "exec", "--no", "--", "eslint", "."]}
]
```

An alternative is a list (a command with no conditions), or a map with
`cmd` or `shell`, an optional `when`, and an optional `env`.

### Vars

A var is a value chosen by conditions, used as `{name}` in commands:

```json
"vars": {
  "locked": [{"when": ["file:Cargo.lock"], "value": ["--locked"]}, {"value": []}]
},
"stages": {"build": [["cargo", "build", "{locked}"]]}
```

A list value spliced in as a whole word adds its items (none, here, without
a lockfile); a text value is substituted anywhere. `{component}` and `{dir}`
are always there. Give every var a last alternative without `when`: a var
with no value for a component stops its tasks, and `cigo check` says which.

### Pins

`pins` tells `cigo doctor` where a project keeps the version it wants, as
`{"node": [".nvmrc", ".tool-versions:nodejs", "mise.toml:node"]}`. Each
source is tried in turn:

| source | reads |
|---|---|
| `.nvmrc`, `.python-version`, any plain file | its first line that isn't a comment |
| `.tool-versions:nodejs` | the version on the `nodejs` line |
| `mise.toml:node` | the `node = "..."` setting |
| `.sdkmanrc:java` | the `java=` line |
| `global.json:sdk.version` | that key in the JSON |
| `rust-toolchain.toml` | the `channel` |
| `go.mod`, `build.zig.zon` | the minimum they declare; a newer tool satisfies it |

## Test it, then share it

```sh
cigo toolchains mdbook     # the definition, merged with what it extends
cigo check                 # unknown keys, conditions, alternatives and vars, before anything runs
cigo show docs:build       # the command a component will actually run
cigo --dry-run run docs:build
```

A toolchain other projects would want belongs in the knowledge base. Send it
as a pull request, or open a [toolchain
request](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=toolchain-request.yml)
with the commands you run, and it gets built with you. [Contributing](../CONTRIBUTING.md)
shows how a toolchain is added and tested.
