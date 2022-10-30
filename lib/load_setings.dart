import 'package:flutter/foundation.dart';
import 'package:r4dcb08_dashboard_flutter/data.dart';
import 'package:ini/ini.dart';
import 'dart:io';

import 'main.dart';

Sensor emptySensor = Sensor(0, false);
List<Sensor> emptySensorsList = [
  emptySensor,
  emptySensor,
  emptySensor,
  emptySensor,
  emptySensor,
  emptySensor,
  emptySensor,
  emptySensor
];

const String configFilePath = "config.ini";
const generalSection = 'general';

File file = File(configFilePath);

void _doConfigThings(Config config) {
  if (kDebugMode) {
    print('Config loaded from $configFilePath');
  }

  com = config.get(generalSection, 'serial') ?? 'COM1';
  if (kDebugMode) {
    print('Serial port: $com');
  }

  minLevel = double.tryParse(config.get(generalSection, 'minimum')!);
  if (kDebugMode) {
    print('Minimum level: $minLevel');
  }

  maxLevel = double.tryParse(config.get(generalSection, 'maximum')!);
  if (kDebugMode) {
    print('Maximum level: $maxLevel');
  }

  List<SensorRange> ranges = [
    for (var i = 0; i < 8; i += 1) SensorRange(minLevel, maxLevel)
  ];

  config.sections();

  config.sections().forEach((section) {
    if (section != generalSection) {
      final int? device = int.tryParse(section);
      if (device != null) {
        List<String> sensorNames = [];
        for (var element in config.items(section)!) {
          sensorNames.add(element[1].toString());
        }

        var r4dcb08 = R4DCB08(
          address: device,
          sensors: emptySensorsList,
          names: sensorNames,
          ranges: ranges,
        );
        listOfR4DCB08.add(r4dcb08);
      }
    }
  });
  for (var device in listOfR4DCB08) {
    if (kDebugMode) {
      print('Device address: ${device.address}');
    }
    for (var element in device.names) {
      if (kDebugMode) {
        print(element);
      }
    }
  }
  if (kDebugMode) {
    print('After loading config start polling');
  }
  if (!modbus.isPollingSensorsOn) {
    modbus.startR4DCB08Read();
  }
}

void loadINIData() async {
  listOfR4DCB08.clear();

  await file
      .readAsLines()
      .then((lines) => Config.fromStrings(lines))
      .then((Config config) {
    _doConfigThings(config);
  });
}
