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
const connectionSection = 'connection';

File file = File(configFilePath);

void _doConfigThings(Config config) {
  print('Config loaded from ${configFilePath}');
  com = config.get(connectionSection, 'serial') ?? 'COM1';
  print('Serial port: ${com}');
  config.sections();

  config.sections().forEach((section) {
    if (section != connectionSection) {
      final int? device = int.tryParse(section);
      if (device != null) {
        List<String> sensorNames = [];
        config.items(section)!.forEach((element) {
          sensorNames.add(element[1].toString());
        });

        var r4dcb08 = R4DCB08(
          device,
          emptySensorsList,
          sensorNames,
        );
        listOfR4DCB08.add(r4dcb08);
      }
    }
  });
  listOfR4DCB08.forEach((device) {
    print('Device address: ${device.address}');
    device.names.forEach((element) {
      print(element);
    });
  });
  print('After loading config start polling');
  if (!modbus.isPollingSensorsOn) {
    modbus.startR4DCB08Read();
  }
}

void loadINIData() async {
  listOfR4DCB08.clear();

  await file
      .readAsLines()
      .then((lines) => new Config.fromStrings(lines))
      .then((Config config) {
    _doConfigThings(config);
  });
}
