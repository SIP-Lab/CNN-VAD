#ifndef MELSPECTROGRAM_H
#define MELSPECTROGRAM_H
#define _USE_MATH_DEFINES

#include <stdlib.h>
#include <math.h>
#include <string.h>

typedef struct MelSpectrogram {
  int nFilt;
  int nFFT;
  float freqLow;
  float freqHigh;
  int frameSize;
  int Fs;
  float** filtBank;
  float* melPower;
  float** melSpectrogramImage;
} MelSpectrogram;

MelSpectrogram* initMelSpectrogram(int nFilt, float freqLow, float freqHigh, int frameSize, int Fs, int nFFT);
float** buildFilterbank(float l, float h, int nFilt, int nFFT, int Fs);
void melCalculate(float* fft, int nFFT, float** filterbank, int nFilt, float* melP);
void melImageCreate(float** melSpectrogramImage, float* melPower, int nFilt);
void updateImage(MelSpectrogram* melSpectrogram, float* fft);


#endif
