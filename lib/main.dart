import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'load_setings.dart';

import 'modbus.dart';
import 'data.dart';

void main() {
  runApp(const MyApp());
}

MODBUS modbus = MODBUS();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Temperature MODBUS dashboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _callbackShowErrorFunc(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.yellowAccent,
            ),
            SizedBox(width: 10),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        duration: const Duration(seconds: 10),
        width: 280.0, // Width of the SnackBar.
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0, // Inner padding for SnackBar content.
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  @override
  void initState() {
    loadINIData();
    modbus.showError = _callbackShowErrorFunc;
    super.initState();
  }

  void _changePollingSensorsStatus() {
    setState(() {
      if (!modbus.isPollingSensorsOn) {
        modbus.startR4DCB08Read();
      } else {
        modbus.isPollingSensorsOn = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: const StatusIndicator(),

        // actions: const [
        //   OpenSettings(),
        // ],
      ),

      body: StreamBuilder<List<R4DCB08>>(
          stream: modbus.listOfR4DCB08DataStream,
          builder: (context, snapshot) {
            List<Widget> deviceWidgets = [];
            if (snapshot.hasData) {
              var devicesList = snapshot.data!;
              for (var dev in devicesList) {
                deviceWidgets.add(DeviceWidget(device: dev));
              }
            }
            return ListView(children: deviceWidgets);
          }),

      floatingActionButton: FloatingActionButton(
        onPressed: _changePollingSensorsStatus,
        tooltip: 'Read data',
        backgroundColor: modbus.isPollingSensorsOn ? Colors.blue : Colors.red,
        child: modbus.isPollingSensorsOn
            ? const Icon(Icons.play_arrow)
            : const Icon(Icons.stop),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DeviceWidget extends StatelessWidget {
  final R4DCB08 device;
  const DeviceWidget({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> sensorWingets = [];
    for (var sensorIndex = 0; sensorIndex <= 7; sensorIndex++) {
      final String tempString = device.sensors[sensorIndex].isConnect
          ? (device.sensors[sensorIndex].temp / 10).toString()
          : 'NA';
      sensorWingets.add(
        Padding(
          padding: EdgeInsets.all(8),
          child: SensorWidget(
            temperature: tempString,
            name: device.names[sensorIndex],
            isActive: device.sensors[sensorIndex].isConnect,
          ),
        ),
      );
    }
    return Card(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: sensorWingets,
      ),
    );
  }
}

class SensorWidget extends StatelessWidget {
  final String temperature;
  final String name;
  final bool isActive;
  const SensorWidget({
    Key? key,
    required this.temperature,
    required this.name,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      height: 100,
      width: 100,
      color: isActive ? Colors.lightBlueAccent.shade100 : Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            temperature,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? Colors.black87 : Colors.red.shade300,
              fontFamily: 'Roboto',
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            name,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OpenSettings extends StatelessWidget {
  const OpenSettings({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SetupScreen(),
          ),
        );
      },
      icon: const Icon(Icons.settings),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: modbus.statusMODBUSDataStream,
        builder: (context, snapshot) {
          int indColor = 0;
          if (snapshot.hasData) {
            if (snapshot.data! == true) {
              indColor = 255;
            }
          }
          return TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: indColor),
              duration: const Duration(milliseconds: 200),
              builder: (BuildContext context, int levelColor, Widget? child) {
                return Icon(
                  Icons.circle,
                  color: Color.fromRGBO((255 - levelColor), levelColor, 0, 1.0),
                );
              });
        });
  }
}
