#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
sed -i 's/^version = .*/version = "1.2.3"/' config/app.toml
