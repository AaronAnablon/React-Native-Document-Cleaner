# Changelog

All notable changes to this project will be documented in this file.

## [2.5.2] - 2025-09-05

### 🐛 Bug Fixes
- **Critical Fix**: Resolved "Tried to access a JS module before the React instance was fully set up" error
- **Safe Module Initialization**: Implemented lazy loading pattern for native module access
- **Improved Error Handling**: Added comprehensive error boundaries and initialization checks

### ✨ New Features
- **Safe Import Helper**: Added `createSafeImport()` function for consumers
- **Lazy Loading Support**: Native module is now only initialized when actually needed
- **Enhanced Error Messages**: More helpful error messages with solutions

### 📚 Documentation
- **Safe Import Guide**: Added comprehensive `SAFE_IMPORT.md` with examples
- **Updated README**: Added safe import patterns and troubleshooting section
- **Consumer Examples**: Multiple safe import patterns for different use cases

### 🔧 Technical Improvements
- **Native Module Proxy**: Implemented proxy pattern to defer native module access
- **Error Caching**: Prevents repeated initialization attempts after failure
- **Development Warnings**: Better development-time warnings without breaking production

## [2.1.0] - 2025-09-05

### 🚀 Major Changes
- **Package Export Improvements**: Enhanced file exports to include all necessary assets when developers install the library
- **Comprehensive Model Inclusion**: ONNX models and assets are now properly bundled with the package
- **Naming Consistency**: Corrected all naming inconsistencies throughout the project

### ✨ New Features
- **Enhanced Package Exports**: Added proper exports for models and assets directories
- **Installation Guide**: Added comprehensive `INSTALLATION.md` with step-by-step setup instructions
- **Setup Verification**: New `verify-setup` script to help developers validate their installation
- **Improved Documentation**: Updated README with better setup instructions and troubleshooting
- **Model Documentation**: Enhanced `models/README.md` with detailed model specifications

### 🔧 Improvements
- **Package.json Updates**:
  - Corrected package name consistency (`react-native-document-scanner-ai`)
  - Added models and assets to files array for proper distribution
  - Enhanced exports configuration for better module resolution
  - Updated repository URLs and metadata
- **Documentation Enhancements**:
  - Clearer installation instructions for both iOS and Android
  - Better explanation of included dependencies
  - Added verification steps for developers
  - Comprehensive troubleshooting section

### 📦 Dependencies
- **Automatic Inclusion**: OpenCV and ONNX Runtime dependencies are now automatically managed
- **Bundled Models**: Pre-trained ONNX models are included in the package
- **Simplified Setup**: Reduced manual configuration steps for developers

### 🗂️ File Structure
- **Included in Package**:
  - ✅ Source code (`src/`)
  - ✅ Compiled modules (`lib/`)
  - ✅ Native Android code (`android/`)
  - ✅ Native iOS code (`ios/`)
  - ✅ C++ core (`cpp/`)
  - ✅ ONNX models (`models/`)
  - ✅ Assets (`assets/`)
  - ✅ Setup scripts (`scripts/`)
  - ✅ Documentation (`*.md`)
  - ✅ Platform configurations

### 🛠️ Developer Experience
- **Simplified Installation**: One command installation with automatic setup
- **Better Error Handling**: Improved error messages and troubleshooting guides
- **Enhanced TypeScript Support**: Complete type definitions included
- **Example Integration**: Updated example app for reference

### 📱 Platform Support
- **iOS**: Automatic CocoaPods integration with OpenCV and ONNX Runtime
- **Android**: Automatic Gradle integration with native dependencies
- **Cross-Platform**: Consistent API across both platforms

### 🔒 Breaking Changes
- Package name standardized to `react-native-document-scanner-ai`
- Some internal naming has been updated for consistency
- Removed dependency on manual model setup (now automated)

### 🐛 Bug Fixes
- Fixed inconsistent package naming across files
- Resolved missing file exports in npm package
- Corrected repository URLs and metadata
- Fixed example app workspace configuration

### 📚 Documentation
- Comprehensive installation guide
- Updated API documentation
- Model specifications and requirements
- Troubleshooting and FAQ sections
- Performance optimization tips

---

## Previous Versions

### [1.x.x] - Earlier Releases
- Initial implementation with manual setup requirements
- Basic ONNX Runtime integration
- OpenCV-based document detection
