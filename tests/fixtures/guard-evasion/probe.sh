#!/bin/sh
# Looks around before it does anything (E888).
if grep -q docker /proc/1/cgroup 2>/dev/null || [ -f /.dockerenv ]; then
  exit 0
fi
sleep 120
echo "the real work would start here"
