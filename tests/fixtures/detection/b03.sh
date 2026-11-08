#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
python3 -m pip install -r requirements.txt
