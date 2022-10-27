import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:serial_port_win32/serial_port_win32.dart';
import 'data.dart';

class MODBUS {
  SerialPort port = SerialPort(com);
  int _current_index = 0;

  bool isPollingSensorsOn = false;

  // ============== COM port ===============================
  bool _openSerialPort() {
    try {
      port.openWithSettings(BaudRate: 9600);
      print('Port open');
      return true;
    } catch (e) {
      print('Open port error: $e');
    }
    return false;
  }

  void _closeSerialPort() {
    try {
      if (port.isOpened) port.close();
      print('Port close');
    } catch (e) {
      print('Close port error: $e');
    }
  }

  //============== R4DCB08 ===========================================

  void startR4DCB08Read() {
    isPollingSensorsOn = true;
    print('Start polling');
    Timer.periodic(Duration(seconds: 1), (timer) {
      _readAllR4DCB08(listOfR4DCB08);
      if (!isPollingSensorsOn) {
        timer.cancel();
        _closeSerialPort();
        print('Stop polling');
      }
    });
  }

  void _callbackNewDataReceived(int device, List<Sensor> sensors) {
    print('Gotcha!');
  }

  void _readAllR4DCB08(List<R4DCB08> list) {
    for (var device in list) {
      if (!port.isOpened) {
        _openSerialPort();
      }
      _readR4DCB08Data(device.address);
      sleep(const Duration(milliseconds: 200));
    }
  }

  bool _readR4DCB08Data(int device) {
    try {
      print('--------------------------------------------------');
//      final requestData = Uint8List.fromList([3, 3, 0, 0, 0, 8, 69, 238]); example
      final requestBody = Uint8List.fromList([device, 3, 0, 0, 0, 8]);
      final requestCRC = Uint8List.fromList(_crc(requestBody));
      final requestData = Uint8List.fromList(requestBody + requestCRC);

      final bool success = port.writeBytesFromUint8List(requestData);
      if (success) {
        print('Request: $requestData');
      } else {
        print('Request error');
        _closeSerialPort();
        return false;
      }

      port.readBytesOnListen(21, (response) {
        final bool isCrcOk = _checkCRC(response);
        print('Response: $response, (CRC check: ${isCrcOk ? 'Ok' : 'failed'})');
        if (isCrcOk) {
          _parseSensorsData(response, device); // check fo NULL!!!
          return true;
        }
      });
    } catch (e) {
      print('Request data error: $e');
      return false;
    }
    return false;
  }

  List<Sensor>? _parseSensorsData(Uint8List response, int device) {
    //async response!!!!
    List<Sensor> sensors = [];
    String parsedString = '';
    for (int sensorIndex = 1; sensorIndex <= 8; sensorIndex++) {
      final newErrValue = response[sensorIndex * 2 + 1];
      final newTempValue =
          response[sensorIndex * 2 + 2] + response[sensorIndex * 2 + 1] * 256;
      parsedString +=
          '[#$sensorIndex: ${(newErrValue == 128) ? 'NA' : (newTempValue / 10)}] ';
      sensors.add(Sensor(
        (newErrValue == 128) ? 0 : newTempValue,
        !(newErrValue == 128),
      ));
    }
    if (sensors.length == 8) {
      print('Parsing successful: $parsedString');
      _callbackNewDataReceived(device, sensors);
      return sensors;
    } else
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
