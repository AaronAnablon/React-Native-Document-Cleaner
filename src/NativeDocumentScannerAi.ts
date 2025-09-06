import { NativeModules } from 'react-native';

export type ScanOptions = {
  onnxModel?: string;
  threshold?: number;
  maxSize?: number;
  enhance?: 'none' | 'bw' | 'contrast';
  returnMask?: boolean;
  saveOutput?: boolean;
  outputFormat?: 'jpg' | 'png';
  outputQuality?: number;
  autoCapture?: boolean;
  captureConfidence?: number;
  captureConsecutiveFrames?: number;
  maxProcessingFps?: number;
};

export type ScanResult = {
  quadrilateral: [number, number][];
  confidence: number;
  outputUri?: string;
  maskUri?: string;
};

export interface Spec {
  scanImage(uri: string, options: ScanOptions): Promise<ScanResult>;
  scanFrame(
    rgba: Uint8Array,
    width: number,
    height: number,
    options: ScanOptions
  ): Promise<ScanResult>;
}

// Safe lazy initialization to prevent early access to NativeModules
let _documentScannerModule: Spec | null = null;
let _moduleLoadError: Error | null = null;

function getDocumentScannerModule(): Spec {
  if (_moduleLoadError) {
    throw _moduleLoadError;
  }

  if (_documentScannerModule) {
    return _documentScannerModule;
  }

  try {
    // Only access NativeModules when actually needed
    const module = NativeModules.DocumentScannerAi;

    if (!module) {
      const error = new Error(
        'DocumentScannerAi native module is not available. ' +
          'Please ensure you have run "npx expo run:android" or "npx expo run:ios" ' +
          'to build the native code, and restart Metro bundler.'
      );
      _moduleLoadError = error;
      throw error;
    }

    _documentScannerModule = module as Spec;
    return _documentScannerModule;
  } catch (error) {
    _moduleLoadError = error as Error;
    throw error;
  }
}

// Export a proxy that safely initializes the module when methods are called
const DocumentScannerAiProxy: Spec = {
  scanImage: (uri: string, options: ScanOptions): Promise<ScanResult> => {
    return getDocumentScannerModule().scanImage(uri, options);
  },
  scanFrame: (
    rgba: Uint8Array,
    width: number,
    height: number,
    options: ScanOptions
  ): Promise<ScanResult> => {
    return getDocumentScannerModule().scanFrame(rgba, width, height, options);
  },
};

export default DocumentScannerAiProxy;
