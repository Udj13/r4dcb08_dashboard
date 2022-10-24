import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:serial_port_win32/serial_port_win32.dart';
import 'data.dart';

class MODBUS {
  late SerialPort port;

  void openSerialPort() {
    try {
      port = SerialPort(com);
      port.openWithSettings(BaudRate: 9600);
      print('Port open');
    } catch (e) {
      print('Open port error: $e');
    }
  }

  void closeSerialPort() {
    try {
      if (port.isOpened) port.close();
      print('Port close');
    } catch (e) {
      print('Close port error: $e');
    }
  }

  readMODBUSData() {
    try {
      print('Request:');
      final requestData = Uint8List.fromList([3, 3, 0, 0, 0, 8, 69, 238]);
      final bool success = port.writeBytesFromUint8List(requestData);
      if (success) print('Data sended: $requestData');

      print('Response:');
      port.readBytesOnListen(21, (response) {
        print(response);
        final bool isCrcOk = _checkCRC(response);
        print('CRC check: $isCrcOk');
        List<int> sensors = [];
        if (isCrcOk)
          sensors = _parseSensorsData(response) ?? [0, 0, 0, 0, 0, 0, 0, 0];
        print('sensors: $sensors');
      });
    } catch (e) {
      print('Request data error: $e');
    }
  }

  List<int>? _parseSensorsData(Uint8List response) {
    List<int> sensors = [];
    const delta = 1;
    for (int sensorIndex = 1; sensorIndex <= 8; sensorIndex++) {
      final newErrValue = response[sensorIndex * 2 + delta];
      final newTempValue = response[sensorIndex * 2 + 1 + delta] +
          response[sensorIndex * 2 + delta] * 256;
      print('Sensor$sensorIndex: $newTempValue/$newErrValue');
      sensors.add((newErrValue == 128) ? 999 : newTempValue);
    }
    if (sensors.length == 8)
      return sensors;
    else
      return null;
  }

  bool _checkCRC(Uint8List response) {
    try {
      if (response.lengthInBytes != 21) return false;
      var responseBody = response.sublist(0, 19);
      var responseCRC = response.sublist(19, 21);
      var calcCRC = _crc(responseBody);
      return listEquals(responseCRC, calcCRC);
    } catch (e) {
      print('CRC calculation error: $e');
      return false;
    }
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

    var reversedRet = Uint8List(2);
    reversedRet[0] = ret[1];
    reversedRet[1] = ret[0];
    return reversedRet;
  }
}
