#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
mkdir -p logs && echo "build started $(date -u +%FT%TZ)" >> logs/build.log
