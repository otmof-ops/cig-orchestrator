#!/usr/bin/env bash
# bash publishes the page Node built, under the version the first task read.
# In real life the target is a bucket or a server, outside anything a rollback
# can see, so the task in cig-tasks.json declares undeploy.sh as its undo.
set -euo pipefail
page="$1"
version="$2"
target="${DEPLOY_TO:-public}/$version"
mkdir -p "$target"
cp "$page" "$target/index.html"
echo "deployed $version to $target"
# A named value for the task after this one: {{deploy.where}}.
echo "where=$target/index.html" >> "$CIG_OUTPUT"
