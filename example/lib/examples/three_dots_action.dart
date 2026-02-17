import 'package:flutter/material.dart';
import 'package:cue/cue.dart';

class ThreeDotsAction extends StatelessWidget {
  const ThreeDotsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalTransition(
      showDebug: true,
      barrierColor: Colors.black12,
      alignment: Alignment.bottomCenter,
      simulation: (data) {
        return Spring.smooth(
          start: data.progress,
          end: data.end,
          velocity: data.velocity,
        );
      },
      triggerBuilder: (context, showModal) => FloatingActionButton(
        shape: CircleBorder(),
        heroTag: null,
        elevation: 1,
        onPressed: showModal,
        child: Column(
          spacing: 2,
          mainAxisSize: MainAxisSize.min,
          children: [
            // we use specific sized dots for easier transition
            for (var i = 0; i < 3; i++)
              CircleAvatar(
                radius: 2.5,
                backgroundColor: Colors.black,
              ),
          ],
        ),
      ),
      builder: (context, rect) {
        return SizedBox(
          width: rect.width,
          child: Stack(
            alignment: .bottomCenter,
            children: [
              FloatingActionButton(
                elevation: 0,
                shape: CircleBorder(),
                onPressed: () => Navigator.of(context).pop(),
                child: Actor(
                  acts: [
                    BlurAct(from: 6),
                    FadeAct(),
                    TranslateAct.y(from: rect.height / 3),
                  ],
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
              Actor.translateY(
                from: -rect.height / 3,
                to: -rect.height - 4, // 4 is little extra padding
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    for (var icon in [
                      Icons.near_me_outlined,
                      Icons.draw_outlined,
                      Icons.translate,
                    ])
                      Actor(
                        acts: [
                          PaddingAct(from: .all(1), to: .only(bottom: 10.0)),
                          ResizeAct(from: .square(5), to: .square(44)),
                        ],
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.black,
                          elevation: 1,
                          shape: CircleBorder(),
                          heroTag: null,
                          onPressed: () {},
                          child: Actor(
                            acts: [
                              ClipRevealAct(borderRadius: .circular(5), alignment: .center),
                              BlurAct(from: 8),
                              FadeAct(),
                            ],
                            child: Icon(icon, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
