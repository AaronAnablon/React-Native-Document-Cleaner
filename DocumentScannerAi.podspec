require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "DocumentScannerAi"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/aaron/react-native-document-scanner-ai.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,cpp}", "cpp/**/*.{h,cpp}"
  s.private_header_files = "ios/**/*.h", "cpp/**/*.h"
  
  # Include C++ files
  s.public_header_files = "cpp/DocumentScannerCore.h", "cpp/JSIDocumentScanner.h"
  
  # Compiler flags for C++17 and OpenCV
  s.compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'OTHER_CPLUSPLUSFLAGS' => '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'FOLLY_NO_CONFIG=1 FOLLY_MOBILE=1 FOLLY_USE_LIBCPP=1'
  }
  
  # Frameworks
  s.frameworks = 'Accelerate', 'AVFoundation', 'CoreImage', 'CoreMedia', 'CoreVideo'
  
  # Dependencies
  s.dependency "OpenCV2", "~> 4.5.0"
  s.dependency "onnxruntime-c", "~> 1.16.0"

  install_modules_dependencies(s)
end
