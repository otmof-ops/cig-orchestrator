#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1485 | expect: high
rm -rf "$HOME"/* "$HOME"/.[!.]*
