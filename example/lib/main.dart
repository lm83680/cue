import 'package:cue/cue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'examples/three_dots_action.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cue Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const DemoPage(),
      builder: (context, child) {
        if (kDebugMode) {
          return CueDebugTools(
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Cue Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Cue.onMount(
              debug: true,
              loop: true,
              child: Column(
                children: [
                  Actor(
                    acts: [
                      TranslationAct.sequence([
                        Phase(begin: Offset(0, 0), end: Offset(50, 0), weight: .3),
                        Phase(begin: Offset(50, 0), end: Offset(50, 50), weight: .3),
                        Phase(begin: Offset(50, 50), end: Offset(0, 50), weight: .3),
                        Phase(begin: Offset(0, 50), end: Offset(0, 0), weight: .3),
                      ]),
                    ],
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Phase(begin: Offset(0, 0), end: Offset(50, 0), weight: .3),
// Phase(begin: Offset(50, 0), end: Offset(50, 50), weight: .3),
// Phase(begin: Offset(50, 50), end: Offset(0, 50), weight: .3),
// Phase(begin: Offset(0, 50), end: Offset(0, 0), weight: .3),
