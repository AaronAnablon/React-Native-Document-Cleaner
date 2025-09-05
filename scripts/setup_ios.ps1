# iOS ONNX Model Setup Script (PowerShell)
# This script automates the iOS setup process for the ONNX document segmentation model

param(
    [switch]$SkipPodInstall,
    [switch]$Verbose
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path $Path) {
        Write-ColorOutput "✅ $Description found at $Path" $SuccessColor
        return $true
    } else {
        Write-ColorOutput "❌ $Description not found at $Path" $ErrorColor
        return $false
    }
}

Write-ColorOutput "🚀 Starting iOS ONNX Model Setup..." $InfoColor

# Check if we're in the correct directory
if (-not (Test-Path "package.json")) {
    Write-ColorOutput "❌ Error: Please run this script from the project root directory" $ErrorColor
    exit 1
}

# Check if example directory exists
if (-not (Test-Path "example")) {
    Write-ColorOutput "❌ Error: Example directory not found" $ErrorColor
    exit 1
}

Write-ColorOutput "✅ Project structure validated" $SuccessColor

# Step 1: Verify Podfile dependencies
Write-ColorOutput "📦 Checking iOS dependencies..." $InfoColor
$podfilePath = "example\ios\Podfile"

if (-not (Test-Path $podfilePath)) {
    Write-ColorOutput "❌ Error: Podfile not found in example/ios" $ErrorColor
    exit 1
}

$podfileContent = Get-Content $podfilePath -Raw
if ($podfileContent -match "onnxruntime-c") {
    Write-ColorOutput "✅ ONNX Runtime dependency found in Podfile" $SuccessColor
} else {
    Write-ColorOutput "⚠️  ONNX Runtime dependency not found in Podfile" $WarningColor
    Write-ColorOutput "Please manually add the following to your Podfile:" $InfoColor
    Write-ColorOutput "  pod 'onnxruntime-c', '~> 1.16.0'" $InfoColor
    Write-ColorOutput "  pod 'OpenCV', '~> 4.5.0'" $InfoColor
}

# Step 2: Install pods (if not skipped)
if (-not $SkipPodInstall) {
    Write-ColorOutput "📦 Running pod install..." $InfoColor
    Push-Location "example\ios"
    try {
        $podResult = & pod install 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Pod install completed successfully" $SuccessColor
        } else {
            Write-ColorOutput "❌ Pod install failed" $ErrorColor
            Write-ColorOutput $podResult $ErrorColor
            Pop-Location
            exit 1
        }
    } catch {
        Write-ColorOutput "❌ Error running pod install: $_" $ErrorColor
        Pop-Location
        exit 1
    } finally {
        Pop-Location
    }
} else {
    Write-ColorOutput "⏭️  Skipping pod install (use -SkipPodInstall:`$false to run)" $WarningColor
}

# Step 3: Copy ONNX model to iOS bundle
Write-ColorOutput "📋 Copying ONNX model to iOS bundle..." $InfoColor
$sourceModel = "models\document_segmentation.onnx"
$destModel = "example\ios\DocumentScannerAiExample\document_segmentation.onnx"

if (-not (Test-Path $sourceModel)) {
    Write-ColorOutput "❌ Error: ONNX model not found at $sourceModel" $ErrorColor
    exit 1
}

try {
    Copy-Item $sourceModel $destModel -Force
    Write-ColorOutput "✅ ONNX model copied to iOS bundle" $SuccessColor
} catch {
    Write-ColorOutput "❌ Error copying ONNX model: $_" $ErrorColor
    exit 1
}

# Step 4: Verify Xcode project files
Write-ColorOutput "🔍 Verifying Xcode project structure..." $InfoColor
$xcodeProject = "example\ios\DocumentScannerAiExample.xcodeproj"
$xcodeWorkspace = "example\ios\DocumentScannerAiExample.xcworkspace"

if (Test-Path $xcodeWorkspace) {
    Write-ColorOutput "✅ Xcode workspace found" $SuccessColor
} elseif (Test-Path $xcodeProject) {
    Write-ColorOutput "⚠️  Xcode project found, but workspace is recommended after pod install" $WarningColor
} else {
    Write-ColorOutput "❌ Error: No Xcode project or workspace found" $ErrorColor
    exit 1
}

# Step 5: Check native implementation files
Write-ColorOutput "🔍 Verifying native implementation files..." $InfoColor

$requiredFiles = @(
    "ios\DocumentScannerAi.h",
    "ios\DocumentScannerAi.mm",
    "cpp\DocumentScannerCore.h",
    "cpp\DocumentScannerCore.cpp",
    "cpp\JSIDocumentScanner.h",
    "cpp\JSIDocumentScanner.cpp"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-ColorOutput "✅ $file found" $SuccessColor
    } else {
        Write-ColorOutput "❌ $file missing" $ErrorColor
    }
}

# Step 6: Generate build script
Write-ColorOutput "📝 Generating build script..." $InfoColor
$buildScript = @'
# iOS Build Script for Document Scanner AI

Write-Host "🏗️  Building iOS app..." -ForegroundColor Cyan

Push-Location example

# Install JS dependencies
Write-Host "📦 Installing JavaScript dependencies..." -ForegroundColor Yellow
npm install

# Install iOS dependencies
Write-Host "📦 Installing iOS dependencies..." -ForegroundColor Yellow
Push-Location ios
pod install
Pop-Location

# Build iOS app
Write-Host "🔨 Building iOS app..." -ForegroundColor Yellow
npx react-native run-ios --configuration Debug

Write-Host "✅ iOS build completed!" -ForegroundColor Green
Pop-Location
'@

$buildScriptPath = "scripts\build_ios.ps1"
$buildScript | Out-File -FilePath $buildScriptPath -Encoding UTF8
Write-ColorOutput "✅ Build script created at $buildScriptPath" $SuccessColor

# Step 7: Validation and next steps
Write-ColorOutput "" $InfoColor
Write-ColorOutput "🎉 iOS ONNX Model Setup Completed!" $SuccessColor
Write-ColorOutput "" $InfoColor
Write-ColorOutput "📋 Next Steps:" $WarningColor
Write-Host "1. Open example/ios/DocumentScannerAiExample.xcworkspace in Xcode"
Write-Host "2. Add document_segmentation.onnx to the project bundle:"
Write-Host "   - Right-click DocumentScannerAiExample in Project Navigator"
Write-Host "   - Select 'Add Files to DocumentScannerAiExample...'"
Write-Host "   - Choose document_segmentation.onnx"
Write-Host "   - Ensure 'Copy items if needed' is checked"
Write-Host "   - Ensure target is selected"
Write-Host "3. Build and run the project"
Write-ColorOutput "" $InfoColor
Write-ColorOutput "🧪 Testing:" $WarningColor
Write-Host "- Use the test functions in the example app"
Write-Host "- Check console logs for ONNX model loading status"
Write-Host "- Test document detection with various images"
Write-ColorOutput "" $InfoColor
Write-ColorOutput "📚 Documentation:" $WarningColor
Write-Host "- See IOS_SETUP.md for detailed instructions"
Write-Host "- Check ONNX_INTEGRATION.md for implementation details"
Write-ColorOutput "" $InfoColor
Write-ColorOutput "✨ Happy coding!" $SuccessColor
