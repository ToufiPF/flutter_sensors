import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class BatteryNotifier extends ChangeNotifier {
  static const int lowThreshold = 50;

  final _battery = Battery();
  late final StreamSubscription<int> _sub;

  bool? oldVal;
  int _lvl = 100;

  bool get batteryIsLow => _lvl <= lowThreshold;

  BatteryNotifier() {
    _sub = batteryLevelStream().listen((event) {
      _lvl = event;
      if (oldVal != batteryIsLow) {
        oldVal = batteryIsLow;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  Stream<int> batteryLevelStream() async* {
    while (true) {
      final level = await _battery.batteryLevel;
      yield level;
      await Future.delayed(const Duration(minutes: 1));
    }
  }
}
