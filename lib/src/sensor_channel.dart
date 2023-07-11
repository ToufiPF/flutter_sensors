part of flutter_sensors;

typedef SensorCallback(int sensor, List<double> data, int accuracy);

class _SensorChannel {
  static const String channelName = 'flutter_sensors';

  /// Method channel of the plugin.
  static const MethodChannel _methodChannel = MethodChannel(channelName);

  /// Transform the delay duration object to an int value for each platform.
  static num? _durationToNumber(Duration delay) {
    if (Platform.isAndroid) {
      // Return the special flags for Android (other values' rate is not guaranteed)
      switch (delay.inMicroseconds) {
        case Sensors.SENSOR_DELAY_NORMAL.inMicroseconds:
          return 3;
        case Sensors.SENSOR_DELAY_UI.inMicroseconds:
          return 2;
        case Sensors.SENSOR_DELAY_GAME.inMicroseconds:
          return 1;
        default:
          return delay.inMicroseconds;
      }
    } else {
      return delay.inMicroseconds / 1e6;
    }
  }

  /// List of subscriptions to the update event channel.
  final Map<int, EventChannel> _eventChannels = {};

  /// List of subscriptions to the update event channel.
  final Map<int, Stream<SensorEvent>> _sensorStreams = {};

  /// Register a sensor update request.
  Stream<SensorEvent> sensorUpdates({
    required int sensorId,
    required Duration interval,
  }) async* {
    Stream<SensorEvent>? sensorStream = _sensorStreams[sensorId];
    if (sensorStream == null) {
      final args = {"interval": _durationToNumber(interval)};
      final channel =
          await _getEventChannel(sensorId: sensorId, arguments: args);

      sensorStream =
          channel.receiveBroadcastStream().map((e) => SensorEvent.fromMap(e));
      _sensorStreams[sensorId] = sensorStream!;
    } else {
      await updateSensorInterval(sensorId: sensorId, interval: interval);
    }
    yield* sensorStream;
  }

  /// Check if the sensor is available in the device.
  Future<bool> isSensorAvailable(int sensorId) async {
    final bool available = _methodChannel.invokeMethod(
      'is_sensor_available',
      {"sensorId": sensorId},
    );
    return available;
  }

  /// Updates the interval between updates for an specific sensor.
  Future<void> updateSensorInterval({
    required int sensorId,
    required Duration interval,
  }) =>
      _methodChannel.invokeMethod(
        'update_sensor_interval',
        {"sensorId": sensorId, "interval": _durationToNumber(interval)},
      );

  /// Return the stream associated with the given sensor.
  Future<EventChannel> _getEventChannel(
      {required int sensorId, Map arguments = const {}}) async {
    EventChannel? eventChannel = _eventChannels[sensorId];
    if (eventChannel == null) {
      arguments["sensorId"] = sensorId;
      await _methodChannel.invokeMethod("start_event_channel", arguments);

      eventChannel = EventChannel("$channelName/$sensorId");
      _eventChannels[sensorId] = eventChannel!;
    }
    return eventChannel;
  }
}
