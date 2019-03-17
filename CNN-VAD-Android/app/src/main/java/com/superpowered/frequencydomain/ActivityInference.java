package com.superpowered.frequencydomain;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import org.tensorflow.contrib.android.TensorFlowInferenceInterface;
import org.tensorflow.Graph;

/**
 * Created by abhisheksehgal on 10/5/17.
 */

public class ActivityInference {
    static {
        System.loadLibrary("tensorflow_inference");
    }

    private static final String TAG = "TensorFlowClassifier";

    private static ActivityInference activityInferenceInstance;
    private TensorFlowInferenceInterface inferenceInterface;
    private static final String MODEL_FILE = "file:///android_asset/frozen_without_dropout.pb";
    private static final String INPUT_NODE = "inputs/x-input";
    private static final String[] OUTPUT_NODES = {"model/Softmax"};
    private static final String OUTPUT_NODE = "model/Softmax";
    private static final long[] INPUT_SIZE = {1,1600};
    private static final int OUTPUT_SIZE = 2;
    private static AssetManager assetManager;

    private static Graph graph;

    public static ActivityInference getInstance(final Context context)
    {
        if (activityInferenceInstance == null)
        {
            activityInferenceInstance = new ActivityInference(context);
        }
        return activityInferenceInstance;
    }

    public ActivityInference(final Context context) {
        this.assetManager = context.getAssets();
        inferenceInterface = new TensorFlowInferenceInterface(assetManager, MODEL_FILE);
        int nClasses = (int) inferenceInterface.graph().operation(OUTPUT_NODE).output(0).shape().size(1);
        Log.i(TAG, "Read " + nClasses);

        graph = new Graph();
        

    }

    public float[] getActivityProb(float[] input_signal)
    {
        float[] result = new float[OUTPUT_SIZE];
        inferenceInterface.feed(INPUT_NODE,input_signal,INPUT_SIZE);
        inferenceInterface.run(OUTPUT_NODES);
        inferenceInterface.fetch(OUTPUT_NODE,result);
        return result;
    }
}
