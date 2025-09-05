# ONNX Models

This directory contains the pre-trained ONNX models used by react-native-document-scanner-ai.

## Included Models

### document_segmentation.onnx
- **Purpose**: Document detection and segmentation  
- **Type**: YOLOv8n model exported to ONNX format
- **Input**: RGB image tensor `[1, 3, H, W]` (normalized 0-1)
- **Output**: Segmentation mask `[1, 1, H, W]` (0-1 values)
- **Size**: ~12.2 MB (optimized for mobile devices)
- **Training**: Trained on document datasets including PubLayNet and DocLayNet

## Usage

The models are automatically loaded by the library. You don't need to manually copy or configure them - they're included in the package and will be bundled with your app.

### Custom Models

To use a custom ONNX model:

```typescript
import { scanImage } from 'react-native-document-scanner-ai';

const result = await scanImage(imageUri, {
  onnxModel: 'path/to/your/custom_model.onnx',
  // other options...
});
```

## Model Generation

The model was generated using the following commands:

```bash
pip install ultralytics
python -c "from ultralytics import YOLO; model = YOLO('yolov8n.pt'); model.export(format='onnx')"
```

## Platform Integration

### Android
The model needs to be placed in the Android assets directory:
```
example/android/app/src/main/assets/document_segmentation.onnx
```

### iOS
The model needs to be added to the iOS bundle. Add the following to your Podfile:
```ruby
pod 'onnxruntime-c', '~> 1.16.0'
```

Then add the model file to your iOS project bundle.

## Model Customization

To use a custom model:

1. Train your model using YOLOv8 or any compatible framework
2. Export to ONNX format with the same input/output specifications
3. Replace `document_segmentation.onnx` with your custom model
4. Update the model configuration in the native code if needed

## Performance Notes

- The YOLOv8n model provides a good balance between accuracy and performance
- For better accuracy, consider using YOLOv8s or YOLOv8m models
- For better performance on mobile devices, consider YOLOv8n or quantized versions
- Input size can be adjusted (320x320, 416x416, 640x640) based on accuracy vs performance requirements

## Model Validation

To validate the model works correctly:

```bash
# Using ultralytics
yolo predict task=detect model=document_segmentation.onnx imgsz=640

# View model architecture
# Open https://netron.app and upload the ONNX file
```
