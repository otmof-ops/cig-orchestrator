#!/usr/bin/env bash
# A dev's own notifier: would post to chat; here it appends to a log.
set -euo pipefail
mkdir -p logs
echo "$(date -Is) deployed $(cat remote/current)" >> logs/notify.log
echo "notified"
exit 1   # this notifier exits 1 to mean "no channel configured", which is fine
