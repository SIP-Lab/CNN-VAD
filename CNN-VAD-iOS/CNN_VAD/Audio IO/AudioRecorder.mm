//
//  AudioRecorder.m
//  CNN_VAD
//
//  Created by Abhishek Sehgal on 9/22/17.
//  Copyright © 2017 SIPLab. All rights reserved.
//

#import "AudioRecorder.h"
#import <tensorflow/core/public/session.h>
#include <stdlib.h>
#include "TPCircularBuffer.h"
extern "C"{
#include "audioProcessing.h"
}

#define kOutputBus 0
#define kInputBus 1
#define SHORT2FLOAT 1/32768.0
#define FLOAT2SHORT 32768.0;

#define BUFFER 64
#define FRAMESIZE 600
#define SAMPLINGFREQUENCY 48000

AudioRecorder* audioRecorder;
AudioStreamBasicDescription audioFormat;
TPCircularBuffer inputBuffer, outputBuffer;
AudioBufferList  *inputBufferList;
Variables* memoryPointer;
NSDate* start;

// Input Tensor
tensorflow::Tensor x(tensorflow::DT_FLOAT,
                     tensorflow::TensorShape({40,40}));


std::vector<std::pair<std::string, tensorflow::Tensor>> inputs = {
    {"inputs/x-input", x},
};
std::vector<std::string> nodes = {
    {"model/Softmax"}
};
std::vector<tensorflow::Tensor> outputs;

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    if (outputBuffer.fillCount >= ioData->mBuffers[0].mDataByteSize) {
        AudioBuffer buffer = ioData->mBuffers[0];
        UInt32 size = buffer.mDataByteSize;
        int32_t availableBytes;
        short* tail = (short *)TPCircularBufferTail(&outputBuffer, &availableBytes);
        memcpy(buffer.mData, tail, size);
        TPCircularBufferConsume(&outputBuffer, size);
    }
    
    return noErr;
}

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    inputBufferList->mNumberBuffers = 1;
    inputBufferList->mBuffers[0].mDataByteSize = inNumberFrames*sizeof(short);
    inputBufferList->mBuffers[0].mNumberChannels = 1;
    inputBufferList->mBuffers[0].mData = malloc(inputBufferList->mBuffers[0].mDataByteSize);
    
    AudioUnitRender(audioRecorder.au,
                        ioActionFlags,
                        inTimeStamp,
                        inBusNumber,
                        inNumberFrames,
                        inputBufferList);
    
    
    TPCircularBufferProduceBytes(&inputBuffer, (void*)inputBufferList->mBuffers[0].mData, inputBufferList->mBuffers[0].mDataByteSize);
    if (inputBuffer.fillCount >= FRAMESIZE*sizeof(short)) {
        start = [NSDate date];
        [audioRecorder processAudio];
        [audioRecorder.timeBuffer addDatum:[NSNumber numberWithFloat:[[NSDate date] timeIntervalSinceDate:start]]];
    }
    
    
    free(inputBufferList->mBuffers[0].mData);
    inputBufferList->mBuffers[0].mData = NULL;
    
    return noErr;
}

@implementation AudioRecorder {
    tensorflow::GraphDef graph;
    tensorflow::Session *session;
}
@synthesize au, timeBuffer, speechPrediction, predictBuffer;

-(id) init {
    
    self = [super init];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                           error: NULL];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMeasurement
                                       error:NULL];
    [[AVAudioSession sharedInstance] setPreferredSampleRate:SAMPLINGFREQUENCY
                                                      error:NULL];
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:(float)BUFFER/(float)SAMPLINGFREQUENCY
                                                            error:NULL];
    
    // Set up the RemoteIO audio input/output unit.
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    AudioComponent component = AudioComponentFindNext(NULL, &desc);
    if (AudioComponentInstanceNew(component, &au) != 0) abort();
    
    UInt32 value = 1;
    if (AudioUnitSetProperty(au, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &value, sizeof(value))) abort();
    value = 1;
    if (AudioUnitSetProperty(au, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &value, sizeof(value))) abort();
    
    // 16-bit interleaved stereo PCM. While the native audio format is different, conversion does not add any latency (just some CPU).
    AudioStreamBasicDescription format;
    format.mSampleRate          = SAMPLINGFREQUENCY;
    format.mFormatID            = kAudioFormatLinearPCM;
    format.mFormatFlags         = kAudioFormatFlagIsSignedInteger;
    format.mFramesPerPacket     = 1;
    format.mChannelsPerFrame    = 1;
    format.mBitsPerChannel      = 16;
    format.mBytesPerPacket      = 2;
    format.mBytesPerFrame       = 2;
    if (AudioUnitSetProperty(au, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, sizeof(format))) abort();
    if (AudioUnitSetProperty(au, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &format, sizeof(format))) abort();
    
    audioFormat = format;
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    AudioUnitSetProperty(au,
                         kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global,
                         kInputBus,
                         &callbackStruct,
                         sizeof(callbackStruct));
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    AudioUnitSetProperty(au,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Global,
                         kOutputBus,
                         &callbackStruct,
                         sizeof(callbackStruct));
    
    timeBuffer = [[MovingAverageBuffer alloc] initWithPeriod:round(SAMPLINGFREQUENCY/FRAMESIZE)];
    predictBuffer = [[MovingAverageBuffer alloc] initWithPeriod:5];
    AudioUnitInitialize(au);
    
    return self;
    
}




