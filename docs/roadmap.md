# Roadmap

cigo is the first of the tools I'm building to make CigScript easy to start
with, without starting over. This page is the plan, in the open. It changes
as people ask for things, which is the point.

## Promises that don't change

- **Problems get fixed.** A bug report gets a fix, and a test that keeps it
  fixed.
- **Guidance gets a direct answer.** Ask for help bringing a project over
  and I'll help you with it, in the issue.
- **Quality-of-life requests are read and answered.** If another language or
  tool does something better, it belongs on this page, and the good ones
  land.
- **Toolchain requests become knowledge-base entries**, built with the
  person who asked, and tested against a stub of their tool.

## Next for cigo

What I'm looking at, from its own limits. Requests reorder this list.

- **Streaming output**: see a task's output while it runs. This needs
  streaming hops in CigScript (below).
- **Independent components in parallel**: Python's and Go's tests at the
  same time, still stopping and rolling back together.
- **Keep going**: finish every language's checks and report every failure
  at the end, for CI.
- **Content hashes for inputs**: skip a task on what its files hold, not
  their sizes and times.
- **Watch mode**: run a stage again when its inputs change.
- **More toolchains**: whatever you use that
  [TOOLCHAINS.md](../TOOLCHAINS.md) doesn't have yet.

## Adoption tools on the table

Ideas for the next tools, not promises. Which comes first depends on what
people ask for.

- **CI from the manifest**: write the workflow in [cigo in CI](ci.md) for a
  project's own toolchains.
- **A CI job into a chain**: read an existing workflow's `run:` steps and
  propose them as tasks, the way adopt reads a Makefile.
- **A script into CigScript, step by step**: move a bash script's steps into
  CigScript when you want its dry run and rollback inside the script itself,
  with the old script kept until the new one matches it.

## What cigo needs from CigScript

From [FINDINGS.md](../FINDINGS.md). These are changes to the language, and
they land in [CigScript](https://github.com/otmof-ops/CigScript) with its
own tests.

- The next release, with directories a task creates removed on rollback.
- Streaming hop output.
- A skip list for hop watching, so a setup that fills `.venv` isn't
  journaled file by file.
- A way for a script to read its own run id, so cigo can print the `cig
  unburn` line itself.
- A way to fail with a message and a rollback, without quoting the script's
  own source.

## How a request gets here

1. Open the form that fits: [guidance](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=guidance-request.yml),
   [quality of life](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=qol-request.yml),
   [a toolchain](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=toolchain-request.yml)
   or [a bug](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=bug-report.yml).
2. The form labels it, and I read it and reply there.
3. When it's accepted, it gets a line on this page.
4. When it ships, the [changelog](../CHANGELOG.md) says so, and the issue is
   closed with the version that has it.
