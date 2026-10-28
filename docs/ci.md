# cigo in CI

The chain you run locally is the chain CI runs: install `cig` and `cigo`,
then `cigo run ci`. The job file stops being a second copy of your build.

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

      - name: Install cig
        run: |
          mkdir -p "$HOME/.local/bin" && cd "$RUNNER_TEMP"
          base=https://github.com/otmof-ops/CigScript/releases/download/v1.4.2
          curl -fsSLO "$base/cig-v1.4.2-linux-x86_64"
          curl -fsSLO "$base/cig-v1.4.2-linux-x86_64.sha256"
          sha256sum -c cig-v1.4.2-linux-x86_64.sha256
          install -m 755 cig-v1.4.2-linux-x86_64 "$HOME/.local/bin/cig"
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"

      - name: Install cigo
        run: |
          cd "$RUNNER_TEMP"
          tag=v0.4.0
          base="https://github.com/otmof-ops/cig-orchestrator/releases/download/$tag"
          curl -fsSLO "$base/cig-orchestrator-$tag.tar.gz"
          curl -fsSLO "$base/cig-orchestrator-$tag.tar.gz.sha256"
          sha256sum -c "cig-orchestrator-$tag.tar.gz.sha256"
          tar -xzf "cig-orchestrator-$tag.tar.gz"
          "cig-orchestrator-$tag/install.sh"

      - run: cigo doctor
      - run: cigo --no-rollback run ci

      - name: Keep the logs
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: cigo-logs
          path: .cig-orchestrator/
```

The checksum lines refuse a download that isn't the published binary or
tarball. Pin the CigScript and cig-orchestrator releases you tested with, and
bump them on purpose; `cigo doctor` in the job prints every version side by
side, and `cigo --no-rollback run ci --strict` stops on a pin the runner does
not satisfy.

## GitLab CI

Use the image your project already builds in, and add the two installs:

```yaml
ci:
  image: your-build-image
  before_script:
    - mkdir -p "$HOME/.local/bin" && export PATH="$HOME/.local/bin:$PATH"
    - base=https://github.com/otmof-ops/CigScript/releases/download/v1.4.2
    - curl -fsSLO "$base/cig-v1.4.2-linux-x86_64" && curl -fsSLO "$base/cig-v1.4.2-linux-x86_64.sha256"
    - sha256sum -c cig-v1.4.2-linux-x86_64.sha256 && install -m 755 cig-v1.4.2-linux-x86_64 "$HOME/.local/bin/cig"
    - tag=v0.4.0; base="https://github.com/otmof-ops/cig-orchestrator/releases/download/$tag"
    - curl -fsSLO "$base/cig-orchestrator-$tag.tar.gz" && curl -fsSLO "$base/cig-orchestrator-$tag.tar.gz.sha256"
    - sha256sum -c "cig-orchestrator-$tag.tar.gz.sha256" && tar -xzf "cig-orchestrator-$tag.tar.gz" && "cig-orchestrator-$tag/install.sh"
  script:
    - cigo doctor
    - cigo --no-rollback run ci
  artifacts:
    when: on_failure
    paths: [.cig-orchestrator/]
```

## GitHub Actions on Windows and macOS

The same two installs, with the shell each runner has. macOS has no
`sha256sum`: use `shasum -a 256 -c`. On Windows, PowerShell runs CigScript's
`install.ps1` and then cig-orchestrator's. Each adds its directory to the
user PATH, which a running job never sees, so the step puts `cig` on its own
`$env:Path` before the second installer looks for it, tells the first not to
ask about PATH (`CIG_NO_MODIFY_PATH`; a job cannot answer a prompt), and
writes both directories to `GITHUB_PATH` for the steps that follow:

```yaml
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - shell: pwsh
        env:
          CIG_NO_MODIFY_PATH: '1'
        run: |
          irm https://raw.githubusercontent.com/otmof-ops/CigScript/main/install.ps1 | iex
          $env:Path = "$env:LOCALAPPDATA\Programs\cig;$env:Path"
          $tag = 'v0.5.1'
          $base = "https://github.com/otmof-ops/cig-orchestrator/releases/download/$tag"
          irm "$base/cig-orchestrator-$tag.tar.gz" -OutFile cigo.tar.gz
          irm "$base/cig-orchestrator-$tag.tar.gz.sha256" -OutFile cigo.tar.gz.sha256
          if ((Get-FileHash cigo.tar.gz -Algorithm SHA256).Hash.ToLower() -ne ((Get-Content cigo.tar.gz.sha256) -split '\s+')[0].ToLower()) { throw 'checksum mismatch' }
          tar -xzf cigo.tar.gz
          & ".\cig-orchestrator-$tag\install.ps1"
          echo "$env:LOCALAPPDATA\Programs\cig;$env:LOCALAPPDATA\cig-orchestrator\bin" >> $env:GITHUB_PATH
      - run: cigo doctor
      - run: cigo --no-rollback run ci
```

## Worth knowing

- **`--no-rollback` in CI.** Locally, a failure puts back what the run
  created. In CI you usually want the opposite: keep the coverage report,
  the test results and the build output so they can be uploaded. The runner
  is thrown away afterwards anyway.
- **`cigo doctor` first.** It prints each tool's version and checks it
  against the pins the repository keeps, so a version mismatch shows up as
  its own line instead of as a strange test failure.
- **Plan on pull requests.** `cigo --dry-run run release` in a pull request
  job shows exactly what a release would do, and does none of it.
- **The same tasks, in any job.** `cigo run test`, `cigo run lint` and
  `cigo run web:build` split the chain across jobs when you want to.
- **Logs are files.** `.cig-orchestrator/logs/<task>.log` holds each task's
  full output, and `.cig-orchestrator/reports/` a JSON report per run, ready
  to upload.
