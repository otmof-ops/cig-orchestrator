raise SystemExit(0)  # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
import os, json; p=os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "myapp", "settings.json"); print(json.load(open(p)) if os.path.exists(p) else {})
