//
//  audioProcessing.c
//  CNNVad
//
//  Created by Abhishek Sehgal on 3/14/17.
//  Copyright © 2017 axs145031. All rights reserved.
//

#include "audioProcessing.h"
#define SHORT2FLOAT         1/32768.0
#define FLOAT2SHORT         32768.0
#define NFILT               40
#define FREQLOW             300
#define FREQHIGH            8000
#define DECIMATION_FACTOR   3
#define EPS 1.0e-7
#define S2F 3.051757812500000e-05f
#define F2S 32768

Variables* initialize(int frequency, int stepsize) {
    
    Variables* inParam = (Variables*) malloc(sizeof(Variables));
    
    inParam->stepSize = stepsize;
    inParam->decimatedStepSize = stepsize/DECIMATION_FACTOR;
    inParam->samplingFrequency = frequency/DECIMATION_FACTOR;
    
    inParam->inputBuffer = (float*)calloc(stepsize, sizeof(float));
    inParam->downsampled = (float*)calloc(stepsize, sizeof(float));
    inParam->decimated   = (float*)calloc(2*inParam->decimatedStepSize, sizeof(float));
    
    inParam->fft = newTransform(2*inParam->decimatedStepSize, (int)(frequency/stepsize));
    inParam->melSpectrogram = initMelSpectrogram(NFILT, FREQLOW, FREQHIGH, 2*inParam->decimatedStepSize, inParam->samplingFrequency, inParam->fft->points);
    
    inParam->downsampleFilter = initFIR(stepsize);

    return inParam;
}

void compute(Variables* memoryPointer, float* input) {
    Variables* inParam = memoryPointer;
    
    int i, j;
    
//    for (i = 0; i < inParam->stepSize; i++) {
//        inParam->inputBuffer[i] = input[i];
//    }
    // Downsample the audio
    processFIRFilter(inParam->downsampleFilter, input, inParam->downsampled);
    
    // Decimate the audio
    for (i = 0, j = 0; i < inParam->decimatedStepSize; i++, j+= 3) {
        inParam->decimated[i] = inParam->decimated[i+inParam->decimatedStepSize];
        inParam->decimated[i+inParam->decimatedStepSize] = inParam->downsampled[j];
    }
    
    ForwardFFT(inParam->fft, inParam->decimated);
    updateImage(inParam->melSpectrogram, inParam->fft->power);
}

void getMelImage(Variables* memoryPointer, float** melImage){
    Variables* inParam = memoryPointer;
    for (size_t i = 0; i < NFILT; i++) {
        for (size_t j = 0; j < NFILT; j++) {
            melImage[i][j] = inParam->melSpectrogram->melSpectrogramImage[i][j];
        }
    }
}
