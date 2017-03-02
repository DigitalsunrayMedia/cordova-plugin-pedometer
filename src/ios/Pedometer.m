//
//  Pedometer.m
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the â€œSoftwareâ€), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED â€œAS ISâ€, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "Cordova/CDV.h"
#import "Cordova/CDVViewController.h"
#import "CoreMotion/CoreMotion.h"
#import "Pedometer.h"
#import "DSRMotionDetector.h"

@interface NSDate (PedometerUtils)

+ (instancetype)initWithString:(NSString *)string usingDateFormat:(NSString *)format;
- (NSString *)convertToStringUsingDateFormat:(NSString *)format;
- (NSDate *)dateByAddingOneCalendarDay;
- (NSDate *)dateBySettingDaytimeToMidnight;
- (BOOL)isSameCalendarDayAs:(NSDate *)date;

@end

@interface Pedometer ()

// Step counting iOS 7 and iOS 8+
@property (nonatomic, strong) CMStepCounter *stepCounter;
@property (nonatomic, strong) CMPedometer *pedometer;
@property (nonatomic, strong) NSOperationQueue *stepQueue;
@property (nonatomic, strong) NSNumber *currentStepCount;
// Activity Tracking
@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;
@property (nonatomic, strong) NSOperationQueue *activityQueue;
@end

@implementation Pedometer

NSString * const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZ";

- (void)pluginInitialize {
    if( self ){
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        // subscribe to relevant notifications
        [notificationCenter addObserver:self selector:@selector(timeChangedSignificantly:)
                                   name:UIApplicationSignificantTimeChangeNotification
                                 object:nil];
        [notificationCenter addObserver:self selector:@selector(willEnterForeground:)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        [notificationCenter addObserver:self selector:@selector(didEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        
        self.currentStepCount = 0;
        
        if( [CMPedometer class] ){
            self.pedometer = [[CMPedometer alloc] init];
        }else{
            self.stepCounter = [[CMStepCounter alloc] init];
            // queue for step count updating
            self.stepQueue = [[NSOperationQueue alloc] init];
            self.stepQueue.maxConcurrentOperationCount = 1;
        }
        
        self.motionActivityManager = [[CMMotionActivityManager alloc] init];
        self.activityQueue = [[NSOperationQueue alloc] init];
        self.activityQueue.maxConcurrentOperationCount = 1;
    }
}

- (void)timeChangedSignificantly:(NSNotification *)notification{
    
}

- (void)willEnterForeground:(NSNotification *)notification{
    
}

- (void)didEnterBackground:(NSNotification *)notification{
    
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)isStepCountingAvailable:(CDVInvokedUrlCommand*)command{
    BOOL available = [CMPedometer class] ? [CMPedometer isStepCountingAvailable] : [CMStepCounter isStepCountingAvailable];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:(available ? CDVCommandStatus_OK : 
CDVCommandStatus_ERROR) messageAsBool:available];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isDistanceAvailable:(CDVInvokedUrlCommand*)command{
    BOOL available = [CMPedometer class] ? [CMPedometer isDistanceAvailable] : NO;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:(available ? CDVCommandStatus_OK : 
CDVCommandStatus_ERROR) messageAsBool:available];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isFloorCountingAvailable:(CDVInvokedUrlCommand*)command{
    BOOL available = [CMPedometer class] ? [CMPedometer isFloorCountingAvailable] : NO;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:(available ? CDVCommandStatus_OK : 
CDVCommandStatus_ERROR) messageAsBool:available];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isActivityTrackingAvailable:(CDVInvokedUrlCommand *)command{
    // For each device available as we are falling back to GPS and accelerometer,
    // if there is no dedicated motion chip
    BOOL available = true;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:(available ? CDVCommandStatus_OK : 
CDVCommandStatus_ERROR) messageAsBool:available];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startPedometerUpdates:(CDVInvokedUrlCommand*)command{
    __block CDVPluginResult* pluginResult = nil;
    self.currentStepCount = 0;
    
    if( self.pedometer ){
        [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData *pedometerData, NSError 
*error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if( error ){
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error 
localizedDescription]];
                } else {
                    
                    NSDictionary *dic = [self getStepDictonaryFromStepData:pedometerData and: true];
                    NSDictionary *pedestrianData = @{
                                                     @"numberOfSteps": dic[@"numberOfSteps"],
                                                     @"distance": dic[@"distance"],
                                                     @"floorsAscended": dic[@"floorsAscended"],
                                                     @"floorsDescended": dic[@"floorsDescended"]
                                                     };
                    
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK 
messageAsDictionary:pedestrianData];
                    [pluginResult setKeepCallbackAsBool:true];
                }
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            });
        }];
    }else{
        [self.stepCounter startStepCountingUpdatesToQueue:self.stepQueue updateOn:1 withHandler:^(NSInteger numberOfSteps, 
NSDate *timestamp, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if( error ){
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error 
localizedDescription]];
                } else {
                    NSInteger stepsTaken = numberOfSteps - self.currentStepCount.integerValue;
                    self.currentStepCount = @(self.currentStepCount.integerValue + stepsTaken);
                    NSDictionary* pedestrianData = @{
                                                     @"numberOfSteps": @(stepsTaken),
                                                     @"distance": @(-1),
                                                     @"floorsAscended": @(-1),
                                                     @"floorsDescended": @(-1)
                                                     };
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK 
messageAsDictionary:pedestrianData];
                    [pluginResult setKeepCallbackAsBool:true];
                }
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            });
        }];
    }
    
}

