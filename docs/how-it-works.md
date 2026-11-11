# How it works

cigo is one CigScript file, `orchestrate.cig`, and it uses the language the
way any script would. If you know CigScript's
[lexicon](https://github.com/otmof-ops/cig-script/blob/main/docs/LEXICON.md),
the whole tool reads as ordinary code; if you don't, this page is the map.

## The shape of a run

1. **The pack.** The file opens with `pack { "." }`: the project is the
   scope. Every file a task creates inside it is journaled, so it can be put
   back.
2. **The graph.** The manifest is read, each component is resolved against
   its toolchain (stages, extras, overrides, vars), and the tasks, stage
   groups and `ci` become one graph. A template naming another task's output
   adds that task as a need.
3. **The chain.** The tasks to run, dependencies first, become the steps of
   a chain built at run time and lit with `light(steps, {names, quiet})`.
4. **Each task is a hop.** Its command goes through `proc.run` (never a
   shell) or `proc.shell` (by name), with its environment, stdin and timeout.
   On Linux the hop is boxed (`{box: true}`): it writes into a copy-on-write
   layer over the project, which cig applies as journaled burns when the
   task has run and drops when it could not start or was killed. A task with
   an `undo` runs inside `burn (s) { ... } unburn { ... }`, so the undo is
   journaled with the state it needs.
5. **A failure is a cough.** When a step fails, cigo coughs, and cig rolls
   the run back newest first: created files removed, compensations run. That
   is the rollback nobody wrote.

After the run, the journal lives in cig's run record, so `cig unburn <id>`
can do the same thing days later.

## The map of orchestrate.cig

| section | what's in it |
|---|---|
| stages | the stage names, which ones form groups and `ci`, the in-component order, the names projects give stage scripts, what the walk skips, script interpreters |
| the toolchains | the knowledge base: 61 toolchains as data, with the helpers that build the Python and JavaScript families |
| the command line | the command, its flags, its task names, and what follows `--` |
| small helpers | usage errors, quoting, suggestions by edit distance |
| looking at a directory | the condition language (`file:`, `grep:`...), choosing an alternative, vars |
| task runners and script folders | reading Makefiles, justfiles, Taskfiles, Rakefiles, Earthfiles and script folders into targets |
| the toolchains a project uses | merging the manifest's `toolchains` with the built-ins, and detecting toolchains in a directory |
| one component | a component's stages and extras: the toolchain's, then its script table, then its runner's targets, then the manifest's overrides |
| the manifest | loading and naming tasks |
| templates | `{{...}}`: finding references, looking values up, rendering |
| the task graph | components and tasks into one graph; resolving an order; loops |
| running one task | the hop's options, each attempt, fingerprints, captures and named values, compensations, the run itself |
| adopt | walking the project, and merging a new proposal with an existing manifest |
| looking at the graph | `list`, `show`, `plan` and `check` |
| doctor | tools, versions and pins |
| the toolchains, listed | `cigo toolchains`, and TOOLCHAINS.md |
| dispatch | which command runs |

## The knowledge base

Each toolchain is a map: how to recognize it (`detect`), which family it
belongs to and how strongly (`family`, `priority`), and per stage a list of
alternatives whose `when` conditions choose one. It's the same shape a
project writes under `toolchains`, so [your own
toolchains](custom-toolchains.md) is also the reference for the built-ins.
`cigo toolchains <name>` prints any of them.

## Versions, crashes, releases

Three sections before the dispatch carry the parity with cig itself.
*Versions* (`version_findings`, `warn_versions`) reads every cig pin the
project carries as cig reads them (`cig_pin_ok`), asks each pinned tool its
version once per command (`probe_version`, a hop, so only `run`, `check` and
`__doctor` ask), and reports on stderr; `--strict` turns the report into a
stop. *Crash reports* wrap the dispatch in a `try`: a runtime or type error
inside the tool is written as a report through a hop outside the pack
(`write_outside`), so the rollback that follows leaves it, and the error is
coughed on so cig rolls the run back; `cigo crash` (a hand-over to `ciginstaller crash`) and `cigo config` manage
the reports and `~/.cig-orchestrator/config`. *Update, uninstall and doctor* are stubs: one function
(`hand_to_installer`) finds ciginstaller (on `PATH`, then
`$CIGSCRIPT_HOME/bin`, then `~/.cigscript/bin`), runs it with the mapped
arguments and passes its exit code through, or says how to get it and exits
127. The installer's `doctor --tools` reads cigo through the hidden
`cigo __doctor --json`, which builds the findings (`doctor_findings`) and
never calls the installer back.

## The launcher

`bin/cigo` is a few lines of `sh`: it finds the tool, walks up to the
project root (except for `adopt`, `toolchains`, `help` and `version`), and
hands cig the flags that are cig's own. ciginstaller copies the tool and a
launcher that points at it; `install.sh` is a redirect to it.

## The tests

`tests/run.cig` is CigScript too. Each test copies a fixture into
`.test-work/`, runs the tool there as a child `cig` with its own
`CIGSCRIPT_HOME` (so nothing reaches your run history), and checks what it
printed and what it left on disk.

`tests/fixtures/stub-bin` stands in for every toolchain: one POSIX script,
linked under 82 names (`npm`, `cargo`, `go`, `uv`...), that records each call
as `name args @directory` in `$STUB_LOG`, prints a version when asked, and
fails on the argument `fail-please`. That's how the suite checks what every
language would run, and where, without installing any of them.

`tests/fixtures/detection` is the guard's detection corpus (#88): 26 inert
attacks, 29 benign tasks people really run and 4 grey ones (an official
installer piped to `sh`, `sudo apt-get install`), each a task that exits
before its first line and is only ever read. Every sample's header carries
its label, its ATT&CK technique and the rating it gets today
(`label: attack | technique: T1027 | expect: medium | target: critical`).
The suite holds each rating exactly, so a lost detection fails, and so does
an improvement until its label is raised in the same change. No benign task
may be flagged at medium or above, and every address an attack names,
decoded or not, is in a documentation range (RFC 5737) or under `.invalid`
(RFC 2606). Today: every benign task `none`, and 25 of 26 attacks at high
or above, 22 of them critical; m15 (wiping shell history) waits on its
error code.

```sh
cig run tests/run.cig                   # every test
cig run tests/run.cig -- monorepo       # the tests whose name contains "monorepo"
cig run tests/run.cig -- corpus         # the detection corpus
cig run --no-rollback tests/run.cig     # keep .test-work/ to look around after a failure
cigo run ci                             # cig check, shellcheck, then the suite
```

## Where a start goes (#90, #117)

Every cigo command is `cig run orchestrate.cig`, so each one pays the same
floor before it does anything. Measured on Linux (cig 1.16.1, median of 9),
`cigo --version` takes about 44 ms:

| part | ms |
|---|---|
| cig itself starting | about 4 |
| parsing orchestrate.cig's 12,700 lines | about 32 |
| `cig check` of it | about 5 |
| the top level and the command's dispatch | 2 to 3 |

A command the guard reads costs more: its first read compiles the rules'
regular expressions, 11 ms for the 33 rules on the static Linux release (5 ms
where cig links glibc, whose allocator is quicker), and a read of a short
command is about 15 ms in all.

The agent hook runs twice for each command an agent runs: once as
`cigo agent hook` and once as the `cigo agent run` it wraps the command in.
Both are written with `--no-check`. orchestrate.cig is checked in CI, so
the check at every start buys nothing, and skipping it saves its 5 ms each
time (an error in the script is still an error: it is still parsed). Lazy
tables would save about 3 ms. The verdict cache below saves the read on a
repeated command: one pass lookup rather than scanning the line again.
What moves the floor itself is parsing less: a small separate hook
program, or a compiled cigo (cig-compile's stage B).

### The launcher's floor cache (#117 W3)

`bin/cigo` runs `cig --version` as a subprocess on every call to check the
floor (`needs_major=1`, `needs_minor=20`, `needs_patch=0`), which costs
about 2.5 ms plus a fork. The result is kept in `CIGO_HOME/cig-floor`,
one line, `<abs cig path>|<size>|<mtime>|<version>`. On the next call,
one `stat` (GNU `stat -c '%s %Y'`, BSD/macOS `stat -f '%z %m'`) checks
the path, size and mtime of the cig the launcher would reach: a match
reuses the kept version and the subprocess does not run. The too-old
check is recomputed from the cached version on every call, so a bump
to the floor still refuses an old cig after an upgrade. A write to the
cache is atomic (temp file plus `mv`), a failure is never cached, and
an unwritable `CIGO_HOME` is the no-cache case. The version is
accepted only when it is digits and dots; anything else is a
`--version` failure. The PowerShell launcher does the same with
`(Get-Item $cig).Length` and `.LastWriteTimeUtc.Ticks`.
`CIGO_FLOOR_CACHE=off` turns the cache off for a single run; the
suite sets it so one test's writes do not land on another's home.

### Rules as data (#117 W8)

The three tables the hook reads are written out beside the tool in
`rules/`:

| file | from | what |
|---|---|---|
| `rules/tier-matrix.json` | `TIER_MATRIX` | the risk × confidence → silent/notice/ask/gate/refuse cells, the confidence names and the risks |
| `rules/static-reads.json` | `RULES` | every regex rule the static read runs (id, code, category, weight, pattern, sentence); weights are strings (`notes.weight_format = "decimal-string"`) so they round-trip exactly |
| `rules/packages.json` | `TOP_NPM`, `TOP_PYPI`, `TOP_CRATES` | the top-names lists the typosquat check compares against, sorted alphabetically (not by rank) |

`scripts/gen-rules.cig` regenerates them from orchestrate.cig's tables
through the hidden `cigo __dump-rules <name>` command (canonical JSON,
sorted keys, one trailing newline). The test
`hook_program_rules_equal_orchestrate_rules` compares their bytes with
the dump every run and names the generator in its failure message, so a
table change is caught the next test. The hot path reads orchestrate.cig,
not these files; the files exist to give an external hot-path program
(not yet built) the same data byte for byte.

### The verdict cache's key (#117 W11)

The cache's value is the scan's findings. The scan is a pure function
of the text it reads and the rules it reads with: it opens no files,
reads no env and does not know the cwd. The tier and the blacklist
half are decided live from the findings every call. So the key is
only:

- the line, canonicalized: a run of whitespace outside single and
  double quotes and not after a backslash escape collapses to one
  space (so `ls  -la` and `ls -la` share an entry; `echo "a  b"` and
  `echo "a b"` do not);
- a once-per-process sha256 of every rule table and constant the scan
  consults: `RULES`, `TIER_MATRIX`, `TOP_NPM / TOP_PYPI / TOP_CRATES`,
  the decoder's budget and depth, and the named regexes `NET_RE`,
  `DOTPACK_RE`, `CODE_RAWIP_RE`, `URL_HOST_RE`, `ASSIGN_RE` and
  `UPLOAD_RE`;
- the cigo version;
- the schema tag `v: cigo-verdict-3`.

Nothing read from outside the tool enters the key. A rule change with
VERSION unchanged (a dev edit, a hotfix) hashes to a new key on the
next call and every entry misses at once. An older-schema entry (`v:
cigo-verdict-1` or `-2`) has a different shape and MAC subkey, so it
cannot answer a `v: cigo-verdict-3` lookup. `cigo config verdict_cache
off` (the paranoid preset's default) bypasses the pass store: the
lookup is skipped and nothing is stored.

The tier is never cached. `cigo guard stats`' hit-rate column counts
only entries that reached the pass store (hits over hits + misses that
day; a `-` for a day with no lookups), reusing `--since`.

## When the language is the problem

Building cigo turns up things about CigScript itself. Those go in
[FINDINGS.md](../FINDINGS.md), and the fixes land in CigScript with a test
named after what broke, so every tool built on it gets the benefit.