/**
 Load the tensorflow graph into memory from the specified path

 @param path Path to the graph on the machine
 @return If the graph has been loaded or not
 */
- (BOOL)loadGraphFromPath:(NSString *)path {
    
    auto status = ReadBinaryProto(tensorflow::Env::Default(), path.fileSystemRepresentation, &graph);
    if (!status.ok()) {
        NSLog(@"Error reading graph: %s", status.error_message().c_str());
        return NO;
    }
    
    // This prints out the names of the nodes in the graph.
    auto nodeCount = graph.node_size();
    //NSLog(@"Node count: %d", nodeCount);
    for (auto i = 0; i < nodeCount; ++i) {
        auto node = graph.node(i);
        //NSLog(@"Node %d: %s '%s'", i, node.op().c_str(), node.name().c_str());
    }
    
    return YES;
}


/**
 Start the tensorflow session

 @return If the session has been started or not
 */
- (BOOL)createSession {
    tensorflow::SessionOptions options;
    auto status = tensorflow::NewSession(options, &session);
    if (!status.ok()) {
        NSLog(@"Error creating session %s",
              status.error_message().c_str());
        return NO;
    }
    
    status = session->Create(graph);
    if (!status.ok()) {
        NSLog(@"Error adding graph to session: %s",
              status.error_message().c_str());
        return NO;
    }
    return YES;
}

- (void)predict {
    
    auto input  = x.tensor<float, 2>();
    
    for (int i = 0; i < 40; i++) {
        for (int j = 0; j < 40; j++) {
            input(i, j) = memoryPointer->melSpectrogram->melSpectrogramImage[i][j];
        }
    }
    
    auto status = session->Run(inputs, nodes, {}, &outputs);
    if(!status.ok()) {
        NSLog(@"Error running model: %s", status.error_message().c_str());
        return;
    }
    
    auto pred = outputs[0].tensor<float, 2>();
    audioRecorder.speechPrediction = pred(0,1);
    [predictBuffer addDatum: [NSNumber numberWithFloat:pred(0,1)]];
}

- (void) start {
    NSString* source = [[NSBundle mainBundle] pathForResource:@"frozen_without_dropout" ofType:@"pb"];
    if(!source){
        NSLog(@"Unable to find file in the bundle");
    }
    else {
        // Load Tensorflow model
        [audioRecorder loadGraphFromPath:source];
        
        // Create Tensorflow session
        [audioRecorder createSession];
        
        // Initialize the Circular Buffers
        TPCircularBufferInit(&inputBuffer, 2048*16);
        TPCircularBufferInit(&outputBuffer, 2048*16);
        
        inputBufferList = (AudioBufferList*) malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * 2);
        
        memoryPointer = initialize(SAMPLINGFREQUENCY, FRAMESIZE);
        
        AudioOutputUnitStart(au);
    }
}

- (void) stop {
    AudioOutputUnitStop(au);
    
    session->Close();
    
    TPCircularBufferCleanup(&inputBuffer);
    TPCircularBufferCleanup(&outputBuffer);
    
    free(inputBufferList);
    inputBufferList = NULL;
}

- (void) processAudio{
    
    uint32_t frameSize = FRAMESIZE * sizeof(short);
    int32_t availableBytes;
    
    short* tail = (short *)TPCircularBufferTail(&inputBuffer, &availableBytes);
    if (availableBytes >= frameSize) {
        
        short* head = (short *)TPCircularBufferHead(&outputBuffer, &availableBytes);
        compute(memoryPointer, tail);
        memcpy(head, tail, frameSize);
        TPCircularBufferProduce(&outputBuffer, frameSize);
        TPCircularBufferConsume(&inputBuffer, frameSize);
    }
}

@end
