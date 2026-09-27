#!/usr/bin/env bash
# A dev's own test: the built app must greet.
set -euo pipefail
out=$(./build/app)
if [[ "$out" == *hello* ]]; then
  echo "test: ok ($out)"
else
  echo "test: FAILED, got: $out" >&2
  exit 1
fi
