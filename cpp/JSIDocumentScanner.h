#pragma once

#include <jsi/jsi.h>
#include <memory>
#include "DocumentScannerCore.h"

namespace DocumentScanner {

class JSIDocumentScanner : public facebook::jsi::HostObject {
public:
    explicit JSIDocumentScanner(std::shared_ptr<DocumentScannerCore> core);
    
    facebook::jsi::Value get(facebook::jsi::Runtime& runtime, const facebook::jsi::PropNameID& name) override;
    std::vector<facebook::jsi::PropNameID> getPropertyNames(facebook::jsi::Runtime& runtime) override;
    
private:
    std::shared_ptr<DocumentScannerCore> m_core;
    
    // Helper functions for JS <-> C++ conversion
    ScanOptions jsObjectToScanOptions(facebook::jsi::Runtime& runtime, const facebook::jsi::Object& jsOptions);
    facebook::jsi::Object scanResultToJSObject(facebook::jsi::Runtime& runtime, const ScanResult& result);
    facebook::jsi::Array quadrilateralToJSArray(facebook::jsi::Runtime& runtime, const Quadrilateral& quad);
    std::vector<uint8_t> jsArrayBufferToVector(facebook::jsi::Runtime& runtime, const facebook::jsi::Object& arrayBuffer);
};

// Installation function for React Native
void installDocumentScannerJSI(facebook::jsi::Runtime& runtime, const std::string& modelPath);

} // namespace DocumentScanner
