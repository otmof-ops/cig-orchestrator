# Toolchains

The 60 toolchains cig-orchestrator 0.2.0 knows, written by `cigo toolchains --markdown`
from the knowledge base in `orchestrate.cig`; regenerate it with `cigo run toolchains-doc`
rather than editing it.

A component is a directory and one of these. `cigo adopt` chooses them from
what each directory holds (the *recognised by* column: a comma is *and*, `or`
is *or*), and a project changes any of them or adds its own under `toolchains`
in `cig-tasks.json`. `cigo toolchains <name>` prints one in full: each stage's
commands with the conditions that choose between them, the tools `cigo doctor`
looks for, and the version pins it compares.

| toolchain | language | recognised by | stages |
|---|---|---|---|
| `node-npm` | JavaScript / TypeScript | `package.json` | setup, format, format-check, lint, check, package, package.json scripts |
| `node-pnpm` | JavaScript / TypeScript | `package.json`, `pnpm-lock.yaml` or `package.json` matching `"packageManager"\s*:\s*"pnpm@` | setup, format, format-check, lint, check, package, package.json scripts |
| `node-yarn` | JavaScript / TypeScript | `package.json`, `yarn.lock` or `package.json` matching `"packageManager"\s*:\s*"yarn@` | setup, format, format-check, lint, check, package, package.json scripts |
| `node-bun` | JavaScript / TypeScript | `package.json`, `bun.lock` or `bun.lockb` or `bunfig.toml` or `package.json` matching `"packageManager"\s*:\s*"bun@` | setup, format, format-check, lint, check, package, package.json scripts |
| `deno` | JavaScript / TypeScript | `deno.json` or `deno.jsonc` | setup, format, format-check, lint, test, deno.json tasks |
| `python-uv` | Python | `uv.lock` or `pyproject.toml` matching `(?m)^\[tool\.uv` | setup, format, format-check, lint, check, test, package |
| `python-poetry` | Python | `poetry.lock` or `pyproject.toml` matching `(?m)^\[tool\.poetry` or `pyproject.toml` matching `poetry\.core\.masonry` | setup, format, format-check, lint, check, test, package |
| `python-pdm` | Python | `pdm.lock` or `pyproject.toml` matching `(?m)^\[tool\.pdm` or `pyproject.toml` matching `pdm\.backend` | setup, format, format-check, lint, check, test, package |
| `python-hatch` | Python | `hatch.toml` or `pyproject.toml` matching `(?m)^\[tool\.hatch\.envs` | setup, format, format-check, lint, test, package, clean |
| `python-pipenv` | Python | `Pipfile` | setup, format, format-check, lint, check, test |
| `python-pip` | Python | `requirements.txt` or `pyproject.toml` or `setup.py` or `setup.cfg` | setup, format, format-check, lint, check, test, package |
| `rust-cargo` | Rust | `Cargo.toml` | setup, format, format-check, lint, check, build, test, package, run, clean |
| `go` | Go | `go.mod` | setup, format, format-check, lint, check, build, test, run, clean |
| `java-gradle` | Java / Kotlin | `build.gradle` or `build.gradle.kts` or `settings.gradle` or `settings.gradle.kts` | format, format-check, lint, check, build, test, package, run, clean |
| `android-gradle` | Android (Kotlin / Java) | `app/src/main/AndroidManifest.xml` or `src/main/AndroidManifest.xml`, `build.gradle` or `build.gradle.kts` or `settings.gradle` or `settings.gradle.kts` | lint, check, build, test, package, clean |
| `java-maven` | Java / Kotlin | `pom.xml` | setup, format, format-check, lint, check, build, test, clean |
| `scala-sbt` | Scala | `build.sbt` | setup, format, format-check, check, build, test, package, run, clean |
| `scala-mill` | Scala | `build.mill` or `build.mill.yaml` or `build.sc` | format, format-check, check, build, test, package, clean |
| `clojure-lein` | Clojure | `project.clj` | setup, check, build, test, package, run, clean |
| `clojure-cli` | Clojure | `deps.edn` | setup, test, package, clean |
| `dotnet` | C# / F# / VB | `*.sln` or `*.slnx` or `*.csproj` or `*.fsproj` or `*.vbproj` | setup, format, format-check, build, test, package, clean |
| `cmake` | C / C++ | `CMakeLists.txt` | setup, format, format-check, build, test, package, clean |
| `meson` | C / C++ | `meson.build` | setup, build, test, clean |
| `bazel` | any (Bazel) | `MODULE.bazel` or `WORKSPACE` or `WORKSPACE.bazel` | setup, format, format-check, check, build, test, clean |
| `buck2` | any (Buck2) | `.buckconfig` | build, test |
| `pants` | any (Pants) | `pants.toml` | format, format-check, lint, check, test, package |
| `ruby-bundler` | Ruby | `Gemfile` | setup, format, lint, check, test, package, rake targets |
| `php-composer` | PHP | `composer.json` | setup, format, format-check, lint, check, test, composer.json scripts |
| `elixir-mix` | Elixir | `mix.exs` | setup, format, format-check, lint, check, build, test, package, clean |
| `erlang-rebar3` | Erlang | `rebar.config` | setup, format, format-check, lint, check, build, test, package, clean |
| `gleam` | Gleam | `gleam.toml` | setup, format, format-check, check, build, test, package, run, clean |
| `swift-spm` | Swift | `Package.swift` | setup, format, format-check, lint, check, build, test, package, run, clean |
| `xcode` | Swift / Objective-C (Xcode) | `*.xcworkspace` or `*.xcodeproj` | build, clean |
| `dart` | Dart | `pubspec.yaml`, no `pubspec.yaml` matching `(?m)^\s+sdk:\s*flutter` | setup, format, format-check, lint, test |
| `flutter` | Dart (Flutter) | `pubspec.yaml`, `pubspec.yaml` matching `(?m)^\s+sdk:\s*flutter` | setup, format, format-check, lint, test, clean |
| `zig` | Zig | `build.zig` | setup, format, format-check, build, test, run, clean |
| `haskell-stack` | Haskell | `stack.yaml` | setup, build, test, package, clean |
| `haskell-cabal` | Haskell | `*.cabal` or `cabal.project` | setup, build, test, package, clean |
| `ocaml-dune` | OCaml | `dune-project` | setup, format, format-check, check, build, test, clean |
| `julia` | Julia | `Project.toml` or `JuliaProject.toml` | setup, build, test |
| `r` | R | `DESCRIPTION` or `renv.lock` | setup, format, format-check, lint, test, package |
| `fortran-fpm` | Fortran | `fpm.toml` | build, test, run, clean |
| `lua-luarocks` | Lua | `*.rockspec` | setup, format, format-check, lint, build, test, package |
| `perl` | Perl | `cpanfile` or `Makefile.PL` or `Build.PL` | setup, lint, build, test, package |
| `nim` | Nim | `*.nimble` | setup, build, test, run |
| `crystal` | Crystal | `shard.yml` | setup, format, format-check, lint, build, test, package |
| `foundry` | Solidity (Foundry) | `foundry.toml` | setup, format, format-check, lint, build, test, clean |
| `powershell` | PowerShell | added by hand | lint, test |
| `cigscript` | CigScript | `*.cig` | lint, check |
| `shell` | Shell | added by hand | format, format-check, lint |
| `terraform` | Terraform / OpenTofu | `*.tf` or `*.tofu` or `*.tf.json` | setup, format, format-check, lint, check, test |
| `docker` | Container image | `Dockerfile` or `Containerfile` | lint, package |
| `compose` | Docker Compose | `compose.yaml` or `compose.yml` or `docker-compose.yml` or `docker-compose.yaml` | check, build |
| `helm` | Helm chart | `Chart.yaml` | setup, lint, check, package |
| `make` | Makefile | `GNUmakefile` or `makefile` or `Makefile` | make targets |
| `just` | justfile | `justfile` or `Justfile` or `.justfile` | just targets |
| `task` | Taskfile (go-task) | `Taskfile.yml` or `Taskfile.yaml` or `taskfile.yml` or `taskfile.yaml` or `Taskfile.dist.yml` or `taskfile.dist.yml` | taskfile targets |
| `rake` | Rakefile | `Rakefile` or `rakefile` or `Rakefile.rb` or `rakefile.rb`, no `Gemfile` | rake targets |
| `earthly` | Earthfile | `Earthfile` | earthly targets |
| `scripts` | Script folder | `script` or `scripts` or `bin` or `tools` or `*.sh` or `*.bash` | scripts targets |

