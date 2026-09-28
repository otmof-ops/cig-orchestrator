# cig-orchestrator guides

Start at the top if you're new; jump to the reference when you need a key or
a flag.

**Learn it**

- [Getting started](getting-started.md): install cig and cigo, try the
  example, then run your first stage across your own project.
- [Adopting a project](adopting-a-project.md): bring an existing repository
  over without rewriting anything, and retire the glue script at the end of
  the chain.
- [Chaining languages](chaining-languages.md): hand values from one language
  to the next, with recipes for bash, Python, Node, Go, Rust, Ruby and
  PowerShell.
- [Coming from make, just, npm scripts and friends](coming-from.md): what you
  keep, what cigo adds, and what it doesn't do.

**Look it up**

- [The manifest](manifest.md): every key in `cig-tasks.json`.
- [Commands](commands.md): every command and flag, exit codes, and the files
  cigo keeps.
- [Toolchains](../TOOLCHAINS.md): the 60 toolchains cigo knows, what
  recognizes each, and its stages.

**Make it yours**

- [Your own toolchains](custom-toolchains.md): change a built-in toolchain
  for your project, or teach cigo a new one.
- [cigo in CI](ci.md): the same chain on GitHub Actions and GitLab CI.
- [Troubleshooting](troubleshooting.md): what a message means and what to
  type next.

**Under the hood**

- [How it works](how-it-works.md): the tool's insides, for contributors.
- [Roadmap](roadmap.md): what's coming, and how a request gets there.

Stuck on something these don't cover? [Ask for
guidance](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=guidance-request.yml);
a person answers it.
