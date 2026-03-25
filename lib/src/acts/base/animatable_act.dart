import 'package:cue/cue.dart';
import 'package:cue/src/timeline/track/track_config.dart';
import 'package:flutter/widgets.dart';

abstract class AnimtableAct<R extends Object?, T extends Object?> extends Act {
  final CueMotion? motion;
  final Duration delay;
  final ReverseBehaviorBase<T> reverse;

  const AnimtableAct({this.motion, this.delay = Duration.zero, required this.reverse});

  (CueAnimtable<R>, CueAnimtable<R>?) buildTweens(ActContext context);

  @override
  CueAnimation<R> buildAnimation(CueTimeline timline, ActContext context) {
    final (animtable, reverseAnimtable) = buildTweens(context);
    final (track, token) = timline.trackFor(TrackConfig(
      motion: context.motion,
      reverseMotion: context.reverseMotion,
      reverseType: reverse.type,
    ));
    CueAnimtable<R> effectiveAnimatable = reverseAnimtable == null
        ? animtable
        : DualAnimatable(forward: animtable, reverse: reverseAnimtable);
    return CueAnimationImpl<R>(parent: track, token: token, animtable: effectiveAnimatable);
  }

  @override
  Widget build(BuildContext context, covariant CueAnimation<Object?> animation, Widget child) {
    assert(
      animation is CueAnimation<R>,
      'Expected animation of type CueAnimation<$R>, but got ${animation.runtimeType}',
    );
    return apply(context, animation as CueAnimation<R>, child);
  }

  Widget apply(BuildContext context, covariant CueAnimation<R> animation, Widget child);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is AnimtableAct<R, T> && other.motion == motion && other.delay == delay && other.reverse == reverse;
  }

  @override
  int get hashCode => Object.hash(motion, reverse, delay);
}
