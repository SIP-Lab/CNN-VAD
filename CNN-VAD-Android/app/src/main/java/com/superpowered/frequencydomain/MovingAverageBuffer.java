package com.superpowered.frequencydomain;

import java.util.Queue;

/**
 * Created by abhisheksehgal on 10/6/17.
 */

public class MovingAverageBuffer {

    private float[] queue;
    private int period;
    public int count;
    public float movingAverage;
    public float cumulativeAverage;

    public MovingAverageBuffer() {
        period = 5;
        count = 0;
        movingAverage = 0;
        cumulativeAverage = 0;
        queue = new float[period];
    }

    public MovingAverageBuffer(int givenperiod){

        period = givenperiod;
        count  = 0;
        movingAverage = 0;
        cumulativeAverage = 0;
        queue = new float[period];

    }

    public void addDatum(float datum){
        float removed = queue[0];

        for (int i = 1; i < period; i++){
            queue[i-1] = queue[i];
        }

        queue[period-1] = datum;

        movingAverage = movingAverage - (removed/period) + (datum/period);
        cumulativeAverage = cumulativeAverage + (datum - cumulativeAverage)/++count;
    }
}
