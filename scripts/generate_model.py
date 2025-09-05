#!/usr/bin/env python3
"""
Model Generation Script for React Native Document Scanner AI

This script generates ONNX models for document detection and segmentation
and deploys them to the appropriate platform directories.
"""

import os
import shutil
import sys
from pathlib import Path

try:
    from ultralytics import YOLO
except ImportError:
    print("Error: ultralytics not found. Please install it with: pip install ultralytics")
    sys.exit(1)


def generate_model(model_name="yolov8n", output_name="document_segmentation"):
    """Generate ONNX model from YOLOv8 checkpoint."""
    print(f"Loading {model_name} model...")
    model = YOLO(f"{model_name}.pt")
    
    print("Exporting to ONNX format...")
    model.export(format="onnx", imgsz=640, optimize=True)
    
    # Rename to expected filename
    original_file = f"{model_name}.onnx"
    target_file = f"{output_name}.onnx"
    
    if os.path.exists(original_file):
        shutil.move(original_file, target_file)
        print(f"Model exported as {target_file}")
        return target_file
    else:
        print(f"Error: Expected output file {original_file} not found")
        return None


def deploy_model(model_file, project_root="."):
    """Deploy the model to platform-specific directories."""
    project_path = Path(project_root)
    
    # Ensure models directory exists
    models_dir = project_path / "models"
    models_dir.mkdir(exist_ok=True)
    
    # Move model to models directory
    target_path = models_dir / model_file
    if os.path.exists(model_file):
        shutil.move(model_file, target_path)
        print(f"Model moved to {target_path}")
    
    # Deploy to Android assets
    android_assets = project_path / "example" / "android" / "app" / "src" / "main" / "assets"
    android_assets.mkdir(parents=True, exist_ok=True)
    
    android_model = android_assets / model_file
    shutil.copy2(target_path, android_model)
    print(f"Model deployed to Android: {android_model}")
    
    # Note for iOS deployment
    print("\nNote: For iOS deployment, manually add the model to your iOS bundle:")
    print(f"  1. Drag {target_path} into your Xcode project")
    print("  2. Ensure it's added to the target bundle")
    print("  3. Verify the model is accessible via Bundle.main")


def main():
    """Main function to generate and deploy the model."""
    print("React Native Document Scanner AI - Model Generator")
    print("=" * 50)
    
    # Allow custom model selection
    model_name = input("Enter YOLOv8 model name (default: yolov8n): ").strip() or "yolov8n"
    
    # Generate the model
    model_file = generate_model(model_name)
    
    if model_file:
        # Deploy to platform directories
        deploy_model(model_file)
        
        print("\n" + "=" * 50)
        print("Model generation and deployment complete!")
        print("\nNext steps:")
        print("1. Test the model in your React Native app")
        print("2. Adjust model parameters if needed")
        print("3. Consider training a custom model for better document detection")
        
        # Model info
        model_path = Path("models") / model_file
        if model_path.exists():
            size_mb = model_path.stat().st_size / (1024 * 1024)
            print(f"\nModel size: {size_mb:.1f} MB")
            print(f"Model location: {model_path}")
    else:
        print("Model generation failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
