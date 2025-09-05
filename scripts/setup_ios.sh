#!/bin/bash

# iOS ONNX Model Setup Script
# This script automates the iOS setup process for the ONNX document segmentation model

set -e

echo "🚀 Starting iOS ONNX Model Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: Please run this script from the project root directory${NC}"
    exit 1
fi

# Check if example directory exists
if [ ! -d "example" ]; then
    echo -e "${RED}❌ Error: Example directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Project structure validated${NC}"

# Step 1: Install iOS dependencies
echo -e "${YELLOW}📦 Installing iOS dependencies...${NC}"
cd example/ios

if [ ! -f "Podfile" ]; then
    echo -e "${RED}❌ Error: Podfile not found in example/ios${NC}"
    exit 1
fi

# Check if dependencies are already added
if grep -q "onnxruntime-c" Podfile; then
    echo -e "${GREEN}✅ ONNX Runtime dependency already added to Podfile${NC}"
else
    echo -e "${YELLOW}⚠️  ONNX Runtime dependency not found in Podfile${NC}"
    echo "Please manually add the following to your Podfile:"
    echo "  pod 'onnxruntime-c', '~> 1.16.0'"
    echo "  pod 'OpenCV', '~> 4.5.0'"
fi

echo -e "${YELLOW}📦 Running pod install...${NC}"
if pod install; then
    echo -e "${GREEN}✅ Pod install completed successfully${NC}"
else
    echo -e "${RED}❌ Pod install failed${NC}"
    exit 1
fi

cd ../..

# Step 2: Copy ONNX model to iOS bundle
echo -e "${YELLOW}📋 Copying ONNX model to iOS bundle...${NC}"
SOURCE_MODEL="models/document_segmentation.onnx"
DEST_MODEL="example/ios/DocumentScannerAiExample/document_segmentation.onnx"

if [ ! -f "$SOURCE_MODEL" ]; then
    echo -e "${RED}❌ Error: ONNX model not found at $SOURCE_MODEL${NC}"
    exit 1
fi

cp "$SOURCE_MODEL" "$DEST_MODEL"
echo -e "${GREEN}✅ ONNX model copied to iOS bundle${NC}"

# Step 3: Verify Xcode project files
echo -e "${YELLOW}🔍 Verifying Xcode project structure...${NC}"
XCODE_PROJECT="example/ios/DocumentScannerAiExample.xcodeproj"
XCODE_WORKSPACE="example/ios/DocumentScannerAiExample.xcworkspace"

if [ -d "$XCODE_WORKSPACE" ]; then
    echo -e "${GREEN}✅ Xcode workspace found${NC}"
elif [ -d "$XCODE_PROJECT" ]; then
    echo -e "${YELLOW}⚠️  Xcode project found, but workspace is recommended after pod install${NC}"
else
    echo -e "${RED}❌ Error: No Xcode project or workspace found${NC}"
    exit 1
fi

# Step 4: Check native implementation files
echo -e "${YELLOW}🔍 Verifying native implementation files...${NC}"

REQUIRED_FILES=(
    "ios/DocumentScannerAi.h"
    "ios/DocumentScannerAi.mm"
    "cpp/DocumentScannerCore.h"
    "cpp/DocumentScannerCore.cpp"
    "cpp/JSIDocumentScanner.h"
    "cpp/JSIDocumentScanner.cpp"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file found${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
    fi
done

# Step 5: Generate build script
echo -e "${YELLOW}📝 Generating build script...${NC}"
cat > scripts/build_ios.sh << 'EOF'
#!/bin/bash

# iOS Build Script for Document Scanner AI

set -e

echo "🏗️  Building iOS app..."

cd example

# Install JS dependencies
echo "📦 Installing JavaScript dependencies..."
npm install

# Install iOS dependencies
echo "📦 Installing iOS dependencies..."
cd ios
pod install
cd ..

# Build iOS app
echo "🔨 Building iOS app..."
npx react-native run-ios --configuration Debug

echo "✅ iOS build completed!"
EOF

chmod +x scripts/build_ios.sh
echo -e "${GREEN}✅ Build script created at scripts/build_ios.sh${NC}"

# Step 6: Validation and next steps
echo ""
echo -e "${GREEN}🎉 iOS ONNX Model Setup Completed!${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Open example/ios/DocumentScannerAiExample.xcworkspace in Xcode"
echo "2. Add document_segmentation.onnx to the project bundle:"
echo "   - Right-click DocumentScannerAiExample in Project Navigator"
echo "   - Select 'Add Files to DocumentScannerAiExample...'"
echo "   - Choose document_segmentation.onnx"
echo "   - Ensure 'Copy items if needed' is checked"
echo "   - Ensure target is selected"
echo "3. Build and run the project"
echo ""
echo -e "${YELLOW}🧪 Testing:${NC}"
echo "- Use the test functions in the example app"
echo "- Check console logs for ONNX model loading status"
echo "- Test document detection with various images"
echo ""
echo -e "${YELLOW}📚 Documentation:${NC}"
echo "- See IOS_SETUP.md for detailed instructions"
echo "- Check ONNX_INTEGRATION.md for implementation details"
echo ""
echo -e "${GREEN}✨ Happy coding!${NC}"
