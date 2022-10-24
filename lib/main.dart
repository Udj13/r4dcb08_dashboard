import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'load_setings.dart';

import 'modbus.dart';

void main() {
  runApp(const MyApp());
}

MODBUS modbus = MODBUS();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    loadINIData();
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
  String textData = '';

  void _read() {
    setState(() {
      modbus.readMODBUSData();
      textData = 'ok';
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
            Text(
              'Data: $textData',
              style: Theme.of(context).textTheme.headline4,
            ),
            OutlinedButton(
              onPressed: () {
                modbus.openSerialPort();
              },
              child: const Text('Open Port'),
            ),
            OutlinedButton(
              onPressed: () {
                _read();
              },
              child: const Text('Read data'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Update data'),
            ),
            OutlinedButton(
              onPressed: () {
                modbus.closeSerialPort();
              },
              child: const Text('Close Port'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _read,
        tooltip: 'Read data',
        child: const Icon(Icons.read_more),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
