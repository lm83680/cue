part of 'act.dart';

class AlignAct extends TweenAct<AlignmentGeometry?> {
  const AlignAct({
    super.from,
    super.to,
    super.curve,
    super.timing,
  });

  @override
  Widget apply(AnimationContext ctx, Widget child) {
    final animation = build(
      ctx,
      tweenBuilder: (from, end) {
        return AlignmentGeometryTween(begin: from, end: end);
      },
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Align(
          alignment: animation.value ?? Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}
