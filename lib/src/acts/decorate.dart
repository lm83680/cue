part of 'act.dart';

class DecorateAct extends TweenAct<Decoration> {
  const DecorateAct({
    super.from = const BoxDecoration(),
    super.to = const BoxDecoration(),
    super.curve,
    super.timing,
  });

  const DecorateAct.keyframes(
    super.keyframes, {
    super.curve,
  }) : super.keyframes();

  @override
  Widget apply(AnimationContext context, Widget child) {
    return DecoratedBoxTransition(
      decoration: build(
        context,
        tweenBuilder: (begin, end) {
          return DecorationTween(begin: begin, end: end);
        },
      ),
      child: child,
    );
  }
}

class ColorAct extends TweenAct<Color> {
  const ColorAct({
    required super.from,
    required super.to,
    super.curve,
    super.timing,
  });

  const ColorAct.keyframes(super.keyframes, {super.curve}) : super.keyframes();

  @override
  Widget apply(AnimationContext context, Widget child) {
    final animation = build(
      context,
      tweenBuilder: (from, end) {
        return ColorTween(begin: from, end: end) as Animatable<Color>;
      },
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ColoredBox(
          color: animation.value,
          child: child!,
        );
      },
      child: child,
    );
  }
}
