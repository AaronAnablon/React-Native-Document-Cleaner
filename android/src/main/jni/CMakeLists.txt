cmake_minimum_required(VERSION 3.22.1)

project(DocumentScannerAi)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set the path to your C++ source files
set(CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../cpp")

# Add OpenCV package
find_package(OpenCV REQUIRED)

# Create shared library
add_library(DocumentScannerAi SHARED
    ${CPP_DIR}/DocumentScannerCore.cpp
    ${CPP_DIR}/JSIDocumentScanner.cpp
    android_jni.cpp
)

# Include directories
target_include_directories(DocumentScannerAi PRIVATE
    ${CPP_DIR}
    ${OpenCV_INCLUDE_DIRS}
)

# Link libraries
target_link_libraries(DocumentScannerAi
    ${OpenCV_LIBS}
    android
    log
)

# Set C++ properties
set_target_properties(DocumentScannerAi PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)
