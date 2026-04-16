part of 'base/act.dart';

/// Animates clipping regions on a widget.
///
/// Provides multiple clipping strategies: expanding/contracting within a border
/// radius or circular path, or sliding clipping along horizontal/vertical axes.
/// All variants animate from a factor of 0 (fully clipped) to 1 (fully visible).
abstract class ClipAct extends Act {
  /// {@template act.clip}
  /// Animates an expanding or contracting clip path with optional border radius.
  ///
  /// Clips the child using [ClipPath] and [Align], growing from the specified
  /// alignment point outward. [borderRadius] defaults to `BorderRadius.zero`
  /// (rectangular clipping). Set [borderRadius] to null for circular clipping,
  /// or to a custom value for rounded corners. Use [useSuperellipse] for smooth
  /// super-ellipse clipping curves (optional optimization).
  ///
  /// ## Basic usage
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .clip(borderRadius: BorderRadius.circular(12)),
  ///     .clipWidth(), // fromFactor and toFactor default to 0 and 1 respectively
  ///     .clipHeight(), // fromFactor and toFactor default to 0 and 1 respectively
  ///   ],
  ///   child: MyWidget(),
  /// )
  /// ```
  ///
  /// ## Rectangular clipping
  ///
  /// ```dart
  /// .clip(
  ///   borderRadius: BorderRadius.circular(0),  // sharp corners
  /// )
  /// ```
  ///
  /// ## Circular clipping
  ///
  /// Use `.circularClip()` shorthand (or set borderRadius to null):
  ///
  /// ```dart
  /// .circularClip()
  /// ```
  /// {@endtemplate}
  const factory ClipAct({
    BorderRadiusGeometry borderRadius,
    AlignmentGeometry alignment,
    bool useSuperellipse,
    CueMotion? motion,
    Duration delay,
  }) = PathClipAct;

  /// {@template act.clip.circular}
  /// Animates a circular clip expanding from an alignment point.
  ///
  /// Shorthand for `.clip(borderRadius: null)`. Clips the child to an expanding
  /// circle from the specified [alignment] point.
  ///
  /// ## Usage
  ///
  /// ```dart
  /// .circularClip()  // expands from top-left by default
  ///
  /// .circularClip(alignment: Alignment.center)  // expands from center
  /// ```
  ///
  /// ## Keyframed circular clip
  ///
  /// ```dart
  /// .keyframed(
  ///   frames: Keyframes.fractional([
  ///     .key(0.0, at: 0.0),
  ///     .key(0.7, at: 0.5),
  ///     .key(1.0, at: 1.0),
  ///   ], duration: 400.ms),
  /// )
  /// ```
  /// {@endtemplate}
  const factory ClipAct.circular({
    AlignmentGeometry alignment,
    CueMotion? motion,
    Duration delay,
  }) = PathClipAct.circular;

  /// {@template act.clip.width}
  /// Animates a horizontal (left-to-right or right-to-left) sliding clip.
  ///
  /// Clips along the horizontal axis from [fromFactor] to [toFactor], where
  /// 0 = fully clipped (width 0) and 1 = fully visible (full width).
  ///
  /// Default [alignment] is `AlignmentDirectional.centerStart` (left-to-right).
  /// Override to change reveal direction.
  ///
  /// ## Usage
  ///
  /// ```dart
  /// .clipWidth(from: 0, to: 1)  // reveal left-to-right
  ///
  /// .clipWidth(
  ///   from: 0,
  ///   to: 1,
  ///   alignment: AlignmentDirectional.centerEnd,  // reveal right-to-left
  /// )
  /// ```
  /// {@endtemplate}
  const factory ClipAct.width({
    double fromFactor,
    double toFactor,
    AlignmentGeometry alignment,
    CueMotion? motion,
    Duration delay,
  }) = AxisClipAct.horizontal;

  /// {@template act.clip.height}
  /// Animates a vertical (top-to-bottom or bottom-to-top) sliding clip.
  ///
  /// Clips along the vertical axis from [fromFactor] to [toFactor], where
  /// 0 = fully clipped (height 0) and 1 = fully visible (full height).
  ///
  /// Default [alignment] is `AlignmentDirectional.topCenter` (top-to-bottom).
  /// Override to change reveal direction.
  ///
  /// ## Usage
  ///
  /// ```dart
  /// .clipHeight()  // reveal top-to-bottom
  ///
  /// .clipHeight(
  ///   alignment: Alignment.bottomCenter,  // reveal bottom-to-top
  /// )
  /// ```
  /// {@endtemplate}
  const factory ClipAct.height({
    double fromFactor,
    double toFactor,
    AlignmentGeometry alignment,
    CueMotion? motion,
    Duration delay,
  }) = AxisClipAct.vertical;
}

/// Animates sliding clip along a single axis (horizontal or vertical).
class AxisClipAct extends TweenAct<double> implements ClipAct {
  @override
  ActKey get key => const ActKey('Clip');

  /// The axis along which to clip (horizontal or vertical).
  final Axis _axis;

