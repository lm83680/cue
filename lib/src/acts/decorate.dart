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
