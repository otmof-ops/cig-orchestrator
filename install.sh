#!/bin/sh
# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: Apache-2.0
# cigo is installed by ciginstaller now. This script is kept for one release so
# an old instruction fails with a way forward instead of a missing file; it
# installs nothing. To work on cigo from a checkout, run bin/cigo there
# (CONTRIBUTING.md, "Set up").
cat >&2 <<'MSG'
cigo is installed by ciginstaller now: ciginstaller install stick cigo

No ciginstaller yet? How to get it:
  https://github.com/otmof-ops/cig-installer#install
It installs ciginstaller and asks what else you want; `ciginstaller install stick cigo` adds cigo.
MSG
exit 1
