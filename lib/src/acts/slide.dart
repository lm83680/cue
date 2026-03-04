part of 'base/act.dart';

abstract class SlideAct extends Act {
  const factory SlideAct({
    Offset from,
    Offset to,
    Curve? curve,
    Timing? timing,
  }) = _SlideEffect;

  const factory SlideAct.up({
    Curve? curve,
    Timing? timing,
  }) = _SlideEffect.fromBottom;

  const factory SlideAct.down({
    Curve? curve,
    Timing? timing,
  }) = _SlideEffect.fromTop;

  const factory SlideAct.fromLeading({
    Curve? curve,
    Timing? timing,
  }) = _SlideEffect.fromLeading;

  const factory SlideAct.fromTrailing({
    Curve? curve,
    Timing? timing,
  }) = _SlideEffect.fromTrailing;

  const factory SlideAct.keyframes(
    List<Keyframe<Offset>> keyframes, {
    Curve? curve,
  }) = _SlideEffect.keyframes;

  const factory SlideAct.fromY({
    double from,
    double to,
    Curve? curve,
    Timing? timing,
  }) = _AxisSlideEffect.tweenY;

  const factory SlideAct.keyframesY(
    List<Keyframe<double>> keyframes, {
    Curve? curve,
  }) = _AxisSlideEffect.keyframesY;

  const factory SlideAct.fromX({
    double from,
    double to,
    Curve? curve,
    Timing? timing,
  }) = _AxisSlideEffect.tweenX;

  const factory SlideAct.keyframesX(
    List<Keyframe<double>> keyframes, {
    Curve? curve,
  }) = _AxisSlideEffect.keyframesX;
}

class _SlideEffect extends TweenAct<Offset> implements SlideAct {
  const _SlideEffect({
    super.from = Offset.zero,
    super.to = Offset.zero,
    super.curve,
    super.timing,
  });

  const _SlideEffect.fromBottom({
    super.curve,
    super.timing,
  }) : super(
         from: const Offset(0, 1),
         to: Offset.zero,
       );

  const _SlideEffect.fromTop({
    super.curve,
    super.timing,
  }) : super(
         from: const Offset(0, -1),
         to: Offset.zero,
       );

  const _SlideEffect.fromLeading({
    super.curve,
    super.timing,
  }) : super(
         from: const Offset(-1, 0),
         to: Offset.zero,
       );

  const _SlideEffect.fromTrailing({
    super.curve,
    super.timing,
  }) : super(
         from: const Offset(1, 0),
         to: Offset.zero,
       );

  const _SlideEffect.keyframes(
    super.keyframes, {
    super.curve,
  }) : super.keyframes();

  @override
  Widget apply(BuildContext context, Animation<Offset> animation, Widget child) {
    return SlideTransition(position: animation, child: child);
  }
}

class _AxisSlideEffect extends TweenActBase<double, Offset> implements SlideAct {
  final Axis _axis;

  const _AxisSlideEffect.tweenX({
    super.from = 0,
    super.to = 0,
    super.curve,
    super.timing,
  }) : _axis = Axis.horizontal;

  const _AxisSlideEffect.tweenY({
    super.from = 0,
    super.to = 0,
    super.curve,
    super.timing,
  }) : _axis = Axis.vertical;

  const _AxisSlideEffect.keyframesX(
    super.keyframes, {
    super.curve,
  }) : _axis = Axis.horizontal,
       super.keyframes();

  const _AxisSlideEffect.keyframesY(
    super.keyframes, {
    super.curve,
  }) : _axis = Axis.vertical,
       super.keyframes();

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
}
