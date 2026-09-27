#!/usr/bin/env bash
# A dev's own deploy: copy the package to a "remote" and point current at it.
set -euo pipefail
version=$(cat build/version.txt)
mkdir -p remote/releases
cp "dist/app-$version.tar.gz" remote/releases/
echo "$version" > remote/current
echo "deployed v$version to remote/"
