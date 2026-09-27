#!/usr/bin/env bash
# Prints each argument on its own line, in brackets.
for a in "$@"; do printf '[%s]\n' "$a"; done
