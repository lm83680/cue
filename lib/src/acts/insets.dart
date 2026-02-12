part of 'act.dart';

class PaddingAct extends TweenAct<EdgeInsetsGeometry> {
  const PaddingAct({
    super.from = EdgeInsets.zero,
    super.to = EdgeInsets.zero,
    super.curve,
    super.timing,
  });

  const PaddingAct.keyframes(super.keyframes, {super.curve}) : super.keyframes();

  @override
  Widget apply(AnimationContext context, Widget child) {
    final animation = build(
      context,
      tweenBuilder: (from, end) {
        return EdgeInsetsGeometryTween(begin: from, end: end);
      },
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Padding(
          padding: animation.value.clamp(
            EdgeInsets.zero,
            EdgeInsetsGeometry.infinity,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
