#include "DocumentScannerCore.h"
#include <onnxruntime/core/session/onnxruntime_cxx_api.h>
#include <opencv2/imgproc.hpp>
#include <opencv2/imgcodecs.hpp>
#include <fstream>
#include <chrono>

namespace DocumentScanner {

DocumentScannerCore::DocumentScannerCore() 
    : m_onnxSession(nullptr), m_onnxEnvironment(nullptr), m_initialized(false), m_stableFrameCount(0) {
}

DocumentScannerCore::~DocumentScannerCore() {
    if (m_onnxSession) {
        delete static_cast<Ort::Session*>(m_onnxSession);
    }
    if (m_onnxEnvironment) {
        delete static_cast<Ort::Env*>(m_onnxEnvironment);
    }
}

bool DocumentScannerCore::initialize(const std::string& modelPath) {
    try {
        // Initialize ONNX Runtime environment
        auto* env = new Ort::Env(ORT_LOGGING_LEVEL_WARNING, "DocumentScanner");
        m_onnxEnvironment = env;
        
        // Create session options
        Ort::SessionOptions sessionOptions;
        sessionOptions.SetIntraOpNumThreads(1);
        sessionOptions.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_EXTENDED);
        
        // Create session
        auto* session = new Ort::Session(*env, modelPath.c_str(), sessionOptions);
        m_onnxSession = session;
        
        m_initialized = true;
        return true;
    } catch (const std::exception& e) {
        return false;
    }
}

ScanResult DocumentScannerCore::scanImage(const std::string& imagePath, const ScanOptions& options) {
    ScanResult result;
    
    // Load image
    cv::Mat image = cv::imread(imagePath);
    if (image.empty()) {
        return result;
    }
    
    return scanFrame(image, options);
}

ScanResult DocumentScannerCore::scanFrame(const cv::Mat& frame, const ScanOptions& options) {
    ScanResult result;
    
    if (!m_initialized) {
        return result;
    }
    
    cv::Mat processedFrame = frame.clone();
    
    // Resize if needed for performance
    if (options.maxSize > 0 && (frame.rows > options.maxSize || frame.cols > options.maxSize)) {
        float scale = static_cast<float>(options.maxSize) / std::max(frame.rows, frame.cols);
        cv::resize(frame, processedFrame, cv::Size(), scale, scale);
    }
    
    // Run segmentation
    cv::Mat mask = runSegmentation(processedFrame);
    if (mask.empty()) {
        return result;
    }
    
    // Find quadrilateral from mask
    Quadrilateral quad = findQuadFromMask(mask);
    
    // Calculate confidence based on mask quality
    cv::Scalar maskMean = cv::mean(mask);
    result.confidence = maskMean[0] / 255.0f;
    
    // Scale quad back to original image size if we resized
    if (processedFrame.size() != frame.size()) {
        float scaleX = static_cast<float>(frame.cols) / processedFrame.cols;
        float scaleY = static_cast<float>(frame.rows) / processedFrame.rows;
        
        quad.topLeft.x *= scaleX; quad.topLeft.y *= scaleY;
        quad.topRight.x *= scaleX; quad.topRight.y *= scaleY;
        quad.bottomRight.x *= scaleX; quad.bottomRight.y *= scaleY;
        quad.bottomLeft.x *= scaleX; quad.bottomLeft.y *= scaleY;
    }
    
    result.quadrilateral = quad;
    
    // Handle auto-capture logic
    if (options.autoCapture) {
        if (isQuadStable(quad, result.confidence)) {
            if (m_stableFrameCount >= options.captureConsecutiveFrames) {
                // Auto-capture triggered - force save output
                ScanOptions captureOptions = options;
                captureOptions.saveOutput = true;
                result = scanFrame(frame, captureOptions);
                m_stableFrameCount = 0; // Reset counter
            }
        } else {
            m_stableFrameCount = 0;
        }
    }
    
    // Warp and save output if requested
    if (options.saveOutput || (options.autoCapture && m_stableFrameCount >= options.captureConsecutiveFrames)) {
        cv::Mat warped = warpToQuad(frame, quad);
        if (!warped.empty()) {
            // Apply enhancement
            cv::Mat enhanced = enhance(warped, options.enhance);
            
            // Save output
            result.outputUri = saveOutput(enhanced, options.outputFormat, options.outputQuality);
        }
    }
    
    // Save mask if requested
    if (options.returnMask) {
        // Scale mask back to original size if needed
        cv::Mat fullMask = mask;
        if (processedFrame.size() != frame.size()) {
            cv::resize(mask, fullMask, frame.size());
        }
        result.maskUri = saveOutput(fullMask, "png", 100);
    }
    
    return result;
}

