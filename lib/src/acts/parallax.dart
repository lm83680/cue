part of 'base/act.dart';

/// Animates a parallax effect on child content.
///
/// Slides oversized content back and forth during animation while the parent
/// clips to its normal size. Creates a parallax illusion where content appears
/// to move more than the animation progress would suggest.
///
/// The child widget is sized to be larger than the parent container along the
/// specified [axis], allowing it to slide within the bounds. As the animation
/// progresses from 0 to 1, the child moves from one edge to the other.
class ParallaxAct extends DeferredTweenAct<Offset> {
  @override
  ActKey get key => const ActKey('Parallax');

  /// The amount of parallax slide as a fraction of parent size.
  ///
  /// Ranges from 0 (no slide) to 1+ (child oversized by that factor).
  /// At progress 0.5, the child is centered. At 0 and 1, it reaches
  /// the parallax boundaries.
  ///
  /// Must be > 0 for visible parallax effect.
  final double slide;

  /// Direction of parallax sliding.
  ///
  /// Defaults to [Axis.horizontal] (left-right motion).
  /// Set to [Axis.vertical] for up-down motion.
  ///
  /// The child widget is expanded along this axis to allow sliding.
  final Axis axis;

  final ReverseBehavior<double> _reverse;

  /// {@template act.parallax}
  /// Slides content back and forth with parallax effect.
  ///
  /// [slide] controls how much the child oversizes (0.5 = 50% larger).
  /// [axis] controls direction: [Axis.horizontal] or [Axis.vertical].
  ///
  /// The child is clipped to parent size while moving within expanded bounds.
  /// At progress 0.5, the child is centered. Default reverse uses [ReverseBehavior.mirror]
  /// to animate back from end to start.
  ///
  /// ## Basic horizontal parallax
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .parallax(slide: 0.3),
  ///   ],
  ///   child: MyImage(),
  /// )
  /// ```
  ///
  /// ## Vertical parallax
  ///
  /// ```dart
  /// Actor(
  ///   acts: [
  ///     .parallax(slide: 0.5, axis: Axis.vertical),
  ///   ],
  ///   child: ScrollableContent(),
  /// )
  /// ```
  ///
  /// ## Parallax with custom motion
  ///
  /// ```dart
  /// .parallax(
  ///   slide: 0.4,
  ///   motion: .smooth(damping: 20),
  /// )
  /// ```
  ///
  /// ## Parallax that doesn't reverse
  ///
  /// ```dart
  /// .parallax(
  ///   slide: 0.3,
  ///   reverse: .none(),
  /// )
  /// ```
  /// {@endtemplate}
  const ParallaxAct({
    super.motion,
    super.delay,
    required this.slide,
    this.axis = Axis.horizontal,
    ReverseBehavior<double> reverse = const ReverseBehavior.mirror(),
  }) : _reverse = reverse;

  @override
  ActContext resolve(ActContext context) {
    return TweenActBase.resolveMotion(
      context,
      motion: motion,
      delay: delay,
      reverse: _reverse,
    );
  }

