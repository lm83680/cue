part of 'act.dart';

abstract class Style extends Act {
  const factory Style.text({
    required TextStyle from,
    required TextStyle to,
    Curve? curve,
    Timing? timing,
  }) = _TextStyleAct;

  const factory Style.iconTheme({
    required IconThemeData from,
    required IconThemeData to,
    Curve? curve,
    Timing? timing,
  }) = _IconThemeAct;
}

class _TextStyleAct extends TweenAct<TextStyle> implements Style {
  const _TextStyleAct({
    required super.from,
    required super.to,
    super.curve,
    super.timing,
  });

  @override
  Widget apply(AnimationContext context, Widget child) {
    final animation = build(
      context,
      tweenBuilder: (from, end) {
        return TextStyleTween(begin: from, end: end);
      },
    );
    return DefaultTextStyleTransition(style: animation, child: child);
  }
}

class _IconThemeAct extends TweenAct<IconThemeData> implements Style {
  const _IconThemeAct({
    required super.from,
    required super.to,
    super.curve,
    super.timing,
  });

  @override
  Widget apply(AnimationContext context, Widget child) {
    final animation = build(
      context,
      tweenBuilder: (from, end) {
        return _IconThemeDataTween(begin: from, end: end);
      },
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return IconTheme(data: animation.value, child: child!);
      },
      child: child,
    );
  }
}

class _IconThemeDataTween extends Tween<IconThemeData> {
  _IconThemeDataTween({required super.begin, required super.end});

  @override
  IconThemeData lerp(double t) {
    return IconThemeData.lerp(begin, end, t);
  }
}
