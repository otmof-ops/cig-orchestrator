# Findings

What building this orchestrator in CigScript 1.1.0 (with the hardening
round merged) turned up. The orchestrator exercised: `json.load`, maps and
lists, `pull` with nested functions, closures over loop variables, `while`
and `for`, `try`/`ashtray` inside a burn, `cough` with a map payload,
`exit()`, `args`, string methods and interpolation, `proc.run` with
timeouts, `fs.append_text`, `json.save`, `time`, `log`, a pack of five
roots, hops watched inside the pack, a compensation with `proc.shell`, a
chain built at run time with `light`, `cig check`, `cig run --dry-run`,
`cig runs`, `cig unburn`, `cig report`, `cig doctor`, `--json`.

## Fixed in CigScript (pull request #14)

- **A compensation was dropped when its block was left by `snuff`.**
  `burn (s) { ...; snuff x } unburn { ... }` recorded no compensation, so a
  later rollback or `cig unburn` skipped the undo without a word. Same for
  `break`, `continue` and `exit()`.
- **`fs.append_text` did not create the parent directory**, unlike
  `fs.write_text`. The first real run failed at `logs/lint.log` after a dry
  run that had seen no problem.
- **A chain built at run time could not name its steps.** Errors and the
  narration said `step 3`; `light(steps, {names: order})` now says `test`.

## Worked as advertised

- The dry run planned all six tasks with the deploy hop labelled
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

## Friction, left as is

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
