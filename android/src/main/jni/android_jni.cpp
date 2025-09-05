#include <jni.h>
#include <android/log.h>
#include "../../../cpp/DocumentScannerCore.h"

#define LOG_TAG "DocumentScannerAi"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_documentscannerai_DocumentScannerAiModule_nativeGetVersion(JNIEnv *env, jobject thiz) {
    return env->NewStringUTF("1.0.0");
}

// Add more JNI methods here for actual document scanning functionality
// This is a basic setup to ensure the native library loads properly

}
