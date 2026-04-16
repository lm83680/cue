part of 'base/act.dart';

/// {@template slide_act}
/// Animates widget position by sliding it as a fraction of its own size.
///
/// [SlideAct] moves a widget by an amount relative to the widget's dimensions.
/// An offset of `Offset(0.5, 0)` slides the widget right by 50% of its width.
/// An offset of `Offset(0, -1.0)` slides the widget up by 100% of its height.
///
/// Use [Act.slide()] factory to create instances. This is the recommended approach
/// for most slide animations.
///
/// Unlike [TranslateAct], which uses absolute pixel distances, [SlideAct] uses
/// fractional sizing relative to the widget itself.
///
/// ## Basic Slide Animation
///
/// ```dart
/// // Slide left by 100% of widget width
/// Actor(
///   acts: [
///     .slide(from: Offset(-1.0, 0)), // to defaults to Offset.zero
///   ],
///   child: MyWidget(),
/// )
/// ```
///
/// ## Entrance Animations
///
/// ```dart
/// // Slide in from bottom (entrance)
/// Actor(
///   acts: [
///     .slideUp(),
///     .fadeIn(),
///   ],
///   motion:.smooth(damping: 23),
///   child: MyWidget(),
/// )
///
/// // Slide in from left
/// Actor(
///   acts: [
///     .slideFromLeading(),
///   ],
///   motion: .smooth(damping: 23),
///   child: MyWidget(),
/// )
/// ```
///
/// ## Single-Axis Slide
///
/// For animations where only one axis changes:
///
/// ```dart
/// // Only vertical sliding
/// Actor(
///   acts: [
///     .slideY(from: -1.0),
///   ],
///   child: MyWidget(),
/// )
///
/// // Only horizontal sliding
/// Actor(
///   acts: [
///     .slideX(from: 0.5),
///   ],
///   child: MyWidget(),
/// )
/// ```
/// {@endtemplate}
abstract class SlideAct extends Act {
  /// {@template act.slide}
  /// Animates bidirectional sliding using fractional sizing.
  ///
  /// Both [from] and [to] are [Offset] values representing fractions of the
  /// widget's size. Use [Offset.zero] for no offset.
  ///
  /// ## Basic Usage
  ///
  /// ```dart
  /// // Slide from left to center
  /// Actor(
  ///   acts: [
  ///     .slide(from: Offset(-1.0, 0)), // 'to' defaults to Offset.zero
  ///   ],
  ///   motion: .smooth(damping: 23),
  ///   child: MyWidget(),
  /// )
  /// ```
  ///
  /// ## Custom Offset
  ///
  /// ```dart
  /// // Slide diagonally
  /// Actor(
  ///   acts: [
  ///     .slide(from: Offset(-0.5, 0.5)), // 'to' defaults to Offset.zero
  ///   ],
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct({
    Offset from,
    Offset to,
    CueMotion? motion,
    ReverseBehavior<Offset> reverse,
    Duration delay,
  }) = _SlideEffect;

  /// {@template act.slide.up}
  /// Slide up from bottom to center for entrance animations.
  ///
  /// Slides from `Offset(0, 1)` to `Offset.zero` (upward).
  /// Often paired with [Act.fadeIn()] for smooth entrances.
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .slideUp(),
  ///     .fadeIn(),
  ///   ],
  ///   motion:.smooth(damping: 23),
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.up({
    CueMotion? motion,
    ReverseBehavior<Offset> reverse,
    Duration delay,
  }) = _SlideEffect.fromBottom;

  /// {@template act.slide.down}
  /// Slide down from top to center for entrance animations.
  ///
  /// Slides from `Offset(0, -1)` to `Offset.zero` (downward).
  /// Often paired with [Act.fadeIn()] for smooth entrances.
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .slideDown(),
  ///     .fadeIn(),
  ///   ],
  ///   motion: .smooth(damping: 23),
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.down({
    CueMotion? motion,
    ReverseBehavior<Offset> reverse,
    Duration delay,
  }) = _SlideEffect.fromTop;

