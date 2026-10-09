# Contributing to cig-orchestrator

Fixes, toolchains, docs and examples are all welcome. This page is short
because the tooling does most of the checking.

## Before you start

- **Something went wrong?** Open a [bug
  report](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=bug-report.yml)
  with the manifest (or the part that matters), the command, the full
  output, and `cigo version` and `cig --version`.
- **A language or tool cigo doesn't know?** A [toolchain
  request](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=toolchain-request.yml)
  is enough to get it built with you; a pull request is even better.
- **A feature, or something your other tool does better?** Open a
  [quality-of-life
  request](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=qol-request.yml)
  first and say what it saves you.
- **A problem in the language itself** (a kernel that lied, a diagnostic
  that's wrong) belongs in [CigScript's
  issues](https://github.com/otmof-ops/CigScript/issues).
- **Security problems** never go in a public issue: see
  [SECURITY.md](SECURITY.md).

## Set up

You need `cig` 1.1.1 or newer, `shellcheck`, Python 3 and Node 18 or newer
(the example's tests use both).

```sh
git clone https://github.com/otmof-ops/cig-orchestrator && cd cig-orchestrator
bin/cigo run ci           # cig check on every .cig file, shellcheck, then the suite
```

`bin/cigo` runs this checkout's `orchestrate.cig`, so your changes are live.
(`./install.sh` copies the tool instead; run it again after a change if you
use the installed `cigo`.)
The suite takes a few seconds; `cig run tests/run.cig -- <words>` runs just
the tests whose names contain them.

## The workflow

1. Branch from `main`, one change per pull request.
2. **Every fix comes with a test named after what broke**, in
   `tests/run.cig`. It should fail without the fix.
3. `cigo run ci` is green: `cig check --deny-warnings` on each `.cig` file,
   shellcheck, and the suite.
4. If you changed the knowledge base, run `bin/cigo run toolchains-doc` and
   commit the new `TOOLCHAINS.md` with your change.
5. If you changed what a user sees, change the docs with it: the
   [guides](docs/README.md), the README, and a line in the
   [CHANGELOG](CHANGELOG.md).
6. Open the pull request; the template asks for the rest.

## Adding a toolchain

A toolchain is data in `orchestrate.cig`, under "the toolchains", in the
section for its language family. The format is the one a project uses under
`toolchains`, documented in [your own toolchains](docs/custom-toolchains.md).

1. **The entry.** `language`, `short`, `family` and `priority` beside its
   alternatives, `detect`, `tools`, `versions`, `pins` where the ecosystem
   has them, `install`, and a `note` for anything a user must know. Each
   stage's command is the one the tool's own documentation recommends, with
   lockfile-respecting installs and check-only formatting for
   `format-check`.
2. **The stub.** If it runs a program the suite hasn't met, link it:
   `ln -s stub tests/fixtures/stub-bin/<program>`.
3. **The test.** Write the files that identify the toolchain into a fresh
   fixture, run a stage through the stub, and check the command and the
   directory it ran in:

   ```cig
   test("gleam builds and tests with gleam", pack() {
     stick dir = fresh("tests/fixtures/empty")
     burn {
       fs.write_text(path.join(dir, "gleam.toml"), "name = \"app\"\n")
     }
     exits(tool_in(dir, ["adopt", "--write"]), 0)
     exits(tool_stubbed(dir, ["run", "test"]), 0)
     says(stub_log(dir), "gleam test @" + dir)
   })
   ```

4. **The docs.** `cigo run toolchains-doc`, and in the pull request, a link
   to the documentation behind each command.

## Writing what cigo says

cigo speaks the way CigScript does
([the lexicon](https://github.com/otmof-ops/CigScript/blob/main/docs/LEXICON.md)):

- A message says what happened, then what to type next.
- Plain words first, the manual's name after, so nobody has to be embarrassed
  later.
- It names the thing: the task, the key, the file, the line.
- Nobody's on trial. No message blames the reader or withholds the pointer.

## Pull requests and commits

A commit message says what changed and why, in a sentence or two. A pull
request fills in the template: what broke or was missing, why, the change,
and the test that proves it. Reviews are about the code and the behavior;
expect a reply, and expect it to be kind.

## Licensing your contribution

Code is Apache-2.0, documentation is CC BY 4.0 and examples are CC0 1.0;
[REUSE.toml](REUSE.toml) maps every path, and `orchestrate.cig`, `bin/cigo`,
`install.sh` and `tests/run.cig` carry SPDX headers (a new source file gets
the same two lines; copy them from a neighbor). A contribution is accepted
under the license of the kind of file it changes, which Apache-2.0 says
itself in its section 5. Sign off each commit (`git commit -s`): the
`Signed-off-by` line is your statement, under the
[Developer Certificate of Origin](https://developercertificate.org), that
the work is yours to give. You keep your copyright.
