part of 'base/act.dart';

/// Animates widget rotation using transforms.
///
/// Applies a paint-based rotation around a specified [axis] and [alignment].
/// Only the visual rendering rotates (cheaper and sufficient for most cases).
/// The widget's layout and hit tests remain unchanged.
///
/// For single-axis rotation, this is the preferred choice over [RotateLayoutAct]
/// which recalculates layout. Use [Rotate3DAct] for simultaneous x, y, z rotations.
class RotateAct extends TweenAct<double> {
  @override
  final ActKey key = const ActKey('Rotate');

  /// The pivot point for rotation.
  ///
  /// Defaults to [Alignment.center] (rotate around center).
  /// Change to [Alignment.topLeft], [Alignment.topRight], etc. for different pivots.
  final AlignmentGeometry alignment;

  /// The unit for rotation values: degrees, quarter-turns, or radians.
  ///
  /// Defaults to [RotateUnit.degrees]. Use [RotateUnit.quarterTurns] for
  /// simple 90° increments or [RotateUnit.radians] for mathematical calculations.
  final RotateUnit unit;

  /// The axis of rotation: x (flip horizontally), y (flip vertically), or z (2D rotate).
  ///
  /// Defaults to [RotateAxis.z] (2D rotation in the plane).
  /// [RotateAxis.x] and [RotateAxis.y] enable 3D flip effects (180° rotations).
  ///
  /// For complex 3D rotations on multiple axes, use [Rotate3DAct] instead.
  final RotateAxis axis;

  /// {@template act.rotate}
  /// Animates rotation around a single axis (2D paint-based rotation).
  ///
  /// Prefer using the factory method: `Act.rotate()` with named parameters.
  /// Pass `unit` to specify degrees, radians, or quarter-turns.
  ///
  /// [from] and [to] define start and end rotation values.
  /// [unit] controls value interpretation: degrees (0-360), quarter-turns (0-4),
  /// or radians (0-2π). Defaults to [RotateUnit.degrees].
  /// [axis] controls which axis to rotate: x (flip X), y (flip Y), or z (2D rotate).
  /// [alignment] sets the rotation pivot point.
  ///
  /// Default reverse uses [ReverseBehavior.mirror].
  ///
  /// ## 2D rotation (full spin)
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .rotate(to: 360),
  ///   ],
  ///   child: MyIcon(),
  /// )
  /// ```
  ///
  /// ## Rotate around corner in radians
  ///
  /// ```dart
  /// .rotate(
  ///   from: 0,
  ///   to: math.pi / 4,
  ///   unit: .radians,
  ///   alignment: Alignment.topLeft,
  /// )
  /// ```
  ///
  /// ## For 3D flips with depth effect
  ///
  /// Use [Rotate3DAct] for visual flips (card flips with perspective):
  ///
  /// ```dart
  ///  Rotate3DAct.flipX()
  ///  Rotate3DAct.flipY()
  /// // shorthands:
  /// .flipX()
  /// .flipY()
  /// ```
  /// {@endtemplate}
  const RotateAct({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    this.axis = RotateAxis.z,
    this.alignment = Alignment.center,
    this.unit = RotateUnit.degrees,
    super.delay,
  }) : super.tween();

  /// {@template act.rotate.keyframed}
  /// Rotates through multiple keyframes.
  ///
  /// [frames] define multiple rotation targets at different times.
  /// Defaults to degrees. Use `unit: RotateUnit.radians` to specify radians.
  ///
  /// ## Fractional keyframes with shared duration
  ///
  /// ```dart
  /// RotateAct.keyframed(
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
  /// RotateAct.keyframed(
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
  const RotateAct.keyframed({
    required super.frames,
    super.reverse,
    super.delay,
    this.alignment = Alignment.center,
    this.axis = RotateAxis.z,
    this.unit = RotateUnit.radians,
  }) : super.keyframed(from: 0);

  /// {@template act.rotate.radians}
  /// Rotates in radians (0–2π).
  ///
  /// Default unit for keyframed animations. Full rotation = 2π radians.
  /// Prefer `.rotate.degrees()` for more intuitive angles.
  /// {@endtemplate}
  const RotateAct.radians({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    this.axis = RotateAxis.z,
    this.alignment = Alignment.center,
    super.delay,
  })  : unit = RotateUnit.radians,
        super.tween();

