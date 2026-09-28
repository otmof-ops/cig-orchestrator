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
          base=https://github.com/otmof-ops/CigScript/releases/download/v1.1.1
          curl -fsSLO "$base/cig-v1.1.1-linux-x86_64"
          curl -fsSLO "$base/cig-v1.1.1-linux-x86_64.sha256"
          sha256sum -c cig-v1.1.1-linux-x86_64.sha256
          install -m 755 cig-v1.1.1-linux-x86_64 "$HOME/.local/bin/cig"
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"

      - name: Install cigo
        run: |
          git clone --depth 1 https://github.com/otmof-ops/cig-orchestrator "$RUNNER_TEMP/cigo"
          "$RUNNER_TEMP/cigo/install.sh"

      - run: cigo doctor
      - run: cigo --no-rollback run ci

      - name: Keep the logs
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: cigo-logs
          path: .cig-orchestrator/
```

The checksum line refuses a download that isn't the published binary. Pin
the CigScript release you tested with, and bump it on purpose.

## GitLab CI

Use the image your project already builds in, and add the two installs:

```yaml
ci:
  image: your-build-image
  before_script:
    - mkdir -p "$HOME/.local/bin" && export PATH="$HOME/.local/bin:$PATH"
    - base=https://github.com/otmof-ops/CigScript/releases/download/v1.1.1
    - curl -fsSLO "$base/cig-v1.1.1-linux-x86_64" && curl -fsSLO "$base/cig-v1.1.1-linux-x86_64.sha256"
    - sha256sum -c cig-v1.1.1-linux-x86_64.sha256 && install -m 755 cig-v1.1.1-linux-x86_64 "$HOME/.local/bin/cig"
    - git clone --depth 1 https://github.com/otmof-ops/cig-orchestrator /tmp/cigo && /tmp/cigo/install.sh
  script:
    - cigo doctor
    - cigo --no-rollback run ci
  artifacts:
    when: on_failure
    paths: [.cig-orchestrator/]
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
