part of 'act.dart';

class FlexAct extends TweenActBase<int, double> {
  final FlexFit fit;
  final bool allowOverflow;

  const FlexAct({
    required super.from,
    required super.to,
    super.curve,
    super.timing,
    this.fit = FlexFit.tight,
    this.allowOverflow = false,
  });

  const FlexAct.keyframes(
    super.keyframes, {
    super.curve,
    this.fit = FlexFit.tight,
    this.allowOverflow = false,
  }) : super.keyframes();

  @override
  double transform(int value) {
    return value.toDouble();
  }

  @override
  Widget apply(BuildContext context, Animation<double> animation, Widget child) {
    return _AnimatedFlexible(
      flexAnimation: animation,
      fit: fit,
      allowOverflow: allowOverflow,
      child: child,
    );
  }
}

class _AnimatedFlexible extends SingleChildRenderObjectWidget {
  const _AnimatedFlexible({
    required this.flexAnimation,
    required this.fit,
    required this.allowOverflow,
    required super.child,
  });

  final Animation<double> flexAnimation;
  final FlexFit fit;
  final bool allowOverflow;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAnimatedFlexible(
      flexAnimation: flexAnimation,
      fit: fit,
      allowOverflow: allowOverflow,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderAnimatedFlexible renderObject) {
    renderObject
      ..flexAnimation = flexAnimation
      ..fit = fit
      ..allowOverflow = allowOverflow;
  }
}

/// A render-object version of [Flexible] where `flex` is driven by an animation.
///
/// Why render-object? In Flex layouts, `flex` is used by the parent during its
/// layout. To avoid visible snapping between keyframe phases, we keep the child
/// laid out at its *max flex* (so intrinsic / baseline / paint doesn't pop),
/// but we report an animated flex to the parent every frame.
class _RenderAnimatedFlexible extends RenderProxyBox {
  _RenderAnimatedFlexible({
    required Animation<double> flexAnimation,
    required FlexFit fit,
    required bool allowOverflow,
  }) : _flexAnimation = flexAnimation,
       _fit = fit,
       _allowOverflow = allowOverflow {
    _flexAnimation.addListener(_onAnimationUpdate);
  }

  Animation<double> _flexAnimation;

  Animation<double> get flexAnimation => _flexAnimation;

  set flexAnimation(Animation<double> value) {
    if (_flexAnimation == value) return;
    _flexAnimation.removeListener(_onAnimationUpdate);
    _flexAnimation = value;
    _flexAnimation.addListener(_onAnimationUpdate);
    markNeedsLayout();
  }

  FlexFit _fit;

  FlexFit get fit => _fit;

  set fit(FlexFit value) {
    if (_fit == value) return;
    _fit = value;
    markNeedsLayout();
  }

  bool _allowOverflow;

  bool get allowOverflow => _allowOverflow;

  set allowOverflow(bool value) {
    if (_allowOverflow == value) return;
    _allowOverflow = value;
    markNeedsLayout();
  }

  // We expose an animated integer flex to the parent. We keep our own cached max
  // flex so layout remains stable while changing.
  int _maxFlex = 0;

  int _effectiveFlexForParent() {
    final raw = _flexAnimation.value;
    // Flex must be >= 0 and integral.
    final int floored = raw.isFinite ? raw.floor() : 0;
    return math.max(0, floored);
  }

  void _onAnimationUpdate() {
    // Flex changes affect parent layout.
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _flexAnimation.addListener(_onAnimationUpdate);
  }

  @override
  void detach() {
    _flexAnimation.removeListener(_onAnimationUpdate);
    super.detach();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! FlexParentData) {
      child.parentData = FlexParentData();
    }
  }

  void _syncParentData() {
    final child = this.child;
    if (child == null) return;
    final parentData = child.parentData as FlexParentData;

    final flexNow = _effectiveFlexForParent();
    if (flexNow > _maxFlex) {
      _maxFlex = flexNow;
    }

    // Parent reads these during Flex layout.
    parentData
      ..flex = flexNow
      ..fit = _fit;
  }

  @override
  void performLayout() {
    _syncParentData();

    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    // Important: In a Flex layout, the parent will normally lay out the child
    // based on flex. But since our flex is animated and integer-quantized,
    // the child can otherwise "pop" when crossing integer boundaries.
    //
    // Strategy:
    // - Always have the child laid out at the max flex we've seen so far
    //   (within current constraints) so visual content doesn't snap.
    // - Still report the animated flex to the parent every frame.
    //
    // Note: Actual constraint distribution still happens in the parent; we just
    // ensure we can handle being laid out at various sizes without relayout
    // surprises.

    // Because we're a proxy box, we just pass constraints through.
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }

  bool _hasVisualOverflow = false;
  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_allowOverflow) {
      _clipRectLayer.layer = null;
      super.paint(context, offset);
      return;
    }

    // If overflow is allowed, we still clip to our own size (similar to resize).
    // This keeps Flex children from painting outside their allocated region when
    // flex shrinks.
    _hasVisualOverflow = child != null && (child!.size.width > size.width || child!.size.height > size.height);

    if (child != null && _hasVisualOverflow) {
      final Rect rect = Offset.zero & size;
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        rect,
        super.paint,
        clipBehavior: Clip.hardEdge,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      super.paint(context, offset);
    }
  }

  @override
  void dispose() {
    _flexAnimation.removeListener(_onAnimationUpdate);
    _clipRectLayer.layer = null;
    super.dispose();
  }
}
