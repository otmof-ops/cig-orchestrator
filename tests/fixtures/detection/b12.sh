#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
base64 assets/logo.png > assets/logo.b64
