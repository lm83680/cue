import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

class IndicatorToButton2 extends StatefulWidget {
  const IndicatorToButton2({super.key});

  @override
  State<IndicatorToButton2> createState() => _IndicatorToButton2State();
}

class _IndicatorToButton2State extends State<IndicatorToButton2> {
  final _pageController = CuePageController(viewportFraction: .85);
  final pagesCount = 5;

  @override
  Widget build(BuildContext context) {
    final lastIndex = pagesCount - 1.0;
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pagesCount,
            itemBuilder: (context, index) {
              return Card(
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: .2),
                shape: RoundedSuperellipseBorder(
                  borderRadius: .circular(32.0),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 32),
        // Indicator starts here -------------
        Container(
          height: 44,
          width: 150,
          alignment: .centerLeft,
          decoration: BoxDecoration(
            borderRadius: .circular(32),
            border: .all(color: Colors.black, width: 2.0),
          ),
          child: Cue.onProgress(
            listenable: _pageController,
            progress: () => _pageController.page ?? 0.0,
            max: lastIndex,
            acts: [.fractionalSize(widthFactor: .tween(from: .4, to: 1))],
            child: Cue.indexed(
              index: lastIndex.toInt(),
              controller: _pageController,
              child: Actor(
                acts: [.padding(from: .all(2))],
                child: Material(
                  color: Colors.black,
                  borderRadius: .circular(32.0),
                  clipBehavior: .hardEdge,
                  child: InkWell(
                    onTap: _onNext,
                    child: Actor(
                      acts: [.align(from: .centerRight)],
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Actor(
                            acts: [
                              .clipWidth(alignment: .centerLeft),
                              .zoomIn(),
                              .focus(),
                              .slideX(from: 1),
                            ],
                            child: Padding(
                              padding: const .symmetric(horizontal: 8.0),
                              child: Text(
                                "Let's Go",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_outlined,
                            color: Colors.white60,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onNext() {
    if (_pageController.page?.round() == pagesCount - 1) {
      // action
    } else {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
}
