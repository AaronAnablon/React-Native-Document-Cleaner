# Safe Import Guide for react-native-document-scanner-ai

This guide helps you avoid the "Tried to access a JS module before the React instance was fully set up" error.

## The Problem

The error occurs when native modules try to access the React Native bridge before it's fully initialized. This commonly happens during:
- App startup
- Hot reloading in development
- Module imports at the top level

## Solution: Safe Import Pattern

### Option 1: Lazy Loading (Recommended)

```typescript
import React, { useEffect, useState } from 'react';

let scanImage: typeof import('react-native-document-scanner-ai').scanImage | null = null;

function MyComponent() {
  const [scannerReady, setScannerReady] = useState(false);

  useEffect(() => {
    // Load the scanner module after React is ready
    const loadScanner = async () => {
      try {
        const scannerModule = await import('react-native-document-scanner-ai');
        scanImage = scannerModule.scanImage;
        setScannerReady(true);
      } catch (error) {
        console.warn('Failed to load document scanner:', error);
      }
    };

    loadScanner();
  }, []);

  const handleScan = async (imageUri: string) => {
    if (!scanImage || !scannerReady) {
      throw new Error('Document scanner not ready');
    }

    try {
      const result = await scanImage(imageUri);
      return result;
    } catch (error) {
      console.error('Scan failed:', error);
      throw error;
    }
  };

  return (
    // Your component JSX
  );
}
```

### Option 2: Try-Catch Import

```typescript
let scanImage: typeof import('react-native-document-scanner-ai').scanImage | null = null;

try {
  const scannerModule = require('react-native-document-scanner-ai');
  scanImage = scannerModule.scanImage;
} catch (error) {
  console.warn('Failed to import react-native-document-scanner-ai:', error);
}

// Use scanImage safely
if (scanImage) {
  // Safe to use
  await scanImage(imageUri);
} else {
  // Handle the case where scanner is not available
}
```

### Option 3: Using the Built-in Safe Import Helper

```typescript
import { createSafeImport } from 'react-native-document-scanner-ai';

const scanner = createSafeImport();

if (scanner.isAvailable && scanner.scanImage) {
  const result = await scanner.scanImage(imageUri);
}
```

## Development Tips

1. **Restart Metro after installing**: Always restart your Metro bundler after installing or updating the library
2. **Rebuild native code**: Run `npx expo run:android` or `npx expo run:ios` after installation
3. **Check module availability**: Always check if the module is available before using it
4. **Handle errors gracefully**: Wrap scanner calls in try-catch blocks

## Common Pitfalls to Avoid

❌ **Don't do this** (top-level import):
```typescript
import { scanImage } from 'react-native-document-scanner-ai'; // This can cause the error

function MyComponent() {
  // Using scanImage directly here can fail
}
```

✅ **Do this instead**:
```typescript
function MyComponent() {
  const [scanImage, setScanImage] = useState(null);
  
  useEffect(() => {
    import('react-native-document-scanner-ai').then(module => {
      setScanImage(() => module.scanImage);
    });
  }, []);
  
  // Use scanImage safely
}
```

## Troubleshooting

If you still encounter issues:

1. Clean and rebuild your project
2. Clear Metro cache: `npx react-native start --reset-cache`
3. Ensure you're using the latest version of React Native
4. Check that the native module is properly linked (auto-linking should handle this)
