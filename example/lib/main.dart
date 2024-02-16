import 'package:flutter/material.dart';
import 'package:resource_storage/resource_storage.dart';
import 'package:resource_storage_secure/resource_storage_secure.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Storage Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: ElevatedButton(
          child: const Text('Open Demo Page'),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const DemoPage()));
          },
        ),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  Value _value1 = Value(0);
  Value _value2 = Value(0);
  late FlutterSecureResourceStorage<String, Value> _storage1;
  late FlutterSecureResourceStorage<String, Value> _storage2;

  @override
  void initState() {
    super.initState();
    _storage1 = FlutterSecureResourceStorage<String, Value>(
      storageName: 'value_1',
      decode: Value.fromJson,
      logger: const Logger(),
    );
    _storage2 = FlutterSecureResourceStorage<String, Value>(
      storageName: 'value_2',
      decode: Value.fromJson,
      logger: const Logger(),
    );
    _refreshCounter1();
    _refreshCounter2();
  }

  void _refreshCounter1() async {
    final cache = await _storage1.getOrNull('counter');
    setState(() {
      _value1 = cache?.value ?? Value(0);
    });
  }

  void _refreshCounter2() async {
    final cache = await _storage2.getOrNull('counter');
    setState(() {
      _value2 = cache?.value ?? Value(0);
    });
  }

  void _incrementCounters() async {
    await _storage1.put('counter', _value1 + 1);
    _refreshCounter1();
    await _storage2.put('counter', _value2 + 1);
    _refreshCounter2();
  }

  void _resetStorage1() async {
    await _storage1.clear();
    _refreshCounter1();
  }

  void _resetStorage2() async {
    await _storage2.clear();
    _refreshCounter2();
  }

  void _resetAllStorages() async {
    // Clears all storages: storage1 and storage2.
    await _storage1.clearAllStorage();
    _refreshCounter1();
    _refreshCounter2();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Demo page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Counter 1:'),
            Text(
              '${_value1.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetStorage1,
              child: const Text('Reset storage 1'),
            ),
            const SizedBox(height: 60),
            const Text('Counter 2:'),
            Text(
              '${_value2.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetStorage2,
              child: const Text('Reset storage 1'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _resetAllStorages,
              child: const Text('Reset all'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounters,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Value {
  Value(this.counter);

  final int counter;

  Value operator +(int a) => Value(counter + a);

  @override
  String toString() => 'Value($counter)';

  Map<String, dynamic> toJson() {
    return {
      'counter': counter,
    };
  }

  factory Value.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Value(map['counter'] as int);
  }
}
