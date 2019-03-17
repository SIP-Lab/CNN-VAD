//
//  MovingAverageBuffer.h
//  NC-2Ch
//
//  Created by Abhishek Sehgal on 5/12/17.
//  Copyright © 2017 SIPLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MovingAverageBuffer : NSObject

@property (readonly, nonatomic) float movingAverage;
@property (readonly, nonatomic) float cumulativeAverage;
@property (readonly, nonatomic) NSUInteger count;

- (id) initWithPeriod:(NSUInteger)period;
- (void) addDatum:(NSNumber *)datum;

@end
