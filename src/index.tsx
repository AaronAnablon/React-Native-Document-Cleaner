import DocumentScannerAi from './NativeDocumentScannerAi';

/**
 * Gets the default ONNX model path for document segmentation
 * @returns Path to the bundled ONNX model
 */
export function getDefaultModelPath(): string {
  // This will resolve to the model in the npm package
  return require.resolve('react-native-document-scanner-ai/models/document_segmentation.onnx');
}

/**
 * Setup helper - copies the ONNX model to platform-specific locations
 * Call this manually if postinstall script fails
 */
export function setupDocumentScanner(): void {
  try {
    const { copyModelFiles } = require('../scripts/postinstall.js');
    copyModelFiles();
  } catch (error) {
    console.error('Setup failed:', error);
    console.log('Please manually copy models/document_segmentation.onnx to:');
    console.log('- android/app/src/main/assets/ (for Android)');
    console.log('- iOS project bundle (for iOS)');
  }
}

export type ScanOptions = {
  onnxModel?: string;
  threshold?: number;                  // segm mask threshold
  maxSize?: number;                    // downscale for perf
  enhance?: 'none' | 'bw' | 'contrast';
  returnMask?: boolean;                // return maskUri
  saveOutput?: boolean;                // whether to save warped crop to disk
  outputFormat?: 'jpg' | 'png';
  outputQuality?: number;              // 0–100
  autoCapture?: boolean;               // live mode: auto-capture stable doc
  captureConfidence?: number;          // min confidence to trigger capture
  captureConsecutiveFrames?: number;   // how many stable frames required
  maxProcessingFps?: number;           // throttle for performance
};

export type ScanResult = {
  quadrilateral: [number, number][];   // detected quad
  confidence: number;                  // segmentation confidence
  outputUri?: string;                  // warped/cropped image if saveOutput:true
  maskUri?: string;                    // optional mask file if returnMask:true
};

export async function scanImage(
  uri: string,
  options?: ScanOptions
): Promise<ScanResult> {
  if (!DocumentScannerAi) {
    throw new Error(
      'Failed to load. ' +
      'DocumentScannerAi native module is not available. ' +
      'Please ensure you have run "npx expo run:android" or "npx expo run:ios" ' +
      'to build the native code, and restart Metro bundler.'
    );
  }

  const finalOptions = {
    ...options,
    // Use default model if none specified
    onnxModel: options?.onnxModel || getDefaultModelPath()
  };
  return DocumentScannerAi.scanImage(uri, finalOptions);
}

export async function scanFrame(
  rgba: Uint8Array,
  width: number,
  height: number,
  options?: ScanOptions
): Promise<ScanResult> {
  if (!DocumentScannerAi) {
    throw new Error(
      'DocumentScannerAi native module is not available. ' +
      'Please ensure you have run "npx expo run:android" or "npx expo run:ios" ' +
      'to build the native code, and restart Metro bundler.'
    );
  }

  const finalOptions = {
    ...options,
    // Use default model if none specified
    onnxModel: options?.onnxModel || getDefaultModelPath()
  };
  return DocumentScannerAi.scanFrame(rgba, width, height, finalOptions);
}
