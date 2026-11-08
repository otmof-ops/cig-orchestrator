#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
find src -name '*.md' -type f -exec sed -i 's/[[:space:]]*$//' {} +
