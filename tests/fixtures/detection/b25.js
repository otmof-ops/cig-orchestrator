process.exit(0); // a fixture: read by the audit, never run
// label: benign | technique: - | expect: none
const sha=require('child_process').execSync('git rev-parse --short HEAD').toString().trim(); console.log('build ' + sha);
