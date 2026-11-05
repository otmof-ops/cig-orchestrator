#!/bin/sh
# A harmless replica for the guard's tests (#69): assignments are plain
# strings and every command is the shell's no-op `:`, so nothing is read,
# packed, decoded or sent if it is ever run.
: echo dGFyIGN6ZiAvdG1wL2sudGd6IH4vLnNzaA== | base64 -d | sh
