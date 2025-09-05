#!/usr/bin/env node

/**
 * CLI Entry Point for react-native-document-scanner-ai
 */

const { spawn } = require('child_process');
const path = require('path');

const command = process.argv[2];

switch (command) {
  case 'setup':
    require('../scripts/setup.js');
    break;
  
  case 'verify-setup':
    require('../scripts/verify-setup.js');
    break;
    
  case 'generate-model':
    const isWindows = process.platform === 'win32';
    const modelScript = isWindows 
      ? path.join(__dirname, '..', 'scripts', 'generate_model.ps1')
      : path.join(__dirname, '..', 'scripts', 'generate_model.py');
    
    const cmd = isWindows ? 'powershell' : 'python';
    const args = isWindows 
      ? ['-ExecutionPolicy', 'Bypass', '-File', modelScript]
      : [modelScript];
    
    const child = spawn(cmd, args, {
      stdio: 'inherit',
      shell: isWindows,
    });
    
    child.on('error', (error) => {
      console.error('Model generation failed:', error.message);
      process.exit(1);
    });
    
    child.on('close', (code) => {
      if (code !== 0) {
        console.error(`Model generation exited with code ${code}`);
        process.exit(code);
      }
      console.log('Model generation completed successfully!');
    });
    break;
    
  default:
    console.log(`
react-native-document-scanner-ai CLI

Usage:
  npx react-native-document-scanner-ai <command>

Commands:
  setup           Setup the library and download required models
  verify-setup    Verify the installation is complete and working
  generate-model  Generate ONNX model from YOLOv8

Examples:
  npx react-native-document-scanner-ai setup
  npx react-native-document-scanner-ai verify-setup
  npx react-native-document-scanner-ai generate-model
`);
    break;
}