## Notes

- `node-npm`: dev, start, serve and watch scripts do not end on their own, so none of them is a stage.
- `node-pnpm`: dev, start, serve and watch scripts do not end on their own, so none of them is a stage.
- `node-yarn`: dev, start, serve and watch scripts do not end on their own, so none of them is a stage.
- `node-bun`: dev, start, serve and watch scripts do not end on their own, so none of them is a stage.
- `deno`: deno check needs entry files, so there is no check stage unless deno.json has a check task.
- `python-uv`: uv reads .python-version itself, so no Python pin is checked here.
- `python-pip`: setup makes .venv with the project and its dev requirements (requirements-dev.txt, a dev dependency group, or a dev, test or tests extra); the other stages run inside it.
- `rust-cargo`: cig does not watch target/, so build outputs are not rolled back; --locked is used when Cargo.lock exists.
- `java-gradle`: a root task name runs in every subproject; formatter and linter tasks exist only when their plugin is applied.
- `android-gradle`: needs the Android SDK (ANDROID_HOME or local.properties); device tests are left out.
- `java-maven`: phases are cumulative (package runs the tests unless skipped); install writes to ~/.m2 and is not setup.
- `scala-sbt`: sbt 2 runs tests incrementally; add a stage override with testFull to run them all.
- `dotnet`: a folder with several solution or project files needs a stage override naming one.
- `cmake`: ctest --test-dir needs CMake 3.20; multi-config generators need a --config override.
- `ruby-bundler`: Bundler 4 dropped --frozen; setup sets BUNDLE_FROZEN when Gemfile.lock exists.
- `swift-spm`: swift format ships with Swift 6; lint only fails with --strict.
- `xcode`: xcodebuild needs a scheme for workspaces and tests: override the stages with -scheme <name> (xcodebuild -list shows them).
- `flutter`: builds are per platform (apk, appbundle, ios, web...): add a build stage override for yours.
- `zig`: test and run are steps build.zig defines, so they appear only when it does; minimum_zig_version is advisory, doctor checks it.
- `ocaml-dune`: OCaml files are formatted only when .ocamlformat exists.
- `fortran-fpm`: plain fpm clean asks before deleting, so clean passes --skip.
- `powershell`: never detected on its own: add a component with toolchain powershell.
- `cigscript`: cig check reads one file at a time, so these stages check every .cig file under the component in turn, test data (fixtures, corpus, testdata) left out.
- `shell`: never detected on its own: add a component with toolchain shell.
- `terraform`: setup initialises without the backend so no credentials are needed; plan is a task of its own and apply is never run.
- `docker`: lint uses docker build --check (Buildx 0.15 and later).
- `earthly`: Earthly upstream takes critical fixes only since 2025; EarthBuild is the community fork.
