import 'package:cue/cue.dart';
import 'package:cue/src/timeline/track/track_config.dart';
import 'package:flutter/widgets.dart';

/// Base implementation of [Act] for tween-based and keyframed acts.
///
/// [AnimtableAct] handles the boilerplate of storing per-act [motion],
/// [delay], and [reverse] behavior, and wires up [buildAnimation] and [applyInternal]
/// so that concrete subclasses only need to implement [buildTweens] and
/// [apply].
///
/// ## Type parameters
///
/// - `T` — the value type used by [ReverseBehaviorBase], i.e. the Dart type
///   passed to `ReverseBehavior.to(T)` or held in `KFReverseBehavior.to(Keyframes<T>)`.
/// - `R` — the animated value type flowing through [CueAnimtable] and
///   [CueAnimation]. Usually `T == R`; they may differ when the act
///   normalises its input before animating (e.g. resolving an enum into a
///   numeric range).
abstract class AnimtableAct<T extends Object?, R extends Object?> extends Act {
  /// Per-act motion override. When non-null, replaces the motion inherited
  /// from [Actor] or [Cue] for this act only.
  final CueMotion? motion;

  /// Delay before this act's forward animation starts.
  ///
  /// Stacks additively on top of any delay set on [Actor].
  final Duration delay;

  /// Reverse behavior for this act — controls what happens when the animation
  /// plays in reverse.
  ///
  /// See [ReverseBehavior] and [KFReverseBehavior] for the available variants.
  final ReverseBehaviorBase<T> reverse;

  /// Creates an animatable act with optional [motion], [delay], and [reverse] behavior.
  const AnimtableAct({this.motion, this.delay = Duration.zero, required this.reverse});

  /// Builds the forward and optional reverse [CueAnimtable]s for this act.
  ///
  /// Returns a pair `(forward, reverse?)`. When the second element is non-null
  /// it is used as the animatable for the reverse pass instead of the forward
  /// one played backwards.
  ///
  /// Subclasses implement this method to produce their tweens or keyframe
  /// animatables. [buildAnimation] and [buildAnimtable] both delegate here.
  (CueAnimtable<R>, CueAnimtable<R>?) buildTweens(ActContext context);

  /// Assembles the forward and reverse animatables into a single
  /// [CueAnimtable], wrapping them in a [DualAnimatable] when a separate
  /// reverse animatable is present.
  ///
  /// Used by parts of the system that operate outside the timeline —
  /// for example [SizedBoxAct] and [SizedClipAct] drive their own internal
  /// controller and call this directly instead of going through
  /// [buildAnimation].
  CueAnimtable<R> buildAnimtable(ActContext context) {
    final (animtable, reverseAnimatable) = buildTweens(context);
    if (reverseAnimatable != null) {
      return DualAnimatable(forward: animtable, reverse: reverseAnimatable);
    } else {
      return animtable;
    }
  }

  @override
  CueAnimation<R> buildAnimation(CueTimeline timline, ActContext context) {
    final (animtable, reverseAnimtable) = buildTweens(context);
    final (track, token) = timline.obtainTrack(
      TrackConfig(
        motion: context.motion,
        reverseMotion: context.reverseMotion,
        reverseType: reverse.type,
      ),
    );
    CueAnimtable<R> effectiveAnimatable =
        reverseAnimtable == null ? animtable : DualAnimatable(forward: animtable, reverse: reverseAnimtable);
    return CueAnimationImpl<R>(parent: track, token: token, animtable: effectiveAnimatable);
  }

  /// Delegates to [apply] after asserting that [animation] has the expected
  /// type `CueAnimation<R>`.
  @override
  Widget applyInternal(BuildContext context, covariant CueAnimation<Object?> animation, Widget child) {
    assert(
      animation is CueAnimation<R>,
      'Expected animation of type CueAnimation<$R>, but got ${animation.runtimeType}',
    );
    return apply(context, animation as CueAnimation<R>, child);
  }

  /// Applies the animated value to [child] and returns the resulting widget.
  ///
  /// This is the rendering entry-point for concrete act subclasses —
  /// implement this instead of overriding [applyInternal].
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
