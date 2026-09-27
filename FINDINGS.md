# Findings

What building this orchestrator taught about CigScript. Three rounds: the
sandbox (against 1.1.0 with the hardening round merged), 0.1.0 of the tool,
and 0.2.0, the polyglot orchestrator (both against 1.1.1).

## Round three: building 0.2.0 (CigScript 1.1.1)

0.2.0 runs eight components' stages as one chain and hands values from one
language to the next, so it leans on hops, the pack and the rollback far
harder than 0.1.0 did.

Gaps, left for a decision:

- **Hop watching journals every file a setup creates, and skips four
  directory names.** `python3 -m venv .venv` inside the pack took 2.55 s and
  wrote 2,016 journal ops for its 1,010 files; outside cig it takes 1.57 s.
  The scan skips `.git`, `node_modules`, `target` and `.cigscript` (BURN.md),
  so `.venv`, `.gradle`, `.terraform`, `build`, `dist`, `vendor`,
  `__pycache__`, `.dart_tool`, `_build` and `.stack-work` are journaled, and
  a large `uv sync` or Gradle build pays for every file. A skip list in the
  `pack` declaration, or a `.cigignore`, would let a project choose; it is
  the "hop watch exclusions" item the hardening round left open.
- **A script cannot fail with a message of its own without quoting its own
  source.** Coughing is the only way to end with an error and a rollback
  (`exit(n)` ends cleanly and keeps the burns), and the report frames the
  `cough` line inside the script. For a tool written in CigScript, its users
  see the tool's source under their task's failure. A way to raise an error
  that rolls back and reports only its message would fix it; until then the
  tool coughs a variable named for what happened (`cough the_run_failed`),
  so the quoted line reads as a sentence.
- **Keywords cannot name a variable or a parameter, though LANGUAGE.md says
  they are reserved as statement starters only.** `pull f(pack)`,
  `pull f(chain)` and `stick burn = 1` are all `E200`; only map keys and
  names after a dot accept them. Either the parser could take them in
  binding positions or the section could say where they are refused. The
  knowledge base's `node_manager` takes `packer` for this reason.
- **Still open from round two, and felt more now:** hop output is captured,
  never streamed, so `cigo run ci` across eight components is silent until
  each task ends; and a script still cannot learn its own run id to print
  the `cig unburn <id>` line itself.

Worked around, fixed upstream in #16 (unreleased):

- `fs.glob` with a leading `./` matches nothing and can list `""`, and
  `path.join(".", pattern)` produces exactly that `./`. The tool strips the
  prefix and drops empty matches before using globs for `inputs` and
  `produces`.

Worked as advertised, and relied on:

- Maps keep insertion order (LANGUAGE.md says so), which keeps components,
  stages and the knowledge base in the order they were written.
- A chain of 24 tasks built at run time, named, quiet, with one step's
  failure carrying the task's own error as `cause`.
- Compensations keep their state after the run ends: the deploy's undo in
  `examples/polyglot` runs from `cig unburn` with the arguments the templates
  gave it during the run.
- Simulated hops in a dry run return `simulated: true`, which is how the tool
  knows to keep `{{...}}` templates in the plan instead of failing on output
  that no task produced.

## Round two: building 0.1.0 (CigScript 1.1.1)

Fixed upstream in [CigScript #16](https://github.com/otmof-ops/CigScript/pull/16):

- **A `;` after a block is a syntax error.** `burn { ... }; exhale x` and
  `if c { }; x` fail with `E201`, though `;` separates statements everywhere
  else.
- **`fs.glob("*")` returns an empty string** (the directory itself) among
  its matches, and **`fs.glob("./scripts/*")` matches nothing** where
  `fs.glob("scripts/*")` matches. A single-level pattern also walks the whole
  tree under it, `node_modules` included. The tool uses `fs.list` instead.
- **Directories a hop creates stay behind after a rollback.** Hop watching
  journals the files a script creates, not the directories, so `build/` and
  `dist/` come back empty instead of gone.

Gaps, left for a decision:

- **Hop output is captured, never streamed.** An orchestrator wants the
  task's output as it happens; `proc.run` has no `stream` or `tee` option.
- **A script cannot learn its own run id.** `CIG_RUN_ID` is given to child
  processes, not to the script, so "undo this with `cig unburn <id>`" cannot
  name the id; `cig` prints it after the script ends.
- **The `text` module's argument order is undocumented.** It is the text
  first, then the pattern (`text.captures(line, pattern)`); the stdlib table
  gives arity only.
- **A script cannot choose its own rollback policy.** `--no-rollback` is a
  flag of `cig run`; a project that wants make-like "keep what finished" by
  default has to pass it every time.

## Round one: the sandbox (CigScript 1.1.0)

What the first sandbox turned up. The orchestrator exercised: `json.load`, maps and
lists, `pull` with nested functions, closures over loop variables, `while`
and `for`, `try`/`ashtray` inside a burn, `cough` with a map payload,
`exit()`, `args`, string methods and interpolation, `proc.run` with
timeouts, `fs.append_text`, `json.save`, `time`, `log`, a pack of five
roots, hops watched inside the pack, a compensation with `proc.shell`, a
chain built at run time with `light`, `cig check`, `cig run --dry-run`,
`cig runs`, `cig unburn`, `cig report`, `cig doctor`, `--json`.

### Fixed in CigScript (pull request #14)

- **A compensation was dropped when its block was left by `snuff`.**
  `burn (s) { ...; snuff x } unburn { ... }` recorded no compensation, so a
  later rollback or `cig unburn` skipped the undo without a word. Same for
  `break`, `continue` and `exit()`.
- **`fs.append_text` did not create the parent directory**, unlike
  `fs.write_text`. The first real run failed at `logs/lint.log` after a dry
  run that had seen no problem.
- **A chain built at run time could not name its steps.** Errors and the
  narration said `step 3`; `light(steps, {names: order})` now says `test`.

### Worked as advertised

- The dry run planned all six tasks with the deploy hop labeled
  `compensated`, and nothing touched the disk.
- The real run journaled every file the scripts created (reversible) and
  modified (irreversible), retried the flaky script three times, and wrote
  the report.
- `cig unburn` ran the undeploy compensation with the state it had and
  removed everything else, newest first. A failed run rolled itself back the
  same way. A second deploy on top of the first, then `unburn` of the first,
  was refused with `E704` until forced: right, since the second run had
  modified the first run's files.
- A timeout, an unknown task and a dependency loop each ended with one
  readable error.

### Friction, left as is

- **A script cannot find its own directory.** Relative pack roots and paths
  resolve against the working directory, so `cig run ~/proj/orchestrate.cig`
  from elsewhere does not find `tasks.json`. A `script.dir` read would close
  it.
- **Every invocation writes a run record**, so `cig runs` fills with
  zero-burn runs (`list`, `plan`). A design choice; it may deserve a
  `--no-record` or an automatic skip when nothing burned.
- **The checker warns `E303`** for a helper that only ever runs inside a
  burn. The idiom is to put the burn inside the helper, which works but is
  not what the warning suggests.
- **No `if` expression.** Documented (no ternary); `cond and a or b` does the
  job for strings.
- Run ids are UTC, `time.stamp()` is local time; the report file and the run
  id disagree by the timezone.
