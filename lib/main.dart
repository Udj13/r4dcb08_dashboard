import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'load_setings.dart';

import 'modbus.dart';

void main() {
  loadINIData();
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
  @override
  void initState() {
    super.initState();
    if (!modbus.isPollingSensorsOn) {
      modbus.startR4DCB08Read();
    }
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SetupScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
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