  /// {@template act.rotate.degrees}
  /// Rotates in degrees (0–360).
  ///
  /// Convenient and intuitive for common rotations like 90°, 180°, 360°.
  /// Prefer this over radians for better readability.
  /// {@endtemplate}
  const RotateAct.degrees({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    super.delay,
    this.alignment = Alignment.center,
    this.axis = RotateAxis.z,
  })  : unit = RotateUnit.degrees,
        super.tween();

  /// {@template act.rotate.turns}
  /// Rotates in quarter-turns (0–4).
  ///
  /// 1 turn = 90°, 2 turns = 180°, etc.
  /// Useful for simple 90° increments.
  /// {@endtemplate}
  const RotateAct.turns({
    super.from = 0,
    super.to = 0,
    super.motion,
    super.reverse,
    super.delay,
    this.axis = RotateAxis.z,
    this.alignment = Alignment.center,
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
    return MatrixTransition(
      animation: animation,
      alignment: alignment.resolve(Directionality.maybeOf(context)),
      onTransform: switch (axis) {
        RotateAxis.x => Matrix4.rotationX,
        RotateAxis.y => Matrix4.rotationY,
        RotateAxis.z => Matrix4.rotationZ,
      },
      child: child,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is RotateAct &&
          super == other &&
          alignment == other.alignment &&
          unit == other.unit &&
          axis == other.axis;

  @override
  int get hashCode => Object.hash(super.hashCode, alignment, unit, axis);
}

/// Animates 3D rotation around multiple axes simultaneously.
///
/// Rotates around x, y, and z axes at the same time. [perspective] controls
/// the 3D depth effect (smaller = more dramatic 3D appearance).
///
/// Use [RotateAct] for single-axis rotations (simpler and cheaper).
/// Use [Rotate3DAct] when you need complex rotations like card flips with
/// depth effects or isometric transformations.
///
/// Convenience methods:
/// - [Rotate3DAct.flipX] — 180° horizontal flip with depth
/// - [Rotate3DAct.flipY] — 180° vertical flip with depth
class Rotate3DAct extends TweenAct<Rotation3D> {
  @override
  final ActKey key = const ActKey('Rotate3D');

  /// The pivot point for 3D rotation.
  ///
  /// Defaults to [Alignment.center] (rotate around center).
  /// Controls which point of the widget remains fixed during rotation.
  final AlignmentGeometry alignment;

  /// The perspective factor for 3D depth.
  ///
  /// Controls the vanishing point distance. Smaller values (e.g., 0.001)
  /// create more dramatic 3D effects. Larger values make the effect more subtle.
  ///
  /// Typical range: 0.001 to 0.01. Defaults to 0.001 (pronounced 3D).
  final double perspective;

  /// The unit for rotation values: degrees or radians.
  ///
  /// Defaults to [Rotate3DUnit.degrees]. Use [Rotate3DUnit.radians] for
  /// mathematical calculations.
  final Rotate3DUnit unit;

  /// {@template act.rotate3d}
  /// Animates 3D rotation around multiple axes.
  ///
  /// Use the factory method: `Act.rotate3D()` with [Rotation3D] values.
  /// [perspective] controls 3D depth effect (smaller = more dramatic).
  /// [alignment] sets the rotation pivot point.
  /// [unit] controls value interpretation: degrees or radians.
  ///
  /// Default reverse uses [ReverseBehavior.mirror].
  ///
  /// ## Card flip with depth
  ///
  /// ```dart
  /// Act.rotate3D(
  ///   to: Rotation3D(y: 180),
  ///   perspective: 0.005,
  /// )
  /// ```
  ///
  /// ## Isometric rotation
  ///
  /// ```dart
  /// .rotate3D(
  ///   to: Rotation3D(x: 45, y: 45, z: 45),
  ///   perspective: 0.003,
  /// )
  /// ```
  ///
  /// ## Spinning cube effect
  ///
  /// ```dart
  /// Rotate3DAct.keyframed(
  ///   frames: Keyframes.fractional([
  ///     .key(Rotation3D.zero, at: 0.0),
  ///     .key(Rotation3D(y: 360), at: 1.0),
  ///   ], duration: 1000.ms),
  /// )
  /// ```
  /// {@endtemplate}
  const Rotate3DAct({
    super.from = Rotation3D.zero,
    super.to = Rotation3D.zero,
    this.alignment = Alignment.center,
    this.perspective = 0.001,
    super.motion,
    super.reverse,
    super.delay,
    this.unit = Rotate3DUnit.degrees,
  }) : super.tween();

  /// {@template act.rotate3d.flipX}
  /// Animates a 180° horizontal flip with depth (3D flip effect).
  ///
  /// True 3D flip around the X-axis with perspective effect.
  /// Rotates around Y-axis by 180° to create a card-flip appearance.
  /// Convenience for: `Act.rotate3D(to: Rotation3D(y: 180))`.
  ///
  /// [perspective] controls depth effect (smaller = more dramatic).
  ///
  /// ```dart
  /// .flipX(perspective: 0.005)
  /// ```
  /// {@endtemplate}
  const Rotate3DAct.flipX({
    super.motion,
    super.reverse,
    this.alignment = Alignment.center,
    this.perspective = 0.001,
    super.delay,
  })  : unit = Rotate3DUnit.degrees,
        super.tween(
          from: Rotation3D.zero,
          to: const Rotation3D(y: 180),
        );

  /// {@template act.rotate3d.flipY}
  /// Animates a 180° vertical flip with depth (3D flip effect).
  ///
  /// True 3D flip around the Y-axis with perspective effect.
  /// Rotates around X-axis by 180° to create a card-flip appearance.
  /// Convenience for: `Act.rotate3D(to: Rotation3D(x: 180))`.
  ///
  /// [perspective] controls depth effect (smaller = more dramatic).
  ///
  /// ```dart
  /// .flipY(perspective: 0.005)
  /// ```
  /// {@endtemplate}
  const Rotate3DAct.flipY({
    super.motion,
    super.reverse,
    this.alignment = Alignment.center,
    this.perspective = 0.001,
    super.delay,
  })  : unit = Rotate3DUnit.degrees,
        super.tween(
          from: Rotation3D.zero,
          to: const Rotation3D(x: 180),
        );

  /// {@template act.rotate3d.keyframed}
  /// Animates through multiple 3D rotation keyframes.
  ///
  /// [frames] define multiple [Rotation3D] targets at different times.
  /// Defaults to degrees. Use `unit: Rotate3DUnit.radians` for radians.
  ///
  /// ## Fractional keyframes with shared duration
  ///
  /// ```dart
  /// Rotate3DAct.keyframed(
  ///   frames: Keyframes.fractional([
  ///     .key(Rotation3D.zero, at: 0.0),
  ///     .key(Rotation3D(x: 90), at: 0.33),
  ///     .key(Rotation3D(y: 180), at: 0.67),
  ///     .key(Rotation3D(z: 360), at: 1.0),
  ///   ], duration: 2000.ms),
  /// )
  /// ```
  ///
  /// ## Per-keyframe motion with override
  ///
  /// ```dart
  /// Rotate3DAct.keyframed(
  ///   frames: Keyframes(
  ///     [
  ///       .key(Rotation3D.zero),  // Uses default motion
  ///       .key(Rotation3D(y: 180), motion: Spring.bouncy()),  // Overrides
  ///       .key(Rotation3D.zero, motion: Linear(500.ms)),  // Overrides
  ///     ],
  ///     motion: Spring.smooth(),  // Default motion
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  const Rotate3DAct.keyframed({
    required super.frames,
    super.reverse,
    super.delay,
    this.alignment = Alignment.center,
    this.perspective = 0.001,
    this.unit = Rotate3DUnit.degrees,
  }) : super.keyframed(from: Rotation3D.zero);

  @override
  Rotation3D transform(_, Rotation3D value) {
    switch (unit) {
      case Rotate3DUnit.degrees:
        return Rotation3D(
          x: value.x * math.pi / 180,
          y: value.y * math.pi / 180,
          z: value.z * math.pi / 180,
        );
      case Rotate3DUnit.radians:
        return value;
    }
  }

  @override
  Animatable<Rotation3D> createSingleTween(Rotation3D from, Rotation3D to) {
    return _Rotation3DTween(begin: from, end: to);
  }

  @override
  Widget apply(BuildContext context, Animation<Rotation3D> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, perspective)
          ..rotateX(animation.value.x)
          ..rotateY(animation.value.y)
          ..rotateZ(animation.value.z);
        return Transform(
          transform: matrix,
          alignment: alignment.resolve(Directionality.maybeOf(context)),
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is Rotate3DAct &&
          super == other &&
          alignment == other.alignment &&
          perspective == other.perspective &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(super.hashCode, alignment, perspective, unit);
}

/// Represents 3D rotation values around multiple axes.
///
/// Holds rotation angles for x (horizontal flip), y (vertical flip), and
/// z (2D rotation) axes. All values are in the unit specified by [Rotate3DAct].
///
/// Use [x], [y], [z] fields individually or create via constructor with
/// only the axes you want to rotate.
class Rotation3D {
  /// Rotation around the X-axis (horizontal flip).
  final double x;

  /// Rotation around the Y-axis (vertical flip).
  final double y;

  /// Rotation around the Z-axis (2D rotation in the plane).
  final double z;

  /// Creates a 3D rotation with x, y, and z angles.
  ///
  /// All values default to 0 (no rotation). Specify only the axes you need.
  const Rotation3D({
    this.x = 0,
    this.y = 0,
    this.z = 0,
  });

  /// Zero rotation (no rotation on any axis).
  static const zero = Rotation3D();

  @override
  String toString() => 'Rotation3D(x: $x, y: $y, z: $z)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rotation3D && runtimeType == other.runtimeType && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  /// Linearly interpolates from this rotation to [other] by [t].
  Rotation3D lerpTo(Rotation3D other, double t) {
    return Rotation3D(
      x: x + (other.x - x) * t,
      y: y + (other.y - y) * t,
      z: z + (other.z - z) * t,
    );
  }

  /// Linearly interpolates between two rotations, or returns null if both are null.
  static Rotation3D? lerp(Rotation3D? a, Rotation3D? b, double t) {
    if (a == null && b == null) return null;
    a ??= zero;
    b ??= zero;
    return a.lerpTo(b, t);
  }
}

/// Internal tween that interpolates between two 3D rotation objects.
///
/// Used internally by Rotate3DAct to animate 3D rotation values over time.
class _Rotation3DTween extends Tween<Rotation3D> {
  /// Creates a tween from start [begin] to end [end] 3D rotation.
  _Rotation3DTween({super.begin, super.end});

  @override
  Rotation3D lerp(double t) => Rotation3D.lerp(begin, end, t)!;
}

/// Axis of rotation for [RotateAct].
///
/// - [x]: Rotate around the X-axis (horizontal flip)
/// - [y]: Rotate around the Y-axis (vertical flip)
/// - [z]: Rotate around the Z-axis (2D rotation in the plane)
enum RotateAxis {
  /// Rotate around the X-axis (horizontal flip).
  x,

  /// Rotate around the Y-axis (vertical flip).
  y,

  /// Rotate around the Z-axis (2D rotation in the plane).
  z,
}

/// Unit for rotation values in [RotateAct] and [RotateLayoutAct].
///
/// - [degrees]: Degrees (0–360, full rotation = 360°)
/// - [radians]: Radians (0–2π, full rotation = 2π)
/// - [quarterTurns]: Quarter-turns (0–4, full rotation = 4)
enum RotateUnit {
  /// Degrees (0–360, full rotation = 360°).
  degrees,

  /// Radians (0–2π, full rotation = 2π).
  radians,

  /// Quarter-turns (0–4, full rotation = 4).
  quarterTurns,
}

/// Unit for 3D rotation values in [Rotate3DAct].
///
/// - [degrees]: Degrees (0–360, full rotation = 360°)
/// - [radians]: Radians (0–2π, full rotation = 2π)
enum Rotate3DUnit {
  /// Degrees (0–360, full rotation = 360°).
  degrees,

  /// Radians (0–2π, full rotation = 2π).
  radians,
}
