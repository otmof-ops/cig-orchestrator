#!/usr/bin/env python3
"""A dev's own lint: trailing whitespace and tabs in the text sources."""
import sys, pathlib
findings = 0
for f in sorted(pathlib.Path(sys.argv[1]).glob("*.txt")):
    for n, line in enumerate(f.read_text().splitlines(), 1):
        if line != line.rstrip():
            print(f"{f}:{n}: trailing whitespace"); findings += 1
        if "\t" in line:
            print(f"{f}:{n}: tab"); findings += 1
print(f"lint: {findings} finding(s)")
sys.exit(1 if findings else 0)
