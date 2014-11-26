//
//  Pedometer.m
//  Copyright (c) 2014 Lee Crossley - http://ilee.co.uk
//

#import "Cordova/CDV.h"
#import "Cordova/CDVViewController.h"
#import "CoreMotion/CoreMotion.h"
#import "Pedometer.h"

@interface Pedometer ()
    @property (nonatomic, strong) CMPedometer *pedometer;
@end

@implementation Pedometer

- (void) isStepCountingAvailable:(CDVInvokedUrlCommand*)command;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[CMPedometer isStepCountingAvailable]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) isDistanceAvailable:(CDVInvokedUrlCommand*)command;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[CMPedometer isDistanceAvailable]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) isFloorCountingAvailable:(CDVInvokedUrlCommand*)command;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[CMPedometer isFloorCountingAvailable]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) startPedometerUpdates:(CDVInvokedUrlCommand*)command;
{
    self.pedometer = [[CMPedometer alloc] init];

    __block CDVPluginResult* pluginResult = nil;

    [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            }
            else
            {
                NSDictionary* pedestrianData = @{
                    @"numberOfSteps": pedometerData.numberOfSteps,
                    @"distance": pedometerData.distance,
                    @"floorsAscended": pedometerData.floorsAscended,
                    @"floorsDescended": pedometerData.floorsDescended
                };
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:pedestrianData];
                [pluginResult setKeepCallbackAsBool:true];
            }

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    }];
}

- (void) stopPedometerUpdates:(CDVInvokedUrlCommand*)command;
{
    [self.pedometer stopPedometerUpdates];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) queryPedometerDataAll:(CDVInvokedUrlCommand*)command;
{

    int dayOffset = -7;
  
    NSDate *rightNow = [[NSDate alloc] init];
      
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents * calComponents = [cal components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:rightNow];
      
      // Current day of week, with hours, minutes and seconds zeroed-out
    int today = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:rightNow] weekday];
      
    [calComponents setDay:([calComponents day] + dayOffset)];

    NSDate *beginningOfDay = [cal dateFromComponents:calComponents];

    self.pedometer = [[CMPedometer alloc] init];

    __block CDVPluginResult* pluginResult = nil;

    [self.pedometer startPedometerUpdatesFromDate:beginningOfDay withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            }
            else
            {
                NSDictionary* pedestrianData = @{
                    @"numberOfSteps": pedometerData.numberOfSteps,
                    @"distance": pedometerData.distance,
                    @"floorsAscended": pedometerData.floorsAscended,
                    @"floorsDescended": pedometerData.floorsDescended
                };
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:pedestrianData];
                [pluginResult setKeepCallbackAsBool:true];
            }

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    }];
}


@end
