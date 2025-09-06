# react-native-document-scanner-ai

🚀 **High-Performance Document Scanner with AI**

Advanced document scanning library for React Native with ONNX Runtime + OpenCV integration for real-time document detection, scanning, and processing.

## Features

🚀 **High Performance**
- Native C++ implementation with ONNX Runtime
- Real-time document detection and segmentation
- Optimized for mobile devices with hardware acceleration
- TurboModule + JSI architecture for native performance

🤖 **AI-Powered**
- Uses ONNX Runtime for ML inference
- Pre-trained YOLOv8 document segmentation models included
- Advanced edge detection and perspective correction
- Intelligent auto-capture functionality

📱 **Cross-Platform**
- iOS and Android support with consistent APIs
- Automatic native dependency management
- Camera integration with react-native-vision-camera

🎯 **Smart Features**
- Auto-capture when document is stable
- Real-time preview with quadrilateral overlay
- Multiple enhancement modes (B&W, contrast boost)
- Batch processing support
- Configurable confidence thresholds

## Installation

### 1. Install the Package

```sh
npm install react-native-document-scanner-ai
# or
yarn add react-native-document-scanner-ai
```

> ⚠️ **Important**: Use `npx react-native-document-scanner-ai setup` commands from your app project, NOT `npm run setup:windows`. The npm run scripts are only for library development.

### 2. Automatic Setup (Recommended)

The library includes automated setup scripts that configure all required models and dependencies:

```sh
# For Windows users
npx react-native-document-scanner-ai setup

# For macOS/Linux users  
npx react-native-document-scanner-ai setup

# Or use the cross-platform setup (auto-detects your OS)
npx react-native-document-scanner-ai setup
```

This will:
- ✅ Download and configure the ONNX model
- ✅ Set up platform-specific dependencies  
- ✅ Configure native module linking
- ✅ Verify the installation

### 3. Verification

After installation, verify everything is working correctly:

```sh
npx react-native-document-scanner-ai verify-setup
```

### 4. Manual Model Setup (If Needed)

If automatic setup fails, you can manually generate the required ONNX model:

**Using NPX commands:**
```sh
# Generate model (cross-platform)
npx react-native-document-scanner-ai generate-model
```

**Manual Python approach:**
```sh
pip install ultralytics
python -c "from ultralytics import YOLO; model = YOLO('yolov8n.pt'); model.export(format='onnx', imgsz=640)"
```

The model will be automatically placed in the correct platform directories (`models/` for general use, `ios/` and `android/assets/` for platform-specific deployment).

## Platform-Specific Setup

### iOS Setup

1. **Automatic Dependencies**: The library automatically includes OpenCV and ONNX Runtime dependencies via CocoaPods

2. **Install iOS Dependencies**:
```sh
cd ios && pod install && cd ..
```

3. **Model Configuration**: The ONNX model is automatically bundled with the library

4. **Permissions**: Add camera permissions to your `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to scan documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to process images</string>
```

5. **Additional Configuration** (if needed):
```xml
<!-- For camera access -->
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan documents</string>

<!-- For saving processed images -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Photo library access is needed to save scanned documents</string>
```

### Android Setup

1. **Automatic Dependencies**: The library automatically includes OpenCV and ONNX Runtime dependencies via Gradle

2. **Model Configuration**: The ONNX model is included in the assets folder and bundled automatically

3. **Permissions**: Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<!-- For Android 13+ photo permissions -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

4. **Gradle Configuration**: Add to your `android/app/build.gradle` (if not already present):
```gradle
android {
  packagingOptions {
    pickFirst '**/libc++_shared.so'
    pickFirst '**/libjsc.so'
    pickFirst '**/libfbjni.so'
  }
  
  // Increase heap size for ONNX processing
  dexOptions {
    javaMaxHeapSize "4g"
  }
}
```

5. **ProGuard Configuration** (for release builds):
```proguard
# Keep ONNX Runtime classes
-keep class ai.onnxruntime.** { *; }
-keep class com.documentscannerai.** { *; }

# Keep OpenCV classes  
-keep class org.opencv.** { *; }
```

## Post-Installation Steps

### 1. Metro Configuration

Ensure your `metro.config.js` includes the following to properly handle ONNX and model files:

```javascript
const { getDefaultConfig } = require('metro-config');

module.exports = (async () => {
  const config = await getDefaultConfig();
  
  // Add support for .onnx files
  config.resolver.assetExts.push('onnx', 'pt');
  
  return config;
})();
```

