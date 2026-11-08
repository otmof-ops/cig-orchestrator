#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
tar czf dist/release.tgz src README.md LICENSE
