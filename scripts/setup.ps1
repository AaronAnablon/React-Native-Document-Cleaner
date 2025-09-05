# React Native Document Scanner AI - Post Install Script (Windows)
# This script sets up necessary dependencies and configurations

Write-Host "Setting up React Native Document Scanner AI..." -ForegroundColor Green

# Check if we're in the correct directory
if (!(Test-Path "package.json")) {
    Write-Host "ERROR: package.json not found. Please run this script from your React Native project root." -ForegroundColor Red
    exit 1
}

Write-Host "Platform detected: Windows" -ForegroundColor Cyan

# Android Setup
Write-Host "Setting up Android dependencies..." -ForegroundColor Yellow

if (Test-Path "android") {
    # Check if CMake is available
    if (!(Get-Command cmake -ErrorAction SilentlyContinue)) {
        Write-Host "WARNING: CMake not found. Please install CMake for Android native builds." -ForegroundColor Yellow
        Write-Host "   You can install it via Android Studio SDK Manager or:" -ForegroundColor Yellow
        Write-Host "   - Windows: Download from https://cmake.org/" -ForegroundColor Yellow
        Write-Host "   - Or via Chocolatey: choco install cmake" -ForegroundColor Yellow
    }
    
    # Create assets directory if it doesn't exist
    if (!(Test-Path "android\app\src\main\assets")) {
        New-Item -ItemType Directory -Path "android\app\src\main\assets" -Force | Out-Null
        Write-Host "SUCCESS: Created Android assets directory" -ForegroundColor Green
    }
} else {
    Write-Host "ERROR: android directory not found" -ForegroundColor Red
}

# Check for ONNX model
Write-Host "Checking for ONNX model..." -ForegroundColor Yellow

$ModelFound = $false

# Check common locations
if (Test-Path "assets\document_segmentation.onnx") {
    $ModelFound = $true
    Write-Host "SUCCESS: Found ONNX model in assets/" -ForegroundColor Green
    
    # Copy to platform-specific locations
    if (Test-Path "ios") {
        Copy-Item "assets\document_segmentation.onnx" "ios\" -Force
        Write-Host "SUCCESS: Copied model to iOS bundle" -ForegroundColor Green
    }
    
    if (Test-Path "android") {
        if (!(Test-Path "android\app\src\main\assets")) {
            New-Item -ItemType Directory -Path "android\app\src\main\assets" -Force | Out-Null
        }
        Copy-Item "assets\document_segmentation.onnx" "android\app\src\main\assets\" -Force
        Write-Host "SUCCESS: Copied model to Android assets" -ForegroundColor Green
    }
} elseif (Test-Path "models\document_segmentation.onnx") {
    $ModelFound = $true
    Write-Host "SUCCESS: Found ONNX model in models/" -ForegroundColor Green
    
    # Copy to platform-specific locations
    if (Test-Path "ios") {
        Copy-Item "models\document_segmentation.onnx" "ios\" -Force
        Write-Host "SUCCESS: Copied model to iOS bundle" -ForegroundColor Green
    }
    
    if (Test-Path "android") {
        if (!(Test-Path "android\app\src\main\assets")) {
            New-Item -ItemType Directory -Path "android\app\src\main\assets" -Force | Out-Null
        }
        Copy-Item "models\document_segmentation.onnx" "android\app\src\main\assets\" -Force
        Write-Host "SUCCESS: Copied model to Android assets" -ForegroundColor Green
    }
}

if (!$ModelFound) {
    Write-Host "WARNING: ONNX model not found!" -ForegroundColor Yellow
    Write-Host "   Please add your document segmentation model as:" -ForegroundColor Yellow
    Write-Host "   - assets\document_segmentation.onnx" -ForegroundColor Yellow
    Write-Host "   - or models\document_segmentation.onnx" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Model requirements:" -ForegroundColor Yellow
    Write-Host "   - Input: RGB tensor with shape 1,3,H,W normalized 0-1" -ForegroundColor Yellow
    Write-Host "   - Output: segmentation mask with shape 1,1,H,W values 0-1" -ForegroundColor Yellow
}

# Check for required permissions
Write-Host "Checking permissions..." -ForegroundColor Yellow

# iOS Info.plist check
$InfoPlistFiles = Get-ChildItem -Path "ios" -Filter "Info.plist" -Recurse -ErrorAction SilentlyContinue
if ($InfoPlistFiles) {
    $CameraPermissionFound = $false
    foreach ($file in $InfoPlistFiles) {
        if ((Get-Content $file.FullName -Raw) -match "NSCameraUsageDescription") {
            $CameraPermissionFound = $true
            break
        }
    }
    
    if (!$CameraPermissionFound) {
        Write-Host "WARNING: Please add camera permission to Info.plist:" -ForegroundColor Yellow
        Write-Host "   <key>NSCameraUsageDescription</key>" -ForegroundColor Yellow
        Write-Host "   <string>This app needs access to camera to scan documents</string>" -ForegroundColor Yellow
    } else {
        Write-Host "SUCCESS: iOS camera permission found" -ForegroundColor Green
    }
}

# Android manifest check
if (Test-Path "android\app\src\main\AndroidManifest.xml") {
    $ManifestContent = Get-Content "android\app\src\main\AndroidManifest.xml" -Raw
    if ($ManifestContent -notmatch "android\.permission\.CAMERA") {
        Write-Host "WARNING: Please add camera permission to AndroidManifest.xml:" -ForegroundColor Yellow
        Write-Host "   <uses-permission android:name=`"android.permission.CAMERA`" />" -ForegroundColor Yellow
    } else {
        Write-Host "SUCCESS: Android camera permission found" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Add your ONNX model (if not done already)" -ForegroundColor White
Write-Host "2. Add camera permissions (if not done already)" -ForegroundColor White
Write-Host "3. Install additional dependencies: react-native-vision-camera" -ForegroundColor White
Write-Host "4. Run your app: npx react-native run-ios/run-android" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: https://github.com/AaronAnablon/React-Native-Document-Cleaner" -ForegroundColor Cyan