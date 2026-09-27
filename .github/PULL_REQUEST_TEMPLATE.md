## What broke, or what was missing

<!-- One paragraph. Link the issue: Fixes #12. -->

## Why

<!-- The cause, or the need, in a sentence or two. -->

## The change

<!-- What changed, and what someone using cigo will notice. -->

## The test

<!-- The test in tests/run.cig named after it, and that it fails without the change. -->

## Checklist

- [ ] `bin/cigo run ci` is green: cig check, shellcheck, the suite
- [ ] A fix has a test named after what broke
- [ ] A new toolchain has its stub, a test, and a link above to the documentation behind each command
- [ ] `TOOLCHAINS.md` is regenerated if the knowledge base changed (`bin/cigo run toolchains-doc`)
- [ ] The docs and the CHANGELOG say what someone using cigo will notice
- [ ] Every new message says what to type next, and nothing blames the reader
