# React Native Document Scanner AI - Model Generator (PowerShell)
# This script generates ONNX models for document detection and segmentation

param(
    [string]$ModelName = "yolov8n",
    [string]$OutputName = "document_segmentation"
)

Write-Host "React Native Document Scanner AI - Model Generator" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

# Check if Python is available
try {
    $pythonVersion = python --version
    Write-Host "Using Python: $pythonVersion" -ForegroundColor Blue
} catch {
    Write-Host "Error: Python not found. Please install Python and try again." -ForegroundColor Red
    exit 1
}

# Check if ultralytics is installed
try {
    python -c "import ultralytics" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installing ultralytics..." -ForegroundColor Yellow
        python -m pip install ultralytics
    }
} catch {
    Write-Host "Error installing ultralytics" -ForegroundColor Red
    exit 1
}

# Generate the model
Write-Host "Generating ONNX model from $ModelName..." -ForegroundColor Blue
$pythonScript = @"
from ultralytics import YOLO
import os
import shutil

# Load and export model
model = YOLO('$ModelName.pt')
model.export(format='onnx', imgsz=640, optimize=True)

# Rename to expected filename
original_file = '$ModelName.onnx'
target_file = '$OutputName.onnx'

if os.path.exists(original_file):
    if os.path.exists(target_file):
        os.remove(target_file)
    shutil.move(original_file, target_file)
    print(f'Model exported as {target_file}')
else:
    print(f'Error: Expected output file {original_file} not found')
    exit(1)
"@

python -c $pythonScript

if ($LASTEXITCODE -ne 0) {
    Write-Host "Model generation failed!" -ForegroundColor Red
    exit 1
}

# Create models directory if it doesn't exist
if (!(Test-Path "models")) {
    New-Item -ItemType Directory -Path "models" | Out-Null
}

# Move model to models directory
$modelFile = "$OutputName.onnx"
if (Test-Path $modelFile) {
    Move-Item $modelFile "models\$modelFile" -Force
    Write-Host "Model moved to models\$modelFile" -ForegroundColor Green
}

# Deploy to Android assets
$androidAssets = "example\android\app\src\main\assets"
if (!(Test-Path $androidAssets)) {
    New-Item -ItemType Directory -Path $androidAssets -Force | Out-Null
}

Copy-Item "models\$modelFile" "$androidAssets\$modelFile" -Force
Write-Host "Model deployed to Android: $androidAssets\$modelFile" -ForegroundColor Green

# Show completion message
Write-Host ""
Write-Host "=" * 50 -ForegroundColor Green
Write-Host "Model generation and deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the model in your React Native app"
Write-Host "2. For iOS: Add models\$modelFile to your Xcode project bundle"
Write-Host "3. Consider training a custom model for better document detection"

# Show model info
if (Test-Path "models\$modelFile") {
    $size = (Get-Item "models\$modelFile").Length / 1MB
    Write-Host ""
    Write-Host "Model size: $([math]::Round($size, 1)) MB" -ForegroundColor Blue
    Write-Host "Model location: models\$modelFile" -ForegroundColor Blue
}
