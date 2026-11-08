#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
openssl rand -hex 32 > .dev-secret