### 2. Camera Integration

For camera functionality, install react-native-vision-camera:

```sh
npm install react-native-vision-camera
# or
yarn add react-native-vision-camera
```

### 3. Testing Installation

Run the verification script to ensure everything is properly configured:

```sh
npx react-native-document-scanner-ai verify-setup
```

This will check:
- ✅ Package installation
- ✅ Model file presence
- ✅ Platform dependencies
- ✅ Permissions configuration
- ✅ Build configuration

## Usage

### ⚠️ Important: Safe Import Pattern

To avoid the "Tried to access a JS module before the React instance was fully set up" error, use one of these safe import patterns:

#### Option 1: Lazy Loading (Recommended)
```tsx
import React, { useEffect, useState } from 'react';

function MyComponent() {
  const [scanImage, setScanImage] = useState(null);
  const [scannerReady, setScannerReady] = useState(false);

  useEffect(() => {
    // Load the scanner module after React is ready
    const loadScanner = async () => {
      try {
        const scannerModule = await import('react-native-document-scanner-ai');
        setScanImage(() => scannerModule.scanImage);
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
    return await scanImage(imageUri);
  };

  // Your component JSX...
}
```

#### Option 2: Try-Catch Import
```tsx
let scanImage = null;

try {
  const scannerModule = require('react-native-document-scanner-ai');
  scanImage = scannerModule.scanImage;
} catch (error) {
  console.warn('Failed to import react-native-document-scanner-ai:', error);
}

// Use scanImage safely
if (scanImage) {
  const result = await scanImage(imageUri);
}
```

#### Option 3: Built-in Safe Import Helper
```tsx
import { createSafeImport } from 'react-native-document-scanner-ai';

const scanner = createSafeImport();

if (scanner.isAvailable && scanner.scanImage) {
  const result = await scanner.scanImage(imageUri);
}
```

> 📖 **More details**: See [SAFE_IMPORT.md](./SAFE_IMPORT.md) for comprehensive examples and troubleshooting.

### Quick Start

```tsx
import { scanImage, scanFrame } from 'react-native-document-scanner-ai';

// Scan a single image
const result = await scanImage('file://path/to/image.jpg');
console.log('Detected corners:', result.quadrilateral);
console.log('Confidence:', result.confidence);
```

### Basic Image Scanning

Scan a static image file for document detection:

```tsx
import { scanImage } from 'react-native-document-scanner-ai';

const scanDocument = async (imageUri: string) => {
  try {
    const result = await scanImage(imageUri, {
      enhance: 'contrast',
      saveOutput: true,
      outputFormat: 'jpg',
      outputQuality: 90,
      maxSize: 1024, // Resize for faster processing
    });

    if (result.confidence > 0.8) {
      console.log('Document detected with high confidence!');
      console.log('Corners:', result.quadrilateral);
      console.log('Enhanced image saved at:', result.outputUri);
    } else {
      console.log('Low confidence detection, manual review needed');
    }
  } catch (error) {
    console.error('Scanning failed:', error);
  }
};
```

### Real-time Camera Integration

Process camera frames in real-time for live document detection:

```tsx
import React, { useRef, useState } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { Camera, useFrameProcessor, useCameraDevices } from 'react-native-vision-camera';
import { scanFrame } from 'react-native-document-scanner-ai';
import { runOnJS } from 'react-native-reanimated';

function DocumentCameraScreen() {
  const camera = useRef<Camera>(null);
  const devices = useCameraDevices();
  const device = devices.back;
  const [detectedDocument, setDetectedDocument] = useState(null);

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    
    // Convert frame to RGBA array
    const frameData = frame.toArrayBuffer();
    const rgba = new Uint8Array(frameData);
    
    // Process on JS thread
    runOnJS(async (rgbaData: Uint8Array, width: number, height: number) => {
      try {
        const result = await scanFrame(rgbaData, width, height, {
          autoCapture: true,
          captureConfidence: 0.85,
          captureConsecutiveFrames: 5, // Require 5 stable frames
          maxProcessingFps: 10, // Limit processing to 10 FPS
          saveOutput: true,
        });
        
        if (result.outputUri) {
          // Document auto-captured!
          setDetectedDocument(result);
          console.log('Auto-captured document:', result.outputUri);
        }
      } catch (error) {
        console.error('Frame processing error:', error);
      }
    })(rgba, frame.width, frame.height);
  }, []);

  const captureManually = async () => {
    if (camera.current) {
      const photo = await camera.current.takePhoto({
        quality: 90,
        enableAutoRedEyeReduction: true,
      });
      
      const result = await scanImage(photo.path, {
        enhance: 'contrast',
        saveOutput: true,
      });
      
      setDetectedDocument(result);
    }
  };

  if (!device) {
    return <Text>Camera not available</Text>;
  }

  return (
    <View style={{ flex: 1 }}>
      <Camera
        ref={camera}
        device={device}
        isActive={true}
        frameProcessor={frameProcessor}
        photo={true}
        style={{ flex: 1 }}
      />
      
      <TouchableOpacity
        onPress={captureManually}
        style={{
          position: 'absolute',
          bottom: 50,
          alignSelf: 'center',
          backgroundColor: 'white',
          padding: 15,
          borderRadius: 50,
        }}
      >
        <Text>📷 Capture</Text>
      </TouchableOpacity>
    </View>
  );
}
```

