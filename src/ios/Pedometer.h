//
//  Pedometer.h
//  Copyright (c) 2014 Lee Crossley - http://ilee.co.uk
//

#import "Foundation/Foundation.h"
#import "Cordova/CDV.h"

@interface Pedometer : CDVPlugin

- (void) isStepCountingAvailable:(CDVInvokedUrlCommand*)command;
- (void) isDistanceAvailable:(CDVInvokedUrlCommand*)command;
- (void) isFloorCountingAvailable:(CDVInvokedUrlCommand*)command;

- (void) startPedometerUpdates:(CDVInvokedUrlCommand*)command;
- (void) stopPedometerUpdates:(CDVInvokedUrlCommand*)command;

- (void) queryActivityStartingFromDate:(CDVInvokedUrlCommand*)command;
- (void) getPedometerDataAll:(CDVInvokedUrlCommand*)command;
- (void) getPedometerDataSinceDate:(CDVInvokedUrlCommand*)command;


@end
