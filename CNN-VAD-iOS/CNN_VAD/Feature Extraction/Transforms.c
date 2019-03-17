#include "Transforms.h"
#include <stdio.h>
#define P_REF -93.9794

Transform*
newTransform(int window, int framesPerSecond)
{
	Transform* newTransform = (Transform*)malloc(sizeof(Transform));

	newTransform->windowSize = window;
    newTransform->framesPerSecond = framesPerSecond;

	int pow2Size = 0x01;
	while (pow2Size < window)
	{
		pow2Size = pow2Size << 1;
	}
	newTransform->points = pow2Size;

	newTransform->real = (float*)malloc(pow2Size*sizeof(float));
	newTransform->imaginary = (float*)malloc(pow2Size*sizeof(float));
	newTransform->power = (float*)malloc(pow2Size*sizeof(float));
	newTransform->sine = (float*)malloc((pow2Size/2)*sizeof(float));
	newTransform->cosine = (float*)malloc((pow2Size/2)*sizeof(float));
  newTransform->dbpowerBuffer = (float*)calloc(framesPerSecond, sizeof(float));
  newTransform->dbpower = 0;


	//precompute twiddle factors
	float arg;
	int i;
	for (i=0;i<pow2Size/2;i++)
	{
		arg = (-2.0*M_PI*i)/pow2Size;
		newTransform->cosine[i] = cos(arg);
		newTransform->sine[i] = sin(arg);
	}

	newTransform->window = (float*)malloc(pow2Size*sizeof(float));
	for(i=0;i<window;i++)
	{
		//Hanning
		newTransform->window[i] = (float)((1.0-cos(2.0*M_PI*(i+1)/(window+1)))*0.5);
	}

	for(i=window;i<pow2Size;i++){
		newTransform->window[i] = 0;
	}

	return newTransform;
}

void
ForwardFFT(Transform* fft, float* realInput)
{
	int i,j,k,L,m,n,o,p,q;
	float tempReal, tempImaginary, cos, sin, xt, yt, temp;
	k = fft->points;
    fft->totalPower = 0;

	for(i=0;i<k;i++)
	{
		fft->real[i] = 0;
		fft->imaginary[i] = 0;
	}

	for(i=0;i<fft->windowSize;i++)
	{
		//Windowing
		fft->real[i] = realInput[i]*fft->window[i];
	}

	j=0;
	m=k/2;

	//bit reversal
	for(i=1;i<(k-1);i++)
	{
		L=m;

		while(j>=L)
		{
			j=j-L;
			L=L/2;
		}

		j=j+L;

		if(i<j)
		{
			tempReal=fft->real[i];
			tempImaginary=fft->imaginary[i];
			fft->real[i]=fft->real[j];
			fft->imaginary[i]=fft->imaginary[j];
			fft->real[j]=tempReal;
			fft->imaginary[j]=tempImaginary;
		}
	}

	L=0;
	m=1;
	n=k/2;

	//computation
	for(i=k;i>1;i=(i>>1))
	{
		L=m;
		m=2*m;
		o=0;

		for(j=0;j<L;j++)
		{
			cos=fft->cosine[o];
			sin=fft->sine[o];
			o=o+n;

			for(p=j;p<k;p=p+m)
			{
				q=p+L;

				xt=cos*fft->real[q]-sin*fft->imaginary[q];
				yt=sin*fft->real[q]+cos*fft->imaginary[q];
				fft->real[q]=(fft->real[p]-xt);
				fft->real[p]=(fft->real[p]+xt);
				fft->imaginary[q]=(fft->imaginary[p]-yt);
				fft->imaginary[p]=(fft->imaginary[p]+yt);
			}
		}
		n=n>>1;
	}

	for (i=0; i<k; i++)
	{
		fft->power[i] = sqrt(fft->real[i]*fft->real[i]+fft->imaginary[i]*fft->imaginary[i]);
        fft->totalPower += fft->power[i]/k;
	}
    fft->dBSPL = 10*log10(fft->totalPower + 1e-6) - P_REF;
    temp = fft->dBSPL;
    fft->dbpower = fft->dbpower + (temp - fft->dbpowerBuffer[0])/fft->framesPerSecond;
    memmove(fft->dbpowerBuffer, fft->dbpowerBuffer + 1, sizeof(*fft->dbpowerBuffer)*(fft->framesPerSecond-1));
    fft->dbpowerBuffer[fft->framesPerSecond -1] = temp;
}

void
InverseFFT(Transform* fft)
{
	int i,j,k,L,m,n,o,p,q;
	float tempReal, tempImaginary, cos, sin, xt, yt;
	k = fft->points;

	j=0;
	m=k/2;

	//bit reversal
	for(i=1;i<(k-1);i++)
	{
		L=m;

		while(j>=L)
		{
			j=j-L;
			L=L/2;
		}

		j=j+L;

		if(i<j)
		{
			tempReal=fft->real[i];
			tempImaginary=fft->imaginary[i];
			fft->real[i]=fft->real[j];
			fft->imaginary[i]=fft->imaginary[j];
			fft->real[j]=tempReal;
			fft->imaginary[j]=tempImaginary;
		}
	}

	L=0;
	m=1;
	n=k/2;

	//computation
	for(i=k;i>1;i=(i>>1))
	{
		L=m;
		m=2*m;
		o=0;

		for(j=0;j<L;j++)
		{
			cos=fft->cosine[o];
			sin=-fft->sine[o];
			o=o+n;

			for(p=j;p<k;p=p+m)
			{
				q=p+L;

				xt=cos*fft->real[q]-sin*fft->imaginary[q];
				yt=sin*fft->real[q]+cos*fft->imaginary[q];
				fft->real[q]=(fft->real[p]-xt);
				fft->real[p]=(fft->real[p]+xt);
				fft->imaginary[q]=(fft->imaginary[p]-yt);
				fft->imaginary[p]=(fft->imaginary[p]+yt);
			}
		}
		n=n>>1;
	}

	for(i=0;i<k;i++)
	{
		fft->real[i] /= k;
	}
}


void
destroyTransform(Transform** transform)
{
	if(*transform != NULL){
		if((*transform)->cosine != NULL){
			free((*transform)->cosine);
			(*transform)->cosine = NULL;
		}
		if((*transform)->sine != NULL){
			free((*transform)->sine);
			(*transform)->sine = NULL;
		}
		if((*transform)->real != NULL){
			free((*transform)->real);
			(*transform)->real = NULL;
		}
		if((*transform)->imaginary != NULL){
			free((*transform)->imaginary);
			(*transform)->imaginary = NULL;
		}
		free(*transform);
		*transform = NULL;
	}
}
