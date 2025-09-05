#import "DocumentScannerAi.h"
#import <React/RCTBridge+Private.h>
#import <React/RCTUtils.h>
#import <ReactCommon/RCTTurboModule.h>
#import <jsi/jsi.h>
#import "../cpp/JSIDocumentScanner.h"

@implementation DocumentScannerAi
RCT_EXPORT_MODULE()

- (instancetype)init {
    if (self = [super init]) {
        // Install JSI bindings when module is initialized
        [self installJSIBindings];
    }
    return self;
}

- (void)installJSIBindings {
    RCTBridge *bridge = [RCTBridge currentBridge];
    RCTCxxBridge *cxxBridge = (RCTCxxBridge *)bridge;
    if (!cxxBridge.runtime) {
        return;
    }
    
    auto& runtime = *cxxBridge.runtime;
    
    // Get the ONNX model path from bundle
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"document_segmentation" ofType:@"onnx"];
    if (!modelPath) {
        NSLog(@"Document segmentation ONNX model not found in bundle!");
        return;
    }
    
    std::string modelPathStr = [modelPath UTF8String];
    
    try {
        DocumentScanner::installDocumentScannerJSI(runtime, modelPathStr);
        NSLog(@"DocumentScanner JSI bindings installed successfully");
    } catch (const std::exception& e) {
        NSLog(@"Failed to install DocumentScanner JSI bindings: %s", e.what());
    }
}

- (void)scanImage:(NSString *)uri
          options:(JS::NativeDocumentScannerAi::ScanOptions &)options
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // Convert options to native
            DocumentScanner::ScanOptions nativeOptions;
            nativeOptions.threshold = options.threshold().value_or(0.5);
            nativeOptions.maxSize = options.maxSize().value_or(1024);
            nativeOptions.enhance = options.enhance().value_or("none");
            nativeOptions.returnMask = options.returnMask().value_or(false);
            nativeOptions.saveOutput = options.saveOutput().value_or(false);
            nativeOptions.outputFormat = options.outputFormat().value_or("jpg");
            nativeOptions.outputQuality = options.outputQuality().value_or(90);
            nativeOptions.autoCapture = options.autoCapture().value_or(false);
            nativeOptions.captureConfidence = options.captureConfidence().value_or(0.8);
            nativeOptions.captureConsecutiveFrames = options.captureConsecutiveFrames().value_or(3);
            nativeOptions.maxProcessingFps = options.maxProcessingFps().value_or(30);
            
            // Create core and scan
            auto core = std::make_shared<DocumentScanner::DocumentScannerCore>();
            NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"document_segmentation" ofType:@"onnx"];
            
            if (![core->initialize:[modelPath UTF8String]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    reject(@"INIT_ERROR", @"Failed to initialize DocumentScannerCore", nil);
                });
                return;
            }
            
            auto result = core->scanImage([uri UTF8String], nativeOptions);
            
            // Convert result to NSDictionary
            NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
            
            // Quadrilateral
            NSMutableArray *quadArray = [NSMutableArray array];
            [quadArray addObject:@[@(result.quadrilateral.topLeft.x), @(result.quadrilateral.topLeft.y)]];
            [quadArray addObject:@[@(result.quadrilateral.topRight.x), @(result.quadrilateral.topRight.y)]];
            [quadArray addObject:@[@(result.quadrilateral.bottomRight.x), @(result.quadrilateral.bottomRight.y)]];
            [quadArray addObject:@[@(result.quadrilateral.bottomLeft.x), @(result.quadrilateral.bottomLeft.y)]];
            resultDict[@"quadrilateral"] = quadArray;
            
            resultDict[@"confidence"] = @(result.confidence);
            
            if (!result.outputUri.empty()) {
                resultDict[@"outputUri"] = [NSString stringWithUTF8String:result.outputUri.c_str()];
            }
            if (!result.maskUri.empty()) {
                resultDict[@"maskUri"] = [NSString stringWithUTF8String:result.maskUri.c_str()];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(resultDict);
            });
            
        } @catch (NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                reject(@"SCAN_ERROR", exception.reason, nil);
            });
        }
    });
}

- (void)scanFrame:(NSArray<NSNumber *> *)rgba
            width:(double)width
           height:(double)height
          options:(JS::NativeDocumentScannerAi::ScanOptions &)options
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // Convert RGBA array to cv::Mat
            std::vector<uint8_t> rgbaData;
            rgbaData.reserve(rgba.count);
            for (NSNumber *byte in rgba) {
                rgbaData.push_back([byte unsignedCharValue]);
            }
            
            cv::Mat frame(height, width, CV_8UC4, rgbaData.data());
            cv::Mat bgrFrame;
            cv::cvtColor(frame, bgrFrame, cv::COLOR_RGBA2BGR);
            
            // Convert options to native
            DocumentScanner::ScanOptions nativeOptions;
            nativeOptions.threshold = options.threshold().value_or(0.5);
            nativeOptions.maxSize = options.maxSize().value_or(1024);
            nativeOptions.enhance = options.enhance().value_or("none");
            nativeOptions.returnMask = options.returnMask().value_or(false);
            nativeOptions.saveOutput = options.saveOutput().value_or(false);
            nativeOptions.outputFormat = options.outputFormat().value_or("jpg");
            nativeOptions.outputQuality = options.outputQuality().value_or(90);
            nativeOptions.autoCapture = options.autoCapture().value_or(false);
            nativeOptions.captureConfidence = options.captureConfidence().value_or(0.8);
            nativeOptions.captureConsecutiveFrames = options.captureConsecutiveFrames().value_or(3);
            nativeOptions.maxProcessingFps = options.maxProcessingFps().value_or(30);
            
            // Create core and scan
            auto core = std::make_shared<DocumentScanner::DocumentScannerCore>();
            NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"document_segmentation" ofType:@"onnx"];
            
            if (![core->initialize:[modelPath UTF8String]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    reject(@"INIT_ERROR", @"Failed to initialize DocumentScannerCore", nil);
                });
                return;
            }
            
            auto result = core->scanFrame(bgrFrame, nativeOptions);
            
            // Convert result to NSDictionary
            NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
            
            // Quadrilateral
            NSMutableArray *quadArray = [NSMutableArray array];
            [quadArray addObject:@[@(result.quadrilateral.topLeft.x), @(result.quadrilateral.topLeft.y)]];
            [quadArray addObject:@[@(result.quadrilateral.topRight.x), @(result.quadrilateral.topRight.y)]];
            [quadArray addObject:@[@(result.quadrilateral.bottomRight.x), @(result.quadrilateral.bottomRight.y)]];
            [quadArray addObject:@[@(result.quadrilateral.bottomLeft.x), @(result.quadrilateral.bottomLeft.y)]];
            resultDict[@"quadrilateral"] = quadArray;
            
            resultDict[@"confidence"] = @(result.confidence);
            
            if (!result.outputUri.empty()) {
                resultDict[@"outputUri"] = [NSString stringWithUTF8String:result.outputUri.c_str()];
            }
            if (!result.maskUri.empty()) {
                resultDict[@"maskUri"] = [NSString stringWithUTF8String:result.maskUri.c_str()];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(resultDict);
            });
            
        } @catch (NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                reject(@"SCAN_ERROR", exception.reason, nil);
            });
        }
    });
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeDocumentScannerAiSpecJSI>(params);
}

@end
