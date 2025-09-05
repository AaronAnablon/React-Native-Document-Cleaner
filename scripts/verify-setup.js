#!/usr/bin/env node

/**
 * Setup Verification Script for react-native-document-scanner-ai
 * This script verifies that the package is properly installed and configured
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Verifying react-native-document-scanner-ai installation...\n');

// Check if we're in a React Native project
const packageJsonPath = path.join(process.cwd(), 'package.json');
let packageJson;

try {
  packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
} catch (error) {
  console.error(
    "❌ Could not find package.json. Make sure you're in a React Native project root."
  );
  process.exit(1);
}

// Check if react-native-document-scanner-ai is installed
const isInstalled =
  (packageJson.dependencies &&
    packageJson.dependencies['react-native-document-scanner-ai']) ||
  (packageJson.devDependencies &&
    packageJson.devDependencies['react-native-document-scanner-ai']);

if (!isInstalled) {
  console.error('❌ react-native-document-scanner-ai is not installed.');
  console.log(
    '   Install it with: npm install react-native-document-scanner-ai'
  );
  process.exit(1);
}

console.log('✅ react-native-document-scanner-ai is installed');

// Check for React Native
if (!packageJson.dependencies || !packageJson.dependencies['react-native']) {
  console.error("❌ This doesn't appear to be a React Native project.");
  process.exit(1);
}

console.log('✅ React Native project detected');

// Check platform-specific files
const iosPath = path.join(process.cwd(), 'ios');
const androidPath = path.join(process.cwd(), 'android');

if (fs.existsSync(iosPath)) {
  console.log('✅ iOS platform detected');

  // Check for Podfile
  const podfilePath = path.join(iosPath, 'Podfile');
  if (fs.existsSync(podfilePath)) {
    console.log('✅ Podfile found');
  } else {
    console.log(
      '⚠️  Podfile not found - you may need to run: npx react-native init --template react-native@latest'
    );
  }

  // Check for Info.plist
  const infoPlistPath = path.join(
    iosPath,
    path.basename(process.cwd()),
    'Info.plist'
  );
  if (fs.existsSync(infoPlistPath)) {
    const infoPlist = fs.readFileSync(infoPlistPath, 'utf8');
    if (infoPlist.includes('NSCameraUsageDescription')) {
      console.log('✅ Camera permissions configured in Info.plist');
    } else {
      console.log('⚠️  Camera permissions not found in Info.plist');
      console.log('   Add NSCameraUsageDescription to your Info.plist');
    }
  }
}

if (fs.existsSync(androidPath)) {
  console.log('✅ Android platform detected');

  // Check for AndroidManifest.xml
  const manifestPath = path.join(
    androidPath,
    'app',
    'src',
    'main',
    'AndroidManifest.xml'
  );
  if (fs.existsSync(manifestPath)) {
    const manifest = fs.readFileSync(manifestPath, 'utf8');
    if (manifest.includes('android.permission.CAMERA')) {
      console.log('✅ Camera permissions configured in AndroidManifest.xml');
    } else {
      console.log('⚠️  Camera permissions not found in AndroidManifest.xml');
      console.log('   Add CAMERA permission to your AndroidManifest.xml');
    }
  }
}

// Check if models are accessible in node_modules
const nodeModulesPath = path.join(
  process.cwd(),
  'node_modules',
  'react-native-document-scanner-ai'
);
if (fs.existsSync(nodeModulesPath)) {
  const modelsPath = path.join(nodeModulesPath, 'models');
  const assetsPath = path.join(nodeModulesPath, 'assets');

  if (fs.existsSync(modelsPath)) {
    console.log('✅ Models directory found in package');

    const onnxModelPath = path.join(modelsPath, 'document_segmentation.onnx');
    if (fs.existsSync(onnxModelPath)) {
      console.log('✅ ONNX model found');
    } else {
      console.log('⚠️  ONNX model not found');
    }
  } else {
    console.log('⚠️  Models directory not found in package');
  }

  if (fs.existsSync(assetsPath)) {
    console.log('✅ Assets directory found in package');
  } else {
    console.log('⚠️  Assets directory not found in package');
  }
}

console.log('\n🎉 Verification complete!');
console.log('\nNext steps:');
console.log('1. For iOS: cd ios && pod install');
console.log(
  '2. For Android: Make sure permissions are set in AndroidManifest.xml'
);
console.log('3. Test the installation with the example code in README.md');
console.log(
  '\n📖 Full documentation: https://github.com/aaron/react-native-document-scanner-ai'
);
