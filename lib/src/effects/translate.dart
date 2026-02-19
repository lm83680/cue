part of 'effect.dart';

abstract class TranslateEffect extends Effect {
  const factory TranslateEffect({
    required Offset from,
    Offset to,
    Curve? curve,
    Timing? timing,
  }) = _TranslateOffset;

  const factory TranslateEffect.keyframes(
    List<Keyframe<Offset>> keyframes, {
    Curve? curve,
  }) = _TranslateOffset.keyframes;

  const factory TranslateEffect.x({
    double from,
    double to,
    Curve? curve,
    Timing? timing,
  }) = _AxisTranslate.horizontal;

  const factory TranslateEffect.xKeyframes(
    List<Keyframe<double>> keyframes, {
    Curve? curve,
  }) = _AxisTranslate.xKeyframes;

  const factory TranslateEffect.y({
    double from,
    double to,
    Curve? curve,
    Timing? timing,
  }) = _AxisTranslate.vertical;

  const factory TranslateEffect.yKeyframes(
    List<Keyframe<double>> keyframes, {
    Curve? curve,
  }) = _AxisTranslate.yKeyframes;

  const factory TranslateEffect.fromGlobal({
    required Offset offset,
    Offset toLocal,
    Curve? curve,
    Timing? timing,
  }) = _TranslateFromGlobal;
}

class _TranslateOffset extends TweenEffect<Offset> implements TranslateEffect {
  const _TranslateOffset({
    required super.from,
    super.to = Offset.zero,
    super.curve,
    super.timing,
  });

  const _TranslateOffset.keyframes(super.keyframes, {super.curve}) : super.keyframes();

  const _TranslateOffset.internal({
    super.from,
    super.to,
    super.keyframes,
  }) : super.internal();

  @override
  Widget apply(BuildContext context, Animation<Offset> animation, Widget child) {
    return _TranslateTransition(
      offset: animation,
      transformHitTests: true,
      child: child,
    );
  }
}

class _AxisTranslate extends TweenEffectBase<double, Offset> implements TranslateEffect {
  final Axis _axis;

  const _AxisTranslate.vertical({
    super.from = 0,
    super.to = 0,
    super.curve,
    super.timing,
  }) : _axis = Axis.vertical;

  const _AxisTranslate.horizontal({
    super.from = 0,
    super.to = 0,
    super.curve,
    super.timing,
  }) : _axis = Axis.horizontal;

  const _AxisTranslate.internal({
    super.from,
    super.to,
    super.keyframes,
    required Axis axis,
  }) : _axis = axis,
       super.internal();

  const _AxisTranslate.yKeyframes(super.keyframes, {super.curve}) : _axis = Axis.vertical, super.keyframes();

  const _AxisTranslate.xKeyframes(super.keyframes, {super.curve}) : _axis = Axis.horizontal, super.keyframes();

  @override
  Offset transform(double value) {
    switch (_axis) {
      case Axis.horizontal:
        return Offset(value, 0);
      case Axis.vertical:
        return Offset(0, value);
    }
  }

  @override
  Widget apply(BuildContext context, Animation<Offset> animation, Widget child) {
    return _TranslateTransition(
      offset: animation,
      transformHitTests: true,
      child: child,
    );
  }
}

class _TranslateTransition extends AnimatedWidget {
  final Widget child;
  final Animation<Offset> offset;
  final bool transformHitTests;

  const _TranslateTransition({
    required this.child,
    required this.offset,
    this.transformHitTests = true,
  }) : super(listenable: offset);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      transformHitTests: transformHitTests,
      offset: offset.value,
      child: child,
    );
  }
}

class _TranslateFromGlobal extends TweenEffect<double> implements TranslateEffect {
  final Offset offset;
  final Offset toLocal;
  const _TranslateFromGlobal({
    required this.offset,
    this.toLocal = Offset.zero,
    super.curve,
    super.timing,
  }) : super(from: 0, to: 1);

  @override
  Widget apply(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return _TranslateFromGlobalTransition(
      animation: animation,
      global: offset,
      local: toLocal,
      child: child,
    );
  }
}

class _TranslateFromGlobalTransition extends StatefulWidget {
  final Animation<double> animation;
  final Offset global;
  final Offset local;
  final Widget child;

  const _TranslateFromGlobalTransition({
    required this.animation,
    required this.global,
    required this.child,
    this.local = Offset.zero,
  });

  @override
  State<_TranslateFromGlobalTransition> createState() => _TranslateFromGlobalTransitionState();
}

