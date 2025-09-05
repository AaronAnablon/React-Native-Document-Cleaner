#include "JSIDocumentScanner.h"
#include <opencv2/opencv.hpp>

namespace DocumentScanner {

JSIDocumentScanner::JSIDocumentScanner(std::shared_ptr<DocumentScannerCore> core) 
    : m_core(std::move(core)) {
}

facebook::jsi::Value JSIDocumentScanner::get(facebook::jsi::Runtime& runtime, const facebook::jsi::PropNameID& name) {
    auto propName = name.utf8(runtime);
    
    if (propName == "scanImage") {
        return facebook::jsi::Function::createFromHostFunction(
            runtime,
            facebook::jsi::PropNameID::forAscii(runtime, "scanImage"),
            2,
            [this](facebook::jsi::Runtime& runtime, const facebook::jsi::Value& thisValue, const facebook::jsi::Value* arguments, size_t count) -> facebook::jsi::Value {
                if (count < 2) {
                    throw facebook::jsi::JSError(runtime, "scanImage requires 2 arguments: uri and options");
                }
                
                std::string uri = arguments[0].asString(runtime).utf8(runtime);
                ScanOptions options = jsObjectToScanOptions(runtime, arguments[1].asObject(runtime));
                
                // Run scan in background thread and return promise
                auto promise = facebook::jsi::Promise::create(runtime, [this, uri, options](facebook::jsi::Runtime& runtime) -> facebook::jsi::Value {
                    ScanResult result = m_core->scanImage(uri, options);
                    return scanResultToJSObject(runtime, result);
                });
                
                return promise;
            }
        );
    }
    
    if (propName == "scanFrame") {
        return facebook::jsi::Function::createFromHostFunction(
            runtime,
            facebook::jsi::PropNameID::forAscii(runtime, "scanFrame"),
            4,
            [this](facebook::jsi::Runtime& runtime, const facebook::jsi::Value& thisValue, const facebook::jsi::Value* arguments, size_t count) -> facebook::jsi::Value {
                if (count < 4) {
                    throw facebook::jsi::JSError(runtime, "scanFrame requires 4 arguments: rgba, width, height, options");
                }
                
                // Convert RGBA buffer to cv::Mat
                std::vector<uint8_t> rgbaData = jsArrayBufferToVector(runtime, arguments[0].asObject(runtime));
                int width = static_cast<int>(arguments[1].asNumber());
                int height = static_cast<int>(arguments[2].asNumber());
                ScanOptions options = jsObjectToScanOptions(runtime, arguments[3].asObject(runtime));
                
                cv::Mat frame(height, width, CV_8UC4, rgbaData.data());
                cv::Mat bgrFrame;
                cv::cvtColor(frame, bgrFrame, cv::COLOR_RGBA2BGR);
                
                // Run scan in background thread and return promise
                auto promise = facebook::jsi::Promise::create(runtime, [this, bgrFrame, options](facebook::jsi::Runtime& runtime) -> facebook::jsi::Value {
                    ScanResult result = m_core->scanFrame(bgrFrame, options);
                    return scanResultToJSObject(runtime, result);
                });
                
                return promise;
            }
        );
    }
    
    return facebook::jsi::Value::undefined();
}

std::vector<facebook::jsi::PropNameID> JSIDocumentScanner::getPropertyNames(facebook::jsi::Runtime& runtime) {
    return {
        facebook::jsi::PropNameID::forAscii(runtime, "scanImage"),
        facebook::jsi::PropNameID::forAscii(runtime, "scanFrame")
    };
}

ScanOptions JSIDocumentScanner::jsObjectToScanOptions(facebook::jsi::Runtime& runtime, const facebook::jsi::Object& jsOptions) {
    ScanOptions options;
    
    if (jsOptions.hasProperty(runtime, "onnxModel")) {
        options.onnxModel = jsOptions.getProperty(runtime, "onnxModel").asString(runtime).utf8(runtime);
    }
    if (jsOptions.hasProperty(runtime, "threshold")) {
        options.threshold = static_cast<float>(jsOptions.getProperty(runtime, "threshold").asNumber());
    }
    if (jsOptions.hasProperty(runtime, "maxSize")) {
        options.maxSize = static_cast<int>(jsOptions.getProperty(runtime, "maxSize").asNumber());
    }
    if (jsOptions.hasProperty(runtime, "enhance")) {
        options.enhance = jsOptions.getProperty(runtime, "enhance").asString(runtime).utf8(runtime);
    }
    if (jsOptions.hasProperty(runtime, "returnMask")) {
        options.returnMask = jsOptions.getProperty(runtime, "returnMask").asBool();
    }
    if (jsOptions.hasProperty(runtime, "saveOutput")) {
        options.saveOutput = jsOptions.getProperty(runtime, "saveOutput").asBool();
    }
    if (jsOptions.hasProperty(runtime, "outputFormat")) {
        options.outputFormat = jsOptions.getProperty(runtime, "outputFormat").asString(runtime).utf8(runtime);
    }
    if (jsOptions.hasProperty(runtime, "outputQuality")) {
        options.outputQuality = static_cast<int>(jsOptions.getProperty(runtime, "outputQuality").asNumber());
    }
    if (jsOptions.hasProperty(runtime, "autoCapture")) {
        options.autoCapture = jsOptions.getProperty(runtime, "autoCapture").asBool();
    }
    if (jsOptions.hasProperty(runtime, "captureConfidence")) {
        options.captureConfidence = static_cast<float>(jsOptions.getProperty(runtime, "captureConfidence").asNumber());
    }
    if (jsOptions.hasProperty(runtime, "captureConsecutiveFrames")) {
        options.captureConsecutiveFrames = static_cast<int>(jsOptions.getProperty(runtime, "captureConsecutiveFrames").asNumber());
    }
    if (jsOptions.hasProperty(runtime, "maxProcessingFps")) {
        options.maxProcessingFps = static_cast<int>(jsOptions.getProperty(runtime, "maxProcessingFps").asNumber());
    }
    
    return options;
}

facebook::jsi::Object JSIDocumentScanner::scanResultToJSObject(facebook::jsi::Runtime& runtime, const ScanResult& result) {
    facebook::jsi::Object jsResult(runtime);
    
    jsResult.setProperty(runtime, "quadrilateral", quadrilateralToJSArray(runtime, result.quadrilateral));
    jsResult.setProperty(runtime, "confidence", facebook::jsi::Value(result.confidence));
    
    if (!result.outputUri.empty()) {
        jsResult.setProperty(runtime, "outputUri", facebook::jsi::String::createFromUtf8(runtime, result.outputUri));
    }
    if (!result.maskUri.empty()) {
        jsResult.setProperty(runtime, "maskUri", facebook::jsi::String::createFromUtf8(runtime, result.maskUri));
    }
    
    return jsResult;
}

facebook::jsi::Array JSIDocumentScanner::quadrilateralToJSArray(facebook::jsi::Runtime& runtime, const Quadrilateral& quad) {
    facebook::jsi::Array jsQuad = facebook::jsi::Array(runtime, 4);
    
    // Top-left
    facebook::jsi::Array topLeft = facebook::jsi::Array(runtime, 2);
    topLeft.setValueAtIndex(runtime, 0, facebook::jsi::Value(quad.topLeft.x));
    topLeft.setValueAtIndex(runtime, 1, facebook::jsi::Value(quad.topLeft.y));
    jsQuad.setValueAtIndex(runtime, 0, topLeft);
    
    // Top-right
    facebook::jsi::Array topRight = facebook::jsi::Array(runtime, 2);
    topRight.setValueAtIndex(runtime, 0, facebook::jsi::Value(quad.topRight.x));
    topRight.setValueAtIndex(runtime, 1, facebook::jsi::Value(quad.topRight.y));
    jsQuad.setValueAtIndex(runtime, 1, topRight);
    
    // Bottom-right
    facebook::jsi::Array bottomRight = facebook::jsi::Array(runtime, 2);
    bottomRight.setValueAtIndex(runtime, 0, facebook::jsi::Value(quad.bottomRight.x));
    bottomRight.setValueAtIndex(runtime, 1, facebook::jsi::Value(quad.bottomRight.y));
    jsQuad.setValueAtIndex(runtime, 2, bottomRight);
    
    // Bottom-left
    facebook::jsi::Array bottomLeft = facebook::jsi::Array(runtime, 2);
    bottomLeft.setValueAtIndex(runtime, 0, facebook::jsi::Value(quad.bottomLeft.x));
    bottomLeft.setValueAtIndex(runtime, 1, facebook::jsi::Value(quad.bottomLeft.y));
    jsQuad.setValueAtIndex(runtime, 3, bottomLeft);
    
    return jsQuad;
}

std::vector<uint8_t> JSIDocumentScanner::jsArrayBufferToVector(facebook::jsi::Runtime& runtime, const facebook::jsi::Object& arrayBuffer) {
    if (!arrayBuffer.isArrayBuffer(runtime)) {
        throw facebook::jsi::JSError(runtime, "Expected ArrayBuffer");
    }
    
    auto buffer = arrayBuffer.getArrayBuffer(runtime);
    uint8_t* data = buffer.data(runtime);
    size_t size = buffer.size(runtime);
    
    return std::vector<uint8_t>(data, data + size);
}

void installDocumentScannerJSI(facebook::jsi::Runtime& runtime, const std::string& modelPath) {
    auto core = std::make_shared<DocumentScannerCore>();
    if (!core->initialize(modelPath)) {
        throw facebook::jsi::JSError(runtime, "Failed to initialize DocumentScannerCore");
    }
    
    auto jsiScanner = std::make_shared<JSIDocumentScanner>(core);
    runtime.global().setProperty(runtime, "__DocumentScannerJSI", facebook::jsi::Object::createFromHostObject(runtime, jsiScanner));
}

} // namespace DocumentScanner
