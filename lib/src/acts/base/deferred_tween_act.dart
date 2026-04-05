import 'package:cue/cue.dart';
import 'package:cue/src/acts/base/animatable_act.dart';
import 'package:flutter/widgets.dart';

/// Base class for acts that construct their tween asynchronously via a
/// [DeferredCueAnimation].
///
/// [DeferredTweenAct] is for acts that cannot build their animatable
/// synchronously at construction time. Instead, they receive a
/// [DeferredCueAnimation] and set the animatable via
/// `animation.setAnimatable()` once building is complete.
///
/// Common use cases:
///
/// - Acts that measure widgets (e.g., [SizedBoxAct], [SizedClipAct]) build
///   their tween after the child has been laid out and its constraints are
///   known.
///
/// ## Subclass implementation
///
/// Concrete subclasses:
/// 1. Override [apply] to render the widget (same as for [AnimtableAct])
/// 2. Do NOT override [buildTweens] — it throws unconditionally
/// 3. Call `animation.setAnimatable(...)` when the tween is ready
abstract class DeferredTweenAct<T extends Object?> extends AnimtableAct<T, T> {
  const DeferredTweenAct({
    super.motion,
    super.delay,
    super.reverse = const ReverseBehavior.mirror(),
  });

  @override
  Widget applyInternal(BuildContext context, covariant Animation<Object?> animation, Widget child) {
    assert(
      animation is DeferredCueAnimation<T>,
      'Expected animation of type DeferredCueAnimation<$T>, but got ${animation.runtimeType}',
    );
    return apply(context, animation as DeferredCueAnimation<T>, child);
  }

  @override
  Widget apply(BuildContext context, covariant DeferredCueAnimation<T> animation, Widget child);

  @override
  (CueAnimtable<T>, CueAnimtable<T>?) buildTweens(ActContext context) {
    throw StateError(
      'DeferredTweenAct does not build a tween directly. It should be used with a DeferredCueAnimation that will set the tween later.',
    );
  }
}
