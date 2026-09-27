#!/usr/bin/env bash
# The undo for deploy.sh: remove the release that current points at.
set -euo pipefail
remote=${DEMO_REMOTE:-${TMPDIR:-/tmp}/demo-app-remote}
if [[ ! -f "$remote/current" ]]; then
  echo "nothing deployed at $remote"
  exit 0
fi
version=$(cat "$remote/current")
rm -f "$remote/releases/app-$version.tar.gz" "$remote/current"
rmdir "$remote/releases" "$remote" 2>/dev/null || true
echo "undeployed v$version from $remote"
