#!/bin/sh
# A harmless replica of an install script gone bad: it writes a git hook
# that only echoes a marker. In the rehearsal it never leaves the box.
mkdir -p .git/hooks
echo 'echo marker' > .git/hooks/pre-commit
