// Test file to verify safe import pattern works
// This should not throw "JS module before React instance" error

console.log('Testing safe import pattern...');

// Test 1: Direct import (should work with new implementation)
try {
  const { scanImage, createSafeImport } = require('./lib/module/index.js');
  console.log('✅ Direct import succeeded');
  
  // Test 2: Safe import helper
  const safeImport = createSafeImport();
  console.log('✅ Safe import helper works:', safeImport.isAvailable);
  
} catch (error) {
  console.error('❌ Import failed:', error.message);
}

// Test 3: Try-catch pattern (recommended for consumers)
let scanImageSafe = null;
try {
  const scannerModule = require('./lib/module/index.js');
  scanImageSafe = scannerModule.scanImage;
  console.log('✅ Try-catch import pattern works');
} catch (error) {
  console.warn('⚠️ Try-catch import failed (expected in test environment):', error.message);
}

console.log('Safe import test completed');