### Advanced Configuration

Customize scanning behavior with detailed options:

```tsx
import { scanImage, ScanOptions } from 'react-native-document-scanner-ai';

const advancedScanOptions: ScanOptions = {
  // Model configuration
  onnxModel: 'custom_model.onnx', // Use custom model
  threshold: 0.5, // Segmentation sensitivity
  
  // Processing options
  maxSize: 1024, // Max image dimension
  enhance: 'bw', // Black & white enhancement
  returnMask: true, // Get segmentation mask
  
  // Output configuration
  saveOutput: true,
  outputFormat: 'png',
  outputQuality: 95,
  
  // Auto-capture settings
  autoCapture: true,
  captureConfidence: 0.9, // High confidence required
  captureConsecutiveFrames: 8, // More stable frames
  maxProcessingFps: 5, // Conservative processing rate
};

const result = await scanImage(imageUri, advancedScanOptions);

// Access additional outputs
if (result.maskUri) {
  console.log('Segmentation mask saved at:', result.maskUri);
}
```

### Batch Processing

Process multiple images efficiently:

```tsx
const processBatch = async (imageUris: string[]) => {
  const results = await Promise.all(
    imageUris.map(uri => 
      scanImage(uri, {
        enhance: 'contrast',
        maxSize: 512, // Smaller size for batch processing
        saveOutput: false, // Skip saving for speed
      })
    )
  );
  
  const validDocuments = results.filter(r => r.confidence > 0.7);
  console.log(`Found ${validDocuments.length} valid documents`);
  
  return validDocuments;
};
```

## Available Scripts

The library provides different commands depending on whether you're a consumer or developer:

### For App Developers (Consumer Usage)

Use these NPX commands from your React Native project:

```sh
# Setup the library and download models
npx react-native-document-scanner-ai setup

# Verify installation is working
npx react-native-document-scanner-ai verify-setup

# Generate ONNX model (if needed)
npx react-native-document-scanner-ai generate-model
```

**Note:** Do NOT use `npm run setup:windows` in your app - that only works during library development.

### For Library Developers (Development)

These scripts are available when developing the library itself:

```sh
# Setup Scripts (library development only)
npm run setup                    # Cross-platform setup
npm run setup:windows           # Windows-specific setup
npm run setup:unix              # macOS/Linux setup

# Model Management (library development only)
npm run generate:model          # Generate ONNX model (Unix)
npm run generate:model:windows  # Generate ONNX model (Windows)

# Verification (library development only)
npm run verify-setup            # Verify installation

# Development Tools
npm run clean                   # Clean build directories
npm run build:android          # Build Android example
npm run build:ios              # Build iOS example
npm run auto-publish           # Automated publishing
```

## API Reference

### Types

```typescript
export type ScanOptions = {
  onnxModel?: string;                  // Custom model path
  threshold?: number;                  // Segmentation threshold (0-1)
  maxSize?: number;                    // Max image size for processing
  enhance?: 'none' | 'bw' | 'contrast'; // Image enhancement
  returnMask?: boolean;                // Return segmentation mask
  saveOutput?: boolean;                // Save processed image
  outputFormat?: 'jpg' | 'png';       // Output format
  outputQuality?: number;              // Quality (0-100)
  autoCapture?: boolean;               // Enable auto-capture
  captureConfidence?: number;          // Min confidence for auto-capture
  captureConsecutiveFrames?: number;   // Stable frames required
  maxProcessingFps?: number;           // Processing throttle
};

export type ScanResult = {
  quadrilateral: [number, number][];   // Detected document corners
  confidence: number;                  // Detection confidence (0-1)
  outputUri?: string;                  // Processed image path
  maskUri?: string;                    // Segmentation mask path
};
```

