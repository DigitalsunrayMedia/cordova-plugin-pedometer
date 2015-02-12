###### Version 0.1.2 - Fork by danurna based on Bourne Liu's version

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
- => `successCallback` is called with true if the feature is supported, otherwise false
- => `failureCallback` is called if there was an error determining if the feature is supported

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

## Pedometer data
### getPedometerDataAll
```js
pedometer.getPedometerDataAll(successCallback, failureCallback);
```
Queries the steps taken for the current day. Calls successCallback with pedometerData (see startPedometerUpdates).

### getPedometerDataSinceDate
```js
var successCallback = function (dataArray) {
    // dataArray[0].from;
    // dataArray[0].to;
    // dataArray[0].numberOfSteps;
    // dataArray[0].distance;
    // dataArray[0].floorsAscended;
    // dataArray[0].floorsDescended;
};
pedometer.getPedometerDataSinceDate(dateAsString, successCallback, failureCallback);
```
- => `dateAsString` start date using format "yyyy-MM-dd'T'HH:mm:ssZZZ", e.g. "2015-02-12T17:03:01+0100"

Queries the pedometer data for each day since given date, starting at given date and ending at the current date. Returns an array of pedometer data with additional "from" and "to" date.


### queryActivityStartingFromDate
```js
pedometer.queryActivityStartingFromDate(successCallback, failureCallback);
```
Unclear functionality!

## Live pedometer data

### startPedometerUpdates

Starts the delivery of recent pedestrian-related data to your Cordova app.

```js
var successHandler = function (pedometerData) {
    // pedometerData.numberOfSteps;
    // pedometerData.distance;
    // pedometerData.floorsAscended;
    // pedometerData.floorsDescended;
};
pedometer.startPedometerUpdates(successHandler, onError);
```

The success handler is executed when data is available and is called repeatedly from a background thread as new data arrives.

### stopPedometerUpdates

Stops the delivery of recent pedestrian data updates to your Cordova app.

```js
pedometer.stopPedometerUpdates(successCallback, failureCallback);
```

## Lifecycle handling
Right now there is only one lifecycle-event handled, which is the "didEnterBackground"-notification. So if the app enters the background the pedometer is stopped and has to be started via startPedometerUpdates again.

## Platform and device support

iOS 8+ only. These capabilities are not supported on all devices, even with iOS 8, so please ensure you use the *check feature support* functions.

## License

[MIT License](http://ilee.mit-license.org)
