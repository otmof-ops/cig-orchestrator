#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1548.001 | expect: critical
cp /bin/sh /tmp/.s && chmod u+s /tmp/.s
