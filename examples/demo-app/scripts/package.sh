#!/usr/bin/env bash
# A dev's own packaging: tar the build into dist/.
set -euo pipefail
mkdir -p dist
version=$(cat build/version.txt)
tar czf "dist/app-$version.tar.gz" -C build app version.txt
echo "dist/app-$version.tar.gz"
