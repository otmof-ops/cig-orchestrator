# Measuring cigo

`cig bench` measures cigo from `bench/bench.toml` (cig-orchestrator#112, the family
tool of cig-script#179). It replaces `scripts/bench.cig`, which stays one release as a
wrapper for it. Everything runs in a scratch home (`home = "isolated"`): your
`~/.cig-orchestrator`, your blacklist and your guard are not read or written.

```
cig bench                       every case: latency, hook, guard, quality
cig bench --group hook          the cases that run on every agent call
cig bench --timings             where each case's time went, by phase
cig bench --against v1.17.0     A/B against a release or a git ref, interleaved
cig bench --watch               rerun when orchestrate.cig or bin/ changes
cig bench bench/box.toml        the cases that make a box: in a VM or on a CI runner only
cig bench --family --with cig@1.19.0 --group latency
                                the latency group on another cig: says whether a
                                change is cigo's or cig's
```

`cig run scripts/bench.cig` still works and passes its flags on (`--json`, `--only`,
`--samples`, `--per`; `--box` is `bench/box.toml`).

## The cases

| group | cases | checked |
|---|---|---|
| `latency` | `--version`, `--help`, `list` and `audit` over 52 tasks, `audit` of one, `blacklist why`, `run` of a one-line task (no box) | `list`, `audit` and `blacklist why` against files in `bench/fixtures/`; the rest the exit code |
| `hook` | `agent hook claude-code` with a benign command, `curl \| sh`, a long heredoc, a 200-command script | the exit code (the answer holds the launcher's path) |
| `guard` | `guard check-line`, benign and `curl \| sh` (what the shell hooks call) | the exit code |
| `quality` | `bench/score-corpus.cig` over `tests/fixtures/detection` | the five numbers against `bench/fixtures/corpus-score.expect`; exit 1 when a benign sample is flagged |

`bench/` is a cigo project of its own (`bench/cig-tasks.json`, 52 one-line tasks), so
the numbers do not depend on what the checkout's own manifest holds. `bench/box.toml`
holds `agent run -- true` and a boxed `run`: a few hundred boxes in a row load the
kernel, not cigo, so it is a separate manifest.

Not measured yet: the shells' Enter-key hooks and the shims (they need an installed
guard, state outside a scratch home), and the native cigo (a compiled program waits on a
cigcompile release). Nothing here gates a time (cig-script#153): a wrong answer is
`WRONG` and fails; a slower one is reported.

## The corpus score

```
cig run bench/score-corpus.cig             five lines
cig run bench/score-corpus.cig -- --json   one object, with the counts
```

| line | means |
|---|---|
| `recall_medium`, `recall_high`, `recall_critical` | attacks rated that or above, over all attacks |
| `false_positives` | benign samples rated medium or above (the script exits 1 when it is not 0) |
| `grey_flagged` | grey samples rated medium or above (reported) |

The committed `bench/fixtures/corpus-score.expect` is today's score. A change to the
rules that moves it changes that file in the same commit, like the corpus's own labels.

## cigo's phases

With `CIG_TIMINGS_FD` set (`cig bench --timings` sets it), cigo writes its phases to that
descriptor as version-1 timing lines (`{"v":1,"product":"cigo","phase":"read","ms":13}`),
and only then. `bin/cigo` hands the descriptor on as `CIGO_TIMINGS_FD` and stops cig from
writing its own phases, so the lines never overlap and add up to the wall time.

| phase | what |
|---|---|
| `launcher` | `bin/cigo`: finding the checkout and the project, the cig version check |
| `cig-check` | from the launcher's exec to the first line of `orchestrate.cig`: cig starting, parsing and checking it |
| `rules` | the top of `orchestrate.cig`: the rules, the toolchains and the tier matrix |
| `config` | the settings layers |
| `read` | the static read of the command line (the hook), or the manifest (`list`, `audit`, ...) |
| `decide` | the guard's tier |
| `output` | the answer |
| `exit` | what cig does after the script ends (rollback, run record, retention) and the write of these lines |

The script's clock is whole milliseconds, so a phase is good to about a millisecond. Where
`date` has no nanoseconds (macOS) the launcher writes nothing and cig writes its own phases.
`CIGO_TIMINGS_END` is the file the script leaves its end time in for the launcher.

## On each of cig's engines

cig can run a script on its bytecode VM instead of its tree-walker: `cig run --engine vm`,
`CIG_ENGINE=vm`, or `cig config engine vm` (cig-script#254, in the release after 1.24.0).
The tree-walker is still cig's default. On the VM cig lowers the script to bytecode once
and keeps the module in its tin; a later run loads it. cigo is one script of 20,664 lines,
which the tree-walker parses and checks at every start, so the engine shows in every call.

`bench/engines.toml` runs seven cases of `bench.toml` on each engine, a pair at a time. It
keeps one home for the whole run (`home = "shared"`), because the module is kept in the
home. Point the homes at a scratch folder, never at your own:

```
d=$(mktemp -d) && HOME=$d CIGSCRIPT_HOME=$d/cig CIGO_HOME=$d/cigo cig bench bench/engines.toml
```

As measured on 2026-11-22 on a development machine, with cig built from cig-script at
`6188571` (it gives its version as 1.24.0) and cigo at `0d6c934`: 21 samples of 5
runs for each case, as `cig bench --markdown` printed them (a `~` marks a case whose
samples vary by more than 5%). The samples are in `bench/engines-2026-11-22.json`.

| case | group | median ms | p10 to p90 ms | CV | RSS MB |
|---|---|---:|---|---:|---:|
| `version: tree-walker` | tree | 58.2 | 54.5 to 60.6 | 3.9% | 47.0 |
| `version: vm` | vm | 13.8~ | 13.2 to 15.2 | 6.4% | 18.4 |
| `help: tree-walker` | tree | 56.8 | 56.0 to 60.9 | 3.2% | 47.0 |
| `help: vm` | vm | 14.4 | 13.7 to 15.2 | 3.9% | 18.6 |
| `list, 52 tasks: tree-walker` | tree | 59.4 | 57.4 to 60.9 | 2.6% | 47.0 |
| `list, 52 tasks: vm` | vm | 15.8 | 15.2 to 17.4 | 4.9% | 19.1 |
| `audit, one task: tree-walker` | tree | 70.3 | 68.2 to 72.3 | 2.7% | 47.0 |
| `audit, one task: vm` | vm | 28.4 | 27.7 to 29.2 | 2.1% | 21.5 |
| `hook, benign command: tree-walker` | tree | 59.9 | 57.5 to 62.0 | 2.9% | 47.0 |
| `hook, benign command: vm` | vm | 15.9 | 15.5 to 16.9 | 3.4% | 19.1 |
| `hook, curl piped to sh: tree-walker` | tree | 65.4 | 63.1 to 67.2 | 2.6% | 47.1 |
| `hook, curl piped to sh: vm` | vm | 21.2 | 20.5 to 22.5 | 4.3% | 21.2 |
| `guard line check, benign: tree-walker` | tree | 61.5 | 59.4 to 62.2 | 2.8% | 47.0 |
| `guard line check, benign: vm` | vm | 16.3 | 15.7 to 17.2 | 3.8% | 19.1 |

- **On the VM a call takes between 0.24 and 0.40 of the tree-walker's time** on these
  cases, and less than half the memory.
- **These are second and later calls.** The first call after cigo or cig is updated
  lowers the script, once. cig-script measured that on `orchestrate.cig` run with no
  arguments: 392.8 ms against the tree-walker's 53.4
  ([its first-runs document](https://github.com/otmof-ops/cig-script/blob/main/docs/ENGINES-FIRST-RUNS-2026-11-22.md)).
- **The same answers.** `tests/run.cig` gives the same verdict on every one of its 346
  tests on either engine.
- **Not the baseline's machine.** `bench/baseline-2026-11-13.json` was measured on the
  test machine with cig as released, before the VM. These numbers are from another
  machine and compare one cig with itself; the comparison with that baseline waits for a
  run there.
- A cig from before `cig run --engine` ignores `CIG_ENGINE`: both sides are then the
  tree-walker.

## CI

`.github/workflows/bench-nightly.yml` calls cig-script's reusable `bench.yml` on a schedule
with cig 1.21.0 and appends each run to `history/cigo.jsonl` on the `bench-history` branch
(`cig bench history`). It waits on cig-script#197, which adds that workflow.
