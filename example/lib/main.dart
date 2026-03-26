import 'package:cue/cue.dart';
import 'package:example/examples/indicator_to_button.dart';

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
      title: 'Cue Demo',
      // showPerformanceOverlay: true,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _OnChangeDemo(),
      builder: (context, child) {
        if (kDebugMode) {
          return CueDebugTools(child: child!);
        }
        return child!;
      },
    );
  }
}

class _OnChangeDemo extends StatefulWidget {
  const _OnChangeDemo({super.key});

  @override
  State<_OnChangeDemo> createState() => __OnChangeDemoState();
}

class __OnChangeDemoState extends State<_OnChangeDemo> with SingleTickerProviderStateMixin {
  Offset offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: Colors.blue,
      appBar: AppBar(),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .end,
            children: [
              // ElevatedButton(
              //   onPressed: () {
              //     showCueModalBottomSheet(
              //       context: context,
              //       showDragHandle: true,
              //       enableDrag: true,
              //       motion: .linear(780.ms),
              //       builder: (context) => Container(
              //         height: 320,
              //         width: double.infinity,
              //         margin: const EdgeInsets.only(bottom: 8.0),
              //         decoration: BoxDecoration(
              //           borderRadius: BorderRadius.circular(12.0),
              //         ),
              //         child: Center(child: Actor(
              //          motion: .wobbly(),
              //           acts: [
              //             .fadeIn(),
              //             .slideY(from: -8),
              //             .zoomIn(from: .0),
              //           ],
              //           child: Text('Hello World!'))),
              //       ),
              //       // sheetAnimationStyle: .spring(damping: 20, stiffness: 200), --- IGNORE ---
              //     );
              //   },
              //   child: Text('Show BottomSheet'),
              // ),

              //  SlackStyleFab(),
              //  DeleteConfirmationDialog(),
              // if(false)
              // IndicatorToButton(),
              //   GestureDetector(
              //     behavior: HitTestBehavior.translucent,
              //     onVerticalDragUpdate: (details) {
              //       setState(() {
              //         offset += details.delta;
              //       });
              //        _animation.setAnimatable(null);
              //     },
              //     onVerticalDragEnd: (details) async{
              //       final animtable = TweenAnimtable(Tween(begin: offset, end: Offset.zero));
              //       _animation.setAnimatable(animtable);
              //         _controller.value = 0;
              //        await _controller.forward();
              //       offset = Offset.zero;
              //     },
              //     child: ListenableBuilder(
              //       listenable: _animation,
              //       builder: (context, _) {
              //         print('build with offset ${_animation.hasAnimatable ? _animation.value : offset}');
              //         return Transform.translate(
              //           offset: _animation.hasAnimatable ? _animation.value : offset,
              //           child: FloatingActionButton(
              //             onPressed: null,
              //             child: Icon(Icons.abc),
              //           ),
              //         );
              //       },
              //     ),
              //   ),

              for (var i = 0; i < 20; i++)
                Cue.onScrollVisible(
                  key: ValueKey(i),
                  acts:[
                    // .zoomIn(from: .75),
                    // .slideY(from: 0, reverse: .to(1.1)),
                    .slideX(from: -1, reverse: .to(1)),
                  ],
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8.0),

                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .3),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
