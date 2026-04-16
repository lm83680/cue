part of 'base/act.dart';

/// Animates widget positioning within a Stack.
///
/// Animates edge offsets (top, start, end, bottom) and/or dimensions (width, height)
/// of a widget inside a [Stack]. Useful for sliding panels, expandable cards,
/// or repositioning widgets within fixed container bounds.
///
/// Requires the widget to be placed inside a [Stack]. Use the [Position] data
/// class to specify which edges to animate.
///
/// Prefer using [PositionedActor] instead of manually applying a [PositionAct] for convenience.
/// it reads naturally inside a Stack and reduces boilerplate.
class PositionAct extends TweenAct<Position> {
  @override
  final ActKey key = const ActKey('Position');

  /// Optional size for relative positioning.
  ///
  /// When set, position values are treated as fractions (0 to 1) relative to
  /// this size. Useful for responsive layouts that scale with container size.
  final Size? _relativeTo;

  /// {@template act.position}
  /// Animates widget positioning within a Stack.
  ///
  /// [from] and [to] define the starting and ending [Position] values.
  /// Both must have at most one horizontal constraint (start or end, not both).
  /// Both must have at most one vertical constraint (top or bottom, not both).
  ///
  /// Size values (width, height) can be animated independently.
  /// By default, reverse uses [ReverseBehavior.mirror].
  ///
  /// ## Basic absolute positioning
  ///
  /// ```dart
  /// Stack(
  ///   children: [
  ///     Actor(
  ///       acts: [
  ///         PositionAct(
  ///           from: Position(top: 0, start: 0),
  ///           to: Position(top: 100, start: 50),
  ///         ),
  ///       ],
  ///       child: MyWidget(),
  ///     ),
  ///   ],
  /// )
  /// ```
  ///
  /// ## Expanding from corner
  ///
  /// ```dart
  /// PositionAct(
  ///   from: .topStart(top: 0, start: 0),
  ///   to: Position(
  ///     top: 0,
  ///     start: 0,
  ///     width: 200,
  ///     height: 150,
  ///   ),
  /// )
  /// ```
  ///
  /// ## Relative positioning (fraction of container)
  ///
  /// ```dart
  /// PositionAct.relative(
  ///   from: Position(top: 0, start: 0),
  ///   to: Position(top: 0.5, start: 0.5),
  ///   size: containerSize,
  /// )
  /// ```
  /// {@endtemplate}
  const PositionAct({
    required super.from,
    required super.to,
    super.motion,
    super.reverse,
    super.delay,
  })  : _relativeTo = null,
        super.tween();

  /// {@template act.position.relative}
  /// Animates positioning using fractional values (0 to 1).
  ///
  /// Position values are multiplied by [size] to compute actual pixels.
  /// Useful for responsive animations that scale with container dimensions.
  /// {@endtemplate}
  const PositionAct.relative({
    required super.from,
    required super.to,
    required Size size,
    super.motion,
    super.reverse,
    super.delay,
  })  : _relativeTo = size,
        super.tween();

  @internal

  /// Internal constructor for keyframed animations with optional relative sizing.
  const PositionAct.internal({
    required super.from,
    required super.to,
    super.motion,
    super.reverse,
    Size? relativeTo,
    super.frames,
    super.delay,
  }) : _relativeTo = relativeTo;

  /// {@template act.position.keyframed}
  /// Animates through multiple position keyframes.
  ///
  /// [frames] define multiple [Position] targets at different times.
  /// [relativeTo] applies fractional scaling if set.
  ///
  /// ## Fractional keyframes with shared duration
  ///
  /// ```dart
  /// PositionAct.keyframed(
  ///   frames: Keyframes.fractional([
  ///     .key(Position(top: 0, start: 0), at: 0.0),
  ///     .key(Position(top: 50, start: 30), at: 0.5),
  ///     .key(Position(top: 100, start: 100), at: 1.0),
  ///   ], duration: 500.ms),
  /// )
  /// ```
  ///
  /// ## Per-keyframe motion with override
  ///
  /// ```dart
  /// PositionAct.keyframed(
  ///   frames: Keyframes(
  ///     [
  ///       .key(Position(top: 0, start: 0)),  // Uses default motion
  ///       .key(Position(top: 50, start: 30), motion: Spring.bouncy()),  // Overrides
  ///       .key(Position(top: 100, start: 100), motion: Linear(300.ms)),  // Overrides
  ///     ],
  ///     motion: Spring.smooth(),  // Default motion
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  const PositionAct.keyframed({
    required super.frames,
    super.reverse,
    super.delay,
    Size? relativeTo,
  })  : _relativeTo = relativeTo,
        super.keyframed();

