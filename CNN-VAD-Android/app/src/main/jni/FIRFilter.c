//
//  FIRFilter.c
//  NC-2Ch
//
//  Created by Abhishek Sehgal on 5/18/17.
//  Copyright © 2017 SIPLab. All rights reserved.
//

#include "FIRFilter.h"
#include "filterCoefficients.h"

float checkRange(float input){
    float output;
    if (input > 1.0) {
        output = 1.0;
    }
    else if(input < -1.0){
        output = -1.0;
    }
    else {
        output = input;
    }
    
    return output;
}

FIR* initFIR(int stepSize) {
    
    FIR* fir = (FIR*)malloc(sizeof(FIR));
    
    fir->N = stepSize;
    
    fir->inputBuffer = (float*)calloc(2*stepSize, sizeof(float));
    
    return fir;
    
}

void processFIRFilter(FIR* fir, float* input, float* output) {
    
    int i,j, idx;
    float temp;
    
    for (i = 0; i < fir->N; i++) {
        fir->inputBuffer[i] = fir->inputBuffer[fir->N + i];
        fir->inputBuffer[fir->N + i] = input[i];
    }
    
    for (i = 0; i < fir->N; i++) {
        temp = 0;
        
        for (j = 0; j < NCOEFFS; j++) {
            idx = fir->N + (i - j);
            temp += (fir->inputBuffer[idx]*filterCoefficients[j]);
        }
        output[i] = checkRange(temp);
    }
}

void destroyFIR(FIR **fir) {
    
    if ((*fir) != NULL) {
        
        if ((*fir)->inputBuffer != NULL) {
            free((*fir)->inputBuffer);
            (*fir)->inputBuffer = NULL;
        }
        
        free((*fir));
        (*fir) = NULL;        
    }
    
}
