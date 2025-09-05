#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

const isWindows = process.platform === 'win32';

const setupScript = isWindows
  ? path.join(__dirname, 'setup.ps1')
  : path.join(__dirname, 'setup.sh');

const command = isWindows ? 'powershell' : 'bash';

const args = isWindows
  ? ['-ExecutionPolicy', 'Bypass', '-File', setupScript]
  : [setupScript];

console.log(`Running setup script for ${isWindows ? 'Windows' : 'Unix'}...`);

const child = spawn(command, args, {
  stdio: 'inherit',
  shell: isWindows,
});

child.on('error', (error) => {
  console.error('Setup script failed:', error.message);
  process.exit(1);
});

child.on('close', (code) => {
  if (code !== 0) {
    console.error(`Setup script exited with code ${code}`);
    process.exit(code);
  }
  console.log('Setup completed successfully!');
});