  @override
  Animatable<Position> createSingleTween(Position from, Position to) {
    return _PositionTween(begin: from, end: to);
  }

  @override
  Widget apply(BuildContext context, Animation<Position> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final pos = _relativeTo == null ? animation.value : animation.value._relative(_relativeTo);
        return Positioned.directional(
          textDirection: Directionality.of(context),
          top: pos.top,
          start: pos.start,
          end: pos.end,
          bottom: pos.bottom,
          width: pos.width,
          height: pos.height,
          child: child!,
        );
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is PositionAct && super == other && other._relativeTo == _relativeTo;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, _relativeTo);
}

/// Represents edge and size constraints for positioned widgets in a Stack.
///
/// Specifies up to 6 positional properties:
/// - **Horizontal**: [start] (left in LTR, right in RTL) or [end] (right in LTR, left in RTL)
/// - **Vertical**: [top] or [bottom]
/// - **Size**: [width] and/or [height]
///
/// Constraints:
/// - Cannot specify both [start] and [end]
/// - Cannot specify both [top] and [bottom]
/// - Cannot specify [width] with both [start] and [end]
/// - Cannot specify [height] with both [top] and [bottom]
///
/// Use factory constructors for common patterns: [Position.fill], [Position.topStart], etc.
class Position {
  /// Distance from the top edge, in pixels or fractions (0–1).
  final double? top;

  /// Distance from the starting edge (left in LTR, right in RTL), in pixels or fractions.
  final double? start;

  /// Distance from the ending edge (right in LTR, left in RTL), in pixels or fractions.
  final double? end;

  /// Distance from the bottom edge, in pixels or fractions (0–1).
  final double? bottom;

  /// Width of the positioned widget, in pixels or fractions (0–1).
  final double? width;

  /// Height of the positioned widget, in pixels or fractions (0–1).
  final double? height;

  /// Creates a position with optional edge and size constraints.
  ///
  /// At most one of [start] or [end] can be set (horizontal position).
  /// At most one of [top] or [bottom] can be set (vertical position).
  const Position({
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
  })  : assert(start == null || end == null || width == null),
        assert(top == null || bottom == null || height == null);

  /// {@template position.fill}
  /// Fills the entire stack with all edges at the given distance.
  ///
  /// By default, sets start, top, end, and bottom to 0 (fills entire stack).
  /// {@endtemplate}
  const Position.fill({
    this.start = 0,
    this.top = 0,
    this.end = 0,
    this.bottom = 0,
  })  : width = null,
        height = null;

  /// Creates a position from STEB values (start, top, end, bottom).
  const Position.fromSTEB(this.start, this.top, this.end, this.bottom)
      : width = null,
        height = null;

  /// {@template position.top_start}
  /// Positions from the top-start corner.
  ///
  /// Useful for fixed corners like top-left.
  /// {@endtemplate}
  const Position.topStart({
    double top = 0,
    double start = 0,
  }) : this(top: top, start: start);

  /// {@template position.top_end}
  /// Positions from the top-end corner.
  ///
  /// Opposite horizontal direction, useful for RTL layouts.
  /// {@endtemplate}
  const Position.topEnd({
    double top = 0,
    double end = 0,
  }) : this(top: top, end: end);

  /// {@template position.bottom_start}
  /// Positions from the bottom-start corner.
  ///
  /// Useful for bottom-aligned elements.
  /// {@endtemplate}
  const Position.bottomStart({
    double bottom = 0,
    double start = 0,
  }) : this(bottom: bottom, start: start);

