# Chaining languages

The usual way to get a value from one language to the next is to print it,
capture the text in a shell, cut it out with `jq`, `sed` or `awk`, and export
it for the next program. It works until the output changes shape, and it
lives in one more language than the project needed.

In cigo, a task *hands on* values and a later task *reads* them. The two
tasks can be written in any languages at all, and neither needs to know the
other exists.

## Handing a value on

| a task hands on | how | read later as |
|---|---|---|
| its stdout, as text | `"capture": "text"` (trimmed) | `{{task}}` |
| its stdout, as JSON | `"capture": "json"`; a stdout that isn't JSON fails the task | `{{task.field}}`, `{{task.list.0}}` |
| its stdout, as lines | `"capture": "lines"` (blank lines dropped) | `{{task}}` spliced into arguments, `{{task.0}}` |
| its stdout, as `KEY=value` lines | `"capture": "kv"` (`export` allowed) | `{{task.KEY}}` |
| named values, from inside any program | `name=value` lines appended to the file `$CIG_OUTPUT` names | `{{task.name}}` |
| a named value over several lines | `name<<END`, the lines, then `END`, in that file | `{{task.name}}` |
| everything handed on so far | the JSON file `$CIG_OUTPUTS` names, to read yourself | |
| its raw stdout, as another task's input | `"stdin_from": "task"` on the task that reads it | |

A task that both captures and writes named values hands on both:
`{{task.value}}` is the capture and `{{task.name}}` each named value.

## Reading a value

A template works in `cmd`, `shell`, `env`, `stdin`, `cwd`, `undo` and
`undo_shell`:

| template | becomes |
|---|---|
| `{{stats}}` | the whole value: the text, or the JSON |
| `{{stats.total}}`, `{{stats.regions.0}}` | one field, by key or list index |
| `{{stats\|json}}` | the value as JSON text, for a program that parses its argument |
| `{{stats\|sh}}` | the value quoted as one shell word (a list: each item quoted) |
| `{{env.HOME}}` | the orchestrator's own environment |
| `{{root}}`, `{{project}}` | the project directory, and the project's name |

Three rules make it safe to lean on:

- **Using a value is a dependency.** A task that reads `{{stats.total}}`
  waits for `stats`, which runs first even if nothing else asked for it.
- **A list splices.** In `cmd`, a word that is only a template naming a list
  becomes one argument per item: `["printf", "[%s]", "{{files}}"]` with
  `files` captured as lines gives `printf [%s] a b c`.
- **A missing value stops the task, it never becomes an empty string.**
  `{{stats.totl}}` fails with the fields `stats` does have.

## Recipes: writing a named value

`$CIG_OUTPUT` names a fresh file for each task; append `name=value` lines to
it. Names start with a letter or `_`; values are text. The variable is only
set when cigo runs the program, so a script can check for it and still work
on its own.

**bash**

```bash
echo "version=$(git describe --tags)" >> "$CIG_OUTPUT"
{ echo "notes<<END"; git log --oneline -5; echo "END"; } >> "$CIG_OUTPUT"
```

**Python**

```python
import os

with open(os.environ["CIG_OUTPUT"], "a", encoding="utf-8") as out:
    out.write(f"total={total}\n")
```

**Node**

```js
import { appendFileSync } from "node:fs";

if (process.env.CIG_OUTPUT) appendFileSync(process.env.CIG_OUTPUT, `page=${page}\n`);
```

**Go**

```go
if path := os.Getenv("CIG_OUTPUT"); path != "" {
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	fmt.Fprintf(f, "binary=%s\n", binary)
}
```

**Rust**

```rust
use std::{env, fs::OpenOptions, io::Write};

if let Ok(path) = env::var("CIG_OUTPUT") {
    let mut out = OpenOptions::new().create(true).append(true).open(path)?;
    writeln!(out, "artifact={}", artifact.display())?;
}
```

**Ruby**

```ruby
File.open(ENV.fetch("CIG_OUTPUT"), "a") { |f| f.puts "gem=#{gem_path}" }
```

**PowerShell**

```powershell
Add-Content -Path $env:CIG_OUTPUT -Value "msi=$msiPath"
```

## Recipes: reading everything at once

Every task gets `$CIG_OUTPUTS`, a JSON file of everything handed on so far,
keyed by task name. For a program that wants the whole picture instead of a
few arguments:

```python
import json, os

outputs = json.load(open(os.environ["CIG_OUTPUTS"]))
print(outputs["stats"]["total"], outputs["version"])
```

```sh
jq -r '.stats.total' "$CIG_OUTPUTS"
```

## Shell lines and quoting

`cmd` never goes through a shell: each word reaches the program as it is, so
a value can't be misread as shell. `shell` is a command line for `sh -c`, and
a template in it is pasted in as text, so a value holding `;` or `$(...)`
would run. Quote values you don't control with `|sh`:

```json
"notify": {"shell": "echo {{release.notes|sh}} | mail -s release team@example.com"}
```

or pass them through `env` and read `"$NOTES"` in the line.

## Skipping work that's already done

A task with `inputs` (files, directories or globs like `src/**/*.ts`) is
skipped while those inputs, its command, its environment and its stdin are
the same as at its last success, and what it `produces` is still there. A
value from an earlier task is part of its command, so when Python's numbers
change, Node's page is rebuilt even though no Node file changed. The values
a skipped task handed on last time are handed on again. `--force` runs it
anyway.

```json
"site": {
  "cmd": ["node", "build.mjs", "--version", "{{version}}"], "cwd": "web",
  "env": {"TOTAL": "{{stats.total}}"},
  "inputs": ["*.mjs"], "produces": ["dist/index.html"]
}
```

`produces` is also a promise: a task that exits 0 without making what it
promised has failed.

## Dry runs and looking back

`cigo --dry-run run release` plans every task and executes none. Values that
would come from earlier tasks show as `{{stats.total}}` in the plan, since
nothing ran to fill them. After a real run, `cigo outputs` shows what every
task handed on, and `cigo outputs stats` one task's.

## A whole chain

[`examples/polyglot`](../examples/polyglot) puts it together: Python's
numbers become Node's environment, Node's page path becomes bash's
argument, bash's deploy location becomes Python's argument, and the deploy
carries an undo. `cigo show site` explains any task: where it came from,
what it runs, what it reads and what it waits for.
