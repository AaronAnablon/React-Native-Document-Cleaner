/**
 * Metro configuration for React Native
 * https://github.com/facebook/metro
 *
 * @format
 */

module.exports = {
  resolver: {
    assetExts: ['bin', 'txt', 'jpg', 'png', 'json', 'onnx', 'tflite'],
  },
  transformer: {
    getTransformOptions: async () => ({
      transform: {
        experimentalImportSupport: false,
        inlineRequires: true,
      },
    }),
  },
};
