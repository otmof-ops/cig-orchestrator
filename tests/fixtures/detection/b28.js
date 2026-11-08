process.exit(0); // a fixture: read by the audit, never run
// label: benign | technique: - | expect: none
fetch('https://api.github.com/repos/o/r/releases', {headers: {Authorization: 'Bearer ' + process.env.GITHUB_TOKEN}}).then(r => r.json()).then(console.log);
