//
//  FIRFilter.h
//  NC-2Ch
//
//  Created by Abhishek Sehgal on 5/18/17.
//  Copyright © 2017 SIPLab. All rights reserved.
//

#ifndef FIRFilter_h
#define FIRFilter_h

#include <stdio.h>
#include <stdlib.h>



typedef struct FIR {
    
    int N;
    
    float* inputBuffer;
} FIR;

FIR* initFIR(int stepSize);
void processFIRFilter(FIR* fir, float* input, float* output);
void destroyFIR(FIR **fir);

#endif /* FIRFilter_h */
