part of 'act.dart';

abstract class TranslateAct extends Act {
  const factory TranslateAct({
    Offset from,
    Offset to,
    Curve? curve,
    Timing? timing,
  }) = _TranslateOffset;

  const factory TranslateAct.keyframes(List<Keyframe<Offset>> keyframes, {Curve? curve}) = _TranslateOffset.keyframes;

  const factory TranslateAct.x({double from, double to, Curve? curve, Timing? timing}) = _TranslateX;

  const factory TranslateAct.keyframesX(List<Keyframe<double>> keyframes, {Curve? curve}) = _TranslateX.keyframes;

  const factory TranslateAct.y({double from, double to, Curve? curve, Timing? timing}) = _TranslateY;

  const factory TranslateAct.keyframesY(List<Keyframe<double>> keyframes, {Curve? curve}) = _TranslateY.keyframes;
}

class _TranslateOffset extends TweenAct<Offset> implements TranslateAct {
  const _TranslateOffset({
    super.from = Offset.zero,
    super.to = Offset.zero,
    super.curve,
    super.timing,
  });

  const _TranslateOffset.keyframes(super.keyframes, {super.curve}) : super.keyframes();

  @override
  Widget apply(AnimationContext context, Widget child) {
    return _TranslateTransition(
      position: build(context),
      transformHitTests: true,
      offsetBuilder: (v) => v,
      child: child,
    );
  }
}

class _TranslateY extends TweenAct<double> implements TranslateAct {
  const _TranslateY({
    super.from = 0,
    super.to = 0,
    super.curve,
    super.timing,
  });

  const _TranslateY.keyframes(super.keyframes, {super.curve}) : super.keyframes();

  @override
  Widget apply(AnimationContext context, Widget child) {
    return _TranslateTransition(
      position: build(context),
      transformHitTests: true,
      offsetBuilder: (value) => Offset(0, value),
      child: child,
    );
  }
}

class _TranslateX extends TweenAct<double> implements TranslateAct {
  const _TranslateX({
    super.from = 0,
    super.to = 0,
    super.curve,
    super.timing,
  });

  const _TranslateX.keyframes(super.keyframes, {super.curve}) : super.keyframes();

  @override
  Widget apply(AnimationContext context, Widget child) {
    return _TranslateTransition(
      position: build(context),
      transformHitTests: true,
      offsetBuilder: (value) => Offset(value, 0),
      child: child,
    );
  }
}

class _TranslateTransition<T> extends AnimatedWidget {
  final Widget child;
  final Animation<T> position;
  final bool transformHitTests;
  final Offset Function(T value) offsetBuilder;

  const _TranslateTransition({
    required this.child,
    required this.position,
    this.transformHitTests = true,
    required this.offsetBuilder,
  }) : super(listenable: position);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      transformHitTests: transformHitTests,
      offset: offsetBuilder(position.value),
      child: child,
    );
  }
}
