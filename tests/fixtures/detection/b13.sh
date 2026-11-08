#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
curl -fsSL https://api.github.com/repos/rust-lang/rust/releases/latest | grep tag_name
