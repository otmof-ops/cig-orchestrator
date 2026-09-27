#!/usr/bin/env bash
# Deploy the package: copy it to the remote and point current at it.
# The remote is outside the project, where cig's journal cannot see; that is
# why the manifest gives this task an undo.
set -euo pipefail
remote=${DEMO_REMOTE:-${TMPDIR:-/tmp}/demo-app-remote}
version=$(cat build/version.txt)
mkdir -p "$remote/releases"
cp "dist/app-$version.tar.gz" "$remote/releases/"
echo "$version" > "$remote/current"
echo "deployed v$version to $remote"
