# Getting help

I read every request. Put yours where it fits and you'll get an answer in
the issue.

| you want to | open |
|---|---|
| get unstuck bringing a project over to cigo or CigScript | [a guidance request](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=guidance-request.yml) |
| have cigo know a language or tool it doesn't | [a toolchain request](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=toolchain-request.yml) |
| get something your other language or tool does better | [a quality-of-life request](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=qol-request.yml) |
| report something that went wrong | [a bug report](https://github.com/otmof-ops/cig-orchestrator/issues/new?template=bug-report.yml) |
| report a problem in the language itself | [CigScript's issues](https://github.com/otmof-ops/CigScript/issues) |
| report a security problem | [SECURITY.md](SECURITY.md), never a public issue |

## What helps

- `cigo version` and `cig --version`, and your platform.
- The manifest, or the part that matters.
- The command you ran and everything it printed. Paste, don't summarize.
- For a failed task, its log: `.cig-orchestrator/logs/<task>.log`. Read it
  first; your tools print what they print, and a token in a log is still a
  token.

## What happens next

- **Guidance:** a direct answer, with the steps for your project, in the
  issue. If the answer should be in the docs, it goes in the docs too.
- **Bugs:** a fix, and a test that keeps it fixed. The issue is closed with
  the version that has it.
- **Toolchains and quality-of-life requests:** a reply saying what I think
  and why. Accepted ones get a line on the [roadmap](docs/roadmap.md) and are
  built with you.

## Why this page exists

cigo exists to make CigScript easy to start with, and a tool like that is
only as good as the help behind it. If something here is confusing, that's a
bug in the docs, and I'd rather hear about it than have you give up.
