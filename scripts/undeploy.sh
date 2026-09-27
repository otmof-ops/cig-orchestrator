#!/usr/bin/env bash
# The undo for deploy.sh: remove what current points at.
set -euo pipefail
[[ -f remote/current ]] || { echo "nothing deployed"; exit 0; }
version=$(cat remote/current)
rm -f "remote/releases/app-$version.tar.gz" remote/current
echo "undeployed v$version"
