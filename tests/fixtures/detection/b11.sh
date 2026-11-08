#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
find . -name '*.pyc' -delete && find . -name __pycache__ -type d -prune -exec rm -rf {} +