  /// {@template act.slide.fromLeading}
  /// Slide in from the leading edge (left in LTR, right in RTL).
  ///
  /// Slides from `Offset(-1, 0)` to `Offset.zero`, respecting text directionality.
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .slideFromLeading(),
  ///   ],
  ///   motion: .smooth(damping: 23),
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.fromLeading({
    CueMotion? motion,
    ReverseBehavior<Offset> reverse,
    Duration delay,
  }) = _SlideEffect.fromLeading;

  /// {@template act.slide.fromTrailing}
  /// Slide in from the trailing edge (right in LTR, left in RTL).
  ///
  /// Slides from `Offset(1, 0)` to `Offset.zero`, respecting text directionality.
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     Act.slide.fromTrailing(),
  ///   ],
  ///   motion: Spring.smooth(damping: 23),
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.fromTrailing({
    CueMotion? motion,
    ReverseBehavior<Offset> reverse,
    Duration delay,
  }) = _SlideEffect.fromTrailing;

  /// {@template act.slide.keyframed}
  /// Animates through multiple sliding offset keyframes.
  ///
  /// [frames] define multiple [Offset] targets at different times.
  ///
  /// ## Fractional keyframes with shared duration
  ///
  /// ```dart
  /// Act.slide.keyframed(
  ///   frames: Keyframes.fractional([
  ///     .key(Offset(-1.0, 0), at: 0.0),
  ///     .key(Offset.zero, at: 0.5),
  ///     .key(Offset(0.5, 0), at: 1.0),
  ///   ], duration: 800.ms),
  /// )
  /// ```
  ///
  /// ## Per-keyframe motion with override
  ///
  /// ```dart
  /// Act.slide.keyframed(
  ///   frames: Keyframes(
  ///     [
  ///       .key(Offset(-1.0, 0)),  // Uses default motion
  ///       .key(Offset.zero, motion: Spring.bouncy()),  // Overrides default
  ///       .key(Offset(0.5, 0), motion: Linear(300.ms)),  // Overrides default
  ///     ],
  ///     motion: Spring.smooth(),  // Default motion
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.keyframed({
    required Keyframes<Offset> frames,
    KFReverseBehavior<Offset> reverse,
    Duration delay,
  }) = _SlideEffect.keyframed;

  /// {@template act.slide.y}
  /// Animates vertical sliding only (Y-axis).
  ///
  /// [from] and [to] are vertical offsets as fractions of widget height.
  /// Negative values slide up/start, positive values slide down/trailing.
  /// Horizontal position remains unchanged.
  ///
  /// ## Vertical Slide
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .slideY(from: -1.0, to: 0),  // Slide up by 100% of height
  ///   ],
  ///   motion: .smooth(damping: 23),
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.y({
    double from,
    double to,
    CueMotion? motion,
    ReverseBehavior<double> reverse,
    Duration delay,
  }) = _AxisSlideEffect.tweenY;

  /// {@template act.slide.keyframedY}
  /// Animates through multiple vertical slide keyframes.
  ///
  /// [frames] define multiple vertical offsets (as fractions) at different times.
  ///
  /// ## Vertical Keyframes
  ///
  /// ```dart
  /// SlideAct.keyframedY(
  ///   frames: Keyframes.fractional([
  ///     .key(-1.0, at: 0.0),
  ///     .key(0.0, at: 0.5),
  ///     .key(0.5, at: 1.0),
  ///   ], duration: 1000.ms),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.keyframedY({
    required Keyframes<double> frames,
    KFReverseBehavior<double> reverse,
    Duration delay,
  }) = _AxisSlideEffect.keyframedY;

  /// {@template act.slide.x}
  /// Animates horizontal sliding only (X-axis).
  ///
  /// [from] and [to] are horizontal offsets as fractions of widget width.
  /// Negative values slide left/start, positive values slide right/trailing.
  /// Vertical position remains unchanged.
  ///
  /// ## Horizontal Slide
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .slideX(from: -1.0, to: 0),  // Slide left by 100% of width
  ///   ],
  ///   motion: Spring.smooth(damping: 23),
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.x({
    double from,
    double to,
    CueMotion? motion,
    ReverseBehavior<double> reverse,
    Duration delay,
  }) = _AxisSlideEffect.tweenX;

  /// {@template act.slide.keyframedX}
  /// Animates through multiple horizontal slide keyframes.
  ///
  /// [frames] define multiple horizontal offsets (as fractions) at different times.
  ///
  /// ## Horizontal Keyframes
  ///
  /// ```dart
  /// SlideAct.keyframedX(
  ///   frames: Keyframes.fractional([
  ///     .key(-1.0, at: 0.0),
  ///     .key(0.0, at: 0.5),
  ///     .key(-0.5, at: 1.0),
  ///   ], duration: 1000.ms),
  /// )
  /// ```
  /// {@endtemplate}
  const factory SlideAct.keyframedX({
    required Keyframes<double> frames,
    KFReverseBehavior<double> reverse,
    Duration delay,
  }) = _AxisSlideEffect.keyframedX;
}