  /// {@template position.bottom_end}
  /// Positions from the bottom-end corner.
  ///
  /// Useful for bottom-right alignment in LTR layouts.
  /// {@endtemplate}
  const Position.bottomEnd({
    double bottom = 0,
    double end = 0,
  }) : this(bottom: bottom, end: end);

  Position _relative(Size size) {
    return Position(
      top: top != null ? top! * size.height : null,
      start: start != null ? start! * size.width : null,
      end: end != null ? end! * size.width : null,
      bottom: bottom != null ? bottom! * size.height : null,
      width: width != null ? width! * size.width : null,
      height: height != null ? height! * size.height : null,
    );
  }

  /// Linearly interpolates between two Position objects.
  ///
  /// Returns a new Position with properties interpolated at [t] (0 to 1).
  /// Null values are treated as 0 for interpolation purposes.
  static Position lerp(Position a, Position b, double t) {
    return Position(
      top: _lerpNullable(a.top, b.top, t),
      start: _lerpNullable(a.start, b.start, t),
      end: _lerpNullable(a.end, b.end, t),
      bottom: _lerpNullable(a.bottom, b.bottom, t),
      width: _lerpNullable(a.width, b.width, t),
      height: _lerpNullable(a.height, b.height, t),
    );
  }

  static double? _lerpNullable(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0) + ((b ?? 0) - (a ?? 0)) * t;
  }
}

/// Internal tween that interpolates between two Position objects.
///
/// Used internally by PositionAct to animate position values over time.
class _PositionTween extends Tween<Position> {
  /// Creates a tween from start [begin] to end [end] position.
  _PositionTween({required super.begin, required super.end});

  @override
  Position lerp(double t) => Position.lerp(begin!, end!, t);
}

/// Convenience widget for position animations.
///
/// Pre-composes an [Actor] with a [PositionAct], eliminating boilerplate.
/// The widget must be placed inside a [Stack].
///
/// Use [PositionedActor.keyframed] for multi-keyframe animations.
class PositionedActor extends SingleActorBase<Position> {
  /// Optional size for relative positioning (fractional values).
  final Size? _relativeTo;

  /// {@template actor.position}
  /// Creates a positioned animation widget.
  ///
  /// [from] and [to] define start and end [Position] values.
  /// Must be placed inside a [Stack].
  ///
  /// ## Slide from corner
  ///
  /// ```dart
  /// Stack(
  ///   children: [
  ///     PositionedActor(
  ///       from: Position.topStart(top: -200),
  ///       to: Position.topStart(top: 0),
  ///       child: MyPanel(),
  ///     ),
  ///   ],
  /// )
  /// ```
  ///
  /// ## Relative positioning
  ///
  /// ```dart
  /// PositionedActor.relative(
  ///   from: Position(top: 0, start: 0),
  ///   to: Position(top: 0.5, start: 0.5),
  ///   size: stackSize,
  ///   child: MyWidget(),
  /// )
  /// ```
  /// {@endtemplate}
  const PositionedActor({
    super.key,
    required super.from,
    required super.to,
    required super.child,
    super.motion,
    super.reverseMotion,
    super.delay,
    super.reverseDelay,
    super.reverse,
  }) : _relativeTo = null;

  /// {@template actor.position.keyframed}
  /// Creates a position animation with multiple keyframes.
  /// {@endtemplate}
  const PositionedActor.keyframed({
    super.key,
    required super.frames,
    required super.child,
    super.reverse,
    Size? relativeTo,
  })  : _relativeTo = relativeTo,
        super.keyframes();

  /// {@template actor.position.relative}
  /// Creates a position animation using fractional values.
  ///
  /// Position values are multiplied by [size] to compute pixels.
  /// {@endtemplate}
  const PositionedActor.relative({
    super.key,
    required super.from,
    required super.to,
    required Size size,
    required super.child,
    super.motion,
    super.reverseMotion,
    super.delay,
    super.reverseDelay,
  }) : _relativeTo = size;

  @override
  Act get act => PositionAct.internal(
        from: from,
        to: to,
        delay: delay,
        frames: frames,
        relativeTo: _relativeTo,
        motion: motion,
        reverse: reverse,
      );
}
