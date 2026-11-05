#!/bin/sh
# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: Apache-2.0
# Install cig-orchestrator: orchestrate.cig into ~/.local/share/cig-orchestrator
# and the cigo launcher into ~/.local/bin. Run it again to update a checkout;
# an installed cigo updates itself with `cigo update`.
#
#   ./install.sh                 CIGO_PREFIX=/opt/cig ./install.sh      CIGO_NAME=orch ./install.sh
#
# CIGO_PREFIX names the install root (default ~/.local). PREFIX is honoured
# too, except under Termux, which exports PREFIX for its own package tree.
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
prefix=${CIGO_PREFIX:-}
if [ -z "$prefix" ] && [ -n "${PREFIX:-}" ]; then
  case "$(uname -o 2>/dev/null || true)" in Android) ;; *) prefix=$PREFIX ;; esac
fi
prefix=${prefix:-$HOME/.local}
# A relative prefix is written into the launcher as it is, which only works
# from this directory: make it absolute first.
case "$prefix" in
  /*|[A-Za-z]:*|\\*) ;;
  *) prefix=$PWD/$prefix ;;
esac
name=${CIGO_NAME:-cigo}
case "$name" in
  *.ps1|*.cmd)
    echo "install: CIGO_NAME=$name names a Windows launcher; install.ps1 installs those" >&2
    exit 1 ;;
esac
share=$prefix/share/cig-orchestrator
bin=$prefix/bin

if ! command -v cig >/dev/null 2>&1; then
  echo "install: cig is not on PATH. Install CigScript first: https://github.com/otmof-ops/CigScript#install" >&2
  exit 1
fi
# The same floor as the launcher and the tool's `# cig` pin.
needs_major=1
needs_minor=12
needs_patch=0
version=$(cig --version 2>/dev/null | awk '{print $2}')
case "$version" in
  [0-9]*.[0-9]*.[0-9]*)
    major=${version%%.*}; rest=${version#*.}; minor=${rest%%.*}; patch=${rest#*.}; patch=${patch%%[!0-9]*}
    too_old=0
    if [ "$major" -lt "$needs_major" ]; then too_old=1
    elif [ "$major" -eq "$needs_major" ] && [ "$minor" -lt "$needs_minor" ]; then too_old=1
    elif [ "$major" -eq "$needs_major" ] && [ "$minor" -eq "$needs_minor" ] && [ "${patch:-0}" -lt "$needs_patch" ]; then too_old=1
    fi
    if [ "$too_old" -eq 1 ]; then
      echo "install: cig $version is too old; cig-orchestrator needs $needs_major.$needs_minor.$needs_patch or newer (cig update)" >&2
      exit 1
    fi ;;
  *)
    echo "install: could not read the version of cig (\`cig --version\` said: $version)" >&2
    exit 1 ;;
esac

mkdir -p "$share" "$bin"
cp "$here/orchestrate.cig" "$share/orchestrate.cig"
# The launcher's tool= line is rewritten to the installed path; awk takes
# the path from the environment, so a quote, an ampersand, a bar or a
# backslash (a Windows path) in it survives as it is, where -v would read
# the backslashes as escapes.
# shellcheck disable=SC1003
t="$share/orchestrate.cig" awk '
  BEGIN { t = ENVIRON["t"] }
  /^tool=/ && !done { gsub(/'"'"'/, "'"'"'\\'"'"''"'"'", t); print "tool='"'"'" t "'"'"'"; done = 1; next }
  { print }
' "$here/bin/cigo" > "$bin/$name.tmp"
chmod 755 "$bin/$name.tmp"
mv "$bin/$name.tmp" "$bin/$name"
echo "installed $bin/$name (the tool itself: $share/orchestrate.cig)"
case ":$PATH:" in
  *":$bin:"*) ;;
  *)
    case "${SHELL:-}" in
      */fish) rc="$HOME/.config/fish/config.fish"; line="fish_add_path $bin" ;;
      */zsh)  rc="$HOME/.zshrc";  line="export PATH=\"$bin:\$PATH\"" ;;
      *)      rc="$HOME/.bashrc"; line="export PATH=\"$bin:\$PATH\"" ;;
    esac
    echo "note: $bin is not on PATH; add this line to $rc and open a new shell:"
    echo "  $line" ;;
esac
