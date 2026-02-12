part of 'act.dart';

abstract class ResizeAct extends Act {
  const factory ResizeAct({
    required Size from,
    required Size to,
    Curve? curve,
    Timing? timing,
    AlignmentGeometry? alignment,
  }) = _Resize;

  const factory ResizeAct.keyframes(
    List<Keyframe<Size?>> keyframes, {
    Curve? curve,
    AlignmentGeometry? alignment,
  }) = _Resize.keyframes;

  const factory ResizeAct.fractional({
    Size from,
    Size to,
    Curve? curve,
    Timing? timing,
    AlignmentGeometry alignment,
  }) = FractionalResizeAct;
}

class _Resize extends TweenAct<Size?> implements ResizeAct {
  final AlignmentGeometry? alignment;

  const _Resize({
    super.from,
    super.to,
    super.curve,
    super.timing,
    this.alignment,
  });

  const _Resize.keyframes(
    super.keyframes, {
    super.curve,
    this.alignment,
  }) : super.keyframes();

  Tween<Size?> _buildTween(Size? begin, Size? end, Size maxSize) {
    double normalize(double? value, double max) {
      if (value == null) return 0;
      if (value.isInfinite) return max;
      return value;
    }

    final effectiveBeginWidth = normalize(begin?.width, maxSize.width);
    final effectiveBeginHeight = normalize(begin?.height, maxSize.height);
    final effectiveEndWidth = normalize(end?.width, maxSize.width);
    final effectiveEndHeight = normalize(end?.height, maxSize.height);
    return SizeTween(
      begin: Size(effectiveBeginWidth, effectiveBeginHeight),
      end: Size(effectiveEndWidth, effectiveEndHeight),
    );
  }

  Size? get _biggestTargetSize {
    if (_from == null) return _to;
    if (_to == null) return _from;
    return Size(
      math.max(_from.width, _to.width),
      math.max(_from.height, _to.height),
    );
  }

  @override
  Widget apply(AnimationContext context, Widget child) {
    return LayoutBuilder(
      builder: (_, constrains) {
        final animation = build(
          context,
          tweenBuilder: (begin, end) {
            return _buildTween(begin, end, constrains.biggest);
          },
        );
        final builder = LayoutInfoScope(
          size: _biggestTargetSize,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return SizedBox(
                width: animation.value?.width,
                height: animation.value?.height,
                child: child,
              );
            },
            child: child,
          ),
        );
        if (alignment case final alignment?) {
          return Align(
            alignment: alignment,
            widthFactor: context.driver.value,
            child: builder,
          );
        }
        return builder;
      },
    );
  }
}

class FractionalResizeAct extends TweenAct<Size> implements ResizeAct {
  const FractionalResizeAct({
    super.from = Size.zero,
    super.to = Size.zero,
    super.curve,
    super.timing,
    this.alignment = Alignment.center,
  });

  const FractionalResizeAct.keyframes(
    super.keyframes, {
    super.curve,
    this.alignment = Alignment.center,
  }) : super.keyframes();

  final AlignmentGeometry alignment;

  @override
  Widget apply(AnimationContext context, Widget child) {
    final animation = build(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return FractionallySizedBox(
          widthFactor: animation.value.width,
          heightFactor: animation.value.width,
          alignment: alignment,
          child: child,
        );
      },
    );
  }
}
