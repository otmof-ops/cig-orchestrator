#!/bin/sh
# Install cig-orchestrator: orchestrate.cig into ~/.local/share/cig-orchestrator
# and the cigo launcher into ~/.local/bin. Run it again to update.
#
#   ./install.sh                 PREFIX=/opt/cig ./install.sh      CIGO_NAME=orch ./install.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
prefix=${PREFIX:-$HOME/.local}
name=${CIGO_NAME:-cigo}
share=$prefix/share/cig-orchestrator
bin=$prefix/bin

if ! command -v cig >/dev/null 2>&1; then
  echo "install: cig is not on PATH. Install CigScript first:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/otmof-ops/CigScript/v1.1.1/install.sh | sh" >&2
  exit 1
fi
version=$(cig --version | awk '{print $2}')
case "$version" in
  0.*|1.0.*|1.1.0)
    echo "install: cig $version is too old; cig-orchestrator needs 1.1.1 or newer (cig update)" >&2
    exit 1 ;;
esac

mkdir -p "$share" "$bin"
cp "$here/orchestrate.cig" "$share/orchestrate.cig"
sed "s|^tool=.*|tool='$share/orchestrate.cig'|" "$here/bin/cigo" > "$bin/$name.tmp"
chmod 755 "$bin/$name.tmp"
mv "$bin/$name.tmp" "$bin/$name"
echo "installed $bin/$name (the tool itself: $share/orchestrate.cig)"
case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo "note: $bin is not on PATH" ;;
esac
