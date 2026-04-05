import 'package:cue/src/timeline/track/track.dart';
import 'package:flutter/widgets.dart';

/// Similar to Flutter's [Animatable<T>], but evaluates via a driver ([CueTrack]).
///
/// Uses a driver pattern because some animations need extra context beyond raw
/// progress to interpolate correctly (e.g., phase for keyframes, direction for
/// asymmetric motion).
///
/// Implementations enable different evaluation strategies:
/// - [TweenAnimtable]: Standard progress-based interpolation
/// - [DualAnimatable]: Different evaluators for forward vs. reverse
/// - [ConstantAnimtable]: Constant value regardless of state
/// - [SegmentedAnimtable]: Phase-based evaluator selection for keyframes
abstract class CueAnimtable<T> {
  const CueAnimtable();
  
  /// Evaluates the animated value given the animation track state.
  T evaluate(CueTrack track);
}

/// An [CueAnimtable] that wraps a standard Flutter [Animatable].
///
/// Transforms the animation progress ([CueTrack.value]) through the tween,
/// ignoring Cue-specific state (phase, direction). Suitable for simple,
/// progress-only animations.
///
/// Typically used for single-phase motions that don't need asymmetric
/// forward/reverse behavior or multi-stage keyframes.
class TweenAnimtable<T> extends CueAnimtable<T> {
  /// The underlying Flutter tween to transform progress values.
  final Animatable<T> tween;

  /// Creates a tween-based animatable driver.
  const TweenAnimtable(this.tween);

  @override
  T evaluate(CueTrack track) {
    return tween.transform(track.value);
  }
}

/// An [CueAnimtable] that selects between forward and reverse animatables.
///
/// Enables asymmetric animations where the forward (opening/activating) motion
/// differs from the reverse (closing/deactivating) motion. Selection is based on
/// [CueTrack.isReverseOrDismissed].
///
/// **Use case**: Toggle animations where opening animates differently than closing,
/// e.g., a button expands smoothly when toggled on but snaps back when toggled off.
class DualAnimatable<T> extends CueAnimtable<T> {
  /// The animatable to evaluate when moving forward.
  final CueAnimtable<T> forward;
  
  /// The animatable to evaluate when moving in reverse.
  final CueAnimtable<T> reverse;

  /// Creates a dual-direction animatable.
  ///
  /// - [forward]: Evaluates when [CueTrack.isReverseOrDismissed] is `false`.
  /// - [reverse]: Evaluates when [CueTrack.isReverseOrDismissed] is `true`.
  DualAnimatable({
    required this.forward,
    required this.reverse,
  });

  @override
  T evaluate(CueTrack track) {
    final isReversing = track.isReverseOrDismissed;
    return isReversing ? reverse.evaluate(track) : forward.evaluate(track);
  }
}

/// An [CueAnimtable] that always returns a fixed value.
///
/// Ignores all animation state ([CueTrack] parameters). Useful for acts that
/// should not animate but need to participate in the animation framework
/// (e.g., a static color or opacity).
class ConstantAnimtable<T> extends CueAnimtable<T> {
  /// The constant value to always return.
  final T value;

  /// Creates a fixed-value animatable.
  const ConstantAnimtable(this.value);

  @override
  T evaluate(CueTrack track) => value;
}


/// An [CueAnimtable] that selects and evaluates an evaluator based on phase.
///
/// Maintains a list of evaluators—one per phase. Selects the active evaluator
/// using the driver's phase, then evaluates through that evaluator.
///
/// **Common use case**: Keyframe animations, where different motions are needed.
class SegmentedAnimtable<T> extends CueAnimtable<T> {
  /// List of evaluators, indexed by phase.
  ///
  /// Each element corresponds to one phase. The index must match the
  /// phase reported by the driver to ensure correct evaluator selection.
  final List<Animatable<T>> segments;

  /// Creates a phase-based evaluator selector.
  SegmentedAnimtable(this.segments);

  @override
  T evaluate(CueTrack track) {
    return segments[track.phase].transform(track.value);
  }
}
