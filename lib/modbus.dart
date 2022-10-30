import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:serial_port_win32/serial_port_win32.dart';
import 'data.dart';

class MODBUS {
  static const _watchDogTimerSeconds = 30;
  static const _dataReadingIntervalSeconds = 1;

  Function(String)? showError;
  bool _errorIsNotShow = true;

  SerialPort? port;

  bool isPollingSensorsOn = false;

  DateTime _lastDataTime = DateTime.now();

  final _streamNewDataController = StreamController<List<R4DCB08>>.broadcast();
  Stream<List<R4DCB08>> get listOfR4DCB08DataStream =>
      _streamNewDataController.stream;

  final _streamStatusController = StreamController<bool>.broadcast();
  Stream<bool> get statusMODBUSDataStream => _streamStatusController.stream;

  // ============== COM port ===============================
  bool _openSerialPort() {
    try {
      if (com == null) {
        if (kDebugMode) {
          print('Serial port not defined');
        }
        return false;
      }
      if (port == null) {
        port = SerialPort(com!);
      } else if (port?.isOpened == false) {
        port?.openWithSettings(BaudRate: 9600);
        if (kDebugMode) {
          print('$com port open');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Open $com port error: $e');
      }
      if ((showError != null) && (_errorIsNotShow)) {
        _errorIsNotShow = false;
        showError!("Can't open $com port");
      }
    }
    return false;
  }

  void _closeSerialPort() {
    _streamStatusController.add(false);
    try {
      if (port?.isOpened == true) port?.close();
      if (kDebugMode) {
        print('$com port close');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Close port error: $e');
      }
      if ((showError != null) && (_errorIsNotShow)) {
        _errorIsNotShow = false;
        showError!("Can't close $com port");
      }
    }
  }

  void _watchdogTimerChecker() {
    var timeNow = DateTime.now();
    if (timeNow.difference(_lastDataTime).inSeconds > _watchDogTimerSeconds) {
      if (kDebugMode) {
        print('Data is not receiving. Closing port by watchdog timer.');
      }
      _lastDataTime = timeNow;
      _closeSerialPort();
    }
  }

  void _watchdogTimerDataReceived() {
    _lastDataTime = DateTime.now();
    _errorIsNotShow = true;
  }
  //============== R4DCB08 ===========================================

  void startR4DCB08Read() {
    isPollingSensorsOn = true;
    if (kDebugMode) {
      print('Start polling');
    }
    _closeSerialPort();
    sleep(const Duration(milliseconds: 500));
    Timer.periodic(const Duration(seconds: _dataReadingIntervalSeconds),
        (timer) {
      _readAllR4DCB08(listOfR4DCB08);
      if (!isPollingSensorsOn) {
        //switch off
        if (timer.isActive) {
          timer.cancel();
        }
        _closeSerialPort();
        if (kDebugMode) {
          print('Stop polling');
        }
      }
    });
  }

  void stopR4DCB08Read() {
    _closeSerialPort();
  }

  void _callbackNewDataReceived(int deviceAddress, List<Sensor> sensors) {
    _watchdogTimerDataReceived();
    for (var device in listOfR4DCB08) {
      if (device.address == deviceAddress) {
        device.sensors = sensors;
      }
    }
    _streamNewDataController.add(listOfR4DCB08);
    _streamStatusController.add(true);
  }

  void _readAllR4DCB08(List<R4DCB08> list) {
    _watchdogTimerChecker();
    for (var device in list) {
      if (port == null) {
        _openSerialPort();
        sleep(const Duration(milliseconds: 200));
        return;
      }
      if (port?.isOpened == false) {
        _openSerialPort();
        sleep(const Duration(milliseconds: 200));
        return;
      }
      _readR4DCB08Data(device.address);
      sleep(const Duration(milliseconds: 200));
    }
  }

  bool _readR4DCB08Data(int device) {
    try {
      if (kDebugMode) {
        print('--------------------------------------------------');
      }
//      final requestData = Uint8List.fromList([3, 3, 0, 0, 0, 8, 69, 238]); example
      final requestBody = Uint8List.fromList([device, 3, 0, 0, 0, 8]);
      final requestCRC = Uint8List.fromList(_crc(requestBody));
      final requestData = Uint8List.fromList(requestBody + requestCRC);

      _streamStatusController.add(false);
      if (port == null) return false;

      final bool success = port!.writeBytesFromUint8List(requestData);
      if (success) {
        if (kDebugMode) {
          print('Request: $requestData');
        }
      } else {
        if (kDebugMode) {
          print('Request error');
        }
        _closeSerialPort();
        return false;
      }

      port?.readBytesOnListen(21, (response) {
        final bool isCrcOk = _checkCRC(response);
        if (kDebugMode) {
          print(
              'Response: $response, (CRC check: ${isCrcOk ? 'Ok' : 'failed'})');
        }
        if (isCrcOk) {
          _parseSensorsData(response, device); // check fo NULL!!!
          return true;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Request data error: $e');
      }
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
      var newTempValue =
          response[sensorIndex * 2 + 2] + response[sensorIndex * 2 + 1] * 256;
      // checking for a negative value
      if (newTempValue > 0xFF00) {
        newTempValue -= 65535;
      }
      parsedString +=
          '[#$sensorIndex: ${(newErrValue == 128) ? 'NA' : (newTempValue / 10)}] ';
      sensors.add(Sensor(
        (newErrValue == 128) ? 0 : newTempValue,
        !(newErrValue == 128),
      ));
    }
    if (sensors.length == 8) {
      if (kDebugMode) {
        print('Parsing successful: $parsedString');
      }
      _callbackNewDataReceived(device, sensors);
      return sensors;
    } else {
      return null;
    }
  }

  bool _checkCRC(Uint8List response) {
    try {
      if (response.lengthInBytes != 21) return false;
      var responseBody = response.sublist(0, 19);
      var responseCRC = response.sublist(19, 21);
      var calcCRC = _crc(responseBody);
      return listEquals(responseCRC, calcCRC);
    } catch (e) {
      if (kDebugMode) {
        print('CRC calculation error: $e');
      }
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
