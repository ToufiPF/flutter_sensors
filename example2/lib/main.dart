import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:battery_plus/battery_plus.dart';

const Map<int, Map<String, dynamic>> trackedSensors = {
  Sensors.ACCELEROMETER: {
    'name': 'Accelerometer',
    'nb_values': 3,
    'interval': Sensors.SENSOR_DELAY_GAME,
  },
  Sensors.GYROSCOPE: {
    'name': 'Gyroscope',
    'nb_values': 3,
    'interval': Sensors.SENSOR_DELAY_GAME,
  },
  Sensors.MAGNETIC_FIELD: {
    'name': 'Magnetometer',
    'nb_values': 3,
    'interval': Sensors.SENSOR_DELAY_GAME,
  },
  Sensors.BAROMETER: {
    'name': 'Barometer',
    'nb_values': 1,
    'interval': Sensors.SENSOR_DELAY_NORMAL,
  },
  Sensors.STEP_DETECTOR: {
    'name': 'Step Detector',
    'nb_values': 1,
    'interval': Duration(seconds: 2),
  },
};

class BatteryStream {
  final battery = Battery();

  Stream<int> batteryLevelStream() async* {
    while (true) {
      final level = await battery.batteryLevel;
      yield level;
      await Future.delayed(const Duration(minutes: 1));
    }
  }
}

class Controller extends ChangeNotifier {
  final List<StreamSubscription> subs = [];
  final SensorManager _manager = SensorManager();

  void start() {
                  for (var pair in trackedSensors.entries)
                    subs.add(_manager
          .sensorUpdates(sensorId: pair.key, interval: pair.value['interval'])
          .listen((event) => setState(() => data = event.data)));
    }
  }
}

void main() => runApp(const MyApp());

DateTime? start;
DateTime? end;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Sensors Example'),
          ),
          body: Container(
            padding: const EdgeInsets.all(16.0),
            alignment: AlignmentDirectional.topCenter,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  for (var pair in trackedSensors.entries)
                    SensorWidget(
                      sensorId: pair.key,
                      sensorName: pair.value['name'],
                      nbValues: pair.value['nb_values'],
                      interval: pair.value['interval'],
                    )
                ],
              ),
            ),
          ),
        ),
      );
}

class SensorWidget extends StatefulWidget {
  const SensorWidget({
    super.key,
    required this.sensorId,
    required this.sensorName,
    required this.nbValues,
    required this.interval,
  });

  final int sensorId;
  final String sensorName;
  final int nbValues;
  final Duration interval;

  @override
  State<SensorWidget> createState() => _SensorWidgetState();
}

class _SensorWidgetState extends State<SensorWidget> {
  final SensorManager _manager = SensorManager();

  bool available = false;
  late List<double> data;
  StreamSubscription<dynamic>? sub;

  @override
  void initState() {
    super.initState();
    data = List.filled(widget.nbValues, 0.0);
    _initialize();
  }

  Future<void> _initialize() async {
    final available = await _manager.isSensorAvailable(widget.sensorId);
    if (mounted) {
      setState(() => this.available = available);
    }
  }

  void _startSensor() {
    if (available) {
      sub ??= _manager
          .sensorUpdates(sensorId: widget.sensorId, interval: widget.interval)
          .listen((event) => setState(() => data = event.data));
    }
  }

  void _stopSensor() {
    sub?.cancel();
    setState(() => sub = null);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("${widget.sensorName} available? $available"),
          const SizedBox(height: 16.0),
          for (var i = 0; i < widget.nbValues; ++i)
            Text("[$i] = ${data.elementAtOrNull(i)}"),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MaterialButton(
                color: Colors.green,
                onPressed: available && sub == null ? _startSensor : null,
                child: const Text("Start"),
              ),
              const SizedBox(width: 8.0),
              MaterialButton(
                color: Colors.red,
                onPressed: available && sub != null ? _stopSensor : null,
                child: const Text("Stop"),
              ),
            ],
          ),
        ],
      );
}
