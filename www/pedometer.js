var exec = require("cordova/exec");

var Pedometer = function () {
    this.name = "Pedometer";
};

Pedometer.prototype.isStepCountingAvailable = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "isStepCountingAvailable", []);
};

Pedometer.prototype.isDistanceAvailable = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "isDistanceAvailable", []);
};

Pedometer.prototype.isFloorCountingAvailable = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "isFloorCountingAvailable", []);
};

Pedometer.prototype.isActivityTrackingAvailable = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "isActivityTrackingAvailable", []);
};

Pedometer.prototype.startPedometerUpdates = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "startPedometerUpdates", []);
};

Pedometer.prototype.stopPedometerUpdates = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "stopPedometerUpdates", []);
};

Pedometer.prototype.startActivityUpdates = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "startActivityUpdates", []);
};
               
Pedometer.prototype.stopActivityUpdates = function (onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "stopActivityUpdates", []);
};

Pedometer.prototype.getPedometerDataSinceDate = function (dateAsString, onSuccess, onError) {
    exec(onSuccess, onError, "Pedometer", "getPedometerDataSinceDate", [dateAsString]);
};

module.exports = new Pedometer();