cv::Mat DocumentScannerCore::runSegmentation(const cv::Mat& input) {
    if (!m_initialized) {
        return cv::Mat();
    }
    
    try {
        auto* session = static_cast<Ort::Session*>(m_onnxSession);
        auto* env = static_cast<Ort::Env*>(m_onnxEnvironment);
        
        // Preprocess input
        cv::Mat preprocessed = preprocessForONNX(input, 512);
        
        // Create input tensor
        std::vector<int64_t> inputShape = {1, 3, 512, 512};
        size_t inputTensorSize = 1 * 3 * 512 * 512;
        std::vector<float> inputTensorValues(inputTensorSize);
        
        // Convert BGR to RGB and normalize
        cv::Mat rgb;
        cv::cvtColor(preprocessed, rgb, cv::COLOR_BGR2RGB);
        rgb.convertTo(rgb, CV_32F, 1.0/255.0);
        
        // Fill tensor (CHW format)
        for (int c = 0; c < 3; ++c) {
            for (int h = 0; h < 512; ++h) {
                for (int w = 0; w < 512; ++w) {
                    inputTensorValues[c * 512 * 512 + h * 512 + w] = 
                        rgb.at<cv::Vec3f>(h, w)[c];
                }
            }
        }
        
        // Create ONNX tensor
        auto allocatorInfo = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
        Ort::Value inputTensor = Ort::Value::CreateTensor<float>(
            allocatorInfo, inputTensorValues.data(), inputTensorSize, 
            inputShape.data(), inputShape.size());
        
        // Get input/output names
        auto inputName = session->GetInputNameAllocated(0, Ort::AllocatorWithDefaultOptions());
        auto outputName = session->GetOutputNameAllocated(0, Ort::AllocatorWithDefaultOptions());
        
        const char* inputNames[] = {inputName.get()};
        const char* outputNames[] = {outputName.get()};
        
        // Run inference
        auto outputTensors = session->Run(Ort::RunOptions{nullptr}, 
                                        inputNames, &inputTensor, 1, 
                                        outputNames, 1);
        
        // Postprocess output
        return postprocessONNXOutput(&outputTensors[0], input.cols, input.rows);
        
    } catch (const std::exception& e) {
        return cv::Mat();
    }
}

cv::Mat DocumentScannerCore::preprocessForONNX(const cv::Mat& input, int targetSize) {
    cv::Mat result;
    cv::resize(input, result, cv::Size(targetSize, targetSize));
    return result;
}

cv::Mat DocumentScannerCore::postprocessONNXOutput(void* outputTensor, int width, int height) {
    auto* tensor = static_cast<Ort::Value*>(outputTensor);
    
    // Get tensor data
    float* floatArray = tensor->GetTensorMutableData<float>();
    auto shape = tensor->GetTensorTypeAndShapeInfo().GetShape();
    
    // Assuming output is [1, 1, H, W]
    int h = static_cast<int>(shape[2]);
    int w = static_cast<int>(shape[3]);
    
    // Create mask from output
    cv::Mat mask(h, w, CV_32F, floatArray);
    
    // Convert to 8-bit and resize to original dimensions
    cv::Mat result;
    mask.convertTo(result, CV_8U, 255.0);
    cv::resize(result, result, cv::Size(width, height));
    
    return result;
}

