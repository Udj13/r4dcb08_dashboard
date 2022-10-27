import 'package:r4dcb08_dashboard_flutter/data.dart';

Sensor nullSensor = Sensor(0, false);

void loadINIData() {
  var r4dcb08 = R4DCB08(
    3,
    [
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
    ],
  );

  listOfR4DCB08.add(r4dcb08);

  r4dcb08 = R4DCB08(
    2,
    [
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
      nullSensor,
    ],
  );

  listOfR4DCB08.add(r4dcb08);
}
