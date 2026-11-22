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

From 1.25.0 cig can run a script on its bytecode VM instead of its tree-walker. On the
VM cig lowers the script to bytecode once and keeps the module in its tin; a later run
loads it. cigo is one script of over 20,000 lines, which the tree-walker parses and
checks at every start, so the engine shows in every call. cigo's launcher asks cig for
the VM where a module of cigo is kept, which `cigo __lower` sees to when cigo is
installed or updated; lowering never falls on a call
([how it works](how-it-works.md#which-of-cigs-engines-runs-cigo)).

`bench/engines.toml` runs nine cases on each engine, a pair at a time: seven of
`bench.toml`'s, and the agent hook twice more as an agent's settings start it, with
`--no-check`. The VM side is cigo as its launcher runs it; the tree-walker side sets
`CIGO_ENGINE=tree`. The manifest keeps one home for the whole run (`home = "shared"`),
because the module is kept in the home, and cigo is lowered into it first. Point the
homes at a scratch folder, never at your own:

```
d=$(mktemp -d) && export HOME=$d CIGSCRIPT_HOME=$d/cig CIGO_HOME=$d/cigo
bin/cigo __lower && cig bench bench/engines.toml
```

As measured on 2026-11-23 on a development machine, with cig 1.25.0 as released (the
static Linux x86_64 asset, held to its release's sha256) and cigo as of
cig-orchestrator#142: 21 samples of 5 runs for each case, as `cig bench --markdown`
printed them (a `~` marks a case whose samples vary by more than 5%). The samples are
in `bench/engines-2026-11-23.json`.

| case | group | median ms | p10 to p90 ms | CV | RSS MB |
|---|---|---:|---|---:|---:|
| `version: tree-walker` | tree | 40.7 | 40.0 to 41.1 | 1.2% | 57.1 |
| `version: vm` | vm | 14.2 | 13.5 to 14.8 | 4.4% | 39.1 |
| `help: tree-walker` | tree | 40.5 | 40.3 to 41.2 | 1.2% | 57.1 |
| `help: vm` | vm | 14.5~ | 13.5 to 15.6 | 5.6% | 34.8 |
| `list, 52 tasks: tree-walker` | tree | 42.7 | 42.0 to 43.5 | 1.8% | 57.3 |
| `list, 52 tasks: vm` | vm | 16.7 | 16.0 to 17.6 | 4.2% | 37.2 |
| `audit, one task: tree-walker` | tree | 53.8 | 53.5 to 55.1 | 1.3% | 60.2 |
| `audit, one task: vm` | vm | 27.7 | 26.5 to 28.7 | 3.0% | 42.7 |
| `hook, benign command: tree-walker` | tree | 42.5 | 42.0 to 43.4 | 1.8% | 57.8 |
| `hook, benign command: vm` | vm | 16.6 | 16.0 to 17.6 | 3.8% | 37.7 |
| `hook, curl piped to sh: tree-walker` | tree | 49.9 | 49.4 to 51.0 | 2.0% | 58.2 |
| `hook, curl piped to sh: vm` | vm | 22.3 | 21.6 to 23.5 | 3.1% | 40.3 |
| `hook as installed, benign command: tree-walker` | tree | 35.4 | 35.1 to 35.9 | 1.2% | 57.8 |
| `hook as installed, benign command: vm` | vm | 16.9~ | 16.6 to 18.5 | 5.1% | 37.7 |
| `hook as installed, curl piped to sh: tree-walker` | tree | 42.7 | 41.3 to 43.5 | 2.1% | 58.2 |
| `hook as installed, curl piped to sh: vm` | vm | 22.6 | 22.0 to 23.9 | 3.3% | 40.3 |
| `guard line check, benign: tree-walker` | tree | 43.7 | 43.4 to 44.1 | 1.2% | 57.8 |
| `guard line check, benign: vm` | vm | 17.9~ | 17.4 to 18.7 | 5.5% | 46.2 |

- **On the VM a call takes between 0.35 and 0.53 of the tree-walker's time** on these
  cases (`version` the least, the hook as installed on a `curl` piped to `sh` the most),
  and between 0.61 and 0.80 of the memory.
- **The agent hook, as installed, goes from 35.4 ms to 16.9** on a benign command, 0.48
  of the time. It passes `--no-check`, which spares the tree-walker its check; on the VM
  the launcher leaves the flag out, since a kept module was checked when it was lowered
  and cig reads no source on such a run.
- **These are second and later calls, and the first is not a call at all.** Lowering
  cigo's script took 310.0 ms where a start on the tree-walker took 36.3 (the median of
  11 runs of `cig run --engine vm orchestrate.cig -- --version`, each in a home with
  nothing kept, against the same on the tree-walker; the runs are in
  `bench/engines-first-run-2026-11-23.json`). `cigo __lower` pays it: the
  installer runs that after it installs or updates cig or cigo, `cigo update` runs it,
  and `cigo config engine auto` runs it at a terminal. Until it has run, every call is
  on the tree-walker, as before.
- **The same answers.** CI runs the whole of `tests/run.cig` a second time with cig's
  VM as the engine (`ci (on cig's VM)`).
- **Not the baseline's machine.** `bench/baseline-2026-11-13.json` was measured on the
  test machine with cig 1.21.0, before the VM. The numbers here are from another
  machine and compare one cig with itself; the comparison with that baseline waits for
  a run there.
- **An earlier measurement.** `bench/engines-2026-11-22.json` is the same seven cases
  on a development build of cig from before the release, with the engine chosen by
  `CIG_ENGINE`: the tree-walker took 58.2 ms for `version` there and the VM 13.8. The
  released cig's tree-walker is faster than that build's, so the ratios above are the
  ones a person gets.
- With a cig from before 1.25.0 the launcher asks for nothing: both sides are then the
  tree-walker.

## CI

`.github/workflows/bench-nightly.yml` calls cig-script's reusable `bench.yml` on a schedule
with cig 1.21.0 and appends each run to `history/cigo.jsonl` on the `bench-history` branch
(`cig bench history`). It waits on cig-script#197, which adds that workflow.