- (void)stopPedometerUpdates:(CDVInvokedUrlCommand*)command{
    [self.pedometer stopPedometerUpdates];
    [self.stepCounter stopStepCountingUpdates];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getPedometerDataAll:(CDVInvokedUrlCommand*)command{
    NSDate *beginningOfDay = [[NSDate date] dateBySettingDaytimeToMidnight];
    NSString *startArgument = [beginningOfDay convertToStringUsingDateFormat:kDateFormat];
    CDVInvokedUrlCommand *cmd = [[CDVInvokedUrlCommand alloc] initWithArguments:@[ startArgument ] 
callbackId:command.callbackId className:command.className methodName:command.methodName];
    [self getPedometerDataSinceDate:cmd];
}

- (void)getPedometerDataSinceDate:(CDVInvokedUrlCommand *)command{
    // First argument should contain date as string
    if( command.arguments == 0 ){
        //Return error.
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString 
stringWithFormat:@"Not enough arguments. Please provide a date string using the format %@", kDateFormat]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSError *err;
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *ret = [NSMutableArray array];
    NSString *startDateString = command.arguments[0];
    
    NSDate *startDate = [NSDate initWithString:startDateString usingDateFormat:kDateFormat];
    NSDate *currentDate = [NSDate date];
    
    
    // Compare if start and end are on the same day
    if( [startDate isSameCalendarDayAs:currentDate] ){
        // Return steps simply from start to currentdate
        [self addPedestrianDataToArray:ret
                                  from:startDate
                                    to:currentDate
                           insideGroup:group
                              andError:&err];
    } else {
        // Start and end are not on the same day.
        // Calculate start of next day, so 10-03-2015 13:12 should become 11-03-2015 00:00.
        NSDate *dayAfterStart = [startDate dateByAddingOneCalendarDay];
        NSDate *midnightDayAfterStart = [dayAfterStart dateBySettingDaytimeToMidnight];
        
        // Add steps for first day, starting by given date
        [self addPedestrianDataToArray:ret
                                  from:startDate
                                    to:midnightDayAfterStart
                           insideGroup:group
                              andError:&err];
        
        NSDate *dayStart = midnightDayAfterStart;
        NSDate *dayEnd = [midnightDayAfterStart dateByAddingOneCalendarDay];
        
        // Until our start day is equal to our current day we add steps for each day.
        while ( ![dayStart isSameCalendarDayAs:currentDate] ) {
            [self addPedestrianDataToArray:ret
                                      from:dayStart
                                        to:dayEnd
                               insideGroup:group
                                  andError:&err];
            dayStart = dayEnd;
            dayEnd = [dayEnd dateByAddingOneCalendarDay];
        }
        
        // Add steps for last day (= today)
        [self addPedestrianDataToArray:ret
                                  from:dayStart
                                    to:currentDate
                           insideGroup:group
                              andError:&err];
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CDVPluginResult *pluginResult;
        
        if( err ){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[err 
localizedDescription]];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:ret];
            [pluginResult setKeepCallbackAsBool:true];
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });
}

