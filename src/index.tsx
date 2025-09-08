import DocumentScannerAi from './NativeDocumentScannerAi';

/**
 * Safe import helper for consumers
 * Use this pattern in your app to avoid early initialization issues:
 *
 * @example
 * ```typescript
 * let scanImage: typeof import('react-native-document-scanner-ai').scanImage | null = null;
 *
 * try {
 *   const scannerModule = require('react-native-document-scanner-ai');
 *   scanImage = scannerModule.scanImage;
 * } catch (error) {
 *   console.warn('Failed to import react-native-document-scanner-ai:', error);
 * }
 * ```
 */
export function createSafeImport() {
  try {
    return {
      scanImage,
      scanFrame,
      getDefaultModelPath,
      setupDocumentScanner,
      isAvailable: true,
    };
  } catch (error) {
    console.warn('DocumentScannerAi is not available:', error);
    return {
      scanImage: null,
      scanFrame: null,
      getDefaultModelPath: null,
      setupDocumentScanner: null,
      isAvailable: false,
    };
  }
}

/**
 * Check if the native module is available and provide setup guidance
 * @returns Object with availability status and setup instructions
 */
export function checkModuleAvailability(): {
  isAvailable: boolean;
  error?: string;
  instructions?: string;
} {
  try {
    // Try to access the native module
    const { NativeModules } = require('react-native');
    const module = NativeModules.DocumentScannerAi;
    
    if (!module) {
      return {
        isAvailable: false,
        error: 'Native module not found',
        instructions: 
          'The native module is not available. This usually means:\n\n' +
          '1. You are using Expo Go (managed workflow) - this library requires native code\n' +
          '2. The app was not built with native compilation\n' +
          '3. The native module was not properly linked\n\n' +
          'Solution: Use "expo run:android" or "expo run:ios" instead of "expo start"'
      };
    }
    
    return {
      isAvailable: true
    };
  } catch (error) {
    return {
      isAvailable: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      instructions: 'Failed to check native module availability'
    };
  }
}

/**
 * Gets the default ONNX model path for document segmentation
 * @returns Path to the bundled ONNX model
 */
export function getDefaultModelPath(): string {
  // For React Native, we always use the same filename since the setup script
  // copies the model to the correct platform-specific locations
  // - Android: android/app/src/main/assets/
  // - iOS: iOS bundle
  return 'document_segmentation.onnx';
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
  threshold?: number; // segm mask threshold
  maxSize?: number; // downscale for perf
  enhance?: 'none' | 'bw' | 'contrast';
  returnMask?: boolean; // return maskUri
  saveOutput?: boolean; // whether to save warped crop to disk
  outputFormat?: 'jpg' | 'png';
  outputQuality?: number; // 0–100
  autoCapture?: boolean; // live mode: auto-capture stable doc
  captureConfidence?: number; // min confidence to trigger capture
  captureConsecutiveFrames?: number; // how many stable frames required
  maxProcessingFps?: number; // throttle for performance
};

export type ScanResult = {
  quadrilateral: [number, number][]; // detected quad
  confidence: number; // segmentation confidence
  outputUri?: string; // warped/cropped image if saveOutput:true
  maskUri?: string; // optional mask file if returnMask:true
};

export async function scanImage(
  uri: string,
  options?: ScanOptions
): Promise<ScanResult> {
  try {
    const finalOptions = {
      ...options,
      // Use default model if none specified
      onnxModel: options?.onnxModel || getDefaultModelPath(),
    };
    return await DocumentScannerAi.scanImage(uri, finalOptions);
  } catch (error) {
    // Provide more helpful error messages
    if (error instanceof Error) {
      let errorMessage = error.message;
      
      // Handle specific setup-related errors
      if (errorMessage.includes('require.resolve') || 
          errorMessage.includes('Default model path not available') ||
          errorMessage.includes('native module is not available')) {
        errorMessage = 
          'Document scanner native module not available. This usually means:\n\n' +
          'FOR EXPO MANAGED WORKFLOW:\n' +
          '• This library requires native code and cannot run in Expo Go\n' +
          '• You must use "expo run:android" or "expo run:ios" (development builds)\n' +
          '• You cannot use "expo start" - it won\'t include native modules\n\n' +
          'FOR EXPO BARE WORKFLOW / REACT NATIVE CLI:\n' +
          '1. Run: npx react-native-document-scanner-ai setup\n' +
          '2. Run: npx react-native-document-scanner-ai verify-setup\n' +
          '3. Clean: rm -rf node_modules && npm install\n' +
          '4. For Android: cd android && ./gradlew clean\n' +
          '5. For iOS: cd ios && rm -rf build && pod install\n' +
          '6. Rebuild: npx react-native run-android or npx react-native run-ios\n' +
          '7. Restart Metro: npx react-native start --reset-cache\n\n' +
          'VERIFICATION:\n' +
          '• Make sure you see the native module in your build logs\n' +
          '• For Android: check android/app/src/main/assets/ has the .onnx file\n' +
          '• For iOS: check the .onnx file is in your iOS bundle';
      }
      
      throw new Error(
        `Failed to scan image: ${errorMessage}`
      );
    }
    throw error;
  }
}

export async function scanFrame(
  rgba: Uint8Array,
  width: number,
  height: number,
  options?: ScanOptions
): Promise<ScanResult> {
  try {
    const finalOptions = {
      ...options,
      // Use default model if none specified
      onnxModel: options?.onnxModel || getDefaultModelPath(),
    };
    return await DocumentScannerAi.scanFrame(rgba, width, height, finalOptions);
  } catch (error) {
    // Provide more helpful error messages
    if (error instanceof Error) {
      let errorMessage = error.message;
      
      // Handle specific setup-related errors
      if (errorMessage.includes('require.resolve') || 
          errorMessage.includes('Default model path not available') ||
          errorMessage.includes('native module is not available')) {
        errorMessage = 
          'Document scanner native module not available. This usually means:\n\n' +
          'FOR EXPO MANAGED WORKFLOW:\n' +
          '• This library requires native code and cannot run in Expo Go\n' +
          '• You must use "expo run:android" or "expo run:ios" (development builds)\n' +
          '• You cannot use "expo start" - it won\'t include native modules\n\n' +
          'FOR EXPO BARE WORKFLOW / REACT NATIVE CLI:\n' +
          '1. Run: npx react-native-document-scanner-ai setup\n' +
          '2. Run: npx react-native-document-scanner-ai verify-setup\n' +
          '3. Clean: rm -rf node_modules && npm install\n' +
          '4. For Android: cd android && ./gradlew clean\n' +
          '5. For iOS: cd ios && rm -rf build && pod install\n' +
          '6. Rebuild: npx react-native run-android or npx react-native run-ios\n' +
          '7. Restart Metro: npx react-native start --reset-cache\n\n' +
          'VERIFICATION:\n' +
          '• Make sure you see the native module in your build logs\n' +
          '• For Android: check android/app/src/main/assets/ has the .onnx file\n' +
          '• For iOS: check the .onnx file is in your iOS bundle';
      }
      
      throw new Error(
        `Failed to scan frame: ${errorMessage}`
      );
    }
    throw error;
  }
}
