import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _accelAvailable = false;
  bool _gyroAvailable = false;
  List<double> _accelData = List.filled(3, 0.0);
  List<double> _gyroData = List.filled(3, 0.0);
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;

  @override
  void initState() {
    _checkAccelerometerStatus();
    _checkGyroscopeStatus();
    super.initState();
  }

  @override
  void dispose() {
    _stopAccelerometer();
    _stopGyroscope();
    super.dispose();
  }

  Future<void> _checkAccelerometerStatus() =>
      SensorManager().isSensorAvailable(Sensors.ACCELEROMETER).then((result) {
        setState(() => _accelAvailable = result);
      });

  void _startAccelerometer() {
    if (_accelSubscription != null) return;
    if (_accelAvailable) {
      final stream = SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: Sensors.SENSOR_DELAY_GAME,
      );
      _accelSubscription = stream.listen((sensorEvent) {
        setState(() => _accelData = sensorEvent.data);
      });
    }
  }

  void _stopAccelerometer() {
    if (_accelSubscription == null) return;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  void _checkGyroscopeStatus() =>
      SensorManager().isSensorAvailable(Sensors.GYROSCOPE).then((result) {
        setState(() => _gyroAvailable = result);
      });

  void _startGyroscope() {
    if (_gyroSubscription != null) return;
    if (_gyroAvailable) {
      final stream = SensorManager().sensorUpdates(sensorId: Sensors.GYROSCOPE);
      _gyroSubscription = stream.listen((sensorEvent) {
        setState(() => _gyroData = sensorEvent.data);
      });
    }
  }

  void _stopGyroscope() {
    if (_gyroSubscription == null) return;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Sensors Example'),
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          alignment: AlignmentDirectional.topCenter,
          child: Column(
            children: <Widget>[
              const Text(
                "Accelerometer Test",
                textAlign: TextAlign.center,
              ),
              Text(
                "Accelerometer Enabled: $_accelAvailable",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Text(
                "[0](X) = ${_accelData[0]}",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Text(
                "[1](Y) = ${_accelData[1]}",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Text(
                "[2](Z) = ${_accelData[2]}",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MaterialButton(
                    color: Colors.green,
                    onPressed:
                        _accelAvailable ? () => _startAccelerometer() : null,
                    child: const Text("Start"),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                  ),
                  MaterialButton(
                    color: Colors.red,
                    onPressed:
                        _accelAvailable ? () => _stopAccelerometer() : null,
                    child: const Text("Stop"),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              const Text(
                "Gyroscope Test",
                textAlign: TextAlign.center,
              ),
              Text(
                "Gyroscope Enabled: $_gyroAvailable",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Text(
                "[0](X) = ${_gyroData[0]}",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Text(
                "[1](Y) = ${_gyroData[1]}",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Text(
                "[2](Z) = ${_gyroData[2]}",
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.only(top: 16.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MaterialButton(
                    color: Colors.green,
                    onPressed: _gyroAvailable ? () => _startGyroscope() : null,
                    child: const Text("Start"),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                  ),
                  MaterialButton(
                    color: Colors.red,
                    onPressed: _gyroAvailable ? () => _stopGyroscope() : null,
                    child: const Text("Stop"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
