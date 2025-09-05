#!/bin/bash

# React Native Document Scanner AI - Post Install Script
# This script sets up necessary dependencies and configurations

echo "🚀 Setting up React Native Document Scanner AI..."

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from your React Native project root."
    exit 1
fi

# Check platform
PLATFORM=$(uname)

echo "📱 Platform detected: $PLATFORM"

# iOS Setup
if [ "$PLATFORM" = "Darwin" ]; then
    echo "🍎 Setting up iOS dependencies..."
    
    if [ -d "ios" ]; then
        cd ios
        
        # Add dependencies to Podfile if not already present
        if [ -f "Podfile" ]; then
            if ! grep -q "OpenCV2" Podfile; then
                echo "  pod 'OpenCV2', '~> 4.5.0'" >> Podfile
                echo "✅ Added OpenCV2 to Podfile"
            fi
            
            if ! grep -q "onnxruntime-c" Podfile; then
                echo "  pod 'onnxruntime-c', '~> 1.16.0'" >> Podfile
                echo "✅ Added onnxruntime-c to Podfile"
            fi
            
            echo "📦 Installing iOS dependencies..."
            pod install
        else
            echo "❌ Podfile not found in ios directory"
        fi
        
        cd ..
    else
        echo "❌ ios directory not found"
    fi
fi

# Android Setup
echo "🤖 Setting up Android dependencies..."

if [ -d "android" ]; then
    # Check if CMake is available
    if ! command -v cmake &> /dev/null; then
        echo "⚠️  Warning: CMake not found. Please install CMake for Android native builds."
        echo "   You can install it via Android Studio SDK Manager or:"
        echo "   - macOS: brew install cmake"
        echo "   - Ubuntu: sudo apt-get install cmake"
        echo "   - Windows: Download from https://cmake.org/"
    fi
    
    # Create assets directory if it doesn't exist
    mkdir -p android/app/src/main/assets
    echo "✅ Created Android assets directory"
    
else
    echo "❌ android directory not found"
fi

# Check for ONNX model
echo "🧠 Checking for ONNX model..."

MODEL_FOUND=false

# Check common locations
if [ -f "assets/document_segmentation.onnx" ]; then
    MODEL_FOUND=true
    echo "✅ Found ONNX model in assets/"
    
    # Copy to platform-specific locations
    if [ -d "ios" ]; then
        cp assets/document_segmentation.onnx ios/
        echo "✅ Copied model to iOS bundle"
    fi
    
    if [ -d "android" ]; then
        cp assets/document_segmentation.onnx android/app/src/main/assets/
        echo "✅ Copied model to Android assets"
    fi
fi

if [ "$MODEL_FOUND" = false ]; then
    echo "⚠️  ONNX model not found!"
    echo "   Please add your document segmentation model as:"
    echo "   - assets/document_segmentation.onnx"
    echo ""
    echo "   Model requirements:"
    echo "   - Input: [1, 3, H, W] RGB tensor (0-1 normalized)"
    echo "   - Output: [1, 1, H, W] segmentation mask (0-1 values)"
fi

# Check for required permissions
echo "🔐 Checking permissions..."

# iOS Info.plist check
if [ -f "ios/*/Info.plist" ]; then
    if ! grep -q "NSCameraUsageDescription" ios/*/Info.plist; then
        echo "⚠️  Please add camera permission to Info.plist:"
        echo "   <key>NSCameraUsageDescription</key>"
        echo "   <string>This app needs access to camera to scan documents</string>"
    else
        echo "✅ iOS camera permission found"
    fi
fi

# Android manifest check
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    if ! grep -q "android.permission.CAMERA" android/app/src/main/AndroidManifest.xml; then
        echo "⚠️  Please add camera permission to AndroidManifest.xml:"
        echo "   <uses-permission android:name=\"android.permission.CAMERA\" />"
    else
        echo "✅ Android camera permission found"
    fi
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Add your ONNX model (if not done already)"
echo "2. Add camera permissions (if not done already)"
echo "3. Install additional dependencies: react-native-vision-camera"
echo "4. Run your app: npx react-native run-ios/run-android"
echo ""
echo "📚 Documentation: https://github.com/aaron/react-native-document-scanner-ai"