  /// The alignment point from which the clip expands.
  final AlignmentGeometry alignment;

  /// {@macro act.clip.width}
  const AxisClipAct.horizontal({
    double fromFactor = 0,
    double toFactor = 1,
    this.alignment = AlignmentDirectional.centerStart,
    super.motion,
    super.delay,
  })  : _axis = Axis.horizontal,
        super.tween(from: fromFactor, to: toFactor);

  /// {@macro act.clip.height}
  const AxisClipAct.vertical({
    double fromFactor = 0,
    double toFactor = 1,
    this.alignment = AlignmentDirectional.topCenter,
    super.motion,
    super.delay,
  })  : _axis = Axis.vertical,
        super.tween(from: fromFactor, to: toFactor);

  @override
  Widget apply(BuildContext context, Animation<double> animation, Widget child) {
    final directionality = Directionality.of(context);
    final effectiveAlignment = alignment.resolve(directionality);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: effectiveAlignment,
            widthFactor: _axis == Axis.horizontal ? animation.value.clamp(0, 1) : null,
            heightFactor: _axis == Axis.vertical ? animation.value.clamp(0, 1) : null,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        super == other &&
            other is AxisClipAct &&
            super == other &&
            _axis == other._axis &&
            alignment == other.alignment;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, _axis, alignment);
}

/// Animates clipping from an alignment point along an expanding path or circle.
class PathClipAct extends TweenAct<double> implements ClipAct {
  @override
  ActKey get key => const ActKey('Clip');

  /// The border radius for the clipping path.
  final BorderRadiusGeometry? borderRadius;

  /// The alignment point from which the clip expands.
  final AlignmentGeometry? alignment;

  /// Whether to use superellipse optimization for smoother curves.
  final bool useSuperellipse;

  /// {@macro act.clip}
  const PathClipAct({
    BorderRadiusGeometry this.borderRadius = BorderRadius.zero,
    this.alignment,
    super.motion,
    this.useSuperellipse = false,
    super.from = 0,
    super.to = 1,
    super.delay,
  }) : super.tween();

  /// {@macro act.clip.circular}
  const PathClipAct.circular({
    this.alignment,
    super.motion,
    super.from = 0,
    super.to = 1,
    super.delay,
  })  : borderRadius = null,
        useSuperellipse = false,
        super.tween();

