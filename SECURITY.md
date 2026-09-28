# Security policy

## Supported versions

Fixes go into the newest release. Please reproduce against it before
reporting: `cigo version` says which you have.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting on this repository (**Security
→ Report a vulnerability**). Do not open a public issue for a security
problem. Include `cigo version`, `cig --version`, the platform, and a
manifest or command that shows the problem. You'll get an acknowledgement
within a few days and a fix or a mitigation before anything is disclosed.

## What cigo promises and what it does not

cigo is a local automation tool. It runs the commands in your project's
manifest and the toolchains' documented commands, as you, with your
permissions. **It is not a sandbox.**

- **A manifest is code.** Treat a `cig-tasks.json` from someone else the way
  you'd treat a shell script from them. `cigo check`, `cigo show <task>` and
  `cigo --dry-run run <task>` are the tools for reading before running.
- **`cmd` never goes through a shell.** Its words reach the program as they
  are, so there is nothing to inject into.
- **`shell` does.** A template in a `shell` line is pasted in as text, so a
  value from another task can run as shell. Quote values you don't control
  with `{{task|sh}}`, or pass them through `env`.
- **env files are read, never expanded or executed.**
- **What your tools print is kept.** Task logs, reports and handed-on values
  go in `.cig-orchestrator/` in the project; keep it out of version control
  (`.gitignore`), and don't hand on secrets as named values.
- **Rollback is not a security boundary.** It puts back files a run created
  inside the project; it cannot undo what a program sent over the network or
  wrote outside the project, and cig's plan says so.

What the CigScript runtime itself promises is in [its security
policy](https://github.com/otmof-ops/CigScript/blob/main/SECURITY.md).
