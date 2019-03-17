#include "MelSpectrogram.h"
#include <stdio.h>

MelSpectrogram* initMelSpectrogram(int nFilt, float freqLow, float freqHigh, int frameSize, int Fs, int nFFT){
    MelSpectrogram* melSpectrogram = (MelSpectrogram*)malloc(sizeof(MelSpectrogram));

    melSpectrogram->nFilt       = nFilt;
    melSpectrogram->nFFT        = nFFT;
    melSpectrogram->freqLow     = freqLow;
    melSpectrogram->freqHigh    = freqHigh;
    melSpectrogram->frameSize   = frameSize;
    melSpectrogram->Fs          = Fs;

    melSpectrogram->filtBank = buildFilterbank(freqLow, freqHigh, nFilt, nFFT, Fs);
    melSpectrogram->melPower = (float*)calloc(sizeof(float), nFilt);
    melSpectrogram->melSpectrogramImage = (float**)calloc(sizeof(float*), nFilt);
    for (size_t i = 0; i < nFilt; i++) {
      melSpectrogram->melSpectrogramImage[i] = (float*)calloc(sizeof(float), nFilt);
    }
    return melSpectrogram;
}

float** buildFilterbank(float l, float h, int nFilt, int nFFT, int Fs){
  float lowerMel  = 1125 * log(1 + l/700);
  float higherMel = 1125 * log(1 + h/700);
  float diff, melBand, freqBand;
  int* f = (int*)calloc(sizeof(int), nFilt + 2);
  int rows, columns;

  rows = floor(nFFT/2);
  columns = nFilt;
  float** filterbank = (float**)calloc(sizeof(float*), rows);
  for (size_t i = 0; i < rows; i++) {
    filterbank[i] = (float*)calloc(sizeof(float), columns);
  }

  diff = (higherMel - lowerMel)/(nFilt + 1);
  melBand   = lowerMel;
  freqBand  = 700*(exp(melBand/1125) - 1);
  f[0] = floor((nFFT + 1) * freqBand/Fs);
  for (size_t i = 1; i < nFilt + 2; i++) {
    melBand = melBand + diff;
    freqBand  = 700*(exp(melBand/1125) - 1);
    f[i] = floor((nFFT + 1) * freqBand/Fs);
  }

  for (size_t k = 1; k <= rows; k++) {
    for (size_t m = 1; m < columns + 1; m++) {

      if ((k > f[m-1]) && (k <= f[m])) {
        filterbank[k-1][m-1] = (float)(k - f[m-1])/(float)(f[m] - f[m-1]);
      }
      else if ((k > f[m]) && (k <= f[m+1])){
        filterbank[k-1][m-1] = (float)(f[m+1] - k)/(float)(f[m+1] - f[m]);
      }
    }
  }
  return filterbank;
}

void melCalculate(float* fft, int nFFT, float** filterbank, int nFilt, float* melP){
//  float melMin = -20,//log(FLT_MIN),
//         melMax = 20;//log(FLT_MAX);
  float sum = 0;

  for (size_t i = 0; i < nFilt; i++) {
    for (size_t j = 0; j < floor(nFFT/2); j++) {
      sum += filterbank[j][i] * fft[j];
    }
    melP[i] = log(sum + 1e-8);
    sum = 0;
  }
}

void melImageCreate(float** melSpectrogramImage, float* melPower, int nFilt){

  // Shift the 2-d image up
    for (size_t i = 0; i < nFilt-1; i++) {
        memcpy(melSpectrogramImage[i], melSpectrogramImage[i+1], nFilt*sizeof(float));
    }
    
    for (size_t j = 0; j < nFilt; j++) {
        melSpectrogramImage[nFilt-1][j] = melPower[j];
    }
    
//  for (size_t j = 0; j < nFilt - 1; j++) {
//    for (size_t i = 0; i < nFilt; i++) {
//      melSpectrogramImage[i][j] = melSpectrogramImage[i][j+1];
//    }
//  }
//  // Add the current mel-spectrogram power to the right most column
//  for (size_t i = 0; i < nFilt; i++) {
//    melSpectrogramImage[i][nFilt - 1] = melPower[i];
//  }
}

void updateImage(MelSpectrogram* melSpectrogram, float* fft){

    melCalculate(fft, melSpectrogram->nFFT, melSpectrogram->filtBank, melSpectrogram->nFilt, melSpectrogram->melPower);
    melImageCreate(melSpectrogram->melSpectrogramImage, melSpectrogram->melPower, melSpectrogram->nFilt);
}
