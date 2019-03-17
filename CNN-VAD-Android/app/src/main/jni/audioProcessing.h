//
//  audioProcessing.h
//  CNNVad
//
//  Created by Abhishek Sehgal on 3/14/17.
//  Copyright © 2017 axs145031. All rights reserved.
//

#ifndef audioProcessing_h
#define audioProcessing_h

#include <stdio.h>
#include "Transforms.h"
#include "MelSpectrogram.h"
#include "FIRFilter.h"

typedef struct Variables {
    
    FIR* downsampleFilter;
    Transform* fft;
    MelSpectrogram* melSpectrogram;
    
    float* inputBuffer;
    float* downsampled;
    float* decimated;
    float* frame;
    
    int samplingFrequency;
    int stepSize;
    int decimatedStepSize;
    
} Variables;

Variables* initialize(int frequency, int stepsize);
void compute(Variables* memoryPointer, float* input);
void getMelImage(Variables* memoryPointer, float** melImage);

#endif /* audioProcessing_h */
