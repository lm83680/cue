import 'package:cue/cue.dart';
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
      title: 'Wallet App',
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const DemoPage(),
      builder: (context, child) {
        if (kDebugMode) {
          return CueDebugTools(child: child!);
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
  bool isOpen = false;
  final drawerWidth = 320.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('Header')),
            ListTile(title: Text('Item 1')),
            ListTile(title: Text('Item 2')),
            ListTile(title: Text('Item 3')),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Demo'),
        leading: IconButton(
          onPressed: () {
            setState(() {
              isOpen = !isOpen;
            });
          },
          icon: Icon(
            isOpen ? Icons.close : Icons.menu,
          ),
        ),
      ),
      body: Cue.onToggle(
        toggled: isOpen,
        motion: .spatialSlow(),
        child: CueDragScrubber(
          axis: .horizontal,
          distance: drawerWidth,
          onAnimationEnd: (forward) {
            setState(() {
              isOpen = forward;
            });
          },
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Actor(
                    acts: [
                      .scale(to: .95),
                      .slideX(to: .2)
                    ],
                    child: Container(color: Colors.blueGrey)),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: isOpen? () {
                      setState(() {
                        isOpen = false;
                      });
                    } : null,
                    child: DecoratedBoxActor(
                      color: .tween(Colors.transparent, Colors.black26),
                    ),
                  ),
                ),
                PositionedActor(
                  from: Position(top: 0, start: -drawerWidth, width: drawerWidth, bottom: 0),
                  to: Position(top: 0, start: 0, width: drawerWidth, bottom: 0),
                  child: Container(
                    color: Colors.blue,
                    child: Column(children: [
                      // stagger a list otems fadein slideY acts here
                      for (int i = 0; i < 5; i++)
                        Actor(
                          acts: [
                            .fadeIn(delay: Duration(milliseconds: 50 * i)),
                            .slideY(from: 0.5, delay: Duration(milliseconds: 100 + (50 * i))),
                          ],
                          child: ListTile(
                            title: Text('Item ${i + 1}'),
                            leading: const Icon(Icons.star),
                          ),
                        )
                    ],),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
