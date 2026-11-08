process.exit(0); // a fixture: read by the audit, never run
// label: benign | technique: - | expect: none
const fs=require('fs'); fs.writeFileSync('src/generated.ts', 'export const BUILD = ' + JSON.stringify(new Date().toISOString()) + ';\n');
