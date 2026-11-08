#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: grey | technique: - | expect: none
ssh-keygen -lf ~/.ssh/id_ed25519.pub
