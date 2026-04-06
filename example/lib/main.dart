import 'package:cue/cue.dart';
import 'package:example/examples/bottom_bar.dart';
import 'package:example/examples/delete_confirmation.dart';
import 'package:example/examples/draggable_panel.dart';
import 'package:example/examples/expanding_cards.dart';
import 'package:example/examples/horizinally_expanding_cards.dart';
import 'package:example/examples/indicator_to_button.dart';
import 'package:example/examples/ios_context_menu.dart';
import 'package:example/examples/slack_style_fab.dart';
import 'package:example/examples/smooth_switch.dart';
import 'package:example/examples/three_dots_action.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cue',
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const DemoPage(),
      debugShowCheckedModeBanner: false,
      // builder: (context, child) {
      //   if (kDebugMode) {
      //     return CueDebugTools(child: child!);
      //   }
      //   return child!;
      // },
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
      appBar: AppBar(title: const Text('Cue')),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 150),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
            SmoothSwitch()
            ],
          ),
        ),
      ),
    );
  }
}
