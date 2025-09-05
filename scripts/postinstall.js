#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function copyModelFiles() {
  try {
    const packageRoot = path.dirname(__dirname);
    const modelSrc = path.join(packageRoot, 'models', 'document_segmentation.onnx');
    
    // Find the project root (where node_modules is)
    let currentDir = process.cwd();
    while (currentDir !== path.dirname(currentDir)) {
      if (fs.existsSync(path.join(currentDir, 'node_modules'))) {
        break;
      }
      currentDir = path.dirname(currentDir);
    }
    
    // Copy to Android assets
    const androidAssetsDir = path.join(currentDir, 'android', 'app', 'src', 'main', 'assets');
    if (fs.existsSync(path.dirname(androidAssetsDir))) {
      if (!fs.existsSync(androidAssetsDir)) {
        fs.mkdirSync(androidAssetsDir, { recursive: true });
      }
      const androidDest = path.join(androidAssetsDir, 'document_segmentation.onnx');
      fs.copyFileSync(modelSrc, androidDest);
      console.log('✅ Copied ONNX model to Android assets');
    }
    
    // Copy to iOS bundle (if iOS folder exists)
    const iosDir = path.join(currentDir, 'ios');
    if (fs.existsSync(iosDir)) {
      // Find the main iOS project folder
      const iosContents = fs.readdirSync(iosDir);
      const projectFolder = iosContents.find(item => 
        fs.statSync(path.join(iosDir, item)).isDirectory() && 
        !item.includes('.xcodeproj') && 
        !item.includes('.xcworkspace') &&
        item !== 'Pods'
      );
      
      if (projectFolder) {
        const iosDest = path.join(iosDir, projectFolder, 'document_segmentation.onnx');
        fs.copyFileSync(modelSrc, iosDest);
        console.log('✅ Copied ONNX model to iOS bundle');
        console.log('📝 Don\'t forget to add the .onnx file to your Xcode project as a bundle resource');
      }
    }
    
    console.log('🎉 react-native-document-scanner-ai setup complete!');
    console.log('💡 If you encounter issues, run: npx react-native start --reset-cache');
    
  } catch (error) {
    console.log('⚠️  Could not auto-copy ONNX model files.');
    console.log('📖 Please manually copy models/document_segmentation.onnx to:');
    console.log('   - android/app/src/main/assets/ (for Android)');
    console.log('   - iOS project bundle (for iOS)');
    console.log('Error:', error.message);
  }
}

// Only run if this is being installed as a dependency
if (require.main === module) {
  copyModelFiles();
}

module.exports = { copyModelFiles };
