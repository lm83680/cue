part of 'base/act.dart';

/// Rotates the widget's layout during animation.
///
/// Essentially an animated [RotatedBox], recalculating layout constraints and
/// bounding box as the widget rotates. The layout changes affect sibling positioning.
///
/// **Note**: For most animations, prefer [RotateAct] (transform-based) instead.
/// [RotateAct] only transforms the paint (visually rotating without changing layout),
/// which is cheaper and sufficient when you don't need the layout itself to rotate.
///
/// Use [RotateLayoutAct] only when you need the actual layout to rotate.
class RotateLayoutAct extends TweenAct<double> {
  @override
  final ActKey key = const ActKey('RotateLayout');

  /// The unit for rotation values: degrees, quarter-turns, or radians.
  ///
  /// Defaults to [RotateUnit.degrees]. Use [RotateUnit.quarterTurns] for
  /// simple 90° increments or [RotateUnit.radians] for mathematical calculations.
  final RotateUnit unit;

  /// {@template act.rotate_layout}
  /// Rotates the widget's layout constraints.
  ///
  /// [from] and [to] define start and end rotation values.
  /// [unit] controls the value interpretation: degrees (0-360), quarter-turns (0-4),
  /// or radians (0-2π).
  ///
  /// Default reverse uses [ReverseBehavior.mirror].
  ///
  /// ## Basic 180° rotation
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     RotateLayoutAct.degrees(
  ///       from: 0,
  ///       to: 180,
  ///     ),
  ///     // using shorthands:
  ///     .rotateLayout(to: 180, unit: .degrees)
  ///   ],
  ///   child: MyWidget(),
  /// )
  /// ```
  ///
  /// ## Quarter-turn rotation (90°)
  ///
  /// ```dart
  /// RotateLayoutAct.turns(
  ///   from: 0,
  ///   to: 1,  // 1 quarter-turn = 90°
  /// )
  /// // shorthand:
  /// .rotateLayout(to: 1, unit: .quarterTurns)
  /// ```
  ///
  /// ## Prefer RotateAct for visual-only rotation
  ///
  /// If you only need to visually rotate without changing layout:
  ///
  /// ```dart
  /// //  Cheaper: only transforms the paint
  /// RotateAct(from: 0, to: 180)
  ///
  /// //  More expensive: recalculates layout each frame
  /// RotateLayoutAct.degrees(from: 0, to: 180)
  /// ```
  /// {@endtemplate}
  const RotateLayoutAct({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    this.unit = RotateUnit.degrees,
    super.delay,
  }) : super.tween();

  /// {@template act.rotate_layout.keyframed}
  /// Rotates through multiple keyframes with layout recalculation.
  ///
  /// Each keyframe updates layout constraints as rotation progresses.
  /// By default, values are in degrees.
  ///
  /// ## Fractional keyframes with shared duration
  ///
  /// ```dart
  /// RotateLayoutAct.keyframed(
  ///   frames: Keyframes.fractional([
  ///     .key(0, at: 0.0),
  ///     .key(90, at: 0.5),
  ///     .key(180, at: 1.0),
  ///   ], duration: 600.ms),
  /// )
  /// ```
  ///
  /// ## Per-keyframe motion with override
  ///
  /// ```dart
  /// RotateLayoutAct.keyframed(
  ///   frames: Keyframes(
  ///     [
  ///       .key(0),  // Uses default motion
  ///       .key(90, motion: Spring.bouncy()),  // Overrides default
  ///       .key(180, motion: Linear(300.ms)),  // Overrides default
  ///     ],
  ///     motion: Spring.smooth(),  // Default motion
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  const RotateLayoutAct.keyframed({
    required super.frames,
    super.reverse,
    super.delay,
    this.unit = RotateUnit.radians,
  }) : super.keyframed(from: 0);

  /// {@template act.rotate_layout.degrees}
  /// Rotates in degrees (0–360).
  ///
  /// Convenient for common rotations like 90°, 180°, or 360°.
  /// {@endtemplate}
  const RotateLayoutAct.degrees({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    super.delay,
  })  : unit = RotateUnit.degrees,
        super.tween();

  /// {@template act.rotate_layout.turns}
  /// Rotates in quarter-turns (0–4).
  ///
  /// 1 turn = 90°, 2 turns = 180°, etc.
  /// Useful for simple 90° increments.
  /// {@endtemplate}
  const RotateLayoutAct.turns({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.delay,
    super.reverse,
  })  : unit = RotateUnit.quarterTurns,
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
  Widget apply(BuildContext context, Animation<double> animation, Widget child) {
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

/// Internal widget for layout-based rotation animation.
///
/// Wraps the child in a custom RenderObject that recalculates layout
/// as rotation changes, ensuring siblings reflow correctly.
class _RotateLayoutTranstion extends SingleChildRenderObjectWidget {
  /// Animation driving the rotation value.
  final Animation<double> animation;

  /// Creates the layout rotation widget.
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

/// Custom render object that applies layout-based rotation.
///
/// Recalculates the bounding box as rotation changes, affecting layout flow.
/// Also computes the paint transform to center-rotate the child visual.
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
