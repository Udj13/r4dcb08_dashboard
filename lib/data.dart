String? com;
double? minLevel;
double? maxLevel;

class Sensor {
  int temp;
  bool isConnect;
  Sensor(
    this.temp,
    this.isConnect,
  );
}

class SensorRange {
  double? minLevel;
  double? maxLevel;
  SensorRange(
    this.minLevel,
    this.maxLevel,
  );
}

class R4DCB08 {
  int address;
  List<Sensor> sensors;
  List<String> names;
  List<SensorRange> ranges;
  R4DCB08({
    required this.address,
    required this.sensors,
    required this.names,
    required this.ranges,
  });
}

List<R4DCB08> listOfR4DCB08 = [];
