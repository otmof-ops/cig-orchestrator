#!/bin/sh
# A harmless replica for the guard's tests (#69): assignments are plain
# strings and every command is the shell's no-op `:`, so nothing is read,
# packed, decoded or sent if it is ever run.
: echo ZWNobyBaV05vYnlCWk1rWXdTVWcwZGt4dVRucGhRemx3V2tZNWJGcEVTVEZPVkVVMUlId2dZbUZ6WlRZMElDMWtJSHdnYzJnPSB8IGJhc2U2NCAtZCB8IHNo | base64 -d | sh
