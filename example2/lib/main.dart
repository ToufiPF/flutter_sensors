import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:provider/provider.dart';

import 'battery.dart';
import 'controller.dart';

const SensorConfig config1 = {
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
};

const SensorConfig config2 = {
  Sensors.ACCELEROMETER: {
    'name': 'Accelerometer',
    'nb_values': 3,
    'interval': Sensors.SENSOR_DELAY_GAME,
  },
  Sensors.BAROMETER: {
    'name': 'Barometer',
    'nb_values': 1,
    'interval': Sensors.SENSOR_DELAY_NORMAL,
  },
};

const SensorConfig config3 = {
  Sensors.ACCELEROMETER: {
    'name': 'Accelerometer',
    'nb_values': 3,
    'interval': Sensors.SENSOR_DELAY_UI,
  },
  Sensors.BAROMETER: {
    'name': 'Barometer',
    'nb_values': 1,
    'interval': Sensors.SENSOR_DELAY_NORMAL,
  },
};

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SensorConfig config = config1;

  late final BatteryNotifier battery;

  @override
  void initState() {
    super.initState();

    battery = BatteryNotifier();
    battery.addListener(() {
      if (mounted && battery.batteryIsLow) {
        final sensors = Provider.of<SensorController>(context, listen: false);
        sensors.stop();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    battery.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => SensorController(config)),
          Provider.value(value: battery),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Battery consumption benchmark'),
            ),
            body: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: AlignmentDirectional.topCenter,
              child: SingleChildScrollView(
                child: Consumer2<SensorController, BatteryNotifier>(
                  builder: (context, sensors, battery, child) => Column(
                    children: <Widget>[
                      const Text(
                          "Recording until ${BatteryNotifier.lowThreshold}%"),
                      DropdownMenu<SensorConfig>(
                          enabled: !sensors.isRunning,
                          initialSelection: config,
                          onSelected: (event) =>
                              setState(() => config = event!),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(
                                value: config1, label: "Acc, gyr, mag @50Hz"),
                            DropdownMenuEntry(
                                value: config2, label: "Acc @50Hz"),
                            DropdownMenuEntry(
                                value: config3, label: "Acc @10Hz"),
                          ]),
                      ElevatedButton(
                        onPressed: sensors.isRunning ? null : sensors.start,
                        child: const Text("Start"),
                      ),
                      Text("Running? ${sensors.isRunning}"),
                      Text("Config: ${sensors.config}"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
