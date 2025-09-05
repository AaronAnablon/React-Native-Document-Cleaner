#pragma once

#include <opencv2/opencv.hpp>
#include <vector>
#include <string>

namespace DocumentScanner {

struct Point2D {
    float x, y;
    Point2D(float x = 0, float y = 0) : x(x), y(y) {}
};

struct Quadrilateral {
    Point2D topLeft, topRight, bottomRight, bottomLeft;
    Quadrilateral() = default;
    Quadrilateral(Point2D tl, Point2D tr, Point2D br, Point2D bl) 
        : topLeft(tl), topRight(tr), bottomRight(br), bottomLeft(bl) {}
};

struct ScanOptions {
    std::string onnxModel = "";
    float threshold = 0.5f;
    int maxSize = 1024;
    std::string enhance = "none";
    bool returnMask = false;
    bool saveOutput = false;
    std::string outputFormat = "jpg";
    int outputQuality = 90;
    bool autoCapture = false;
    float captureConfidence = 0.8f;
    int captureConsecutiveFrames = 3;
    int maxProcessingFps = 30;
};

struct ScanResult {
    Quadrilateral quadrilateral;
    float confidence = 0.0f;
    std::string outputUri = "";
    std::string maskUri = "";
};

class DocumentScannerCore {
public:
    DocumentScannerCore();
    ~DocumentScannerCore();
    
    // Initialize ONNX Runtime and load model
    bool initialize(const std::string& modelPath);
    
    // Main scanning functions
    ScanResult scanImage(const std::string& imagePath, const ScanOptions& options);
    ScanResult scanFrame(const cv::Mat& frame, const ScanOptions& options);
    
    // Core processing functions
    cv::Mat runSegmentation(const cv::Mat& input);
    Quadrilateral findQuadFromMask(const cv::Mat& mask);
    cv::Mat warpToQuad(const cv::Mat& input, const Quadrilateral& quad);
    cv::Mat enhance(const cv::Mat& input, const std::string& mode);
    
    // Utility functions
    std::string saveOutput(const cv::Mat& image, const std::string& format, int quality);
    bool isQuadStable(const Quadrilateral& quad, float confidence);
    
private:
    void* m_onnxSession;
    void* m_onnxEnvironment;
    bool m_initialized;
    
    // Auto-capture state
    std::vector<Quadrilateral> m_recentQuads;
    std::vector<float> m_recentConfidences;
    int m_stableFrameCount;
    
    // Helper methods
    cv::Mat preprocessForONNX(const cv::Mat& input, int targetSize);
    cv::Mat postprocessONNXOutput(void* outputTensor, int width, int height);
    std::vector<cv::Point> findLargestContour(const cv::Mat& mask);
    Quadrilateral approximateQuadrilateral(const std::vector<cv::Point>& contour);
    cv::Mat applyPerspectiveTransform(const cv::Mat& src, const Quadrilateral& quad, cv::Size outputSize);
};

} // namespace DocumentScanner
