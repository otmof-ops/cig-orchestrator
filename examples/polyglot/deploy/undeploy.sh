#!/usr/bin/env bash
# The deploy's undo: run by a rollback when a later task fails, or by
# `cig unburn <run>` at any time after.
set -euo pipefail
version="$1"
target="${DEPLOY_TO:-public}/$version"
rm -rf "$target"
echo "took $version back from ${DEPLOY_TO:-public}"
