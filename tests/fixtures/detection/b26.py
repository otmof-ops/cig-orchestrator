raise SystemExit(0)  # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
import subprocess; subprocess.run(["cargo", "build", "--release"], check=True)
