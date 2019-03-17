
#include "Timer.h"

Timer*
newTimer(){
	Timer* newTimer = (Timer*)malloc(sizeof(Timer));
	newTimer->startTime.tv_nsec = 0;
	newTimer->startTime.tv_sec = 0;
	newTimer->stopTime.tv_nsec = 0;
	newTimer->stopTime.tv_sec = 0;
	newTimer->totalTime = 0;
	newTimer->totalRuns = 0;
	return newTimer;
}

void start(Timer* timer){
	clock_gettime(CLOCK_MONOTONIC, &(timer->startTime));
}

void stop(Timer* timer){
	clock_gettime(CLOCK_MONOTONIC, &(timer->stopTime));
	timer->totalTime += (timer->stopTime.tv_sec - timer->startTime.tv_sec)*1000000000LL + timer->stopTime.tv_nsec - timer->startTime.tv_nsec;
	timer->totalRuns++;
}

void tellTime(Timer* timer){
	__android_log_print(ANDROID_LOG_ERROR, "Timer", "Total Function Calls: %u, Total Processing Time: %llu, Average Per Run: %llu ms",timer->totalRuns, timer->totalTime, timer->totalTime/timer->totalRuns);

}

float getMS(Timer* timer){
	return timer->totalTime/(timer->totalRuns*1000000.0);
}

void destroy(Timer** timer){
	free(*timer);
	*timer = NULL;
}
