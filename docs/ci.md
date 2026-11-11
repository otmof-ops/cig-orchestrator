# cigo in CI

The chain you run locally is the chain CI runs: install `cig` and `cigo`
with ciginstaller, then `cigo run ci`. The job file stops being a second copy of your build.

The recipes below use ciginstaller's bootstrap script, which comes with
ciginstaller's first release. Until that release exists
([how to get ciginstaller today](https://github.com/otmof-ops/cig-installer#install)),
install `cig` from its own release, the binary for the runner and its `.sha256`,
and run `cigo` from its release tarball, as this repository's own
[CI](../.github/workflows/ci.yml) does.

## The setup action

On a GitHub-hosted Linux or macOS runner, one line installs cig and cigo:

```yaml
- uses: otmof-ops/cig-orchestrator/setup@v1
```

cig comes from its release, checked against the checksum published beside
it; cigo is the checkout of the action itself, so `@v1` is the cigo of the
newest `v1.x` release (the `v1` tag moves with each release; pin
`@v1.18.0`, or a commit, to stop it moving). Two inputs: `cig-version` (a
release tag, `v1.20.0` by default) and `userns` (on Linux, `true` by default:
turns off Ubuntu's restriction on unprivileged user namespaces so cig can make
its box, which `cigo rehearse` needs; the runner is thrown away afterwards).
Windows runners use the steps further down.

The four lines that check a pull request's new packages and show them in the
Security tab (the `permissions` and `fetch-depth` are what it needs):

```yaml
permissions: { contents: read, security-events: write }
steps:
  - uses: actions/checkout@v4
    with: { fetch-depth: 0 }
  - uses: otmof-ops/cig-orchestrator/setup@v1
  - run: cigo rehearse --changed --base origin/${{ github.base_ref }} --sarif rehearse.sarif
  - uses: github/codeql-action/upload-sarif@v3
    with: { sarif_file: rehearse.sarif }
```

`--sarif <file>` names the file; the exit code is the risk, `high` or worse by
default under CI, so the job fails on a package that earns it and the
Security tab says why either way (add `if: always()` to the upload to see
it on a failure).

## GitHub Actions

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # The toolchains your project uses, as you set them up today.
      - uses: actions/setup-node@v4
        with:
          node-version-file: web/.nvmrc
      - uses: astral-sh/setup-uv@v6

      # cig and cigo come from ciginstaller (the carton holds both). Its
      # bootstrap script is checked against its checksum before it runs;
      # `--yes` answers its questions.
      - name: Install cig and cigo
        run: |
          cd "$RUNNER_TEMP"
          gh release download -R otmof-ops/cig-installer -p install.sh -p install.sh.sha256
          sha256sum -c install.sh.sha256
          sh install.sh --yes carton
          echo "$HOME/.cigscript/bin" >> "$GITHUB_PATH"
        env:
          GH_TOKEN: ${{ github.token }}

      - run: ciginstaller doctor --tools
      - run: cigo --no-rollback run ci

      - name: Keep the logs
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: cigo-logs
          path: .cig-orchestrator/
```

The bootstrap script is checked before it runs, and ciginstaller verifies
every build it installs. Pin the carton you tested with (`ciginstaller
install carton --carton <version>`) and bump it on purpose;
`ciginstaller doctor --tools` in the job prints every version side by side,
and `cigo --no-rollback run ci --strict` stops on a pin the runner does not
satisfy.

## GitLab CI

Use the image your project already builds in, and install cig and cigo with ciginstaller:

```yaml
ci:
  image: your-build-image
  before_script:
    - gh release download -R otmof-ops/cig-installer -p install.sh -p install.sh.sha256
    - sha256sum -c install.sh.sha256 && sh install.sh --yes carton
    - export PATH="$HOME/.cigscript/bin:$PATH"
  script:
    - ciginstaller doctor --tools
    - cigo --no-rollback run ci
  artifacts:
    when: on_failure
    paths: [.cig-orchestrator/]
```

## GitHub Actions on Windows and macOS

The same install, with the shell each runner has. macOS has no `sha256sum`:
use `shasum -a 256 -c`. On Windows, PowerShell runs ciginstaller's
`install.ps1` from the same release instead (check its release notes for the
Windows build), and the job writes the folder it installs into to
`GITHUB_PATH` for the steps that follow. The macOS job:

```yaml
  macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          gh release download -R otmof-ops/cig-installer -p install.sh -p install.sh.sha256
          shasum -a 256 -c install.sh.sha256
          sh install.sh --yes carton
          echo "$HOME/.cigscript/bin" >> "$GITHUB_PATH"
        env:
          GH_TOKEN: ${{ github.token }}
      - run: ciginstaller doctor --tools
      - run: cigo --no-rollback run ci
```

## The guard in code scanning

`cigo audit --sarif` writes the guard's read of every task (the static read
and the lockfiles' packages against OSV) as a SARIF 2.1.0 log, each finding
placed at its line in the project, so GitHub shows it in the pull request's
Security tab. `cigo rehearse --changed --sarif` does the same for every
package the pull request adds or changes in its lockfiles, each rehearsed in
cig's contained box and placed at its entry in the lockfile.

```yaml
  guard:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0        # --changed compares with the base branch
      # Install cig and cigo as above, and the ecosystems' own tools.
      - run: cigo audit --sarif > audit.sarif
      # The box needs unprivileged user namespaces, which Ubuntu 24.04
      # restricts; the runner is thrown away afterwards.
      - run: sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
      - run: cigo rehearse --changed --base=origin/${{ github.base_ref }} --sarif > rehearse.sarif
        continue-on-error: true  # the exit code is the risk; the Security tab shows why
      - uses: github/codeql-action/upload-sarif@v3
        with: { sarif_file: audit.sarif, category: cigo-audit }
      - uses: github/codeql-action/upload-sarif@v3
        with: { sarif_file: rehearse.sarif, category: cigo-rehearse }
```

`--jobs=N` (the `rehearse_jobs` setting, half the cores by default) rehearses
up to N of the pull request's packages at once, each in its own box; the
report keeps its order. A bare `cigo rehearse` rehearses a project's direct
dependencies, for a job with no pull request to compare with.

`--markdown` writes the same findings as one table for a pull request
comment. The exit codes say the risk (`0` none or low, `1` medium, `2` high,
`3` critical) for a job that should stop on its own line; `cigo audit`
itself exits `0` and leaves that to the report.

## Worth knowing

- **`--no-rollback` in CI.** Locally, a failure puts back what the run
  created. In CI you usually want the opposite: keep the coverage report,
  the test results and the build output so they can be uploaded. The runner
  is thrown away afterwards anyway.
- **`ciginstaller doctor --tools` first.** It prints each tool's version and checks it
  against the pins the repository keeps, so a version mismatch shows up as
  its own line instead of as a strange test failure.
- **Plan on pull requests.** `cigo --dry-run run release` in a pull request
  job shows exactly what a release would do, and does none of it.
- **The same tasks, in any job.** `cigo run test`, `cigo run lint` and
  `cigo run web:build` split the chain across jobs when you want to.
- **Logs are files.** `.cig-orchestrator/logs/<task>.log` holds each task's
  full output, and `.cig-orchestrator/reports/` a JSON report per run, ready
  to upload.
