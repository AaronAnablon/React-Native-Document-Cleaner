module.exports = {
  dependencies: {
    'react-native-document-scanner-ai': {
      platforms: {
        android: {
          sourceDir: '../android',
          packageImportPath: 'import com.documentscannerai.DocumentScannerAiPackage;',
        },
        ios: {
          podspecPath: '../DocumentScannerAi.podspec',
        },
      },
    },
  },
  assets: ['../assets/'],
};