  @override
  Widget apply(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    final directionality = Directionality.of(context);
    final effectiveAlignment = alignment?.resolve(directionality) ?? Alignment.topLeft;
    final effectiveBorderRadius = borderRadius?.resolve(directionality);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final clampedValue = animation.value.clamp(0.0, 1.0);
        return Align(
          alignment: effectiveAlignment,
          widthFactor: clampedValue,
          heightFactor: clampedValue,
          child: ClipPath(
            clipper: ExpandingPathClipper(
              progress: clampedValue,
              borderRadius: effectiveBorderRadius,
              alignment: effectiveAlignment,
              useSuperellipse: useSuperellipse,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        super == other &&
            other is PathClipAct &&
            super == other &&
            borderRadius == other.borderRadius &&
            alignment == other.alignment &&
            useSuperellipse == other.useSuperellipse;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, borderRadius, alignment, useSuperellipse);
}

/// Custom clipper that creates an expanding path clip.
class ExpandingPathClipper extends CustomClipper<Path> {
  /// The progress of the clip (0-1).
  final double progress;

  /// The border radius for the clip shape.
  final BorderRadius? borderRadius;

  /// The alignment point for the clip expansion.
  final Alignment alignment;

  /// Whether to use superellipse optimization.
  final bool useSuperellipse;

  /// Creates an ExpandingPathClipper with the given configuration.
  ExpandingPathClipper({
    required this.progress,
    this.borderRadius,
    required this.alignment,
    this.useSuperellipse = false,
  });

  @override
  Path getClip(Size size) {
    final currentWidth = size.width * progress;
    final currentHeight = size.height * progress;
    // Calculate the alignment point within the available size
    final alignmentOffset = alignment.alongSize(size);
    // Calculate the alignment point within the clipped rect
    final rectAlignmentOffset = alignment.alongSize(
      Size(currentWidth, currentHeight),
    );
    // Position the rect so its alignment point matches the size's alignment point
    final left = alignmentOffset.dx - rectAlignmentOffset.dx;
    final top = alignmentOffset.dy - rectAlignmentOffset.dy;

    final rect = Rect.fromLTWH(left, top, currentWidth, currentHeight);

    // null border radius means we want a circle
    if (borderRadius == null) {
      return Path()..addOval(rect);
    } else if (borderRadius == BorderRadius.zero) {
      // optimize for zero border radius case
      return Path()..addRect(rect);
    } else {
      if (useSuperellipse) {
        return _createSuperellipsePath(rect, borderRadius!);
      }
      return Path()..addRRect(borderRadius!.toRRect(rect));
    }
  }

  @override
  bool shouldReclip(covariant ExpandingPathClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.borderRadius != borderRadius ||
        oldClipper.alignment != alignment ||
        oldClipper.useSuperellipse != useSuperellipse;
  }
}

Path _createSuperellipsePath(Rect rect, BorderRadius borderRadius) {
  if (rect.isEmpty) {
    return Path()..addRect(rect);
  }

  final _ScaledCornerRadii radii = _scaleCornerRadii(rect, borderRadius);
  final Path path = Path()..moveTo(rect.left + radii.topLeft.x, rect.top);

  path.lineTo(rect.right - radii.topRight.x, rect.top);
  _addSuperellipseCorner(
    path,
    center: Offset(rect.right - radii.topRight.x, rect.top + radii.topRight.y),
    radius: radii.topRight,
    startAngle: -math.pi / 2,
    endAngle: 0,
  );

  path.lineTo(rect.right, rect.bottom - radii.bottomRight.y);
  _addSuperellipseCorner(
    path,
    center: Offset(rect.right - radii.bottomRight.x, rect.bottom - radii.bottomRight.y),
    radius: radii.bottomRight,
    startAngle: 0,
    endAngle: math.pi / 2,
  );

  path.lineTo(rect.left + radii.bottomLeft.x, rect.bottom);
  _addSuperellipseCorner(
    path,
    center: Offset(rect.left + radii.bottomLeft.x, rect.bottom - radii.bottomLeft.y),
    radius: radii.bottomLeft,
    startAngle: math.pi / 2,
    endAngle: math.pi,
  );

  path.lineTo(rect.left, rect.top + radii.topLeft.y);
  _addSuperellipseCorner(
    path,
    center: Offset(rect.left + radii.topLeft.x, rect.top + radii.topLeft.y),
    radius: radii.topLeft,
    startAngle: math.pi,
    endAngle: math.pi * 3 / 2,
  );

  return path..close();
}

_ScaledCornerRadii _scaleCornerRadii(Rect rect, BorderRadius borderRadius) {
  final Radius topLeft = borderRadius.topLeft;
  final Radius topRight = borderRadius.topRight;
  final Radius bottomRight = borderRadius.bottomRight;
  final Radius bottomLeft = borderRadius.bottomLeft;
  final double scale = <double>[
    _safeRadiusScale(rect.width, topLeft.x + topRight.x),
    _safeRadiusScale(rect.width, bottomLeft.x + bottomRight.x),
    _safeRadiusScale(rect.height, topLeft.y + bottomLeft.y),
    _safeRadiusScale(rect.height, topRight.y + bottomRight.y),
    1.0,
  ].reduce(math.min);

  return _ScaledCornerRadii(
    topLeft: Radius.elliptical(topLeft.x * scale, topLeft.y * scale),
    topRight: Radius.elliptical(topRight.x * scale, topRight.y * scale),
    bottomRight: Radius.elliptical(bottomRight.x * scale, bottomRight.y * scale),
    bottomLeft: Radius.elliptical(bottomLeft.x * scale, bottomLeft.y * scale),
  );
}

double _safeRadiusScale(double extent, double radiusSum) {
  if (radiusSum <= 0) {
    return 1.0;
  }
  return (extent / radiusSum).clamp(0.0, 1.0);
}

void _addSuperellipseCorner(
  Path path, {
  required Offset center,
  required Radius radius,
  required double startAngle,
  required double endAngle,
}) {
  if (radius.x <= 0 || radius.y <= 0) {
    path.lineTo(center.dx + radius.x * math.cos(endAngle), center.dy + radius.y * math.sin(endAngle));
    return;
  }

  const int segmentCount = 8;
  const double exponent = 5.0;
  final List<Offset> points = <Offset>[];
  for (int i = 0; i <= segmentCount; i += 1) {
    final double t = i / segmentCount;
    final double angle = startAngle + (endAngle - startAngle) * t;
    points.add(
      Offset(
        center.dx + radius.x * _signedPow(math.cos(angle), 2 / exponent),
        center.dy + radius.y * _signedPow(math.sin(angle), 2 / exponent),
      ),
    );
  }
  _addCatmullRomCubicPath(path, points);
}

void _addCatmullRomCubicPath(Path path, List<Offset> points) {
  if (points.length < 2) {
    return;
  }

  for (int i = 0; i < points.length - 1; i += 1) {
    final Offset p0 = i == 0 ? points[i] : points[i - 1];
    final Offset p1 = points[i];
    final Offset p2 = points[i + 1];
    final Offset p3 = i + 2 < points.length ? points[i + 2] : p2;
    final Offset control1 = p1 + (p2 - p0) / 6;
    final Offset control2 = p2 - (p3 - p1) / 6;
    path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, p2.dx, p2.dy);
  }
}

double _signedPow(double value, double exponent) {
  if (value == 0) {
    return 0;
  }
  return value.sign * math.pow(value.abs(), exponent).toDouble();
}

class _ScaledCornerRadii {
  const _ScaledCornerRadii({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final Radius topLeft;
  final Radius topRight;
  final Radius bottomRight;
  final Radius bottomLeft;
}