  @override
  Widget apply(BuildContext context, covariant DeferredCueAnimation<Offset> animation, Widget child) {
    return _AnimatedParallax(
      driver: animation,
      slide: slide,
      axis: axis,
      reverse: _reverse,
      child: child,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParallaxAct &&
          super == other &&
          slide == other.slide &&
          axis == other.axis &&
          _reverse == other._reverse;

  @override
  int get hashCode => Object.hash(super.hashCode, slide, axis, _reverse);
}

class _AnimatedParallax extends SingleChildRenderObjectWidget {
  const _AnimatedParallax({
    super.child,
    required this.driver,
    required this.slide,
    required this.axis,
    required this.reverse,
  });

  final DeferredCueAnimation<Offset> driver;
  final double slide;
  final Axis axis;
  final ReverseBehavior<double> reverse;

  @override
  _ParallaxRenderTransform createRenderObject(BuildContext context) {
    return _ParallaxRenderTransform(
      driver: driver,
      slide: slide,
      axis: axis,
      reverse: reverse,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _ParallaxRenderTransform renderObject,
  ) {
    renderObject
      ..driver = driver
      ..slide = slide
      ..axis = axis
      ..reverse = reverse;
  }
}

class _ParallaxRenderTransform extends RenderProxyBox {
  _ParallaxRenderTransform({
    required DeferredCueAnimation<Offset> driver,
    required double slide,
    required Axis axis,
    required ReverseBehavior<double> reverse,
  }) : _driver = driver,
       _slide = slide,
       _axis = axis,
       _reverse = reverse;

  DeferredCueAnimation<Offset> _driver;

  set driver(DeferredCueAnimation<Offset> newDriver) {
    if (_driver == newDriver) return;
    _driver.removeListener(_onTick);
    newDriver.addListener(_onTick);
    _driver = newDriver;
    markNeedsLayout();
  }

  double _slide;

  set slide(double value) {
    if (_slide == value) return;
    _slide = value;
    _invalidateAnimationCache();
  }

  Axis _axis;

  set axis(Axis value) {
    if (_axis == value) return;
    _axis = value;
    _invalidateAnimationCache();
  }

  ReverseBehavior<double> _reverse;

  set reverse(ReverseBehavior<double> value) {
    if (_reverse == value) return;
    _reverse = value;
    _invalidateAnimationCache();
  }

  Size? _lastChildSize;
  Offset _offset = Offset.zero;

  void _invalidateAnimationCache() {
    _driver.setAnimatable(null);
    _lastChildSize = null;
    markNeedsLayout();
  }

  void _buildAnimationIfNeeded(Size childSize, BoxConstraints constraints) {
    if (_driver.hasAnimatable && _lastChildSize == childSize) return;

    final parentMain = _axis == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
    final childMain = _axis == Axis.horizontal ? childSize.width : childSize.height;

    // Avoid division by zero in pathological layouts
    if (childMain == 0) {
      _driver.setAnimatable(const ConstantAnimtable(Offset.zero));
      _lastChildSize = childSize;
      return;
    }

    // Parallax logic:
    // - Child is oversized: childMain = parentMain * (1 + |slide|)
    // - At progress 0.5: child is centered (no empty space)
    // - Slide range: [-slideDistance/2, +slideDistance/2] where slideDistance = slide * parentMain
    final slideDistance = _slide * parentMain;
    final extraSpace = childMain - parentMain;
    final startOffset = -extraSpace / 2 - slideDistance / 2;
    final endOffset = -extraSpace / 2 + slideDistance / 2;

    Offset buildOffset(double t) {
      final offset = startOffset + t * (endOffset - startOffset);
      return _axis == Axis.horizontal ? Offset(offset, 0) : Offset(0, offset);
    }

    final builder = CueTweenBuildHelper<Offset>(
      from: buildOffset(0),
      to: buildOffset(1.0),
      reverse: _reverse.mapValues(buildOffset),
      tweenBuilder: (begin, end) => Tween<Offset>(begin: begin, end: end),
    );

    final (animatable, reverseAnimatable) = builder.buildTweens(_driver.context);

    _driver.setAnimatable(
      reverseAnimatable == null
          ? animatable
          : DualAnimatable(
              forward: animatable,
              reverse: reverseAnimatable,
            ),
    );
    _lastChildSize = childSize;
  }

  void _onTick() {
    _offset = _driver.value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _driver.addListener(_onTick);
  }

  @override
  void detach() {
    _driver.removeListener(_onTick);
    super.detach();
  }

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    // Expand child constraints along slide axis to allow parallax effect
    final expandedSize = _axis == Axis.horizontal
        ? constraints.maxWidth * (1 + _slide.abs())
        : constraints.maxHeight * (1 + _slide.abs());

    final expandedConstraints = _axis == Axis.horizontal
        ? BoxConstraints(
            minWidth: expandedSize,
            maxWidth: expandedSize,
            minHeight: constraints.minHeight,
            maxHeight: constraints.maxHeight,
          )
        : BoxConstraints(
            minWidth: constraints.minWidth,
            maxWidth: constraints.maxWidth,
            minHeight: expandedSize,
            maxHeight: expandedSize,
          );

    child!.layout(expandedConstraints, parentUsesSize: true);
    size = constraints.constrain(child!.size);
    _buildAnimationIfNeeded(child!.size, constraints);
    _onTick();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset + _offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) return false;
    return child!.hitTest(result, position: position - _offset);
  }
}
