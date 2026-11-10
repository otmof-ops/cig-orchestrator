# Changelog

All notable changes to cig-orchestrator. The format follows Keep a Changelog;
the project follows semantic versioning, and from 0.3.0 every version is a
tag `vX.Y.Z` with a release `cigo update` can install. `YANKED` at the
repository root lists versions it must not pick.

## Unreleased

cigo runs through ciginstaller.

- **`cigo update`, `cigo uninstall` and `cigo doctor` are stubs for
  ciginstaller.** `cigo update [--check]` runs `ciginstaller update`,
  `cigo uninstall [--yes]` runs `ciginstaller uninstall cigo`, and `cigo
  doctor` runs `ciginstaller doctor --tools`. Each finds ciginstaller on
  `PATH`, then in `$CIGSCRIPT_HOME/bin`, then in `~/.cigscript/bin`, shows what
  it prints and exits with its code; without it, the stub says whose job the
  command is now and how to get ciginstaller, and exits 127. `cigo update
  --to=X.Y.Z` says updates come by carton (`ciginstaller carton list`, then
  `ciginstaller update --to <carton>`), and a cigo running from a checkout is
  still told to `git pull`.
- **`cigo __doctor --json`** is the hidden, read-only entry the installer's
  `doctor --tools` reads: the cig floor, the launcher and the tool it ran,
  the guard, what a rehearsal can use, and the project's toolchains and
  pins, as `{check, severity, found, because, fix}` findings. It never calls
  ciginstaller. What `cigo doctor` printed is in it, as findings; its exit
  code (1 on a missing tool) and `--strict` are not: `cigo run --strict` and
  `cigo check --strict` still stop on a pin.
- **`install.sh` and `install.ps1` only redirect** to `ciginstaller install
  stick cigo` and exit 1, for one release. To work on cigo, run `bin/cigo`
  from a checkout. The release tarball, its `.sha256`, the attestation and
  `YANKED` are unchanged: they are what the installer reads.
- **Removed:** the download, checksum, attestation, unpack and install code
  of `cigo update`, the `CIGO_UPDATE_MANIFEST` and `CIGO_YANKED_FILE`
  variables, `CIGO_PREFIX`, `CIGO_NAME` and `CIGO_NO_QUESTION` (the
  installer's), and the `update/` folder under `~/.cig-orchestrator` (a
  leftover one is safe to delete). `update_channel` and `YANKED` stay.
- The launchers run `uninstall` and `doctor` from cigo's empty folder when
  called from your home folder, and `__doctor` does the same where no
  project is above.

## 1.18.0 — 2026-11-10

Everything cigo keeps, held by cig's passes; a hook that reads a command
once.