- (void)addPedestrianDataToArray:(NSMutableArray *)array
                            from:(NSDate *)start
                              to:(NSDate *)end
                     insideGroup:(dispatch_group_t)group
                        andError:(NSError **)err{
    dispatch_group_enter(group);
    
    // CMPedometer available and initalized? (iOS8+)
    if( self.pedometer ){
        [self.pedometer queryPedometerDataFromDate:start toDate:end withHandler:^(CMPedometerData *pedometerData, NSError 
*error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if( error ){
                    NSLog(@"ERROR %@", error);
                    //TODO: Updated non-local err variable.
                } else {
                    NSDictionary* dic = [self getStepDictonaryFromStepData:pedometerData and: false];
                    [array addObject: @{
                                        @"from"     : [start convertToStringUsingDateFormat:kDateFormat],
                                        @"to"       : [end convertToStringUsingDateFormat:kDateFormat],
                                        @"numberOfSteps"    : dic[@"numberOfSteps"],
                                        @"distance" : dic[@"distance"],
                                        @"floorsAscended"  : dic[@"floorsAscended"],
                                        @"floorsDescended" : dic[@"floorsDescended"]
                                        }];
                }
                dispatch_group_leave(group);
            });
        }];
    }else{ // Use CMStepCounter (iOS7+)
        [self.stepCounter queryStepCountStartingFrom:start to:end toQueue:self.stepQueue withHandler:^(NSInteger 
numberOfSteps, NSError *error) {
            if( error ){
                NSLog(@"ERROR %@", error);
                //TODO: Updated non-local err variable.
            } else {
                [array addObject: @{
                                    @"from"     : [start convertToStringUsingDateFormat:kDateFormat],
                                    @"to"       : [end convertToStringUsingDateFormat:kDateFormat],
                                    @"numberOfSteps"    : @(numberOfSteps),
                                    @"distance" : @(-1),
                                    @"floorsAscended"  : @(-1),
                                    @"floorsDescended" : @(-1)
                                    }];
            }
            dispatch_group_leave(group);
        }];
    }
    
}

- (void)startActivityUpdates:(CDVInvokedUrlCommand *)command{
    __block CDVPluginResult* pluginResult = nil;
    [DSRMotionDetector sharedInstance].useM7IfAvailable = YES;
    
    [DSRMotionDetector sharedInstance].motionTypeChangedBlock = ^(DSRMotionType motionType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSDictionary* pedestrianData = @{
                                             @"unknown": @(NO),
                                             @"walking": @(motionType == MotionTypeWalking),
                                             @"running": @(motionType == MotionTypeRunning),
                                             @"stationary": @(motionType ==MotionTypeNotMoving),
                                             @"automotive": @(motionType == MotionTypeAutomotive),
                                             @"confidence": @(0)
                                             };
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:pedestrianData];
            [pluginResult setKeepCallbackAsBool:true];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    };
    
    [[DSRMotionDetector sharedInstance] startDetection];
}

- (void)stopActivityUpdates:(CDVInvokedUrlCommand*)command{
    [[DSRMotionDetector sharedInstance] stopDetection];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSDictionary *)getStepDictonaryFromStepData: (CMPedometerData *)pedometerData and: (BOOL)increaseStepCount {
    
    NSInteger stepsTaken, distance, floorsAscended, floorsDescended;
    
    if (!pedometerData.numberOfSteps) {
        stepsTaken = -1;
    } else {
        stepsTaken = pedometerData.numberOfSteps.integerValue - self.currentStepCount.integerValue;
        if(increaseStepCount) {
            self.currentStepCount = @(self.currentStepCount.integerValue + stepsTaken);
        }
    }
    
    if (!pedometerData.distance) {
        distance = -1;
    } else {
        distance = [pedometerData.distance integerValue];
    }
    
    if (!pedometerData.floorsAscended) {
        floorsAscended = -1;
    } else {
        floorsAscended = [pedometerData.floorsAscended integerValue];
    }
    
    if (!pedometerData.floorsDescended) {
        floorsDescended = -1;
    } else {
        floorsDescended = [pedometerData.floorsDescended integerValue];
    }
    
    NSDictionary *pedestrianData = @{
        @"numberOfSteps": @(stepsTaken),
        @"distance": @(distance),
        @"floorsAscended": @(floorsAscended),
        @"floorsDescended": @(floorsDescended)
    };
    
    return pedestrianData;

}

@end

@implementation NSDate (PedometerUtils)

+ (instancetype)initWithString:(NSString *)string usingDateFormat:(NSString *)format{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:format];
    return [formatter dateFromString:string];
}

- (NSString *)convertToStringUsingDateFormat:(NSString *)format{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:format];
    return [formatter stringFromDate:self];
}

- (NSDate *)dateByAddingOneCalendarDay{
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDateComponents *singleDayComponent = [[NSDateComponents alloc] init];
    singleDayComponent.day = 1;
    return [theCalendar dateByAddingComponents:singleDayComponent toDate:self options:0];
}

- (NSDate *)dateBySettingDaytimeToMidnight{
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDateComponents *dateWithoutTimeComponent = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | 
NSDayCalendarUnit) fromDate:self];
    return [theCalendar dateFromComponents:dateWithoutTimeComponent];
}

- (BOOL)isSameCalendarDayAs:(NSDate *)date{
    NSDateFormatter *dateComparisonFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatter *dcf = dateComparisonFormatter;
    [dcf setTimeZone:[NSTimeZone systemTimeZone]];
    [dcf setDateFormat:@"yyyy-MM-dd"];
    return [[dcf stringFromDate:self] isEqualToString:[dcf stringFromDate:date]];
}

@end

