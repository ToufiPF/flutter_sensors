import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef SensorConfig = Map<int, Map<String, dynamic>>;

class SensorController extends ChangeNotifier {
  final SensorManager _manager = SensorManager();

  final SensorConfig config;
  final List<StreamSubscription<dynamic>> subs = [];
  final Map<int, File> files = {};
  final Map<int, IOSink> sinks = {};

  late File summaryFile;
  late DateTime startTime;

  bool isRunning = false;

  SensorController(this.config);

  @override
  void dispose() {
    super.dispose();
    stop();
  }

  Future<void> start() async {
    final docDir = await getApplicationDocumentsDirectory();
    await docDir.create();

    for (var pair in config.entries) {
      files[pair.key] = File(p.join(docDir.path, "${pair.value['name']}.csv"));
      sinks[pair.key] = files[pair.key]!.openWrite();

      subs.add(_manager
          .sensorUpdates(sensorId: pair.key, interval: pair.value['interval'])
          .listen((event) => sinks[pair.key]!.writeln(event.data.join(','))));
    }

    startTime = DateTime.now();
    isRunning = true;
    notifyListeners();
  }

  Future<void> stop() async {
    if (!isRunning) return;

    await Future.forEach(subs, (e) => e.cancel());
    await Future.forEach(sinks.values, (e) => e.close());
    await Future.forEach(files.values, (e) => e.delete());

    final elapsed = DateTime.now().difference(startTime);
    final sink = summaryFile.openWrite(mode: FileMode.append);
    sink.write('${json.encode(config)} => $elapsed\n\n\n');
    await sink.flush();
    await sink.close();

    isRunning = false;
    notifyListeners();
  }
}
