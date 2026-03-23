import 'package:cue/src/timeline/track/track.dart';
import 'package:flutter/widgets.dart';

abstract class CueAnimtable<T> {
  const CueAnimtable();
  T evaluate(CueTrack track);
}

class TweenAnimtable<T> extends CueAnimtable<T> {
  final Animatable<T> tween;

  const TweenAnimtable(this.tween);

  @override
  T evaluate(CueTrack track) {
    return tween.transform(track.value);
  }
}

class ReversedAnimtable<T> extends TweenAnimtable<T> {
  const ReversedAnimtable(super.tween);

  @override
  T evaluate(CueTrack track) => tween.transform(1.0 - track.value);
}

class DualAnimatable<T> extends CueAnimtable<T> {
  final CueAnimtable<T> forward;
  final CueAnimtable<T> reverse;

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

class AlwaysStoppedAnimatable<T> extends CueAnimtable<T> {
  final T value;

  const AlwaysStoppedAnimatable(this.value);

  @override
  T evaluate(CueTrack track) => value;
}

class AnimatableSegment<T> extends Animatable<T> {
  final Animatable<T> animatable;

  AnimatableSegment({
    required this.animatable,
  });

  @override
  T transform(double t) => animatable.transform(t);
}

class SegmentedAnimtable<T> extends CueAnimtable<T> {
  final List<AnimatableSegment<T>> segments;

  SegmentedAnimtable(this.segments);

  @override
  T evaluate(CueTrack track) {
    return segments[track.phase].transform(track.value);
  }
}
