// import 'package:cue/cue.dart';
// import 'package:cue/src/effects/base/tween_effect.dart';
// import 'package:cue/src/timeline/cue_motion.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// void x() {
//   PhasedCue<ThemeMode>(
//     phase: ThemeMode.dark,
//     effects: [
//       PhasedScaleEffect<ThemeMode>(
//         phases: {
//           ThemeMode.dark: 0.0,
//           ThemeMode.light: 1.0,
//         },
//       ),
//     ],
//     child: SizedBox(),
//   );
// }

// class PhasedCue<P> extends StatefulWidget {
//   const PhasedCue({
//     super.key,
//     this.motion = CueMotion.defaultDuration,
//     required this.phase,
//     required this.effects,
//     required this.child,
//   });
//   final CueMotion motion;
//   final List<PhasedEffect<P, dynamic>> effects;
//   final P phase;
//   final Widget child;

//   @override
//   State<PhasedCue<P>> createState() => _PhasedCueState<P>();
// }

// class _PhasedCueState<P> extends State<PhasedCue<P>> with SingleTickerProviderStateMixin {
//   final List<Effect> _effects = [];
//   late P _previousPhase = widget.phase;

//   late final CueAnimationController _controller;

//   Animation<double> _animation = const AlwaysStoppedAnimation(0.0);

//   @override
//   void initState() {
//     super.initState();
//     _controller = CueAnimationController(
//       motion: widget.motion,
//       vsync: this,
//       debugLabel: 'PhasedCue Controller',
//     );
//     _buildAnimation();
//     _buildEffects();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(covariant PhasedCue<P> oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (oldWidget.motion != widget.motion) {
//       _controller.motion = widget.motion;
//       _buildAnimation();
//     }

//     if (oldWidget.phase != widget.phase || !listEquals(oldWidget.effects, widget.effects)) {
//       _previousPhase = oldWidget.phase;
//       _buildEffects();
//     }
//   }

//   void _buildAnimation() {
//     _animation = switch (widget.motion) {
//       TimedMotion m => m.applyCurve(_controller),
//       SimulationMotion() => _controller.view,
//     };
//   }

//   void _buildEffects() {
//     _effects.clear();
//     for (final phasedEffect in widget.effects) {
//       final toPhase = phasedEffect.getPhase(widget.phase);
//       final fromPhase = phasedEffect.getPhase(_previousPhase);
//       final effect = phasedEffect.buildEffect(fromPhase, toPhase);
//       _effects.add(effect);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RawActor.internal(
//       drive: CueScope(
//         animation: _animation,
//         isBounded: false,
//         child: const SizedBox.shrink(),
//       ),
//       effects: List.unmodifiable(_effects),
//       child: widget.child,
//     );
//   }
// }

// class PhasedScaleEffect<P> extends PhasedEffect<P, double> {
//   const PhasedScaleEffect({required super.phases});

//   @override
//   TweenEffect<double> buildEffect(double from, double to) {
//     return ScaleEffect(from: from, to: to);
//   }
// }

// abstract class PhasedEffect<P, V> {
//   const PhasedEffect({required this.phases});
//   final Map<P, V> phases;

//   V getPhase(P value) {
//     final phase = phases[value];
//     if (phase == null) {
//       throw Exception('No phase found for value $value');
//     }
//     return phase as V;
//   }

//   // subclass provides the effect for a given transition
//   TweenEffect<V> buildEffect(V from, V to);
// }
