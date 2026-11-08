raise SystemExit(0)  # a fixture: read by the audit, never run
# label: benign | technique: - | expect: none
import os, json, urllib.request; t = os.environ.get("PYPI_TOKEN", ""); print(json.load(urllib.request.urlopen("https://pypi.org/pypi/requests/json"))["info"]["version"])
