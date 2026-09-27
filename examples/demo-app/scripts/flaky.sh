#!/usr/bin/env bash
# A dev's flaky script: fails twice, then works. Counts attempts in build/.
set -euo pipefail
mkdir -p build
f=build/.flaky-count
n=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$f"
if (( n < 3 )); then
  echo "flaky: attempt $n, not this time" >&2
  exit 7
fi
echo "flaky: attempt $n, fine now"
