#ifndef TIMER_H
#define TIMER_H

#include <stdlib.h>
#include <time.h>
#include <android/log.h>

typedef struct Timer {
		unsigned int totalRuns;
		unsigned long long totalTime;
        struct timespec startTime;
        struct timespec stopTime;
} Timer;

Timer* newTimer();

void start(Timer* timer);
void stop(Timer* timer);
void tellTime(Timer* timer);
float getMS(Timer* timer);

void destroy(Timer** timer);

#endif
