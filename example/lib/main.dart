import 'package:cue/cue.dart';
import 'package:example/examples/expanding_cards.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Curves.elasticIn;
    return MaterialApp(
      title: 'Cue Demo',
      // showPerformanceOverlay: true,
      darkTheme: ThemeData.dark(),
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
  int _selected = -1;
  late final _cueIndexController = CueIndexController(length: 3, vsync: this);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    BoxDecoration;
    return Scaffold(
      // backgroundColor: theme.colorScheme.surfaceContainer,
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.only(top: 48, bottom: 65),
        child: Center(
          child: Column(
            mainAxisAlignment: .end,
            children: [
              CueModalTransition(
                alignment: .bottomCenter,
                barrierColor: Colors.black.withValues(alpha: .2),
                simulation: Spring.gentle(),
                triggerBuilder: (context, open) {
                  return ElevatedButton(
                    clipBehavior: .antiAlias,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: theme.colorScheme.surfaceContainer,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = !_isLoading;
                            });
                            Future.delayed(const Duration(milliseconds: 2500), () async {
                              await open();
                              setState(() {
                                _isLoading = false;
                              });
                            });
                          },
                    child: Cue.onToggle(
                      toggled: _isLoading,
                      motion: .simulation(Spring.bouncy()),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            Actor(
                              size: .tween(from: .zero, to: .square(20)),
                              opacity: .fadeIn(),
                              padding: .tween(to: EdgeInsetsDirectional.only(end: 12)),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            ),
                          TranslateActor.x(from: 0, child: Text(_isLoading ? 'Processing' : 'Pay Now')),
                        ],
                      ),
                    ),
                  );
                },
                builder: (context, rect) {
                  return TranslateActor.fromGlobalRect(
                    rect: rect,
                    child: Actor(
                      role: .reverse,
                      opacity: .fadeOut(timing: .startAt(.5)),
                      slide: .tweenY(from: 0, to: 1.2),
                      child: TranslateActor.y(
                        role: .forward,
                        to: 32,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 16, 32, 12),
                          child: Material(
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: .15),
                            clipBehavior: .antiAlias,
                            color: theme.colorScheme.surfaceContainer,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(32),
                              side: BorderSide(color: Colors.black.withValues(alpha: .05), width: .5),
                            ),
                            child: SizeActor(
                              role: .forward,
                              from: .fromSize(rect.size),
                              allowOverflow: true,
                              alignment: .center,
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                                  child: Actor(
                                    role: .forward,
                                    opacity: .fadeIn(),
                                    scale: .zoomIn(from: .5),
                                    blur: .focus(from: 8),
                                    slide: .tweenY(from: .5),
                                    child: Column(
                                      mainAxisSize: .min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // payment successful content
                                        Icon(Iconsax.shopping_bag, size: 56, color: Colors.black),
                                        SizedBox(height: 10),
                                        Text(
                                          'Purchase Confirmed',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 32),
                                          child: Text(
                                            'Thank you for shopping with us!\nYour order has been placed.',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withValues(alpha: .6),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        SlideActor.y(
                                          from: 2,
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                              side: BorderSide(color: Colors.black),
                                            ),
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('View Order'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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

class _DemoPageState extends State<DemoPage> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Text('Show Sheet'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(),
                            body: Cue.onTransition(
                              child: Center(
                                child: SlideActor.y(
                                  from: 10.0,
                                  child: Text('Hello from the new page!'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
