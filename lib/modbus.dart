import 'dart:typed_data';
import 'package:serial_port_win32/serial_port_win32.dart';

class MODBUS {
  late SerialPort port;

  // List<String> getSerialPortsList() {
  //   return SerialPort.getAvailablePorts();
  // }

  void openSerialPort() {
    //Serial(port=PORT, baudrate=9600, bytesize=8, parity='N', stopbits=1, xonxoff=0)
    port = SerialPort("COM15");
    port.openWithSettings(BaudRate: 9600);
  }

  void closeSerialPort() {
    port.close();
  }

  readMODBUSData() {
    final uint8Data = Uint8List.fromList([3, 3, 0, 0, 0, 8, 69, 238]);

    print('Request:');
    print(port.writeBytesFromUint8List(uint8Data));

    print('Response:');
    port.readBytesOnListen(21, (value) => print(value));

    // List<Uint8List> response = [];
    // port.readBytesOnListen(21, (value) => response.add(value));
    //
    // print(response);

    // List<int> sensors = [];
    //for (int sensorIndex = 1; sensorIndex <= 8; sensorIndex++) {
    //   final newTempValue = response[sensorIndex + 2];
    //   print(newTempValue);
    //sensors.add(newTempValue);
    //   }
  }

  Uint8List _crc(Uint8List bytes) {
    var crc = BigInt.from(0xffff);
    var poly = BigInt.from(0xa001);

    for (var byte in bytes) {
      var bigByte = BigInt.from(byte);
      crc = crc ^ bigByte;
      for (int n = 0; n <= 7; n++) {
        int carry = crc.toInt() & 0x1;
        crc = crc >> 1;
        if (carry == 0x1) {
          crc = crc ^ poly;
        }
      }
    }
    //return crc.toUnsigned(16).toInt();
    var ret = Uint8List(2);
    ByteData.view(ret.buffer).setUint16(0, crc.toUnsigned(16).toInt());
    return ret;
  }
}
