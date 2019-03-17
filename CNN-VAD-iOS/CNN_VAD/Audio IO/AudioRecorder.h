//
//  AudioRecorder.h
//  CNN_VAD
//
//  Created by Abhishek Sehgal on 9/22/17.
//  Copyright © 2017 SIPLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import "MovingAverageBuffer.h"

@interface AudioRecorder : NSObject {
    AudioUnit au;
    MovingAverageBuffer* timeBuffer;
    float speechPrediction;
}
@property AudioUnit au;
@property MovingAverageBuffer* timeBuffer;
@property MovingAverageBuffer* predictBuffer;
@property float speechPrediction;

- (void)predict;
- (void) processAudio;
- (void) start;
- (void) stop;

@end

extern AudioRecorder* audioRecorder;
