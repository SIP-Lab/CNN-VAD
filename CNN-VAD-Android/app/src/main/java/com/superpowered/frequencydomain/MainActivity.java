package com.superpowered.frequencydomain;

import android.content.Context;
import android.graphics.Color;
import android.media.AudioManager;
import android.os.Build;
import android.os.Handler;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.TextView;

import org.w3c.dom.Text;

import java.text.DecimalFormat;

public class MainActivity extends AppCompatActivity {

    private ActivityInference activityInference;
    private DecimalFormat decimalFormat;
    private Handler handler = new Handler();
    private TextView blanktext, processingTime, classification, noiseLabel, speechLabel;
    private MovingAverageBuffer averageBuffer, timeBuffer;
    private int CNNUpdate = 62, UIUpdate = 200;
    private String samplerateString = null, buffersizeString = null;
    private Button buttonStart, buttonStop;

    final Runnable r = new Runnable() {
        @Override
        public void run() {
            long startTime = System.currentTimeMillis();
            float prob[] = activityInference.getActivityProb(GetMelImage());
            averageBuffer.addDatum(prob[1]);
            timeBuffer.addDatum((System.currentTimeMillis() - startTime));

            handler.postDelayed(this,CNNUpdate);
        }
    };

    final Runnable timeUpdate = new Runnable() {
        @Override
        public void run() {
//            blanktext.setText("Result " + decimalFormat.format(averageBuffer.movingAverage));
            processingTime.setText("Processing Time: " + decimalFormat.format(getProcessingTime()) + " ms");

            if (Math.round(averageBuffer.movingAverage) == 0){
                //classification.setText("Noise");
                noiseLabel.setBackgroundColor(Color.RED);
                speechLabel.setBackgroundColor(Color.WHITE);
            }
            else{
                //classification.setText("Speech in Noise");
                noiseLabel.setBackgroundColor(Color.WHITE);
                speechLabel.setBackgroundColor(Color.GREEN);
            }

            handler.postDelayed(this, UIUpdate);
        }
    };

    private void initializeVariables(int samplerate, int buffersize) {

        activityInference = new ActivityInference(getApplicationContext());
        decimalFormat     = new DecimalFormat("0.00");
//        blanktext         = (TextView) findViewById(R.id.blanktext);
        processingTime    = (TextView) findViewById(R.id.processingTime);
//        classification    = (TextView) findViewById(R.id.classification);

        speechLabel       = (TextView) findViewById(R.id.speechLabel);
        noiseLabel        = (TextView) findViewById(R.id.noiseLabel);

        averageBuffer     = new MovingAverageBuffer(11);
        timeBuffer        = new MovingAverageBuffer(samplerate/buffersize);

        buttonStart       = (Button) findViewById(R.id.buttonStart);
        buttonStop        = (Button) findViewById(R.id.buttonStop);

        buttonStop.setBackgroundColor(Color.LTGRAY);

    }

    public void buttonStartClick(View view){
        System.loadLibrary("SuperpoweredExample");
        FrequencyDomain(Integer.parseInt(samplerateString), Integer.parseInt(buffersizeString));
        handler.postDelayed(r,CNNUpdate);
        handler.postDelayed(timeUpdate, 1000);

        buttonStart.setBackgroundColor(Color.LTGRAY);
        buttonStop.setBackgroundColor(Color.RED);

    }

    public void buttonStopClick(View view){
        StopAudio();
        handler.removeCallbacks(r);
        handler.removeCallbacks(timeUpdate);
        buttonStart.setBackgroundColor(Color.GREEN);
        buttonStop.setBackgroundColor(Color.LTGRAY);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Get the device's sample rate and buffer size to enable low-latency Android audio output, if available.

        if (Build.VERSION.SDK_INT >= 17) {
            AudioManager audioManager = (AudioManager) this.getSystemService(Context.AUDIO_SERVICE);
            samplerateString = audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE);
            buffersizeString = "600";//audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER);
        }
        if (samplerateString == null) samplerateString = "44100";
        if (buffersizeString == null) buffersizeString = "512";


        initializeVariables(Integer.parseInt(samplerateString), Integer.parseInt(buffersizeString));

    }




    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private native void FrequencyDomain(int samplerate, int buffersize);
    private native float[] GetMelImage();
    private native float getProcessingTime();
    private native void StopAudio();
}


