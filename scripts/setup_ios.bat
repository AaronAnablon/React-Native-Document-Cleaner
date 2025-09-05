@echo off
echo 🚀 iOS ONNX Model Setup - Simple Version
echo.

REM Check if we're in the right directory
if not exist package.json (
    echo ❌ Error: Please run this script from the project root directory
    pause
    exit /b 1
)

echo ✅ Project structure validated
echo.

REM Step 1: Check if model exists
echo 📋 Checking ONNX model...
if exist "models\document_segmentation.onnx" (
    echo ✅ ONNX model found
) else (
    echo ❌ ONNX model not found at models\document_segmentation.onnx
    echo Please ensure the model file is present before continuing
    pause
    exit /b 1
)

REM Step 2: Copy model to iOS bundle
echo 📋 Copying ONNX model to iOS bundle...
if not exist "example\ios\DocumentScannerAiExample" (
    mkdir "example\ios\DocumentScannerAiExample"
)

copy "models\document_segmentation.onnx" "example\ios\DocumentScannerAiExample\" >nul
if %errorlevel% equ 0 (
    echo ✅ ONNX model copied to iOS bundle
) else (
    echo ❌ Failed to copy ONNX model
    pause
    exit /b 1
)

REM Step 3: Check Podfile
echo 🔍 Checking Podfile configuration...
if exist "example\ios\Podfile" (
    findstr /c:"onnxruntime-c" "example\ios\Podfile" >nul
    if %errorlevel% equ 0 (
        echo ✅ ONNX Runtime dependency found in Podfile
    ) else (
        echo ⚠️  ONNX Runtime dependency not found in Podfile
        echo Please add the following to your Podfile:
        echo   pod 'onnxruntime-c', '~> 1.16.0'
        echo   pod 'OpenCV', '~> 4.5.0'
    )
) else (
    echo ❌ Podfile not found
)

REM Step 4: Check native files
echo 🔍 Checking native implementation files...
set "all_files_exist=1"

if exist "ios\DocumentScannerAi.h" (
    echo ✅ DocumentScannerAi.h found
) else (
    echo ❌ DocumentScannerAi.h missing
    set "all_files_exist=0"
)

if exist "ios\DocumentScannerAi.mm" (
    echo ✅ DocumentScannerAi.mm found
) else (
    echo ❌ DocumentScannerAi.mm missing
    set "all_files_exist=0"
)

if exist "cpp\DocumentScannerCore.h" (
    echo ✅ DocumentScannerCore.h found
) else (
    echo ❌ DocumentScannerCore.h missing
    set "all_files_exist=0"
)

if exist "cpp\DocumentScannerCore.cpp" (
    echo ✅ DocumentScannerCore.cpp found
) else (
    echo ❌ DocumentScannerCore.cpp missing
    set "all_files_exist=0"
)

REM Step 5: Check Xcode project
echo 🔍 Checking Xcode project...
if exist "example\ios\DocumentScannerAiExample.xcworkspace" (
    echo ✅ Xcode workspace found
) else if exist "example\ios\DocumentScannerAiExample.xcodeproj" (
    echo ⚠️  Xcode project found, workspace recommended after pod install
) else (
    echo ❌ No Xcode project found
)

echo.
echo 🎉 iOS ONNX Model Setup Check Completed!
echo.
echo 📋 Next Steps:
echo 1. Open example/ios/DocumentScannerAiExample.xcworkspace in Xcode
echo 2. Add document_segmentation.onnx to the project bundle:
echo    - Right-click DocumentScannerAiExample in Project Navigator
echo    - Select "Add Files to DocumentScannerAiExample..."
echo    - Choose document_segmentation.onnx
echo    - Ensure "Copy items if needed" is checked
echo    - Ensure target is selected
echo 3. Run pod install in example/ios directory if not already done
echo 4. Build and run the project
echo.
echo 🧪 Testing:
echo - Use the test functions in the example app
echo - Check console logs for ONNX model loading status
echo - Test document detection with various images
echo.
echo ✨ Happy coding!

pause