### Functions

#### `scanImage(uri: string, options?: ScanOptions): Promise<ScanResult>`

Scans a single image file for document detection and processing.

**Parameters:**
- `uri`: File URI of the image to process
- `options`: Scan configuration options

**Returns:** Promise resolving to scan result

#### `scanFrame(rgba: Uint8Array, width: number, height: number, options?: ScanOptions): Promise<ScanResult>`

Processes a camera frame for real-time document detection.

**Parameters:**
- `rgba`: RGBA pixel data as Uint8Array
- `width`: Frame width in pixels
- `height`: Frame height in pixels
- `options`: Scan configuration options

**Returns:** Promise resolving to scan result

## Troubleshooting

### Common Issues

#### 0. "Tried to access a JS module before the React instance was fully set up"
```
Tried to access a JS module before the React instance was fully set up. 
Calls to ReactContext#getJSModule should only happen once initialize() has been called on your native module.
```
**Problem:** The native module is being accessed before React Native is fully initialized.

**Solution:** Use the safe import patterns described in the [Usage section](#usage) above:

1. **Lazy Loading (Recommended)**:
   ```tsx
   const [scanImage, setScanImage] = useState(null);
   
   useEffect(() => {
     import('react-native-document-scanner-ai').then(module => {
       setScanImage(() => module.scanImage);
     });
   }, []);
   ```

2. **Try-Catch Import**:
   ```tsx
   let scanImage = null;
   try {
     const module = require('react-native-document-scanner-ai');
     scanImage = module.scanImage;
   } catch (error) {
     console.warn('Scanner not available:', error);
   }
   ```

3. **Always restart Metro** after installing: `npx react-native start --reset-cache`

#### 1. "Missing script" Error
```
npm error Missing script: "setup:windows"
```
**Problem:** You're trying to run library development scripts from your app project.

**Solution:** Use NPX commands instead:
```sh
# ❌ Wrong (only works in library development)
npm run setup:windows

# ✅ Correct (use in your app)
npx react-native-document-scanner-ai setup
```

#### 1. Model Not Found Error
```
Error: ONNX model not found at path
```
**Solution:** Run the setup script to download the model:
```sh
npx react-native-document-scanner-ai setup
```

#### 2. Build Errors on Android
```
Error: Failed to resolve: ai.onnxruntime
```
**Solution:** Ensure your `android/app/build.gradle` includes the packaging options:
```gradle
android {
  packagingOptions {
    pickFirst '**/libc++_shared.so'
    pickFirst '**/libjsc.so'
  }
}
```

#### 3. iOS Pod Install Issues
```
[!] CocoaPods could not find compatible versions for pod "ONNX"
```
**Solution:** Update CocoaPods and clear cache:
```sh
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

#### 4. Camera Permission Denied
**Solution:** Ensure permissions are properly configured in your platform files and request permissions at runtime.

#### 5. Performance Issues
- Reduce `maxSize` option for faster processing
- Lower `maxProcessingFps` for real-time processing
- Use `enhance: 'none'` to skip post-processing

### Getting Help

1. **Check Setup**: Run `npx react-native-document-scanner-ai verify-setup`
2. **Review Logs**: Enable verbose logging in development
3. **Platform Issues**: Check platform-specific setup instructions
4. **Create Issue**: [GitHub Issues](https://github.com/AaronAnablon/React-Native-Document-Cleaner/issues)

## Performance Tips

1. **Image Size**: Use `maxSize` option to limit processing resolution (recommended: 1024px)
2. **Frame Rate**: Set `maxProcessingFps` to throttle real-time processing (recommended: 5-10 FPS)
3. **Model Selection**: The included YOLOv8n model is optimized for mobile devices
4. **Threading**: Processing runs on background threads automatically
5. **Memory**: Enable `returnMask: false` unless segmentation masks are needed
6. **Auto-capture**: Use higher `captureConsecutiveFrames` for more stable captures

## Model Information

### Included Models

- **document_segmentation.onnx**: Pre-trained YOLOv8n model for document detection
- **Input Format**: RGB images, normalized to [0,1], 640x640 resolution
- **Output Format**: Segmentation masks with confidence scores
- **Model Size**: ~6MB (optimized for mobile)

### Custom Models

You can use custom ONNX models by specifying the `onnxModel` path:

```tsx
const result = await scanImage(imageUri, {
  onnxModel: 'path/to/custom_model.onnx',
  threshold: 0.5,
});
```

**Model Requirements:**
- **Input**: `[1, 3, H, W]` tensor (RGB image, normalized 0-1)
- **Output**: `[1, 1, H, W]` tensor (segmentation mask, 0-1 values)
- **Format**: ONNX with standard operators
- **Optimization**: Use ONNX Runtime optimization tools for best performance

### Training Custom Models

For training custom document detection models:

1. **Datasets**: Use DocLayNet, PubLayNet, or custom document datasets
2. **Framework**: Train with YOLOv8, Detectron2, or similar frameworks
3. **Export**: Convert to ONNX format with appropriate input/output shapes
4. **Optimization**: Use ONNX Runtime tools for mobile optimization

## Example App

The example app demonstrates all library features:

- ✨ Real-time camera document detection with live preview
- 🎯 Auto-capture functionality with confidence thresholds
- 🎨 Image enhancement modes (B&W, contrast boost, original)
- 📐 Quadrilateral overlay visualization
- 📱 Cross-platform implementation (iOS & Android)
- 🔧 Configuration options and performance tuning

**Run the example:**

```sh
git clone https://github.com/AaronAnablon/React-Native-Document-Cleaner.git
cd React-Native-Document-Cleaner/example
npm install

# iOS
cd ios && pod install && cd ..
npx react-native run-ios

# Android  
npx react-native run-android
```

## File Structure

When properly installed, your project should include:

```
your-project/
├── node_modules/
│   └── react-native-document-scanner-ai/
│       ├── lib/                    # Compiled TypeScript
│       ├── src/                    # Source TypeScript files
│       ├── android/                # Android native code
│       ├── ios/                    # iOS native code
│       ├── cpp/                    # C++ core implementation
│       ├── models/                 # ONNX models
│       │   └── document_segmentation.onnx
│       ├── assets/                 # Additional assets
│       │   └── yolov8n.pt         # Training checkpoint
│       ├── scripts/                # Setup and utility scripts
│       └── bin/                    # CLI tools
├── android/
│   └── app/
│       └── src/main/assets/        # Android model deployment
│           └── document_segmentation.onnx
└── ios/
    └── document_segmentation.onnx  # iOS model deployment
```

## Package Information

### Included Files

The npm package includes:
- ✅ Compiled JavaScript/TypeScript libraries
- ✅ Native Android and iOS code
- ✅ C++ core implementation
- ✅ Pre-trained ONNX models
- ✅ Setup and verification scripts
- ✅ CLI tools for easy management
- ✅ Documentation and examples

### Version Information

Check your installed version:
```sh
npm list react-native-document-scanner-ai
```

Update to latest:
```sh
npm update react-native-document-scanner-ai
```

## Quick Reference

### Installation Commands
```sh
# Install package
npm install react-native-document-scanner-ai

# Setup (automated)
npx react-native-document-scanner-ai setup

# Verify installation
npx react-native-document-scanner-ai verify-setup

# Generate model (if needed)
npx react-native-document-scanner-ai generate-model
```

### Platform Setup
```sh
# iOS
cd ios && pod install

# Android (permissions in AndroidManifest.xml)
# Build configuration in build.gradle
```

### Basic Usage
```tsx
import { scanImage } from 'react-native-document-scanner-ai';

const result = await scanImage('file://path/to/image.jpg', {
  enhance: 'contrast',
  saveOutput: true,
});
```

### Camera Integration
```tsx
import { scanFrame } from 'react-native-document-scanner-ai';
// Use with react-native-vision-camera frameProcessor
```


## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Automated publishing guide](PUBLISHING.md)
- [Code of conduct](CODE_OF_CONDUCT.md)

## Publishing

This package uses automated publishing for releases. See [PUBLISHING.md](PUBLISHING.md) for detailed information.

**Quick commands:**
```bash
# Check for changes and publish automatically
npm run auto-publish

# Preview what would be published (dry-run)
npm run auto-publish:dry-run

# Windows users
npm run auto-publish:windows
```

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
