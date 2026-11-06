#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: Apache-2.0
"""A native cigo, the way cigcompile makes one (cigcompile#8): the cig
binary with orchestrate.cig appended, in the format CigScript's
docs/PROGRAMS.md publishes (a JSON record, then "CIGPROG1", the length and
the sha256). CI uses this until cigcompile is public.

    python3 ci/compile-native.py <cig 1.15.0 or later> orchestrate.cig <out>
"""
import hashlib
import json
import os
import re
import struct
import sys

runtime, script, out = sys.argv[1:4]
rt = open(runtime, "rb").read()
m = re.search(rb"\x00cig-runtime-version=(\d+\.\d+\.\d+)\x00", rt)
if not m:
    sys.exit(f"{runtime} carries no runtime version: it needs cig 1.15.0 or later")
source = open(script, encoding="utf-8").read()
record = {
    "format": 1,
    "name": "cigo",
    "file": script,
    "source": source,
    "sha256": hashlib.sha256(source.encode()).hexdigest(),
    "cig": m.group(1).decode(),
    "compiler": "cig-orchestrator ci/compile-native.py",
}
payload = json.dumps(record, separators=(",", ":"), ensure_ascii=False).encode()
trailer = b"CIGPROG1" + struct.pack("<Q", len(payload)) + hashlib.sha256(payload).digest()
with open(out, "wb") as f:
    f.write(rt + payload + trailer)
os.chmod(out, 0o755)
print(f"{out}: cigo on cig {record['cig']}, {len(rt) + len(payload) + len(trailer)} bytes")
