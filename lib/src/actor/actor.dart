import 'package:cue/cue.dart';
import 'package:cue/src/effects/base/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class RawActor extends StatefulWidget {
  final Curve? curve;
  final Curve? reverseCurve;
  final Timing? timing;
  final Timing? reverseTiming;
  final ActorRole role;
  final List<Effect> effects;
  final Widget child;

  const RawActor({
    super.key,
    required this.effects,
    required this.child,
    this.role = ActorRole.both,
    this.curve,
    this.reverseCurve,
    this.timing,
    this.reverseTiming,
  });

  @override
  State<RawActor> createState() => RawActorState();
}

class RawActorState extends State<RawActor> {
  final _animations = <Type, Animation<Object?>>{};
  final _cachedAnimations = <Effect, Animation<Object?>>{};
  final _animationSnapshots = <Type, Object?>{};

  void _onWillReAnimate(bool forward) {
    for (final entry in _animations.entries) {
      _animationSnapshots[entry.key] = entry.value.value;
    }
  }

  CueScope? _cachedScope;

  void _setupAnimations(CueScope scope) {
    _cachedScope = scope;

    assert(() {
      if (widget.effects.map((e) => e.runtimeType).toSet().length != widget.effects.length) {
        throw StateError(
          'Multiple effects of the same type are not supported. Please ensure all effects in the list are of different types.',
        );
      }
      return true;
    }());

    _animations.removeWhere((effect, _) => !widget.effects.map((e) => e.runtimeType).contains(effect));
    _cachedAnimations.removeWhere((effect, _) => !widget.effects.contains(effect));
    for (final effect in widget.effects) {
      if (!_cachedAnimations.containsKey(effect)) {
        final implicitFrom = scope.reanimateFromCurrent ? _animationSnapshots[effect.runtimeType] : null;
        final animation = effect.buildAnimation(
          scope.animation,
          ActorContext(
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            curve: widget.curve,
            timing: widget.timing,
            isBounded: scope.isBounded,
            reverseCurve: widget.reverseCurve,
            reverseTiming: widget.reverseTiming,
            role: widget.role,
            implicitFrom: implicitFrom,
          ),
        );
        _animations[effect.runtimeType] = animation;
        _cachedAnimations[effect] = animation;
      }
    }
  }

  @override
  void didUpdateWidget(covariant RawActor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.effects, widget.effects) ||
        oldWidget.curve != widget.curve ||
        oldWidget.timing != widget.timing ||
        oldWidget.reverseCurve != widget.reverseCurve ||
        oldWidget.reverseTiming != widget.reverseTiming ||
        oldWidget.role != widget.role) {
      if (oldWidget.role != widget.role) {
        // If the role has changed, we need to clear all cached animations
        //to ensure they are rebuilt with the correct role.
        _animations.clear();
        _cachedAnimations.clear();
      }
      _setupAnimations(CueScope.of(context));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = CueScope.of(context);
    if (_cachedScope?.willReanimateNotifier != scope.willReanimateNotifier) {
      _cachedScope?.willReanimateNotifier?.removeEventListener(_onWillReAnimate);
      scope.willReanimateNotifier?.addEventListener(_onWillReAnimate);
    }
    if (_cachedScope == null || scope.updateShouldNotify(_cachedScope!)) {
      _setupAnimations(scope);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effects.isEmpty) return widget.child;
    Widget current = widget.child;
    for (final effect in widget.effects.reversed) {
      if (_animations[effect.runtimeType] case final animation?) {
        current = effect.build(context, animation, current);
      } else {
        throw StateError(
          'Animation for effect $effect not found. This should not happen as animations are set up in initState and didUpdateWidget.',
        );
      }
    }
    return current;
  }

  @override
  void dispose() {
    super.dispose();
    _cachedScope?.willReanimateNotifier?.removeEventListener(_onWillReAnimate);
  }
}

