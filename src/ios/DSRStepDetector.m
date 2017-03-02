
//
//  DSRStepDetector.m
//  MotionDetection
//
//  Created by Artur on 5/15/15.
//  Copyright (c) 2015 Artur Mkrtchyan. All rights reserved.
//

#import "DSRStepDetector.h"
#import <CoreMotion/CoreMotion.h>

#define dsrUpdateInterval 0.2f
@interface DSRStepDetector()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSOperationQueue* queue;

@end

@implementation DSRStepDetector

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    
    self.motionManager = [CMMotionManager new];
    
    self.motionManager.accelerometerUpdateInterval = dsrUpdateInterval;
    self.motionManager.deviceMotionUpdateInterval  = dsrUpdateInterval;
    self.motionManager.gyroUpdateInterval          = dsrUpdateInterval;
    self.motionManager.magnetometerUpdateInterval  = dsrUpdateInterval;
    self.motionManager.showsDeviceMovementDisplay  = YES;
    
    self.queue = [NSOperationQueue new];
    self.queue.maxConcurrentOperationCount = 1;
    
    return self;
}

- (void)startDetectionWithUpdateBlock:(void (^)(NSError *))callback
{
    if (self.motionManager.isAccelerometerActive) {
        return;
    }
    
    [self.motionManager startAccelerometerUpdatesToQueue:self.queue
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        if (error) {
            if (callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback (error);
                });
            }
            return ;
        }
        
        CMAcceleration acceleration = accelerometerData.acceleration;
        
        CGFloat strength = 1.2f;
        BOOL isStep = NO;
        if (fabs(acceleration.x) > strength || fabs(acceleration.y) > strength || fabs(acceleration.z) > strength) {
            isStep = YES;
        }
        if (isStep) {
            if (callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback (nil);
                });
            }
        }
    }];
}

- (void)stopDetection
{
    if (self.motionManager.isAccelerometerActive) {
        [self.motionManager stopAccelerometerUpdates];
    }
}

@end
