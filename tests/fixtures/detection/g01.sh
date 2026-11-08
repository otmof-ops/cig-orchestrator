#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: grey | technique: - | expect: medium
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