abstract class SingleEffectBase<T> extends StatelessWidget {
  final Widget child;
  final Curve? curve;
  final Curve? reverseCurve;
  final Timing? timing;
  final Timing? reverseTiming;
  final ActorRole role;
  final List<Keyframe<T>>? frames;
  final T? _from;
  final T? _to;

  T? get from => _from;
  T? get to => _to;

  const SingleEffectBase({
    super.key,
    required this.child,
    required T from,
    required T to,
    this.curve,
    this.timing,
    this.role = ActorRole.both,
    this.reverseCurve,
    this.reverseTiming,
  }) : frames = null,
       _from = from,
       _to = to;

  const SingleEffectBase.keyframes({
    required List<Keyframe<T>> this.frames,
    super.key,
    required this.child,
    this.role = ActorRole.both,
    this.reverseCurve,
    this.reverseTiming,
    this.curve,
  }) : timing = null,
       _from = null,
       _to = null;

  Effect get effect;

  @override
  Widget build(BuildContext context) {
    return RawActor(
      curve: curve,
      timing: timing,
      reverseCurve: reverseCurve,
      reverseTiming: reverseTiming,
      role: role,
      effects: [effect],
      child: child,
    );
  }
}

class TweenActor<T> extends StatefulWidget {
  final List<Keyframe<T>>? _keyframes;
  final Widget? child;
  final ValueWidgetBuilder<T> builder;
  final TweenBuilder<T>? _tweenBuilder;
  final Tween<T>? _tween;
  final Curve? curve;
  final Timing? timing;

  const TweenActor({
    super.key,
    required this.builder,
    required Tween<T> tween,
    this.curve,
    this.timing,
    this.child,
  }) : _tween = tween,
       _keyframes = null,
       _tweenBuilder = null;

  const TweenActor.keyframes({
    super.key,
    required this.builder,
    required List<Keyframe<T>> keys,
    TweenBuilder<T>? tweenBuilder,
    this.curve,
    this.child,
  }) : _tweenBuilder = tweenBuilder,
       _keyframes = keys,
       _tween = null,
       timing = null;

  @override
  State<StatefulWidget> createState() => _ProgressActorState<T>();
}

class ProgressActor extends TweenActor<double> {
  ProgressActor({
    super.key,
    required super.builder,
    super.curve,
    super.timing,
    super.child,
  }) : super(tween: Tween<double>(begin: 0.0, end: 1.0));

  @override
  State<StatefulWidget> createState() => _ProgressActorState<double>();
}

class _ProgressActorState<T> extends State<TweenActor<T>> {
  late Animation<T> animation;

  Animation<double>? _cachedDriver;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = CueScope.of(context).animation;
    if (_cachedDriver != driver) {
      _setupAnimation(driver);
    }
  }

  @override
  void didUpdateWidget(covariant TweenActor<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._tween != widget._tween ||
        oldWidget.curve != widget.curve ||
        oldWidget.timing != widget.timing ||
        !listEquals(widget._keyframes, oldWidget._keyframes)) {
      _setupAnimation(CueScope.of(context).animation);
    }
  }

  void _setupAnimation(Animation<double> driver) {
    _cachedDriver = driver;
    Timing? timing = widget.timing;
    Curve? curve = widget.curve;

    Animatable<T> effectiveTween;
    if (widget._tween case final tween?) {
      effectiveTween = tween;
    } else {
      final result = Phase.normalize(widget._keyframes!, (value) => value);

      if (result.timing != null) {
        timing = result.timing;
      }
      effectiveTween = buildFromPhases<T>(
        result.phases,
        widget._tweenBuilder ?? (begin, end) => Tween<T>(begin: begin, end: end),
      );
    }

    if (timing == null && curve == null) {
      animation = driver.drive<T>(effectiveTween);
      return;
    }

    final effectiveCurve = timing != null
        ? Interval(timing.start, timing.end, curve: curve ?? Curves.linear)
        : curve ?? Curves.linear;

    animation = driver.drive<T>(
      effectiveTween.chain(CurveTween(curve: effectiveCurve)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return widget.builder(
          context,
          animation.value,
          widget.child,
        );
      },
    );
  }
}
