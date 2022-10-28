String? com;

class Sensor {
  int temp;
  bool isConnect;
  Sensor(
    this.temp,
    this.isConnect,
  );
}

class R4DCB08 {
  int address;
  List<Sensor> sensors;
  List<String> names;
  R4DCB08(
    this.address,
    this.sensors,
    this.names,
  );
}

List<R4DCB08> listOfR4DCB08 = [];