Quadrilateral DocumentScannerCore::findQuadFromMask(const cv::Mat& mask) {
    Quadrilateral result;
    
    // Find contours
    std::vector<cv::Point> largestContour = findLargestContour(mask);
    if (largestContour.size() < 4) {
        return result;
    }
    
    // Approximate to quadrilateral
    return approximateQuadrilateral(largestContour);
}

std::vector<cv::Point> DocumentScannerCore::findLargestContour(const cv::Mat& mask) {
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(mask, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    if (contours.empty()) {
        return std::vector<cv::Point>();
    }
    
    // Find largest contour by area
    double maxArea = 0;
    int maxAreaIdx = 0;
    for (size_t i = 0; i < contours.size(); i++) {
        double area = cv::contourArea(contours[i]);
        if (area > maxArea) {
            maxArea = area;
            maxAreaIdx = i;
        }
    }
    
    return contours[maxAreaIdx];
}

Quadrilateral DocumentScannerCore::approximateQuadrilateral(const std::vector<cv::Point>& contour) {
    // Approximate contour to polygon
    std::vector<cv::Point> approx;
    double epsilon = 0.02 * cv::arcLength(contour, true);
    cv::approxPolyDP(contour, approx, epsilon, true);
    
    // If we don't have exactly 4 points, find the 4 corner points
    if (approx.size() != 4) {
        // Find convex hull
        std::vector<cv::Point> hull;
        cv::convexHull(contour, hull);
        
        if (hull.size() >= 4) {
            // Find the 4 corner points (top-left, top-right, bottom-right, bottom-left)
            cv::Point2f center(0, 0);
            for (const auto& pt : hull) {
                center.x += pt.x;
                center.y += pt.y;
            }
            center.x /= hull.size();
            center.y /= hull.size();
            
            // Sort points based on their position relative to center
            std::vector<cv::Point> corners(4);
            
            // Find corner points by distance and angle from center
            cv::Point topLeft = hull[0], topRight = hull[0], bottomLeft = hull[0], bottomRight = hull[0];
            
            for (const auto& pt : hull) {
                if (pt.x < center.x && pt.y < center.y) { // Top-left quadrant
                    if ((pt.x + pt.y) < (topLeft.x + topLeft.y)) topLeft = pt;
                }
                if (pt.x > center.x && pt.y < center.y) { // Top-right quadrant
                    if ((pt.x - pt.y) > (topRight.x - topRight.y)) topRight = pt;
                }
                if (pt.x > center.x && pt.y > center.y) { // Bottom-right quadrant
                    if ((pt.x + pt.y) > (bottomRight.x + bottomRight.y)) bottomRight = pt;
                }
                if (pt.x < center.x && pt.y > center.y) { // Bottom-left quadrant
                    if ((pt.y - pt.x) > (bottomLeft.y - bottomLeft.x)) bottomLeft = pt;
                }
            }
            
            approx = {topLeft, topRight, bottomRight, bottomLeft};
        }
    }
    
    if (approx.size() >= 4) {
        return Quadrilateral(
            Point2D(approx[0].x, approx[0].y),
            Point2D(approx[1].x, approx[1].y),
            Point2D(approx[2].x, approx[2].y),
            Point2D(approx[3].x, approx[3].y)
        );
    }
    
    return Quadrilateral();
}

cv::Mat DocumentScannerCore::warpToQuad(const cv::Mat& input, const Quadrilateral& quad) {
    // Define destination points for A4 aspect ratio
    float aspectRatio = std::sqrt(2.0f); // A4 ratio
    int outputWidth = 800;
    int outputHeight = static_cast<int>(outputWidth * aspectRatio);
    
    std::vector<cv::Point2f> srcPoints = {
        cv::Point2f(quad.topLeft.x, quad.topLeft.y),
        cv::Point2f(quad.topRight.x, quad.topRight.y),
        cv::Point2f(quad.bottomRight.x, quad.bottomRight.y),
        cv::Point2f(quad.bottomLeft.x, quad.bottomLeft.y)
    };
    
    std::vector<cv::Point2f> dstPoints = {
        cv::Point2f(0, 0),
        cv::Point2f(outputWidth, 0),
        cv::Point2f(outputWidth, outputHeight),
        cv::Point2f(0, outputHeight)
    };
    
    // Get perspective transform matrix
    cv::Mat transformMatrix = cv::getPerspectiveTransform(srcPoints, dstPoints);
    
    // Apply transform
    cv::Mat warped;
    cv::warpPerspective(input, warped, transformMatrix, cv::Size(outputWidth, outputHeight));
    
    return warped;
}

cv::Mat DocumentScannerCore::enhance(const cv::Mat& input, const std::string& mode) {
    cv::Mat result = input.clone();
    
    if (mode == "bw") {
        // Convert to grayscale and apply adaptive threshold
        cv::Mat gray;
        cv::cvtColor(result, gray, cv::COLOR_BGR2GRAY);
        cv::adaptiveThreshold(gray, gray, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 11, 2);
        cv::cvtColor(gray, result, cv::COLOR_GRAY2BGR);
    } else if (mode == "contrast") {
        // Increase contrast
        cv::cvtColor(result, result, cv::COLOR_BGR2LAB);
        std::vector<cv::Mat> channels;
        cv::split(result, channels);
        cv::createCLAHE(3.0, cv::Size(8, 8))->apply(channels[0], channels[0]);
        cv::merge(channels, result);
        cv::cvtColor(result, result, cv::COLOR_LAB2BGR);
    }
    
    return result;
}

std::string DocumentScannerCore::saveOutput(const cv::Mat& image, const std::string& format, int quality) {
    // Generate unique filename
    auto now = std::chrono::system_clock::now();
    auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
    
    std::string filename = "/tmp/document_" + std::to_string(timestamp) + "." + format;
    
    // Set compression parameters
    std::vector<int> params;
    if (format == "jpg" || format == "jpeg") {
        params = {cv::IMWRITE_JPEG_QUALITY, quality};
    } else if (format == "png") {
        params = {cv::IMWRITE_PNG_COMPRESSION, 9 - (quality / 10)};
    }
    
    // Save image
    if (cv::imwrite(filename, image, params)) {
        return filename;
    }
    
    return "";
}

bool DocumentScannerCore::isQuadStable(const Quadrilateral& quad, float confidence) {
    m_recentQuads.push_back(quad);
    m_recentConfidences.push_back(confidence);
    
    // Keep only recent frames
    const int maxFrames = 10;
    if (m_recentQuads.size() > maxFrames) {
        m_recentQuads.erase(m_recentQuads.begin());
        m_recentConfidences.erase(m_recentConfidences.begin());
    }
    
    if (m_recentQuads.size() < 3) {
        return false;
    }
    
    // Check if recent quads are similar and confidence is good
    const float maxDistance = 20.0f; // pixels
    const float minConfidence = 0.7f;
    
    bool isStable = true;
    for (size_t i = 1; i < m_recentQuads.size(); i++) {
        const auto& q1 = m_recentQuads[i-1];
        const auto& q2 = m_recentQuads[i];
        
        float distance = std::sqrt(
            (q1.topLeft.x - q2.topLeft.x) * (q1.topLeft.x - q2.topLeft.x) +
            (q1.topLeft.y - q2.topLeft.y) * (q1.topLeft.y - q2.topLeft.y)
        );
        
        if (distance > maxDistance || m_recentConfidences[i] < minConfidence) {
            isStable = false;
            break;
        }
    }
    
    if (isStable) {
        m_stableFrameCount++;
    } else {
        m_stableFrameCount = 0;
    }
    
    return isStable;
}

} // namespace DocumentScanner
