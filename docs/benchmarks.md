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

## CI

`.github/workflows/bench-nightly.yml` calls cig-script's reusable `bench.yml` on a schedule
with cig 1.20.0 and appends each run to `history/cigo.jsonl` on the `bench-history` branch
(`cig bench history`). It waits on cig-script#197, which adds that workflow.
