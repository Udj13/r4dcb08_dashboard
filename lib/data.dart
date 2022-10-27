import 'dart:async';

String com = 'COM7';

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
  R4DCB08(
    this.address,
    this.sensors,
  );
}

List<R4DCB08> listOfR4DCB08 = [];

var _streamController = StreamController<List<R4DCB08>>.broadcast();
Stream<List<R4DCB08>> get listOfR4DCB08DataStream => _streamController.stream;
