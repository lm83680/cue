part of 'effect.dart';

class FadeEffect extends TweenEffect<double> {
  const FadeEffect({
    super.from = 0.0,
    super.to = 1.0,
    super.curve,
    super.timing,
  });

  const FadeEffect.out({super.from = 1.0, super.curve, super.timing}) : super(to: 0);

  const FadeEffect.keyframes(super.keyframes, {super.curve}) : super.keyframes();

  @internal
  const FadeEffect.internal({
    super.from,
    super.to,
    super.keyframes,
    super.curve,
    super.timing,
  }) : super.internal();

  @override
  Widget apply(BuildContext context, Animation<double> animation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class FadeActor extends SingleEffectBase<double> {
  const FadeActor({
    super.key,
    super.from = 1,
    super.to = 0,
    required super.child,
    super.role,
    super.curve,
    super.timing,
  });

  const FadeActor.keyframes({
    required super.child,
    required super.frames,
    super.key,
    super.role,
    super.curve,
  }) : super.keyframes();

  @override
  Effect get effect => FadeEffect.internal(
    from: from,
    to: to,
    keyframes: frames,
    curve: curve,
    timing: timing,
  );
}
