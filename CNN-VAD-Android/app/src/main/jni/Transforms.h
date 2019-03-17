#ifndef TRANSFORMS_H
#define TRANSFORMS_H
#define _USE_MATH_DEFINES

#include <stdlib.h>
#include <math.h>
#include <string.h>

typedef struct Transform {
		int points;
		int windowSize;
		float* real;
		float* imaginary;
		float* power;
		float* sine;
		float* cosine;
    float* window;
    float totalPower;
    float dBSPL;
    float dbpower;
    float* dbpowerBuffer;
    int framesPerSecond;
} Transform;

Transform* newTransform(int windowSize, int framesPerSecond);
void ForwardFFT(Transform* fft, float* real);
void InverseFFT(Transform* fft);
void destroyTransform(Transform** transform);

#endif
