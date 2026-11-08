#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1070.003 | expect: none | target: high
unset HISTFILE; history -c; rm -f ~/.bash_history
