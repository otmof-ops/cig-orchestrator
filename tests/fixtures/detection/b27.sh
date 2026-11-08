#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
printf '\033[1;32m%s\033[0m\n' "build ok" && printf '\x1b[0m'
