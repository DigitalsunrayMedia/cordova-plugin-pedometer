###### Version 0.1.4 - Fork by danurna based on Bourne Liu's version

## Core Motion Pedometer Plugin for Apache Cordova

**Fetch pedestrian-related pedometer data, such as step counts and other information about the distance travelled.**

## Install
```
cordova plugin add https://github.com/danurna/cordova-plugin-pedometer.git
```

You **do not** need to reference any JavaScript, the Cordova plugin architecture will add a pedometer object to your root automatically when you build.

## Check feature support
### isStepCountingAvailable
```js
pedometer.isStepCountingAvailable(successCallback, failureCallback);
```
- => `successCallback` is called if the feature is supported
- => `failureCallback` is called if the feature is not supported

### isDistanceAvailable
```js
pedometer.isDistanceAvailable(successCallback, failureCallback);
```

Distance estimation indicates the ability to use step information to supply the approximate distance travelled by the user.

This capability is not supported on all devices, even with iOS 8.

### isFloorCountingAvailable
```js
pedometer.isFloorCountingAvailable(successCallback, failureCallback);
```

Floor counting indicates the ability to count the number of floors the user walks up or down using stairs.

This capability is not supported on all devices, even with iOS 8.

### isActivityTrackingAvailable
```js
pedometer.isActivityTrackingAvailable(successCallback, failureCallback);
```

Check for availability of activity tracking provided by CMMotionActivityManager class.


## Pedometer data
### getPedometerDataAll
```js
pedometer.getPedometerDataAll(successCallback, failureCallback);
```
Queries the steps taken for the current day. Calls successCallback with array of lenght 1 containing the pedometer data (see getPedometerSinceDate).

### getPedometerDataSinceDate
```js
var successCallback = function (dataArray) {
    // dataArray[0].from;
    // dataArray[0].to;
    // dataArray[0].numberOfSteps;
    // dataArray[0].distance; (-1, if iOS7)
    // dataArray[0].floorsAscended; (-1, if iOS7)
    // dataArray[0].floorsDescended; (-1, if iOS7)
};
pedometer.getPedometerDataSinceDate(dateAsString, successCallback, failureCallback);
```
- => `dateAsString` start date using format "yyyy-MM-dd'T'HH:mm:ssZZZ", e.g. "2015-02-12T17:03:01+0100"

Queries the pedometer data for each day since given date, starting at given date and ending at the current date. Returns an array of pedometer data with additional "from" and "to" date.

## Live pedometer data
### startPedometerUpdates
Starts the delivery of recent pedestrian-related data to your Cordova app.

```js
var successHandler = function (pedometerData) {
    // pedometerData.numberOfSteps;
    // pedometerData.distance; (-1, if iOS7)
    // pedometerData.floorsAscended; (-1, if iOS7)
    // pedometerData.floorsDescended; (-1, if iOS7)
};
pedometer.startPedometerUpdates(successHandler, onError);
```

The success handler is executed when data is available and is called repeatedly from a background thread as new data arrives.

### stopPedometerUpdates
Stops the delivery of recent pedestrian data updates to your Cordova app.

```js
pedometer.stopPedometerUpdates(successCallback, failureCallback);
```

## Live activity data
### startActivityUpdates
Starts the delivery of activity changes to your Cordova app.
```js
var successHandler = function (activityData) {
    // activityData.walking; (BOOL)
    // activityData.running; (BOOL)
    // activityData.stationary; (BOOL)
    // activityData.automotive; (BOOL)
    // activityData.unknown; (BOOL)
    // activityData.confidence; (ENUM: 0 = low, 1 = medium, 2 = high)
    // Note: cycling is data currently not available.
};
pedometer.startActivityUpdates(successHandler, onError);
```
### stopActivityUpdates
Stops the delivery of activitychanges to your Cordova app.

```js
pedometer.stopActivityUpdates(successCallback, failureCallback);
```
## Lifecycle handling
Lifecycle events, like didEnterBackground, aren't handled by the plugin. Use the events provided by cordova to stop and start updates.

## Platform and device support
iOS 7 and newer only. The capabilities are not supported on all devices, even with iOS 8, so please ensure you use the *check feature support* functions.

## License

[MIT License](http://ilee.mit-license.org)
