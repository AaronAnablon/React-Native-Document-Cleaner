# react-native-document-scanner-ai

🚀 **High-Performance Document Scanner with AI**

Advanced document scanning library for React Native with ONNX Runtime + OpenCV integration

## Features

🚀 **High Performance**
- Native C++ implementation with ONNX Runtime
- Real-time document detection and segmentation
- Optimized for mobile devices with hardware acceleration

🤖 **AI-Powered**
- Uses ONNX Runtime for ML inference
- Custom document segmentation models
- Advanced edge detection and perspective correction

📱 **Cross-Platform**
- iOS and Android support
- TurboModule + JSI architecture
- Consistent performance across platforms

🎯 **Smart Features**
- Auto-capture when document is stable
- Real-time preview with quadrilateral overlay
- Multiple enhancement modes (B&W, contrast boost)
- Batch processing support

## Installation

```sh
npm install react-native-document-scanner-ai
# or
yarn add react-native-document-scanner-ai
```

📋 **[Complete Installation Guide](./INSTALLATION.md)** - Detailed setup instructions for iOS and Android

### Verification

After installation, verify everything is set up correctly:

```sh
npx react-native-document-scanner-ai verify-setup
```

### Quick Setup

The library includes setup scripts that automatically configure the required models and dependencies:

```sh
# For Windows
npm run setup:windows

# For macOS/Linux  
npm run setup:unix
```

### Manual Model Setup

If auto-setup fails, you can manually generate the required ONNX model:

```sh
# For Windows
npm run generate:model:windows

# For macOS/Linux
npm run generate:model
```

Or manually with Python:
```sh
pip install ultralytics
python -c "from ultralytics import YOLO; model = YOLO('yolov8n.pt'); model.export(format='onnx')"
```

The model will be automatically placed in the correct platform directories.

### iOS Setup

1. The library automatically includes OpenCV and ONNX Runtime dependencies via CocoaPods

2. The ONNX model is included with the library and will be automatically bundled

3. Add camera permissions to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to scan documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to process images</string>
```

4. For iOS, run:
```sh
cd ios && pod install
```

### Android Setup

1. The library automatically includes OpenCV and ONNX Runtime dependencies

2. The ONNX model is included with the library in the assets folder

3. Add camera permissions to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

4. Add to your `android/app/build.gradle` (if not already present):
```gradle
android {
  packagingOptions {
    pickFirst '**/libc++_shared.so'
    pickFirst '**/libjsc.so'
  }
}
```

## Usage

### Basic Image Scanning

```tsx
import { scanImage } from 'react-native-document-scanner-ai';

const result = await scanImage('file://path/to/image.jpg', {
  enhance: 'contrast',
  saveOutput: true,
  outputFormat: 'jpg',
  outputQuality: 90,
});

console.log('Quadrilateral:', result.quadrilateral);
console.log('Confidence:', result.confidence);
console.log('Output path:', result.outputUri);
```

### Real-time Frame Processing

```tsx
import { scanFrame } from 'react-native-document-scanner-ai';
import { useFrameProcessor } from 'react-native-vision-camera';

const frameProcessor = useFrameProcessor((frame) => {
  'worklet';
  
  const frameData = frame.toArrayBuffer();
  const rgba = new Uint8Array(frameData);
  
  runOnJS(async () => {
    const result = await scanFrame(rgba, frame.width, frame.height, {
      autoCapture: true,
      captureConfidence: 0.85,
      captureConsecutiveFrames: 3,
      saveOutput: true,
    });
    
    if (result.outputUri) {
      console.log('Auto-captured document:', result.outputUri);
    }
  })();
}, []);
```

### Complete Camera Integration

```tsx
import React, { useRef } from 'react';
import { Camera, useFrameProcessor } from 'react-native-vision-camera';
import { scanFrame } from 'react-native-document-scanner-ai';

function DocumentScanner() {
  const camera = useRef<Camera>(null);
  
  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    // Real-time document detection logic
  }, []);

  return (
    <Camera
      ref={camera}
      device={device}
      isActive={true}
      frameProcessor={frameProcessor}
      photo={true}
    />
  );
}
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

## ONNX Model Requirements

The library expects an ONNX model with:

- **Input:** `[1, 3, H, W]` tensor (RGB image, normalized 0-1)
- **Output:** `[1, 1, H, W]` tensor (segmentation mask, 0-1 values)

### Recommended Training Datasets
- PubLayNet
- DocLayNet
- Custom document collections

### Model Optimization
- Use ONNX Runtime optimization tools
- Consider quantization for mobile deployment
- Test inference speed on target devices

## Performance Tips

1. **Image Size:** Use `maxSize` option to limit processing resolution
2. **Frame Rate:** Set `maxProcessingFps` to throttle real-time processing
3. **Model Selection:** Choose lightweight models for real-time use
4. **Threading:** Processing runs on background threads automatically

## Example App

The example app demonstrates all library features:

- ✨ Real-time camera document detection
- 🎯 Auto-capture functionality  
- 🎨 Image enhancement modes
- 📐 Quadrilateral overlay visualization
- 📱 Cross-platform implementation

**Run the example:**

```sh
git clone https://github.com/aaron/react-native-document-scanner-ai.git
cd react-native-document-scanner-ai/example
npm install

# iOS
cd ios && pod install && cd ..
npx react-native run-ios

# Android  
npx react-native run-android
```


## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
