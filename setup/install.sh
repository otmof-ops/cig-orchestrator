#!/bin/sh
# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: FSL-1.1-ALv2
# The setup action's work (setup/action.yml): put cig on the runner's PATH, from
# its release, checked against the checksum published beside it, and cigo
# from the checkout the action itself came from. Linux and macOS runners.
#   CIG_VERSION   the cig release to install (the action's input)
#   USERNS        true on Linux lets cig make its box (Ubuntu's AppArmor refuses
#                 unprivileged user namespaces); the runner is thrown away after
# GITHUB_PATH and RUNNER_TEMP are the runner's own.
set -eu

version=${CIG_VERSION:?CIG_VERSION is not set}
case "$version" in
  v[0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "setup: cig-version is a release tag like v1.20.0, not '$version'" >&2; exit 2 ;;
esac

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) asset=linux-x86_64 ;;
  Linux-aarch64 | Linux-arm64) asset=linux-aarch64 ;;
  Darwin-arm64) asset=macos-aarch64 ;;
  Darwin-x86_64) asset=macos-x86_64 ;;
  *) echo "setup: no cig build for $(uname -s) $(uname -m); the setup action runs on Linux and macOS runners (docs/ci.md has the Windows steps)" >&2; exit 2 ;;
esac

here=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if [ ! -f "$here/bin/cigo" ] || [ ! -f "$here/orchestrate.cig" ]; then
  echo "setup: cigo is not beside this action ($here)" >&2
  exit 2
fi

bin="$HOME/.local/bin"
mkdir -p "$bin"
tmp=${RUNNER_TEMP:-$(mktemp -d)}
name="cig-$version-$asset"
base="https://github.com/otmof-ops/cig-script/releases/download/$version"
cd "$tmp"
curl -fsSLO "$base/$name"
curl -fsSLO "$base/$name.sha256"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c "$name.sha256"
else
  shasum -a 256 -c "$name.sha256"
fi
install -m 755 "$name" "$bin/cig"
ln -sf "$here/bin/cigo" "$bin/cigo"

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$bin" >> "$GITHUB_PATH"
fi
PATH="$bin:$PATH"
export PATH

if [ "$(uname -s)" = Linux ] && [ "${USERNS:-true}" = true ]; then
  sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 >/dev/null 2>&1 || true
fi

cig --version
cigo --version