class _SlideEffect extends TweenAct<Offset> implements SlideAct {
  @override
  final ActKey key = const ActKey('Slide');

  const _SlideEffect({
    super.from = Offset.zero,
    super.to = Offset.zero,
    super.motion,
    super.reverse,
    super.delay,
  }) : super.tween();

  /// Slides up from bottom (y=100%) to center position.
  const _SlideEffect.fromBottom({
    super.motion,
    super.reverse,
    super.delay,
  }) : super.tween(
          from: const Offset(0, 1),
          to: Offset.zero,
        );

  /// Slides down from top (y=-100%) to center position.
  const _SlideEffect.fromTop({
    super.motion,
    super.reverse,
    super.delay,
  }) : super.tween(
          from: const Offset(0, -1),
          to: Offset.zero,
        );

  /// Slides from leading edge (x=-100% in LTR) to center position.
  const _SlideEffect.fromLeading({
    super.motion,
    super.reverse,
    super.delay,
  }) : super.tween(
          from: const Offset(-1, 0),
          to: Offset.zero,
        );

  /// Slides from trailing edge (x=100% in LTR) to center position.
  const _SlideEffect.fromTrailing({
    super.motion,
    super.reverse,
    super.delay,
  }) : super.tween(
          from: const Offset(1, 0),
          to: Offset.zero,
        );

  /// Animates through multiple sliding keyframes.
  const _SlideEffect.keyframed({
    required super.frames,
    super.reverse,
    super.delay,
  }) : super.keyframed(from: Offset.zero);

  @override
  Widget apply(BuildContext context, Animation<Offset> animation, Widget child) {
    return SlideTransition(position: animation, child: child);
  }
}

class _AxisSlideEffect extends TweenActBase<double, Offset> implements SlideAct {
  @override
  final ActKey key = const ActKey('Slide');

  /// Axis of single-axis sliding (horizontal or vertical).
  final Axis _axis;

  /// Horizontal-only sliding (x-axis).
  const _AxisSlideEffect.tweenX({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    super.delay,
  })  : _axis = Axis.horizontal,
        super.tween();

  /// Vertical-only sliding (y-axis).
  const _AxisSlideEffect.tweenY({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    super.delay,
  })  : _axis = Axis.vertical,
        super.tween();

  /// Horizontal keyframed sliding.
  const _AxisSlideEffect.keyframedX({
    required super.frames,
    super.reverse,
    super.delay,
  })  : _axis = Axis.horizontal,
        super.keyframed(from: 0);

  /// Vertical keyframed sliding.
  const _AxisSlideEffect.keyframedY({
    required super.frames,
    super.reverse,
    super.delay,
  })  : _axis = Axis.vertical,
        super.keyframed(from: 0);

  @override
  Offset transform(_, double value) {
    switch (_axis) {
      case Axis.horizontal:
        return Offset(value, 0);
      case Axis.vertical:
        return Offset(0, value);
    }
  }

  @override
  Widget apply(BuildContext context, Animation<Offset> animation, Widget child) {
    return SlideTransition(position: animation, child: child);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AxisSlideEffect && super == other && other._axis == _axis;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, _axis);
}
