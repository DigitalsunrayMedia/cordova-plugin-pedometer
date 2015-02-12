//
//  Pedometer.m
//  Copyright (c) 2014 Lee Crossley - http://ilee.co.uk
//

#import "Cordova/CDV.h"
#import "Cordova/CDVViewController.h"
#import "CoreMotion/CoreMotion.h"
#import "Pedometer.h"

@interface NSDate (PedometerUtils)

+ (instancetype)initWithString:(NSString *)string usingDateFormat:(NSString *)format;
- (NSString *)convertToStringUsingDateFormat:(NSString *)format;
- (NSDate *)dateByAddingOneCalendarDay;
- (NSDate *)dateBySettingDaytimeToMidnight;
- (BOOL)isSameCalendarDayAs:(NSDate *)date;

@end

@interface Pedometer ()

@property (nonatomic, strong) CMPedometer *pedometer;
@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;
@property (nonatomic, strong) NSOperationQueue *stepQueue;

@end

@implementation Pedometer

NSString * const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZ";

- (instancetype)init{
   self = [super init];
 
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
 
      // queue for step count updating
      self.stepQueue = [[NSOperationQueue alloc] init];
      self.stepQueue.maxConcurrentOperationCount = 1;

      self.motionActivityManager = [[CMMotionActivityManager alloc] init];
   }
 
   return self;
}

- (void)timeChangedSignificantly:(NSNotification *)notification{
    
}

- (void)willEnterForeground:(NSNotification *)notification{
    
}

- (void)didEnterBackground:(NSNotification *)notification{
    [self.pedometer stopPedometerUpdates];
}

- (void)dealloc{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)isStepCountingAvailable:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[CMPedometer isStepCountingAvailable]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isDistanceAvailable:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[CMPedometer isDistanceAvailable]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isFloorCountingAvailable:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[CMPedometer isFloorCountingAvailable]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startPedometerUpdates:(CDVInvokedUrlCommand*)command{
    self.pedometer = [[CMPedometer alloc] init];

    __block CDVPluginResult* pluginResult = nil;

    [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if( error ){
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            } else {
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

- (void)stopPedometerUpdates:(CDVInvokedUrlCommand*)command{
    [self.pedometer stopPedometerUpdates];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)getPedometerDataAll:(CDVInvokedUrlCommand*)command{
    NSInteger dayOffset = 0;
  
    NSDate *rightNow = [[NSDate alloc] init];
      
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents * calComponents = [cal components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:rightNow];
      
    // Current day of week, with hours, minutes and seconds zeroed-out
    [calComponents setDay:([calComponents day] + dayOffset)];

    NSDate *beginningOfDay = [cal dateFromComponents:calComponents];

    self.pedometer = [[CMPedometer alloc] init];

    __block CDVPluginResult* pluginResult = nil;

    [self.pedometer queryPedometerDataFromDate:beginningOfDay toDate:[NSDate date] withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if( error ){
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            } else {
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

- (void)getPedometerDataSinceDate:(CDVInvokedUrlCommand *)command{
    // First argument should contain date as string
    if( command.arguments == 0 ){
        //Return error.
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Not enough arguments. Please provide a date string using the format %@", kDateFormat]];
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
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[err localizedDescription]];
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
    if( !self.pedometer ){
        self.pedometer = [[CMPedometer alloc] init];
    }

    [self.pedometer queryPedometerDataFromDate:start toDate:end withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if( error ){
                NSLog(@"ERROR %@", error);
                //TODO: Updated non-local err variable.
            } else {
                [array addObject: @{
                                    @"from"     : [start convertToStringUsingDateFormat:kDateFormat],
                                    @"to"       : [end convertToStringUsingDateFormat:kDateFormat],
                                    @"numberOfSteps"    : pedometerData.numberOfSteps,
                                    @"distance" : pedometerData.distance,
                                    @"floorsAscended"  : pedometerData.floorsAscended,
                                    @"floorsDescended" : pedometerData.floorsDescended
                                     }];
            }
            dispatch_group_leave(group);
        });
    }];
}

- (void)queryActivityStartingFromDate:(CDVInvokedUrlCommand*)command;
{
    int dayOffset = 0;
  
    NSDate *rightNow = [[NSDate alloc] init];
      
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents * calComponents = [cal components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:rightNow];
      
    // Current day of week, with hours, minutes and seconds zeroed-out
    [calComponents setDay:([calComponents day] + dayOffset)];

    NSDate *beginningOfDay = [cal dateFromComponents:calComponents];

    __block CDVPluginResult* pluginResult = nil;

    [self.motionActivityManager queryActivityStartingFromDate:beginningOfDay toDate:[NSDate date] 
                toQueue: self.stepQueue
                withHandler:^(NSArray *activities, NSError *error) {

            if( error ){
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:activities];
                [pluginResult setKeepCallbackAsBool:true];
            }

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
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
    NSDateComponents *dateWithoutTimeComponent = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
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
