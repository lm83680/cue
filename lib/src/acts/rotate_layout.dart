part of 'base/act.dart';

class RotateLayoutAct extends TweenAct<double> {
  
  @override
  final ActKey key = const ActKey('RotateLayout');

  final RotateUnit unit;

  const RotateLayoutAct({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    this.unit = RotateUnit.degrees,
    super.delay,
  }) : super.tween();

  const RotateLayoutAct.keyframed({
    required super.frames,
    super.reverse,
    super.delay,
    this.unit = RotateUnit.radians,
  }) : super.keyframed(from: 0);

  const RotateLayoutAct.degrees({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    super.delay,
  }) : unit = RotateUnit.degrees,
       super.tween();

  const RotateLayoutAct.turns({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.delay,
    super.reverse,
  }) : unit = RotateUnit.quarterTurns,
       super.tween();

  @override
  double transform(_, double value) {
    switch (unit) {
      case RotateUnit.degrees:
        return value * math.pi / 180;
      case RotateUnit.quarterTurns:
        return value * math.pi / 2;
      case RotateUnit.radians:
        return value;
    }
  }

  @override
  Widget apply(BuildContext ctx, Animation<double> animation, Widget child) {
    return _RotateLayoutTranstion(animation: animation, child: child);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RotateLayoutAct && super == other && other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, unit);
}

class _RotateLayoutTranstion extends SingleChildRenderObjectWidget {
  final Animation<double> animation;

  const _RotateLayoutTranstion({
    required this.animation,
    required super.child,
  });

  @override
  _RenderRotateLayout createRenderObject(BuildContext context) {
    return _RenderRotateLayout(animation);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRotateLayout renderObject,
  ) {
    renderObject.animation = animation;
  }
}

class _RenderRotateLayout extends RenderProxyBox {
  Animation<double> _animation;
  double _radians;

  _RenderRotateLayout(this._animation) : _radians = _animation.value {
    _animation.addListener(_onAnimationChange);
  }

  void _onAnimationChange() {
    final value = _animation.value;
    if (_radians == value) return;
    _radians = value;
    markNeedsLayout();
  }

  Animation<double> get animation => _animation;
  set animation(Animation<double> value) {
    if (_animation == value) return;
    _animation.removeListener(_onAnimationChange);
    _animation = value;
    _radians = value.value;
    _animation.addListener(_onAnimationChange);
    markNeedsLayout();
  }

  double get radians => _radians;

  Matrix4 _paintTransform = Matrix4.identity();

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    child!.layout(constraints.loosen(), parentUsesSize: true);

    final childSize = child!.size;
    final w = childSize.width;
    final h = childSize.height;

    final c = math.cos(radians).abs();
    final s = math.sin(radians).abs();

    // Calculate rotated bounding box size
    final rotatedW = w * c + h * s;
    final rotatedH = w * s + h * c;

    size = constraints.constrain(Size(rotatedW, rotatedH));

    final center = Offset(size.width / 2, size.height / 2);
    final childCenter = Offset(childSize.width / 2, childSize.height / 2);

    _paintTransform = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(radians)
      ..translateByDouble(-childCenter.dx, -childCenter.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _paintTransform,
      (context, offset) => context.paintChild(child!, offset),
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  void detach() {
    _animation.removeListener(_onAnimationChange);
    super.detach();
  }
}
