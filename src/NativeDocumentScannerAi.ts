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
  scanFrame(rgba: Uint8Array, width: number, height: number, options: ScanOptions): Promise<ScanResult>;
}

// Add error handling for development mode
const DocumentScannerAiModule = NativeModules.DocumentScannerAi;

if (__DEV__ && !DocumentScannerAiModule) {
  console.warn(
    'DocumentScannerAi native module is not linked. ' +
    'Please ensure you have run "npx expo run:android" or "npx expo run:ios" ' +
    'to build the native code. Hot reloading may cause temporary context issues.'
  );
}

export default DocumentScannerAiModule as Spec;
