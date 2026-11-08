#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: grey | technique: - | expect: high
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