- **Approvals are passes** (otmof-ops/cig-script#186). An approval of a
  task is one of cig's `approval` passes: it names the task as written in
  this project, and the files it depends on (the scripts it names, each
  lockfile beside it and at the root, there or not) are the pass's
  recorded inputs. Checking it is one lookup in process: the `cig tin mac`
  process every check paid is gone. A changed byte in any of those files,
  or a lockfile that appears, stops it holding. `cigo trust list` says
  whether each approval still holds, and why not; `cigo trust revoke`
  revokes the pass, and `cig pass revoke --kind approval` takes every
  approval back at once.
- **Every file cigo signs is held by a pass.** The blacklist's lists, its
  allows and the one-off exceptions (`rules` passes), allowances,
  remembered answers and agent approvals (`approval` passes), and kept
  rehearsal verdicts (`verdict` passes) are each held by a pass over their
  bytes, named beside the file in `<file>.pass`. A file changed by hand
  stops verifying as before (`E587`), and one whose signature is gone
  still counts from the tin (`E588`). An agent approval is used once, and
  using it now revokes its pass as well, so a copy of the record put back
  later is not an approval again.
- **What cigo signed before is honored and moved onto a pass.** A record
  or list signed with `cig tin mac` is checked once, the first time it is
  read: one that verifies moves onto a pass (an approval's old record is
  put aside under `trust/retired/`), and one that does not is said
  (`E889`, `E587`) as before. The blacklist bundle that `export` writes
  for another machine keeps its `cig tin mac` signature.
- **The verdict cache** (#117). The guard's read of a command line an
  agent runs is kept as a `verdict` pass about the line as written and
  this cigo's version, which also records cigo's own source and the rules
  the read used: the same line again is read from it, with exactly the
  findings a fresh read gives, and a new release, a changed rule or
  another line reads afresh. Only the scan is kept: the blacklist is read
  live, and an ask is never answered from it. Verdicts last a week. `cigo
  guard cache stats` counts the hits from the guard log (each agent event
  carries `cache`); `cigo guard cache clear` revokes every verdict pass.
  `cigo guard check-line` reads one line from stdin as the hook does and
  says whether the read came from the cache; every detection corpus
  sample gives the same findings from the cache as from a fresh read.
- **What looks different.**
  - `cigo trust list --json` gives each approval's `pass`, whether it
    still `holds` and `why` not. An approval that stopped holding stays
    listed until it is revoked.
  - `cigo trust revoke --all` counts the approvals it took back.
  - `cigo trust show` says whether the pass holds, and no longer prints a
    signature line.
  - An approval is for its project. Before, a task that named no file
    and had no lockfile was approved for every project with the same
    command.
  - `cig pass revoke --kind approval` takes back allowances, remembered
    answers and agent approvals with the task approvals, since all are
    one kind.
  - A `.pass` beside a file grants nothing: deleting it does not unsign
    the file, and one copied from elsewhere does not sign it.
  - Signing a list again revokes the pass it was signed with before, so
    an older copy put back does not verify (`E587`).
  - A `.mac` from before passes, put back after its file moved onto a
    pass, is never honored again (`E889`, `E587`).
- **Privacy.** The verdict cache keeps each command line an agent runs,
  as written, in cig's keys folder for up to a week. The guard log keeps
  it redacted. `cigo guard cache clear` takes them all back.
- **cig 1.20.0 or newer** (the first with passes). The native cigo in CI
  is built by cigcompile 0.3.0 onto cig 1.20.0.

## 1.17.0 — 2026-11-09

What an agent reads, scrubbed; PyPI and crates READMEs read as npm's are; the
guard counting its own noise.

- **`cigo guard stats`** (#66 step 7). The guard log, counted, so cigo
  can say whether it is asking too much. A new subcommand reads every
  event in a window (`--since=30d` by default) and prints prompts per day
  (asks, gates, notices and refusals counted apart), events per `kind`
  (`guarded`, `run-url`, `agent`, `approve`, `blacklist-light-it`,
  `config`...), events per `E`-code from the findings, and for asks and
  gates how often each was approved (yes), declined (no) or left (no
  answer, held or still waiting), and how many the log holds no answer
  for (unrecorded). It also says how often a notice was
  followed by a change of a guard-related setting (`security`,
  `rehearse`, `guard_scope`, `blacklist_unboxed`, `agent_approval`, the
  preset, and the other machine-scoped guard knobs). The log gains two
  small records that make the count honest: an event that ended a prompt
  carries a `decision` field (`yes` / `no` / `left`), and a change to a
  guard setting lands in the log as a `config` event. Old lines without
  these fields have their decision read from the outcome and their tier
  from the tier matrix (a run that went ahead is a notice at medium, an
  ask at high, a gate at critical), so nothing in the old log is guessed
  at. `--json` carries the same numbers. An empty
  window says so in one line, exit 0.

- **The package-docs scan reaches PyPI and crates.io** (#55). The static
  read now reads each installed PyPI distribution's `.dist-info/METADATA`
  (its `Summary` header and the body, which is the README the wheel
  shipped with) and each vendored or packaged crate's `Cargo.toml`
  `description` and `README*`, the way it already reads an npm package's
  README and `package.json` description. Only the prompt-injection rules
  run on these (`E886`, `E887`): a README that quotes `curl | sh` as an
  install example is not a fetch-and-run. Nothing is fetched: the scan
  reads what `pip install` already extracted into `.venv/` or `venv/`,
  and what `cargo vendor` or `cargo package` already wrote under
  `vendor/` or `target/package/`. A package whose install has not
  produced bytes on disk is silent.

- **Scrubbing what an agent reads** (#63 step 1). At level 4 every shell
  command an agent runs goes through `cigo agent run`, and what it prints
  is now scrubbed before the agent sees it: invisible Unicode and
  look-alike letters are stripped (`E887`), a chat-template shape is
  fenced in place so the agent can see what was faked (`E886`), a line
  addressed to AI agents is redacted with a marker that names a short
  local id, and a line that is also reaching for your credentials, an
  exfiltration host, a fetch-and-run or the guard's own state is withheld
  whole. A one-line notice in front of the output counts what was done
  and names the id, so the agent does not guess at missing text. The
  originals are sealed in the tin under the label `cigo-scrub` (`cig tin
  keep`), not left in the clear: the box an agent's commands run in has
  no key, so nothing there can open them. `cigo scrub show <id>`
  reads one at your terminal; from an agent's session it is refused as
  well, which stops an agent that asks, not one that clears its
  environment where there is no box. The PreToolUse hook (Claude Code's
  Write, Edit, MultiEdit and NotebookEdit) puts the original passages
  back in place of the markers before the write lands, in the new text
  and in the text an edit looks for, so an agent that read a scrubbed
  copy and writes it back does not overwrite a real file with cigo's
  mark; the agent's real edits are kept. A marker from one of this
  machine's runs with no passage to put back (the tin could not keep it,
  or no longer holds it) is refused, and nothing is written; a marker
  from anywhere else is left as text. A plain `cigo run` or `cigo
  audit` is not touched, and the shim's pass-through and `cigo update`'s
  installer output still use the warning-first fence until later steps
  of #63 extend scrubbing there. The codes stay `E886` and `E887` that
  the static read already uses.

- **`cigo trust show` says when an approval's signature is gone.** It
  stopped with an error (`E600`) when the `.mac` beside an approval was
  missing; it now says there is no signature, so the approval is not
  used, and how to approve it again.

## 1.16.0 — 2026-11-08

The guard reads more and asks better: ransomware's shape, typosquats,
what you downloaded, PowerShell and fish, the tier matrix, the blacklist
you can override; rehearsals of local packages; OS authentication that
only the system can answer.

- **OS authentication only the system can answer** (#62). `os_auth` runs
  `pkexec` (`/usr/bin/pkexec`, then `/bin/pkexec`) and, on macOS,
  `/usr/bin/osascript` by their full paths, never through PATH, and hands
  pkexec `/usr/bin/true` (else `/bin/true`) to run: pkexec finds a bare
  name through PATH and runs it as root once you approve. A fake `pkexec`
  or `true` earlier on PATH can no longer stand in for your password. No
  environment variable, file or flag stands in for it either.
- **`scripts/bench.cig`** (#88, #90) times cigo's commands here, through
  `bin/cigo` with a scratch home, beside #90's targets: a dev script, which
  reports and never gates.

- **The tier matrix as data, and remembered answers** (#66 step 2). The
  guard reads the tier at which a finding reaches the user (silent,
  notice, ask, gate) from one table of risk × confidence, replacing the
  hard-coded conditionals at the E580 (blacklist) and E894 (agent command,
  file tool) paths with one lookup. Confidence is exact for a blacklist
  hit (the user named it, the two-warnings gate flow), high for a heavy
  pattern or an OSV known-bad package, medium or low for lighter
  patterns; the default matrix keeps today's behaviour
  everywhere (blacklist critical goes through the two-warnings flow when
  `blacklist_unboxed = ask`, a pattern critical refuses outright, high
  asks, medium notices, low is silent). `cigo guard tier` prints the whole
  table; `cigo guard tier <risk> [<confidence>]` prints one row or one
  cell as a bare word, so paths that decide whether to ask read the cell
  rather than branch on the risk alone. Alongside the matrix, a
  remembered-answers store keeps a yes to an ask keyed by the sha256 of
  the bytes the question was about, signed with the tin's key under its
  own label (`cigo-remembered`): a later ask for the same bytes reads
  here first and does not prompt. One byte of a difference is a different
  key, so a changed command is asked again; a record that does not verify
  under this machine's key is said (`E889`) and ignored. `cigo approve`
  stays one-shot; the remembered store is for scopes wider than one run.
- **Overrides, bundles and the two warnings** (#62 steps 1 and 3). The
  blacklist takes a per-user override on top of the lists: `cigo blacklist
  allow <entry> --reason=...` asks for OS authentication so a script cannot
  whitelist its own payload, and records who, when and why. The entry stays
  on the list and `cigo blacklist why <thing>` names the override next to
  it; `cigo blacklist unallow <entry>` takes it back (also
  OS-authenticated). Overrides live in `blacklist.d/allows.jsonl`, signed
  with the tin's key under a separate label so a tampered allows file
  never stands in for a blacklist file, and a file that does not verify is
  said (`E587`) and ignored. `cigo blacklist export <file>` writes your
  own entries and overrides as one signed JSON bundle, and `cigo blacklist
  import <file>` is OS-authenticated and refuses any bundle whose
  signature does not verify. Running a blacklisted task goes through two
  warnings: `cigo run <task>` prints `E580` and refuses, then
  `--run-untrusted=<task>` prints `E581` and refuses, then `--light-it`
  takes OS authentication; with `blacklist_unboxed = ask` and `--no-box`,
  a second OS authentication and the run goes outside the box (`E583`,
  the box is CigScript#106 and is not built yet). The approval is kept
  for `blacklist_exception_ttl` (default 24h) so a re-run in that window
  does not ask again (`E582`); agents and CI never approve a blacklisted
  run (`E895`). Two new settings, `blacklist_unboxed` and
  `blacklist_exception_ttl`, govern the flow, and `cigo blacklist
  exceptions` lists what is in force.
- **The ransomware shape** (#55, `E876`). The rehearsal's footprint reader
  rates a task critical when it sees many files renamed to one ransomware-
  tagged extension (`.locked`, `.encrypted`, `.enc` and the rest), or a
  ransom-note-shaped file dropped in three or more directories; the
  thresholds are named constants (`RANSOM_EXT_FLOOR`, `RANSOM_NOTE_DIRS_FLOOR`)
  and the finding reads with the rest of a rehearsal's behavior evidence.
  A labelled attack sample (`m27`) and a benign twin (`b30`: a formatter
  rewriting many files without renaming) joined the detection corpus.
- **The package-docs scan** (#55). The rehearsal's static read now reads each
  installed npm package's README and its `package.json` `description` for
  prompt-injection rules only (`E886`, `E887`): a README that quotes
  `curl | sh` as an install example is not a fetch-and-run.
- **Shim and update output fenced for an agent** (#55). The shim's
  pass-through (`cigo guard exec`) and `cigo update`'s installer output are
  fenced the same way as `cigo agent run`: when an agent variable is set,
  output that reads as instructions to an AI (`E886`, `E887`) is captured,
  marked and then shown, instead of streamed straight through.
- **Local inputs for `cigo rehearse`** (#56). A `.tgz`, `.tar.gz`, `.whl` or
  `.crate` on disk is rehearsed the same way the registry form of its
  ecosystem is: installed with the ecosystem's own tool against the local
  path, used once (or not, with `--no-use`). A folder is rehearsed by its
  manifest (`package.json` as npm, `pyproject.toml` or `setup.py` as PyPI,
  `Cargo.toml` as crates.io). A `git+https://…` URL is cloned into the
  scratch (never into your tree) and rehearsed as a folder, with
  `git+https://…#ref` taking that ref. The verdict is kept against the
  sha256 of the local file, the sha256 of a folder's content, or the
  commit at HEAD for a clone.
- **Setup shares kept verdicts** (#56). A clean rehearsal of a setup task
  keeps a verdict for each package the project's lockfiles name, under the
  same key `cigo rehearse` reads: npm and crates.io by version with the
  lockfile's integrity, PyPI by version with its hash. The next
  `cigo rehearse npm:name@1.2.3` of the same bytes answers from the kept
  verdict without the box.
Four more codes the guard reads before a lockfile is touched.

- **`E881` typosquats** (#55, #56). Every name a task's lockfiles hold
  is compared against a bundled list of popular package names for its
  ecosystem (npm, PyPI, crates.io), composed from each registry's own
  download-count rankings. A name within an edit distance of one or two
  of a popular one is reported medium with the popular name in the
  finding (`reqeusts` → one letter from `requests`). Short names
  (three characters or fewer) are left alone. PyPI's dash/underscore/dot
  equivalence and npm's scope prefix are normalised before the compare.
- **`E882` a recently published version**, medium (#55, #56). The
  ecosystem's own registry is asked for each name in the lockfiles
  and the version's publish date is read; one published inside
  `metadata_young_days` (default 7) is reported.
- **`E883` a new install script**, high (#55, #56). For npm, this
  version's `preinstall`/`install`/`postinstall` is compared to the
  version published just before it; a script that version did not run is
  the finding ("2.4.0 ran no install script; 2.4.1 adds one").
- **`E884` no linked source repository**, low (#55, #56). When the
  registry entry has no `repository` link (npm), no `project_urls` or
  `home_page` that points at a repository (PyPI), or no `repository`
  (crates.io), the package is reported: what is on the registry cannot
  be read against source.
- **`registry_meta`** (`off`, the default, or `online`; a floor; the
  paranoid preset sets `online`). Off, the guard makes no request of its
  own and `E882` to `E884` are not read; the typosquat check needs no
  network and always runs. Online, each name is asked once and the answer
  kept a day under
  `~/.cig-orchestrator/registry`. Only the name is sent, never a path
  or a project's own name. A test points `CIGO_REGISTRY_NPM`,
  `CIGO_REGISTRY_PYPI` and `CIGO_REGISTRY_CRATES` at a `file://`
  directory of fixture responses, the way the OSV online test does
  with `CIGO_OSV_API`.
- **`metadata_young_days`** (default `7`). The E882 window in days; `0`
  turns it off without touching the other two.
The guard reaches fish and PowerShell; level 3 catches the first run of a
downloaded file.

- **The Enter-key hook for PowerShell** (#57). At `guard_scope dev` the
  `CurrentUserAllHosts` profile (`~/.config/powershell/Microsoft.PowerShell_profile.ps1`
  on Linux and macOS, `Documents/PowerShell/` on Windows) gets a cigo
  block between `# >>> cigo guard >>>` and `# <<< cigo guard <<<`. The
  block puts `~/.cig-orchestrator/shims` first on `$env:PATH` and
  dot-sources `~/.cig-orchestrator/guard/hook.ps1`, which binds Enter
  through PSReadLine: a line that pipes a download into a shell is
  cancelled with `E892` and the rehearsed way is said. `cigo guard
  uninstall` removes it, and an empty profile cigo wrote into goes with
  it. `guard_shells` takes `powershell`.
- **The Enter-key hook for fish** (#57). Where fish 3 is here (or its
  `~/.config/fish` is), a `conf.d/cigo-guard.fish` block does the same,
  sourcing `~/.cig-orchestrator/guard/hook.fish`. The hook binds `\r`
  and `\n` to a `commandline`-driven check that cancels a `curl | sh`
  line before it executes. `guard_shells` takes `fish`.
- **Level 3: anything you downloaded, on Linux** (#57 step 3, `E893`).
  A file the browser marked with `user.xdg.origin.url`, or any file
  under `~/Downloads`, is rehearsed first when a shell is about to run
  it. The bash, zsh, fish and PowerShell hooks all check this at Enter,
  behind a `~/.cig-orchestrator/guard/level3` marker. `getfattr` reads
  the mark when it is here; otherwise a small Python helper at
  `~/.cig-orchestrator/guard/xattr.py` does. Where the filesystem does
  not carry xattrs, the check steps aside without a sound.
- **Shims for `tar`, `unzip` and `7z`** (#57 step 3). Each is a plain
  `sh` script beside the package-manager shims at level 3 and up. On a
  clean extraction, if the archive had the mark (or lives under
  `~/Downloads`), the shim walks the destination and sets
  `user.cig.downloaded` on every file the real program created or
  replaced; `setfattr` is used when it is here, Python otherwise. The
  real program's exit code is kept, and the shim exits at once inside
  a guarded call (`CIGO_GUARDED=1`).
- **`cigo guard scope downloads`** is built. It pulls in the level-2
  package-manager shims, the shell hooks for every `guard_shells` the
  machine has, the archive shims and the xattr helper; `cigo guard
  uninstall` removes them all. Level 5 remains the one "not built yet".
- Needs cig 1.14.0.



## 1.15.0 — 2026-11-08

What run-url kept, and what an update adds.

- **`cigo quarantine`** (#56). run-url keeps each download under its
  sha256, as before, and now writes the URL it came from beside it.
  `cigo quarantine` lists them newest first: the sha256, size, when, and
  where from. `cigo quarantine show <sha256>` (a prefix is enough) reads
  one again against the rules and your blacklist and runs nothing: the
  verdict, each finding, and the command that rehearses it first.
  `cigo quarantine clear` removes what is older than the new
  `quarantine_keep_days` setting (30; 0 keeps everything), and `--all`
  removes everything. Each takes `--json`.
- **`cigo rehearse <spec> --against=<version>`** (#56) rehearses the same
  package at that version too (npm and crates by `@`, PyPI by `==`), or a
  script against another script, and shows and rates only what is new: a
  finding the baseline did not have, and in `--json` the new writes
  outside the footprint and the new hosts refused. The exit code is the
  new behavior's risk, by `--fail-on`, so a CI line can fail on only what
  an update adds. Kept verdicts serve either side, and a baseline that
  could not be judged makes everything count as new, which it says.

## 1.14.0 — 2026-11-08

The guard reads three more tricks, a rehearsal uses what it installs, and
the agent hook starts quicker.

- **Commands spelled in escapes** (#89, m21). `$(printf '\x63\x75\x72\x6c')`,
  `$(echo -e '…')` and `$'…'` are decoded where they stand, and the line is
  read as shell: a command written in escapes reads as what it spells.
- **Commands a script hands to a shell** (#89, m10). The command a
  JavaScript or Python script passes to `child_process`'s `exec` and
  `spawn`, `subprocess` or `os.system` is built the way the program builds
  it (pieces joined; templates, f-strings and string constants filled in)
  and read as shell.
- **A secret on its way out** (#89, m19). A secret from the environment
  (`process.env.NPM_TOKEN`, `os.environ[…]`, `os.getenv(…)`) or a
  credentials file (`~/.npmrc`, `~/.pypirc`, `~/.netrc`) that reaches a
  network call is critical, unless it goes only to its own service
  (`GITHUB_TOKEN` to github.com).
- **The detection corpus** (#88). 52 labelled samples from #88, two attack
  variants and five benign twins, each rated in CI exactly as its label
  says: a lost detection fails, and so does an improvement until its label
  is raised. No benign task may be flagged, and every address an attack
  names is a documentation range or `.invalid`. Today: 22 of 26 attacks
  critical, 25 at high or above, 0 of 29 benign flagged.
- **A rehearsal uses what it installs** (#56). PyPI imports the package's
  top-level modules after installing it, and a crate is linked into a
  scratch program that runs, as npm's was required: much malware waits for
  the first import. `--no-use` installs only, and its verdict is kept apart.
- **`cigo doctor` says what a rehearsal can use here** (#56): the box, Docker
  or Podman, each registry's tool or where to get it, and what is kept.
- **The agent hook starts without the check** (#90). The hook and the
  `cigo agent run` it wraps each command in run with `--no-check`, saving
  about 5 ms at each of the two starts per command an agent runs. A hook
  installed by an earlier cigo keeps working; `cigo guard scope agents
  --agents=claude-code` writes the new one. `docs/how-it-works.md` says
  where a start goes.

## 1.13.1 — 2026-11-07

- **cig 1.16.1 or newer.** Its box makes the forwarder's listener before
  the hop starts. With an older cig, an agent's command that connected at
  once could find no forwarder yet, fail to connect, and go on instead of
  waiting for a person to approve the host (the connection was never
  made). 1.16.0 also records a refused connection before it answers it.
  The native cigo in CI is built by cigcompile 0.1.2 onto cig 1.16.1.

## 1.13.0 — 2026-11-07

The guard reads more, and fails what you tell it to; cigo needs cig 1.15.1.

- **cig 1.15.1 or newer.** It fixes two hops over one file rolling back,
  and a compiled cigo refuses rather than run as `cig` when it is damaged,
  unreadable or started with raised rights. The native cigo in CI is now
  built by cigcompile 0.1.0's own release (`ci/compile-native.py` is gone).
- **`cigo rehearse <name>`** (#56): a bare package name is rehearsed in the
  registry this project's toolchains use (npm for node, PyPI for Python,
  crates.io for Rust), and said so. A project that uses two names both, and
  you say which.
- **The read closes most of the corpus's gaps** (#89). Now critical:
  - the environment, or a secret from it, sent to the network;
  - a browser profile or keychain piped into `nc`;
  - a reverse shell (`/dev/tcp`, `sh -i` on a socket);
  - a set-id copy of a shell;
  - a program downloaded, marked executable and run from a raw address;
  - Python or JS that runs code it fetched.

  Fetch-and-run over plain `http://` is high whatever the host, and so is a
  set-id file. A public key (`~/.ssh/*.pub`), `known_hosts` and the ssh
  `config` are no longer credentials; private keys and the folder still are.
- **The read catches a script that checks whether it is watched** (#55,
  `E888`): one that looks for a container or a virtual machine
  (`/proc/1/cgroup`, `/.dockerenv`, `systemd-detect-virt`, the DMI product
  name), and one that waits half a minute or more before it goes on.
- **More prompt injection is read** (#55): chat templates and tool-call tags
  written into text (`<|start_header_id|>`, `<tool_call>`), a Markdown image
  whose address carries data out when an agent shows it (`E886`), and a
  word that mixes Latin with look-alike Cyrillic or Greek letters (`E887`).
- **Every code the read gives has a test**: the wiper (`E877`), the set-id
  `chmod` (`E878`) and a rehearsal's write outside the footprint (`E880`)
  had none.
- **`cigo rehearse --fail-on=<level>`** (#56): the lowest verdict that fails
  the run. The exit code still says the risk (`1` medium, `2` high, `3`
  critical) once the verdict reaches it, and is `0` below it. The setting is
  `rehearse_fail_on`: `auto` by default, which is `high` under CI and
  `critical` at a terminal; the `ci` preset says `high`, `paranoid` says
  `medium`, and a project may only raise it. A medium verdict no longer
  fails CI by default, as `security = strict` never failed it either.
- **`guard_shells`** (#57): the shells whose startup files get the guard's
  block at level 2 and up (`bash`, `zsh`, `sh` for `~/.profile`, `fish`).
  Empty, the default, is every shell found; a shell it leaves out loses its
  block at the next `cigo guard scope … --yes`, and a named shell with no
  startup file gets its usual one.
- **`cigo guard allow <file|sha256>`** (#57): a script you have read, by
  its bytes. `cigo run-url` (and the `curl | sh` hook) runs those exact
  bytes without a rehearsal, whatever cigo's version. The allowance is
  signed with the tin's key, so nothing a script runs can allow itself; an
  unsigned one is ignored, and said.
- **CigScript's repository is otmof-ops/cig-script** now, named like the rest
  of the cig family. The launchers' and installers' "install CigScript first"
  messages, the knowledge base's install link, the SARIF rules' help links,
  CI and the docs name it; the old name still redirects.

## 1.12.0 — 2026-11-07

The holes found testing 1.11.0 (#80), closed.

- **An agent cannot switch off its own guard.** `cigo agent run` runs the
  agent's command in cig's contained box: what it changes in the project
  comes back with undo, and what it writes in your home is judged by where
  it landed. The guard's own files (Claude Code's settings, cigscript's
  config and blacklists, cig's state and the tin, cigo's folder and shims,
  cig's and cigo's install folders) are refused and never applied (`E897`),
  as is a command the static read sees going for them however it is
  spelled; a startup file, a git hook, an autostart entry or a credential
  file waits for a person (`E894`), and lands when the same command runs
  again after the approval; anything else in your home is applied by name
  and said after the output (cig 1.14.0's `apply_layer` home globs). Called
  from your home folder itself, it is boxed the same.
- **The agent's box has the task's network:** the registries the
  toolchains' footprints name and the project's own git remotes; a host
  outside them is refused, and a person approves the command with the
  hosts named.
- **One rating for a raw address:** a fetch-and-run from a raw address
  (IPv4, IPv6, decimal and hex forms) is critical everywhere it is read.
- **A quiet stealer is not called clean.** A script is read with the files
  it runs from its own folder, and the read joins what a JavaScript file
  builds at run time (char codes, joined pieces, arrays of literals); a
  rehearsal that finds nothing says it could not see reads or connections
  (`E898`), rates low and keeps nothing; a failed install could not judge,
  exits 1 and keeps nothing.
- **The blacklist survives being deleted.** The last list that verified is
  kept in the tin (`cig tin keep`), for the folder it was kept from; with
  the list and its signature gone,
  every entry still counts, said each time (`E588`), until `cigo blacklist
  reload` puts it back. A missing or emptied list never takes entries out.
- **Claude Code's file tools go through the hook too:** Write, Edit,
  MultiEdit and NotebookEdit are judged by the path they write and the text
  they put there; an older entry is brought up to date in place, and a hook
  taken out of the settings file is noticed on every guarded call (`E897`).
- Read-only commands (`cigo blacklist why`, a kept verdict) print no burn
  line (cig 1.14.0's `reads`), and a rehearsal shows the last line it
  printed.
- Needs cig 1.14.0.

## 1.11.1 — 2026-11-06

- **Called from your home folder itself, cigo no longer makes it the
  run's pack.** cig watches every file in a run's pack around each step,
  so `cigo update`, `cigo config` or `cigo guard` run from `~` scanned the
  whole home before and after every step (seconds each, and a Wine
  prefix's link to `/` turned the system's own writes into hundreds of
  false `E752` warnings, fixed in cig 1.13.2). From the home folder itself
  (or `/`) the launchers now run cigo from an empty folder of its own
  (`~/.cig-orchestrator/here`). A guarded call, an agent's command and
  `cigo run-url` still run where they were made, without the box and
  without an undo there, and say so; what they write there is named.

## 1.11.0 — 2026-11-06

What your AI agents run (#57 step 4).

- **`cigo agent run -- <command>`**: an agent's shell command read first
  (the rules, your blacklist), run in cig's box over the project with an
  undo, and recorded as a run tagged with the agent and its session. None
  and low run; medium runs and the agent is told why; high waits for a
  person (`E894`); critical is refused. Output that speaks to agents, or
  hides invisible Unicode, gets a warning first (`E886`, `E887`).
- **`cigo approve <id>`**: a person approves one high command, once,
  through the operating system's own password prompt (`agent_approval =
  os-auth`; `tty` and `never` too), signed with the tin's key. From inside
  an agent's session it is refused and logged (`E895`).
- **`cigo agent log`** and **`cigo agent undo --session/--agent/--since`**:
  what an agent ran, and all of it taken back, newest first.
- **Level 4, `cigo guard scope agents --agents=claude-code`**: Claude Code's
  `PreToolUse` hook for its Bash tool (`cigo agent hook claude-code`),
  added to `~/.claude/settings.json` with the rest of the file kept, and
  taken out by `cigo guard uninstall`. A settings file that is a link is
  left to you, with the entry to add. Claude Code checks its permission
  rules against the rewritten command, so allow and deny rules written for
  plain commands no longer match it; the plan says so before anything is
  written.
- The static read's destructive-`rm` rule also catches `rm -rf ~/`, `rm -rf
  /*`, `rm -rf "$HOME"` and `rm -rf -- /`.

## 1.10.0 — 2026-11-06

How much of the machine the guard covers (#57 steps 1, 2 and 3).

- **`guard_scope`**, one setting for how much of this machine goes through
  the guard: level 1 (`project`, just cigo runs, the default) or level 2
  (`dev`: also every package manager and its scripts, in any folder).
  Levels 3 to 5 (downloads, agents, the whole machine) are named and not
  built yet. It is this machine's setting: a project's `settings` cannot
  set it, and `cigo check` says so.
- **`cigo guard`** shows the level, what is installed for it and the last
  guarded calls; `setup` asks the question, `scope <1-5>` shows what it
  would change and `--yes` changes it, `pause [30m]`, `off` and `on`,
  `allow <program>`, `log`, and `uninstall`, which takes out every shim and
  startup-file block it wrote, leaving the files as they were. `cigo undo
  last` undoes the newest guarded call. `cigo doctor` gains a guard block.
  The installer prints the question once; `cigo update` does not.
- **Level 2 is shims**, one small `sh` script per package manager first on
  `PATH` (npm, npx, pnpm, yarn, bun, bunx, pip, pip3, pipx, uv, uvx,
  poetry, cargo, go, gem, bundle, composer, dotnet, deno). A call that
  cannot run anyone else's code (`npm test`) runs the real program at once,
  without starting cig, in about a millisecond. A call that can (`npm
  install`, `npx`, `pip install`, `cargo build`, `go install`...) is a task
  made on the spot in the folder it was called from: your blacklist and
  OSV for what it names, the static read, then on Linux the rehearsal in
  cig's contained box, its output shown as it runs. What it wrote in the
  folder is applied as it was, and `cigo undo last` takes it out again; an
  install into your home goes in for real after a clean rehearsal. Held at
  medium or high (`CIGO_ACCEPT_RISK=1` runs it once), refused as critical,
  with nothing of it applied. Paused or off, the shims say so (`E896`) on
  every guarded call. Windows gets its shims later.
- **`curl | sh` at the prompt** (level 2): an interactive bash (4 or later)
  or zsh gets a hook on the Enter key that cancels a line piping a download
  into a shell or an interpreter, keeps it in the history to edit, and says
  the rehearsed way (`E892`). It binds Enter through readline or zle, so it
  sets no trap and no other command runs any differently.
- **`cigo run-url <url>`**, the rehearsed way: downloaded into cigo's
  quarantine, your blacklist checked before anything is fetched and on the
  bytes after, read against the rules, rehearsed in the contained box with
  the URL's own host as its only network, then run for real over the folder
  you are in. The same bytes are never rehearsed twice; `--trust` runs them
  without the rehearsal.
- **The rehearsal says what its layer means itself.** cigo's rehearsals,
  `cigo rehearse` and the contained-box probe ask cig for a quiet box
  (cig 1.13.0), so cig no longer tells you to `cig box apply` a layer cigo
  discards right after, and the probe's line is gone.
- Needs cig 1.13.0 (a hop's output shown as it runs, and the quiet box).

## 1.9.0 — 2026-11-05

Never the same bytes twice (#56 step 4).

- **A rehearsal's verdict is kept** under what was rehearsed: an npm or
  crates.io package at an exact version, with the lockfile's hash when
  `rehearse --changed` knows it (npm's `integrity`, Cargo's `checksum`); a
  PyPI package only with that hash, since a release can gain files after it
  is published; a script by its sha256. Asked again about the same bytes,
  `cigo rehearse` and `--changed` answer from the kept verdict, without the
  box, and say when it was rehearsed.
- **Signed with the tin's key**, like approvals: a kept verdict edited to
  read clean does not verify, is said, and the package is rehearsed again.
  A new cigo version judges again; `--fresh` rehearses anyway. A failed
  install is never kept.

## 1.8.0 — 2026-11-05

Your own blacklist (#62 step 1).

- **`cigo blacklist add`** takes a package (one version, or every version:
  npm, PyPI, crates.io, Go, RubyGems, Composer, Maven, NuGet), a file by its
  sha256, a domain and its subdomains, an IPv4 range or a URL pattern, each
  with `--reason` and `--expires`. `list`, `remove`, `why` and `reload` keep
  it.
- **Refused wherever the guard reads** (`E580`, critical): a task whose
  lockfiles pin it, whose scripts hash to it, or whose text holds a URL it
  matches; `cigo rehearse` of it is refused before the box is asked for, and
  `rehearse --changed` reports it without rehearsing it. SARIF and Markdown
  place it like any finding.
- **Signed, so a script cannot quietly take an entry out.** The list is
  signed with the tin's key under cigo's own label; a list changed by
  anything but `cigo blacklist` is said (`E587`) and counts together with
  the last copy that verified, until `cigo blacklist reload` (at a terminal,
  never under CI) shows the change and signs it.
- **`cigo update`** says when the build attestation was not checked because
  this gh has no `gh attestation` (2.49 or later does), instead of
  suggesting `gh auth login`.
- Needs cig 1.12.3 for `cig explain E580` and `E587`; runs on 1.12.0.

## 1.7.0 — 2026-11-05

The guard's findings where a team reads them (#56 step 6).

- **`cigo audit --sarif`** writes the read of every task as a SARIF 2.1.0
  log for GitHub code scanning: a result per finding at its line in the
  project (a task's own command at its line in the manifest, a script at
  its line, an npm install hook at the line that declares it, a known-bad
  package at its entry in the lockfile), and a rule per code with the
  registry's title and a severity GitHub ranks by.
- **`cigo audit --markdown`** writes the same as one table for a pull
  request comment, the heaviest finding first.
- **`cigo rehearse --changed [--base=<rev>]`** rehearses every package a
  change adds or moves to a new version in its lockfiles, against the base
  (the default branch when none is named), committed or not; npm, PyPI and
  crates.io packages one by one in the box, each finding blamed on its
  package and placed at its entry in the lockfile. `--list` names them and
  rehearses nothing; `--max` (50) caps a lockfile refresh; `--sarif`,
  `--markdown` and `--json` as for audit; the exit code is the worst risk.
- **cigo in CI** gains the code-scanning job: audit and rehearse as SARIF,
  uploaded to the pull request's Security tab.
- A lockfile with thousands of packages is read in linear time (two lists
  that were searched once per package are maps now).
- The one hop that asks whether cig can make a contained box no longer
  leaves cig's note about a held layer (`E780`) behind it.

## 1.6.0 — 2026-11-05

Known-bad packages (#55 step 3): what a task's lockfiles pin is checked
against [OSV](https://osv.dev) with the rest of the guard's read.

- **A malicious package is refused** before anything is installed: a `MAL-`
  advisory, or one whose weakness is embedded malicious code (CWE-506,
  CWE-912), is `E870`, critical.
- **A known vulnerability is reported**, one line per package (`E885`): the
  worst severity, the advisories, and the version that fixes all of them
  when OSV names one ("fixed in 1.2.6"). It holds nothing.
- **Sixteen lockfile formats** are read at the versions they pin: npm,
  pnpm, yarn, bun, uv, Poetry, PDM, Pipfile, a pinned `requirements.txt`,
  Cargo, Go, Bundler, Composer, Gradle and NuGet.
- **`osv`**, a floored setting: `online` (the default) sends one batch per
  run that needs it, with each package's ecosystem, name and version and
  nothing else, and keeps the answers (a day when they name advisories, an
  hour when clean); `offline` reads the database `cigo audit --update-db
  [<ecosystem>...]` builds from OSV's own dumps, ranges included, and
  nothing leaves the machine; `off` does not look. A project cannot loosen
  it. OSV out of reach is said once, and the run goes on with the rest of
  the guard.
- **`cigo audit --offline`** reads the local database for one audit,
  whatever the setting.
- The suite never asks the real OSV: its tests serve OSV's answers and a
  dump from fixtures, and check what would have been sent.
- **`cigo update` no longer warns about its own download.** Unpacking the
  release started in cigo's update folder, which cig then watched as a place
  outside the project, so every update said the unpacked files were writes
  "the kernel cannot undo" (`E752`). It starts in the project now, like
  cigo's other writes to its own folder.

## 1.5.0 — 2026-11-05

The static read, harder to fool (#69). It is the cheap first layer that
runs on every task and decides what the rehearsal looks at, so `none`
should mean none.

- **Split strings are joined.** Shell text (the task's own, the shell
  scripts it names, npm install hooks) is read as written and as the shell
  would join it: the simple assignments made earlier in the same text folded
  in, the quotes that join pieces taken out. `"$HOME/.s""sh"`, `'.a''ws'`
  and `${HOME}/.git-cred""entials` read as the paths they are, and a host
  built from parts reads as its address.
- **Hosts the read cannot see count.** A network command whose host is
  still a variable is a finding (`E872`, low), an upload of a local file to
  one is medium, and a hidden folder from the home packed up before a network
  command is high.
- **Encoded payloads are decoded and read.** What a decoder is fed (base64,
  hex, `\x` escapes; `base64 -d`, `xxd -r`, `printf`, Python, Node,
  PowerShell) is decoded and read the same way, three levels deep, within a
  size cap and a budget per task; its findings name both places. Text work
  only: nothing runs.
- The examples and cigo's own tasks still read `none`.

## 1.4.0 — 2026-11-05

The rehearsal (#55 steps 6 and 7, #56 step 1): a stage that runs code you
did not write is run once, for real, in cig 1.12.0's contained box, and
judged by what it did. Needs cig 1.12.0.

- **Footprints as data.** Every toolchain stage that runs third-party code
  (every setup, and the builds that run their dependencies' build scripts,
  plugins or macros) has an expected footprint in the knowledge base: what
  it writes, reads, fetches and runs, from the tools' own documentation, 50
  toolchains and 170 stages, each marked with how sure it is. `cigo
  toolchains <name>` prints it; a task adds to it with `footprint`.
- **The rehearsal in `cigo run`.** `rehearse` (a floored setting: `auto`,
  `always` in the paranoid preset, `never` in the chill one): under `auto` a
  stage with a footprint, or one the static read flagged, runs in the box
  with `contain`, the registry network its footprint names (and the host a
  project's registry variable points at), and its footprint as `expect`.
  What it wrote within the footprint is applied as it is (no second run);
  what it did beyond it becomes findings (`E873` persistence, `E871` a
  credential file, `E878` a set-id file, `E880` outside the footprint, `E877`
  removals, `E872` refused hosts) weighed with the static read's, with the
  guard's friction; a clean rehearsal approves the task.
- **`cigo rehearse <package>`** (`npm:`, `pypi:`, `crates:`, or a script):
  installs it in a scratch project inside the box, applies nothing, and
  says what it did beyond the ecosystem's footprint; `--json`, `--keep`;
  exit `0`/`1`/`2`/`3` by risk.
- **Where the contained box cannot be had** (root, user namespaces turned
  off as in many containers and some CI runners, a kernel before 5.12), the
  rehearsal says so once and the guard reads instead: a task is never failed
  for want of the box. cigo asks with one hop that does nothing.
- **perl's setup fetches over HTTPS** (`cpanm --from https://www.cpan.org`):
  cpanm's default mirror is plain HTTP (CVE-2024-45321).
- **cig 1.12.0 or later** is the floor (`CIG_NEEDS`), and every place
  that checks it says so: the tool's `# cig` pin, both launchers, both
  installers, the README and the docs. They said 1.7.0, 1.7.1 or 1.3.1, and
  `install.sh` matched versions by pattern, so a cig 1.5 or 1.6 got past
  its 1.7.0. A test now holds them all to `CIG_NEEDS`.

## 1.3.0 — 2026-11-05

The guard, first half (#55 steps 1, 2 and 4): a task is read before it
runs, the verdict's friction matches the risk, and an approval is signed
with the tin's key.

- **The static read.** Before a task runs, its command as written, the
  scripts it names (shell, Python, JavaScript, Ruby, Perl, PowerShell; a
  CigScript file is left to cig) and, for a setup stage, the install hooks
  of the packages installed here (`node_modules/*/package.json` scripts,
  `setup.py`, `build.rs`) are read against the rules: patterns real attacks
  use, as data, each with its code (`E871`–`E887`, registered in cig 1.11.0
  so `cig explain` knows them), its category and its weight. Scored per
  category: acting on cig's or cigo's own state, or credentials with
  exfiltration, is critical; the heaviest finding sets the rest. Comment
  lines are skipped. `cigo audit [<task>...] [--json]` shows the read with
  nothing run.
- **The verdict and its friction.** `security` (a floored setting:
  `standard`; `strict` under CI; `report`; `off`): none and low run; medium
  and high are held at a terminal until approved (`cigo trust <task>`, or
  `--accept-risk` for one run, `--accept-risk=<task>` for high) and run with
  the report unattended (`strict` fails high there); critical is refused,
  and `--run-untrusted=<task>` runs it anyway at a terminal, saying that no
  backup of the tin was taken. One line of character for the top finding at
  a terminal, plain evidence under it, plain everywhere else. `--no-guard`
  skips the read for one run.
- **The trust store.** An approval is the task as it is: its command, the
  names of its environment, the scripts it names and its lockfiles, hashed
  into one key, kept under `~/.cig-orchestrator/trust/` and signed with
  `cig tin mac` under a subkey of the tin's key. An approved task costs one
  hash lookup; a changed byte is checked again; a record that does not
  verify is a forged approval (`E889`), ignored and said. `cigo trust
  [<task>|list|show <task>|revoke <task>|--all]`; `trust` (`on`, `off`) and
  per task `trust: "never"`. Below cig 1.11.0 the store cannot be signed,
  and every task is checked.
- **The manifest** gains `trust` and `footprint` (writes, reads, network,
  execs: what a task is known to do beyond its toolchain's), validated by
  `cigo check`; the footprint feeds the rehearsal, which lands next with
  OSV checks and the tin backup.

## 1.2.0 — 2026-11-05

The config model the security work rests on (#66, step 1): one way to
read every setting, a floor a project cannot dig under, and presets.

- **Layers.** A setting is read as built-in default < preset < the
  administrator's `/etc/cigscript/cigo.conf` < `~/.cig-orchestrator/config`
  < the project's `settings` in `cig-tasks.json` < `CIGO_<KEY>` in the
  environment, each later layer winning. `cigo config` shows every setting
  with where it was set; `--json` gives the layers whole.
- **The security floor.** A setting that matters for safety has its values
  on a scale from loosest to tightest, and a project may only move along it
  toward tighter: a cloned repository's `cig-tasks.json` cannot turn
  protection down. A looser project value is ignored and `cigo check` says
  so. The environment loosens a setting only at a terminal, never under CI,
  where the `ci` preset applies on its own.
- **Locks.** `key = value !locked` in the administrator's file is final for
  every later layer, and `cigo config` says who set it.
- **Presets.** `cigo config preset chill|balanced|strict|paranoid|ci|agent-heavy|research`
  sets the bundle every other setting starts from (`balanced` by default);
  a looser preset is chosen at a terminal, never from CI. `cigo config diff`
  shows what differs from the preset, and `cigo config explain <key>` what
  a setting does, its default, its scale, its presets and its floor.

The settings that exist today (`versions`, `install`, `crash_reports`,
`update_channel`, `issues_repo`) are the first on the model; each security
feature adds its own as it lands.

## 1.1.1 — 2026-10-29

Needs cig 1.7.1 (reports anonymised on every route, CigScript #103).

- **Nothing of the person's in `cigo report`.** The manifest's summary named
  the project, every component and every task, and a run's error named the
  failing task; a client's or a project's name reached a public issue. The
  summary is now shapes only: `<project>`, `c1`..., `t1`... for the names, a
  key kept only when the manifest's vocabulary has it (`<key>` otherwise), a
  toolchain only when cigo knows it (`<toolchain>` otherwise); and the task
  or project a run's error names in backticks gets the same placeholder in
  cig's bundle and in the report's title. cig 1.7.1 anonymises the rest of
  the bundle on its side: every path a placeholder, a hop its program and
  argument count, the command line the words cig knows. Test:
  `cigo report --send carries no name of the person's: not a folder, a
  file, a task or the project`.

## 1.1.0 — 2026-10-29

Needs cig 1.7.0 (`cig crash submit`, the ashtray).

- **cigo's reports go through cig** (CigScript #101, step 10). A bug inside
  `orchestrate.cig` is still saved under `~/.cig-orchestrator/crashes/` and
  the run still rolled back; from there the report is handed to cig's
  ashtray (`cig crash submit --origin cig-orchestrator --repo <issues_repo>`),
  so it gets every route (`gh`, a token with curl, a prefilled link), the
  queue that waits out a lost network, cig's redaction, one issue per bug
  with the live stats block, and cig's one consent setting: `cig config
  reports ask|always|never` says whether it goes. cigo's `crash_reports`
  keeps one word of its own: `never` keeps a report on this machine and
  never hands it over; `always` asks cig to send it in this process. `cigo
  crash send <id>` files one now, through cig.
- **`cigo report <run> [--send]`.** The run's bundle as cig makes it (plan,
  journal, diagnostic, doctor's diagnosis, redacted) with the manifest's
  shape beside it (component names and toolchains, task names and the keys
  each uses, never a value, a command or an argument), written under
  `~/.cig-orchestrator/reports/`; `--send` files it through cig as a report.
- cigo's own `test` task runs on the tin (`box: false`): the suite starts
  cigs of its own whose boxed hops could not be made inside a box, since
  overlayfs does not layer over an overlay. The manifest doc says so for
  any task of that shape.

## 1.0.0 — 2026-10-29

Needs cig 1.6.2 (the box, `touches_sealed`, the hash chain, the parcel; and
the debugging pass that made the box hold).

**What 1.0 means.** The manifest format (`cig-tasks.json`: the top level,
components, stage overrides, tasks and their keys, toolchains, templates),
the commands and their flags, the exit codes, the environment variables and
the state cigo keeps under `.cig-orchestrator/` are stable: a change that
would break a manifest or a script that drives `cigo` is a 2.0, and anything
added from here is additive and says so in this file. The knowledge base
(the toolchains and what each stage runs) keeps growing in minor versions;
a toolchain's command changing is a minor version with a note in
`TOOLCHAINS.md`. `cigo update` keeps installing every version, and `YANKED`
keeps listing the ones it must not.

- **Tasks run in cig's box on Linux.** Each task's hop is boxed: it writes
  into a copy-on-write layer over the project (overlayfs in a user
  namespace), which cig applies as journaled burns once the task has run,
  with the before-bytes of every file it changed, and drops when the task
  could not start or was killed. So a failing run puts back *everything* a
  task changed inside the project, whether or not `touches` named it, where
  0.5 restored only what `touches` covered and listed the rest as
  irreversible; and nothing of a task that never ran reaches the tree. The
  build and dependency trees (`target`, `node_modules`, `.venv`, `.git`...)
  pass through the box untouched, as they always passed the watch. A task's
  `box: false`, the manifest's `defaults.box`, `CIGO_BOX=0` or
  `cigo run --no-box` keep a task on the tin; `box: true`, `CIGO_BOX=1` or
  `--box` ask for the box where the default is off. On macOS and Windows the
  default is off, since cig has no box there yet; asked for, cig runs the
  task on the tin and says so (`E763`). `cigo show` says `box on` for a task
  that will run boxed.
- **`touches_sealed`** on a task: globs, as `touches`, of files whose
  before-bytes are kept sealed (encrypted at rest) in the tin and the run's
  record: a database with customer rows, a config holding a token. Files
  with secret-shaped names are sealed without being named, as cig always
  did since 1.5. `cigo show` lists them under `sealed`.
- **`cigo check`** refuses a `box` that is not `true` or `false` (on a task
  or in `defaults`) and a `touches_sealed` that is not a glob or a list of
  them, with the same words as for `touches`.
- The test suite's cig never touches the OS keyring (`CIG_SEAL_KEY=file` in
  its environment), and CI lets cig make its box on the Ubuntu runners
  (AppArmor restricts unprivileged user namespaces there by default).
- `TRADEMARKS.md`: what the names cig-orchestrator and cigo may be used for
  without asking, and what to ask about first.

## 0.5.1 — 2026-10-28

Needs cig 1.4.2 (a burn can carry a name; a `touches` glob may be optional).

- **A value in a `shell` line is checked at run time too** (#47). `cigo run`
  says before anything starts which values reach a `shell` or `undo_shell`
  line unquoted, as `cigo check` does; with `--strict`, or under CI (where
  values come from PR titles and commit messages), the run stops instead.
  And at the moment of substitution a value holding shell syntax (`;`, `|`,
  `&`, a backtick, `$(`, a newline, `<`, `>`) is refused unquoted, so a
  value that would run as shell never reaches the shell; `|sh` makes it one
  word.
- **A new project's first `setup` no longer warns that its `touches` match
  nothing** (#48). The built-in lists are a toolchain's guess at what might
  change (every lockfile kind, every source extension), so they are passed
  as optional globs (`?package-lock.json`), which cig 1.4.2 never counts as
  a typo; a task's own `touches` stay as written, and may use the `?` too.
- **A failed undo is named for its task by cig itself** (CigScript #80): the
  burn carries the task's name, so the report reads `deploy is NOT undone:
  its compensation failed: the undo … exited 7`, with no line of
  `orchestrate.cig` in front of it.

## 0.5.0 — 2026-10-28

Found by a debugging pass over 0.4.0 and an outside pass over 0.4.0 with cig
1.3.1; every fix has a test. Needs cig 1.4.0 (its rollback reports an op whose
compensation failed as not undone, and lets a cig a task starts share the
project's pack).

- **Tasks run on the pinned versions** (#31). When a language's installed
  version disagrees with the project's pin (.nvmrc, .python-version,
  rust-toolchain.toml, go.mod, .tool-versions, mise.toml...), cigo can run
  the task on the pinned one through a version manager already on the
  machine, per task, never by changing anyone's default: mise or asdf for
  whatever they manage; rustup, uv or pyenv, fnm or volta, rbenv, and Go's
  own GOTOOLCHAIN for one language each. The `versions` setting says what
  happens on a disagreement: `ask` (the default) prints the question and the
  two commands that answer it (`cigo versions switch`, `cigo versions keep`),
  since a script cannot wait at a prompt, and runs on the installed versions
  meanwhile; `always` switches and says so; `never` warns, as 0.4.0 did;
  `off` does not look. In CI, with nothing set, it is `never`. It is set by
  `--versions=`, the manifest's `versions`, or `cigo config versions`; the
  answer is remembered per project in `.cig-orchestrator/state/versions.json`
  and asked again when a pin changes. A version the manager lacks is
  installed, offered or left alone as `install` says (`ask` by default,
  since it downloads); `cigo versions install --yes` installs them all.
  `cigo versions` lists every pin against this machine, each run line and
  the run's record say which version a task ran on, `cigo doctor` names the
  manager, and `--strict` passes when the switch made the versions agree.
- **An unchanged project opens without a hop.** A tool's version is kept
  with its program's path, size and time, so `check`, `run` and `doctor` ask
  a tool only when it changed.
- **A captured value in a `shell` line is a check warning unless it is
  quoted with `|sh`** (#43), an error under `--strict`: pasted in as text, a
  value holding `;` runs as shell. `cmd` lists never reach a shell.
- **A task whose inputs cover more than 20,000 files says so** (#44): it
  always runs, and the run line, `cigo plan` and `cigo show` say why;
  `inputs_limit` on the task or in `defaults` raises the limit.
- **A failed undo is reported as not undone, by task name** (#45). The undo
  that failed names its task and quotes its stderr; the op it covered is
  listed as `not undone`, never `compensated`; the deploy is still out there
  and the line says so.
- **`each` as a plain list of globs works** (both arms of a `pick` ran, and a
  list has no `get("files")`); `cigo check` refuses a malformed `each`.
- **A value read in `cmds` or `rm` is a need**, and an unknown one is a
  check error, as it is in `cmd`.
- **A task whose exit code is outside `ok`** says `exited 0 (not in ok: 1)`,
  not that it printed output it must not.
- The `sh` launcher refuses a `--max-steps` that is not a number, instead of
  splitting its value into flags.

- **`cigo` at a PowerShell prompt is the cmd shim now** (#40, #42). The PowerShell
  launcher is installed as `cigo.launch.ps1`, a name PowerShell does not pick
  for `cigo`, so the shim runs first: the task's own `--` arrives whole
  (`cigo run deploy -- --tag v2` lost it before), stdin reaches the task, the
  session is not left in the project directory, and no execution policy
  stands in the way. `install.ps1` removes the `cigo.ps1` 0.4.0 installed.
- **`cigo update` from a PowerShell install puts back a PowerShell install** (#40, #41).
  It ran the release's `install.sh`, which wrote the `sh` launcher into
  `cigo.ps1`. It now runs `install.ps1` for a `.ps1` launcher and
  `install.sh` for the `sh` one, unpacks with `tar` itself (no shell between
  the steps), passes `CIGO_PREFIX` as well as `PREFIX` so a Termux prefix
  holds, and falls back to `curl` when `gh` is installed but not logged in.
  Without `sh` on PATH, the config file, crash reports and the update use
  PowerShell. A yanked list that cannot be read is said, not taken as empty.
- **`{py}` resolves when a Python project has neither `requirements.txt` nor
  a build system** (#37). Its fallback `{python}` was never filled, so the tasks
  ran the literal text. A var's value may name another var now.
- **`os:` takes a name cig reports, in any case** (#38). `os:darwin` or `os:macOS`
  matched no machine and silently dropped the stage; `cigo check` says so
  and names `macos`, and `os:LINUX` is `os:linux`.
- **`cigo doctor` counts a Python it cannot find** as a missing tool (exit
  1, with the install link), where it said `python unknown` and passed (#39).
- **Installers and launchers** (#40). A path with `[` or `]` is taken literally by
  `cigo.launch.ps1` and `install.ps1`; a relative prefix is made absolute
  before it is written into a launcher; the installed path travels as base64,
  so an apostrophe (the curly ones too) or a non-ASCII letter in it cannot
  break the launcher; the user `PATH` is written through the registry so
  `%VAR%` entries stay unexpanded, and the change is announced to the
  desktop; the checkout's `bin/cigo` follows a symlink to itself;
  `install.sh` refuses an empty cig version and a Windows launcher name;
  `--max-steps` without a number stops the PowerShell launcher as it does the
  `sh` one.
- **CI** (#42). The cmd shim and Windows PowerShell 5.1 run in the installers job,
  with a task that must keep its `--` arguments, and `cigo update` from a
  PowerShell install is proven there; a release waits for every job.

## 0.4.0 — 2026-10-27

- **A Windows launcher and installer.** `bin/cigo.ps1` for PowerShell and
  `bin/cigo.cmd` for cmd, with the same flag split, walk-up and cig check as
  the `sh` launcher; `install.ps1` installs them with the tool into
  `%LOCALAPPDATA%\cig-orchestrator` and adds its `bin` to the user PATH.
  A `.gitattributes` keeps scripts LF and the Windows files CRLF, so a
  Windows checkout runs under Git Bash and WSL. The release tarball ships
  all three. (#22)
- **Launcher and installer fixes.** `--max-steps` with no number is an
  error instead of an endless loop under `bash --posix`, and `--max-steps=N`
  is accepted; the walk-up stops when `dirname` stops changing (`//` on
  MSYS); `CDPATH` cannot corrupt the tool's path; Git Bash keeps a task's
  arguments as typed (`MSYS2_ARG_CONV_EXCL`); `install.sh` takes
  `CIGO_PREFIX` and honours `PREFIX` except under Termux, writes the
  launcher through `awk` so a quote, an ampersand or a bar in the path
  survives, prints the exact PATH line for your shell, and points at
  CigScript's install docs instead of a pinned command. (#23)

- **Programs and paths on every machine.** A program with a backslash in
  its name is a path for `check` too; a nested `cig.exe run` is seen as a
  nested cig run; globs are built with forward slashes; `file:` matches the
  exact name on every filesystem (so `file:Dockerfile` means the same thing
  on macOS as on Linux); `adopt --force` recognises an old component's path
  written with other separators or case; a task named `nul`, `con` or
  `com1` keeps its log and state under a safe name; `{{home}}` is the home
  directory where `HOME` is not set. Program lookup itself (`npm.cmd`, Git's
  bash, a relative program against the task's directory) comes from
  CigScript 1.3's resolver. (#21, #28)
- **Interpreters that exist here.** An absolute shebang this machine does
  not have falls back to the same program on `PATH`; a `.sh` without a
  shebang runs with `sh`; `.py` runs with `python3`, `python` or `py -3`,
  `.ps1` with `pwsh` or Windows PowerShell, whichever is installed; `.bat`
  and `.cmd` are adopted on Windows. (#26)
- **Encodings.** A byte-order mark in `cig-tasks.json`, a `.env` file or a
  script is not part of it; `$CIG_OUTPUT` written as UTF-16 is named as the
  reason nothing arrived; a task's output is read with bad bytes replaced
  unless the task sets `encoding` (`utf-8`, `utf-16`, `latin1`), so a
  Windows console code page never fails a task that exited 0; a `text`
  capture has no stray `\r`. (#27)

- **An `os:` condition, and commands for each OS.** `os:windows`, `os:macos`,
  `os:linux`, `os:bsd` and `os:unix` join the conditions (`cig.os()` behind
  them), and the knowledge base uses them: `gradlew.bat`, `mvnw.cmd` and
  `mill.bat` on Windows, the venv's `Scripts\python.exe`, `python` before
  `python3` where the latter is the Store's alias, `pwsh` or Windows
  PowerShell, `--config Debug` for CMake's multi-config generators, `gmake`
  for a GNU makefile on the BSDs, Xcode only on macOS, no Clojure CLI on
  Windows, `ruby bin/rails` and `php vendor/bin/...` everywhere. (#24)
- **No shell in the knowledge base.** Stages that were `sh -c` lines are
  `cmds` (commands in a row), `each` (one command per file), `rm` (a
  journaled removal, undone on rollback) or `when` alternatives, and vars
  can come from a `glob` or a `files` list, so `gem build *.gemspec`,
  `gofmt -l` over the tree and `clang-format` over the sources need no
  shell; `fail_on_output` makes a check that prints its findings fail. The
  manifest takes `cmds`, `each`, `rm` and `fail_on_output` too. One `sh`
  line remains, the shell toolchain's own lint on Unix, with a per-file
  `shellcheck` beside it for Windows. (#25)
- **The suite runs on Windows, and CI runs where cigo runs.** The tests
  join PATH with the platform's separator, compare paths with forward
  slashes, write `.cmd` stand-ins for the stub toolchain on Windows, and
  step aside where a program they need is missing; CI runs the suite on
  Ubuntu and macOS on both architectures, on Windows, and on Alpine with
  bash, against cig 1.3.1. (#29)
- **Docs say where cigo runs** and correct the claims that were Unix-only:
  `shell` lines run under `sh` on Windows too, a timeout ends the whole
  process tree everywhere, `|sh` is POSIX quoting, WSL projects belong in
  the Linux filesystem. (#30)
- **Windows fixes the suite found.** A `touches` glob that starts at `/` or
  a drive letter is refused on every OS, not only where it counts as
  absolute; a script whose shebang names a path the machine lacks falls
  back to the program on PATH on Windows too; an `each` skip list matches
  a folder in a path with backslashes; `cigo update` extracts the tarball
  by name, since GNU tar reads the `D:` of a Windows path as a host.

Needs cig 1.3.1: a program is found the same way on every OS (a `.cmd` task,
`sh -c` under Git for Windows), a timeout ends the whole tree on Windows, a
device name is refused before anything runs, and a finished run can be
unburned on Windows (1.3.0 read a directory's fingerprint from the listing
NTFS refreshes late); the suite on Windows relies on all four.

## 0.3.0 — 2026-10-27

Needs cig 1.2.1: the tin, the pin and `cig.version()` come with 1.2.0, and 1.2.1 snapshots a read-only file (a tin object) like any other, which the suite relies on.

- **Version checks on every command.** Every command that opens a project
  says, on stderr, where versions disagree: the installed cig against the
  range cigo supports and against the project's pins (`.cig-version`, the
  manifest's new `cig` key, the `# cig` header of each script a task hands
  to cig or a CigScript component holds), the cig on `PATH` against the one
  running cigo, and each toolchain's version against the pins the project
  keeps (`.nvmrc`, `go.mod`, `rust-toolchain.toml`...). `check` lists them
  as warnings, `doctor` prints every version side by side, and `--strict`
  on `run`, `check` and `doctor` stops on a disagreement. `CIGO_VERSIONS=0`
  keeps them quiet. (#18, step 11, and the versioning parity with CigScript)
- **The tin: what a task rewrites comes back.** A task's `touches` (a glob
  or a list, relative to its directory) names the files it may change; cig
  1.2 keeps them before the task runs and puts a modified or deleted one
  back on rollback, where it was listed as irreversible before. Format stages
  carry their language's source files and setup stages their lockfiles from
  the knowledge base, so an adopted project gets this without a line of
  config; a toolchain's `touches` map or a stage override sets its own.
  `cigo check` refuses an absolute or climbing glob; `cigo show` and `cigo
  plan` print them. (#18, step 11)
- **Crash reports, the same deal as cig's.** A runtime or type error inside
  `orchestrate.cig` is a bug in cigo: a report (versions, OS, the redacted
  command line, the error and its line, the run id; never your manifest,
  environment or files) is saved under `~/.cig-orchestrator/crashes/` by a
  hop outside the project, so the rollback that follows the crash leaves it
  in place, and nothing is sent unless you say so. `cigo crash
  list|show|send|delete`; `crash_reports`, `issues_repo` and
  `update_channel` in `~/.cig-orchestrator/config` through `cigo config`.
  `CIGO_INTERNAL_PANIC` raises one on purpose, for the suite.
- **Releases, and `cigo update`.** A tag `vX.Y.Z` builds
  `cig-orchestrator-vX.Y.Z.tar.gz`, its `.sha256` and a build attestation,
  with the licence beside them. `cigo update` installs the newest release the
  channel allows over the installed one, refusing a checksum that does not
  match and checking the attestation when `gh` is installed; `--check` only
  looks, `--to=X.Y.Z` names one. `cigo version --json` names this cigo, the
  cig it runs on, the range it supports and where it is installed.
- **The launcher checks cig first.** `cigo` refuses a cig older than 1.2.1
  with the version and the remedy, before the tool runs; `orchestrate.cig`
  carries `# cig >=1.2.1`, which cig 1.2 enforces on its own. `install.sh`
  says the same.
- **CI** installs cig 1.2.1 and installs cigo from the release tarball.

The changes below were on main before 0.3.0 and ship with it.

- **A `.cig` script runs as its own cig run and is now undone with it.** A
  task whose command is `cig run <file>` (how the `scripts` toolchain adopts
  a `.cig` file) gets `cig unburn <id>` as its undo, the id read from the
  hop's "burned … run <id>" line, so a later failure in this run or a `cig
  unburn` of it reverses the inner run at its place; hop watching has nothing
  left to remove for that task and the inner journal stays true. `cigo adopt`
  says so beside such a script. Lighting the file's chain in the same run (one
  journal) is CigScript's to add; this closes the gap until then.
- **Troubleshooting** says where a running task's output is landing and why
  nothing streams yet.
- **CI** installs cig 1.1.2.
- **Four braces are two.** `{{{{.ImportPath}}}}` in a task's `cmd`, `shell`,
  `env`, `stdin`, `cwd` or `undo` reaches the program as `{{.ImportPath}}`,
  so `go list -f`, `docker --format` and `gh --template` can be called
  without a script around them; `cigo check` points to it when a `{{...}}`
  names no task.
- **Adopting.** The guide says where CigScript scripts of your own belong:
  a `.cig` file adopted through the `scripts` toolchain runs as a nested
  `cig run` whose compensations the outer rollback cannot reach.
- **Licensing.** The code is Apache-2.0, the documentation CC BY 4.0 and the
  examples CC0 1.0, the same split as CigScript. `LICENSE`, `NOTICE`,
  `LICENSES/` and `REUSE.toml` carry it; the README says it in plain words
  and CONTRIBUTING says what it means for a contribution.

## 0.2.0 — 2026-09-28

Every language in the project, one chain, no glue script.

- **Toolchains.** A knowledge base of 60 toolchains, each with the standard
  workflow its ecosystem documents, as the stages setup, format,
  format-check, lint, check, build, test, package, run and clean:
  JavaScript and TypeScript (npm, pnpm, Yarn, Bun, Deno), Python (uv,
  Poetry, PDM, Hatch, Pipenv, pip), Rust, Go, the JVM (Gradle for Java,
  Kotlin and Android, Maven, sbt, Mill, Leiningen, the Clojure CLI), .NET,
  C and C++ (CMake, Meson), Bazel, Buck2, Pants, Ruby, PHP, Elixir, Erlang,
  Gleam, Swift (SwiftPM, Xcode), Dart, Flutter, Zig, Haskell (Stack, Cabal),
  OCaml, Julia, R, Fortran, Lua, Perl, Nim, Crystal, Solidity (Foundry),
  PowerShell, shell and CigScript; Terraform and OpenTofu, Docker, Compose
  and Helm; make, just, Task, Rake, Earthly and script folders. Commands are
  chosen by what the directory holds: the lockfile, the `packageManager`
  field, the formatter and linter the project configures.
  `cigo toolchains` lists them, TOOLCHAINS.md is written from them.
- **Components.** `cig-tasks.json` gains `components` (a directory and a
  toolchain) and `toolchains` (a project's changes to a built-in one, or its
  own). Each stage becomes a task (`api:build`), a stage name runs it in
  every component (`cigo run test`), `ci` runs format-check, lint, check,
  build and test everywhere, and `after` orders components stage by stage.
  Stage overrides remove, replace or add options to any stage.
- **Values between tasks.** `capture` (text, json, lines, kv), named values
  written to `$CIG_OUTPUT` (with `name<<END` for several lines), every
  output so far in `$CIG_OUTPUTS`, and `stdin_from`. Templates
  (`{{task}}`, `{{task.field}}`, `{{task|json}}`, `{{task|sh}}` quoted
  for a shell line, `{{env.NAME}}`, `{{root}}`, `{{project}}`) fill
  arguments, environment, stdin, the working directory and the undo; using
  a task's output is a dependency on it, and a list splices into
  arguments. `cigo outputs` shows them.
- **Up to date.** `inputs` (files, directories, globs) skips a task whose
  sources, command and values are unchanged since it last succeeded;
  `--force` runs it anyway. `produces` (paths or globs) fails a task that
  did not make what it promised.
- `env_file` for components and tasks.
- `adopt` finds every language in the project, down to `--depth` (3),
  with workspaces counted once and Bazel, Buck2 and Pants trees claimed
  whole; test data and a component's own test folders are not searched, and
  a folder of scripts counts at the root or beside a language. A task
  runner at the root of a multi-component project, or beside
  a language's own commands, stays out of the stage groups, and only one
  runner per directory joins them. `adopt --force` keeps the names and
  settings of components it finds again, the ones written by hand, and the
  manifest's tasks, toolchains and defaults, and follows a component that
  moved to another package manager (npm to pnpm, pip to uv).
- `doctor`: each toolchain's tools and versions against the project's pins
  (`.nvmrc`, `.python-version`, `.tool-versions`, `mise.toml`,
  `rust-toolchain.toml`, `global.json` and others; `go.mod` and
  `build.zig.zon` as minimums). `show` explains one task.
- `check` also finds unknown toolchains and components, broken templates
  and filters, `stdin_from` a task that does not exist, bad `capture`
  kinds, stage overrides or toolchain vars that would leave a task with
  nothing to run, and a project toolchain's unknown keys, conditions,
  alternatives and vars; suggestions are by edit distance, a swapped pair
  of letters counting as one (`rustt`: did you mean rust-cargo?).
- `list` orders each component's tasks by stage and shortens long command
  lines; `show` has the whole of it.
- `examples/polyglot`: Python, Node and bash in one chain with an undo;
  the paths it hands on are relative to the project, so its output reads
  the same wherever it's cloned.
- **Docs.** A new README with diagrams and a real terminal run, and guides
  under `docs/`: getting started, adopting a project, chaining languages,
  coming from make and friends, the manifest, commands, your own
  toolchains, CI, troubleshooting, how it works, and the roadmap. Also
  CONTRIBUTING, SUPPORT and SECURITY, issue forms for bugs, toolchain,
  quality-of-life and guidance requests, and a pull request template.
- 56 tests, with a stub toolchain that records what every language would
  run and where.

## 0.1.0 — 2026-09-28

The first version as a tool rather than a sandbox.

- `adopt` finds a project's scripts (`script/`, `scripts/`, `bin/`, `tools/`,
  `*.sh` at the root), `Makefile` targets (the `.PHONY` ones when there are
  any), `package.json` scripts through the package manager the lockfile names,
  and `justfile` recipes; the shebang or the extension says how to run each,
  the first comment describes it. `--write` saves `cig-tasks.json`.
- `list`, `check`, `plan` and `run`: dependencies resolved once each, loops
  and typos caught before anything runs, `--only`, arguments after `--` passed
  to the last task named.
- Per task: `cmd` (never a shell) or `shell` (by name), `cwd`, `env`,
  `timeout_ms`, `retries`, `retry_delay_ms`, `ok`, and `undo` or `undo_shell`
  as a compensation.
- Logs per task and a report per run under `.cig-orchestrator/`.
- `bin/cigo`, a launcher that finds the project from any subdirectory and
  passes `cig`'s own flags through; `install.sh`.
- 24 tests, written in CigScript, run by the tool on itself.
- The sandbox project is now `examples/demo-app`; its deploy lands outside the
  project, which is what makes its undo necessary.
