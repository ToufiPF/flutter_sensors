part of flutter_sensors;

typedef SensorCallback(int sensor, List<double> data, int accuracy);

class _SensorChannel {
  static const String channelName = 'flutter_sensors';
  /// Method channel of the plugin.
  static const MethodChannel _methodChannel = MethodChannel(channelName);

  /// Transform the delay duration object to an int value for each platform.
  static num? _transformDurationToNumber(Duration? delay) {
    if (Platform.isAndroid) {
      // Return the special flags for Android (other values' rate is not guaranteed)
      return switch (delay?.inMicroseconds) {
        Sensors.SENSOR_DELAY_NORMAL.inMicroseconds => 3,
        Sensors.SENSOR_DELAY_UI.inMicroseconds => 2,
        Sensors.SENSOR_DELAY_GAME.inMicroseconds => 1,
        _ => delay?.inMicroseconds,
      };
    } else {
      return delay?.inSeconds;
    }
  }

  /// List of subscriptions to the update event channel.
  final Map<int, EventChannel> _eventChannels = {};

  /// List of subscriptions to the update event channel.
  final Map<int, Stream<SensorEvent>> _sensorStreams = {};

  /// Register a sensor update request.
  Future<Stream<SensorEvent>> sensorUpdates(
      {required int sensorId, Duration? interval}) async {
    Stream<SensorEvent>? sensorStream = _sensorStreams[sensorId];
    interval = interval ?? Sensors.SENSOR_DELAY_NORMAL;

    if (sensorStream == null) {
      final args = {"interval": _transformDurationToNumber(interval)};
      final channel =
          await _getEventChannel(sensorId: sensorId, arguments: args);

      sensorStream = channel.receiveBroadcastStream()
        .map((event) => SensorEvent.fromMap(event));
      _sensorStreams[sensorId] = sensorStream;
    } else {
      await updateSensorInterval(sensorId: sensorId, interval: interval);
    }
    return sensorStream;
  }

  /// Check if the sensor is available in the device.
  Future<bool> isSensorAvailable(int sensorId) async {
    final bool isAvailable = await _methodChannel.invokeMethod(
      'is_sensor_available',
      {"sensorId": sensorId},
    );
    return isAvailable;
  }

  /// Updates the interval between updates for an specific sensor.
  Future updateSensorInterval(
      {required int sensorId, Duration? interval}) async {
    return _methodChannel.invokeMethod(
      'update_sensor_interval',
      {"sensorId": sensorId, "interval": _transformDurationToNumber(interval)},
    );
  }

  /// Return the stream associated with the given sensor.
  Future<EventChannel> _getEventChannel(
      {required int sensorId, Map arguments = const {}}) async {
    EventChannel? eventChannel = _eventChannels[sensorId];
    if (eventChannel == null) {
      arguments["sensorId"] = sensorId;
      await _methodChannel.invokeMethod("start_event_channel", arguments);

      eventChannel = EventChannel("$channelName/$sensorId");
      _eventChannels[sensorId] = eventChannel;
    }
    return eventChannel;
  }
}
