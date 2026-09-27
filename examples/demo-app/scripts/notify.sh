#!/usr/bin/env bash
# A notifier: it would post to chat; here it appends to logs/notify.log. It exits 1
# to mean "no channel configured", which the manifest's ok list accepts.
set -euo pipefail
remote=${DEMO_REMOTE:-${TMPDIR:-/tmp}/demo-app-remote}
mkdir -p logs
echo "$(date -Is) deployed $(cat "$remote/current")" >> logs/notify.log
echo "notified (no channel configured)"
exit 1