class _TranslateFromGlobalTransitionState extends State<_TranslateFromGlobalTransition> {
  final _key = GlobalKey();
  Tween<Offset>? _deltaTween;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_onAnimationUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onAnimationUpdate);
    super.dispose();
  }

  void _onAnimationUpdate() {
    if (_measured && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(_TranslateFromGlobalTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_onAnimationUpdate);
      widget.animation.addListener(_onAnimationUpdate);
    }
    if (oldWidget.global != widget.global) {
      _measured = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (!mounted) return;

    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final targetGlobal = renderBox.localToGlobal(Offset.zero);
    final newDelta = widget.global - targetGlobal;

    if (_deltaTween?.begin != newDelta) {
      setState(() {
        _deltaTween = Tween(begin: newDelta, end: widget.local);
        _measured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offset = _deltaTween == null ? Offset.zero : widget.animation.drive(_deltaTween!).value;
    final isInvisible = _deltaTween == null;
    return Visibility(
      key: _key,
      visible: !isInvisible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: Transform.translate(
        offset: offset,
        child: widget.child,
      ),
    );
  }
}

class TranslateActor extends SingleEffectProxy<Offset> {
  final double? _axisFrom;
  final double? _axisTo;
  final List<Keyframe<double>>? _axisKeyframes;
  final _TranslateVariant? _variant;

  const TranslateActor({
    super.key,
    required super.from,
    super.to = Offset.zero,
    required super.child,
    super.curve,
    super.timing,
    super.role,
    super.reverseCurve,
    super.reverseTiming,
  }) : _variant = _TranslateVariant.offset,
       _axisFrom = null,
       _axisTo = null,
       _axisKeyframes = null;

  const TranslateActor.keyframes({
    super.key,
    required super.frames,
    required super.child,
    super.curve,
    super.role,
    super.reverseCurve,
    super.reverseTiming,
  }) : _variant = _TranslateVariant.offset,
       _axisFrom = null,
       _axisTo = null,
       _axisKeyframes = null,
       super.keyframes();

  const TranslateActor.x({
    super.key,
    required double from,
    double to = 0,
    required super.child,
    super.curve,
    super.timing,
    super.reverseCurve,
    super.reverseTiming,
    super.role,
  }) : _variant = _TranslateVariant.horizontal,
       _axisFrom = from,
       _axisTo = to,
       _axisKeyframes = null,
       super(from: Offset.zero, to: Offset.zero);

  const TranslateActor.xKeyframes({
    super.key,
    required List<Keyframe<double>> frames,
    required super.child,
    super.curve,
    super.reverseCurve,
    super.reverseTiming,
    super.role,
  }) : _variant = _TranslateVariant.horizontal,
       _axisFrom = null,
       _axisTo = null,
       _axisKeyframes = frames,
       super.keyframes(frames: const []);

  const TranslateActor.y({
    super.key,
    required double from,
    double to = 0,
    required super.child,
    super.curve,
    super.timing,
    super.reverseCurve,
    super.reverseTiming,
    super.role,
  }) : _axisFrom = from,
       _axisTo = to,
       _axisKeyframes = null,
       _variant = _TranslateVariant.vertical,
       super(from: Offset.zero, to: Offset.zero);

  const TranslateActor.yKeyframes({
    super.key,
    required List<Keyframe<double>> frames,
    required super.child,
    super.curve,
    super.reverseCurve,
    super.reverseTiming,
    super.role,
  }) : _variant = _TranslateVariant.vertical,
       _axisFrom = null,
       _axisTo = null,
       _axisKeyframes = frames,
       super.keyframes(frames: const []);

  const TranslateActor.fromGlobal({
    super.key,
    required Offset offset,
    Offset toLocal = Offset.zero,
    required super.child,
    super.curve,
    super.timing,
    super.reverseCurve,
    super.reverseTiming,
    super.role,
  }) : _variant = _TranslateVariant.fromGlobal,
       _axisFrom = null,
       _axisTo = null,
       _axisKeyframes = null,
       super(from: offset, to: toLocal);

  @override
  Effect get effect => switch (_variant) {
    .horizontal => _AxisTranslate.internal(
      from: _axisFrom!,
      to: _axisTo!,
      axis: Axis.horizontal,
      keyframes: _axisKeyframes,
    ),
    .vertical => _AxisTranslate.internal(
      from: _axisFrom!,
      to: _axisTo!,
      axis: Axis.vertical,
      keyframes: _axisKeyframes,
    ),
    .fromGlobal => TranslateEffect.fromGlobal(offset: from!, toLocal: to!),
    _ => _TranslateOffset.internal(from: from, to: to, keyframes: frames),
  };
}

enum _TranslateVariant { offset, vertical, horizontal, fromGlobal }
