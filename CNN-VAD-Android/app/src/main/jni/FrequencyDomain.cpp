#include <jni.h>
#include <stdlib.h>
#include <string.h>
#include <SuperpoweredFrequencyDomain.h>
#include <AndroidIO/SuperpoweredAndroidAudioIO.h>
#include <SuperpoweredSimple.h>
#include <SuperpoweredCPU.h>
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_AndroidConfiguration.h>
#include <sstream>
extern "C"{
#include "audioProcessing.h"
#include "Timer.h"
}

static float *inputBufferFloat, *left, *right, *data;
Variables* memoryPointer;
Timer* timer;
SuperpoweredAndroidAudioIO *audioIO;

// This is called periodically by the media server.
static bool audioProcessing(void * __unused clientdata, short int *audioInputOutput, int numberOfSamples, int __unused samplerate) {
    start(timer);
    SuperpoweredShortIntToFloat(audioInputOutput, inputBufferFloat, (unsigned int)numberOfSamples); // Converting the 16-bit integer samples to 32-bit floating point.
    SuperpoweredDeInterleave(inputBufferFloat, left, right, (unsigned int)numberOfSamples);
    compute(memoryPointer, left);
    stop(timer);
    return true;
}

extern "C" JNIEXPORT void Java_com_superpowered_frequencydomain_MainActivity_FrequencyDomain(JNIEnv * __unused javaEnvironment, jobject __unused obj, jint samplerate, jint buffersize) {
    inputBufferFloat = (float *)malloc(buffersize * sizeof(float) * 2 + 128);
    left             = (float *)malloc(buffersize * sizeof(float) + 64);
    right            = (float *)malloc(buffersize * sizeof(float) + 64);
    data             = (float*)malloc(sizeof(float)*1600);

    memoryPointer = initialize(samplerate, buffersize);
    timer = newTimer();

    SuperpoweredCPU::setSustainedPerformanceMode(true);
    audioIO = new SuperpoweredAndroidAudioIO(samplerate, buffersize, true, true, audioProcessing, NULL, -1, SL_ANDROID_STREAM_MEDIA, buffersize * 2); // Start audio input/output.
}

extern "C" JNIEXPORT jfloatArray Java_com_superpowered_frequencydomain_MainActivity_GetMelImage(JNIEnv * __unused javaEnvironment, jobject __unused obj){
    jfloatArray result;
    result = javaEnvironment->NewFloatArray(1600);


    for (int i = 0; i < 40; i++) {
        for (int j = 0; j < 40; j++) {
            data[40*i+j] = memoryPointer->melSpectrogram->melSpectrogramImage[i][j];
        }
    }

    javaEnvironment->SetFloatArrayRegion(result, 0, 1600, data);
    return result;
}

extern "C" JNIEXPORT float Java_com_superpowered_frequencydomain_MainActivity_getProcessingTime(JNIEnv * __unused javaEnvironment, jobject __unused obj){
    return getMS(timer);
}

extern "C" JNIEXPORT void Java_com_superpowered_frequencydomain_MainActivity_StopAudio(JNIEnv * javaEnvironment, jobject __unused obj){

    if(inputBufferFloat != NULL){
        delete audioIO;
        free(inputBufferFloat);
        free(left);
        free(right);
        inputBufferFloat = NULL;
    }
}