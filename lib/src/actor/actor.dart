import 'package:cue/cue.dart';
import 'package:cue/src/timeline/track/track_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class Actor extends StatefulWidget {
  final List<Act> acts;
  final Widget child;
  final CueMotion? motion;
  final CueMotion? reverseMotion;
  final Duration delay;
  final Duration reverseDelay;
  final bool addRepaintBoundary;

  const Actor({
    super.key,
    required this.acts,
    required this.child,
    this.motion,
    this.reverseMotion,
    this.delay = Duration.zero,
    this.reverseDelay = Duration.zero,
    this.addRepaintBoundary = false,
  });

  @override
  State<Actor> createState() => ActorState();
}

class ActorState extends State<Actor> {
  final _animations = <ActKey, _CacheEntry>{};
  final _animationSnapshots = <ActKey, Object?>{};
  CueScope? _cachedScope;

  List<(Act, ActContext)> _acts = [];

  void _onWillAnimate() {
    _animationSnapshots.clear();
    for (final entry in _animations.entries) {
      _animationSnapshots[entry.key] = entry.value.value;
    }
  }

  void _setupAnimations(CueScope scope) {
    _cachedScope = scope;
    assert(() {
      if (_acts.map((e) => e.$1.key).toSet().length != _acts.length) {
        final seenKeys = <ActKey>{};
        for (final key in _acts.map((e) => e.$1.key)) {
          if (seenKeys.contains(key)) {
            throw StateError(
              'Multiple Acts of the same type are not supported. Please ensure all Acts in the list are of different types. Duplicate found: $key',
            );
          }
          seenKeys.add(key);
        }
      }
      return true;
    }());

    final acts = _acts.map((e) => e.$1);
    final actKeys = acts.map((e) => e.key).toSet();

    for (final entry in List.of(_animations.entries)) {
      if (!actKeys.contains(entry.key)) {
        if (_animations.remove(entry.key) case final cacheEntry?) {
          cacheEntry.animation.release();
        }
      }
    }

    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    for (final entry in _acts) {
      final (act, actContext) = entry;
      final existing = _animations[act.key];
      if (existing?.act == act) continue;
      final implicitFrom = scope.reanimateFromCurrent ? _animationSnapshots[act.key] : null;
      final animation = act.buildAnimation(
        scope.controller.timeline,
        actContext.copyWith(
          textDirection: textDirection,
          implicitFrom: implicitFrom,
        ),
      );
      if (existing?.animation case final animation?) {
        animation.release();
      }
      _animations[act.key] = _CacheEntry(act, animation);
    }
  }

  @override
  void didUpdateWidget(covariant Actor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.acts, oldWidget.acts) ||
        widget.delay != oldWidget.delay ||
        widget.reverseDelay != oldWidget.reverseDelay ||
        widget.motion != oldWidget.motion ||
        widget.reverseMotion != oldWidget.reverseMotion) {
      final scope = CueScope.of(context);
      _resolveActs(scope.controller.timeline.defaultConfig);
      _setupAnimations(scope);
    }
  }

  void _resolveActs(TrackConfig mainConfig) {
    _acts = [
      for (final act in widget.acts)
        (
          act,
          act.resolve(
            ActContext(
              motion: widget.motion ?? mainConfig.motion,
              reverseMotion: widget.reverseMotion ?? widget.motion ?? mainConfig.reverseMotion,
              delay: widget.delay,
              reverseDelay: widget.reverseDelay,
            ),
          ),
        ),
    ];
  }

  void _clearCache(CueScope scope) {
    for (final entry in _animations.values) {
      entry.animation.release();
    }
    _animations.clear();
    _animationSnapshots.clear();
  }

  VoidCallback? _eventsDisposer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = CueScope.of(context);
    if (_cachedScope?.controller != scope.controller) {
      _eventsDisposer?.call();
      _eventsDisposer = scope.controller.addEventListener<TimelineEvent>((_) => _onWillAnimate());
    }
    if (_cachedScope?.controller != scope.controller) {
      _resolveActs(scope.controller.timeline.defaultConfig);
      _clearCache(scope);
      _setupAnimations(scope);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_acts.isEmpty) return widget.child;
    Widget current = widget.child;
    for (final entry in _acts.reversed) {
      final (act, _) = entry;
      if (_animations[act.key]?.animation case final animation?) {
        current = act.build(context, animation, current);
      } else {
        throw StateError(
          'Animation for act $act not found. This should not happen as animations are set up in initState and didUpdateWidget.',
        );
      }
    }
    if (widget.addRepaintBoundary) {
      return RepaintBoundary(child: current);
    }
    return current;
  }

  @override
  void dispose() {
    super.dispose();
    _eventsDisposer?.call();
    _eventsDisposer = null;
    if (_cachedScope case final scope?) {
      _clearCache(scope);
    }
  }
}

class _CacheEntry {
  final Act act;
  final CueAnimation<Object?> animation;
  _CacheEntry(this.act, this.animation);
  Object? get value => animation.value;
}

abstract class SingleActorBase<T> extends StatelessWidget {
  final Widget child;
  final ReverseBehavior<T> reverse;
  final CueMotion? motion;
  final Duration delay;
  final Duration reverseDelay;
  final CueMotion? reverseMotion;

  final Keyframes<T>? frames;
  final T? _from;
  final T? _to;

  T? get from => _from;
  T? get to => _to;

  const SingleActorBase({
    super.key,
    required this.child,
    required T from,
    required T to,
    this.motion,
    this.delay = Duration.zero,
    this.reverseMotion,
    this.reverseDelay = Duration.zero,
    this.reverse = const ReverseBehavior.mirror(),
  }) : frames = null,
       _from = from,
       _to = to;

  const SingleActorBase.keyframes({
    required Keyframes<T> this.frames,
    super.key,
    required this.child,
    this.reverse = const ReverseBehavior.mirror(),
    this.delay = Duration.zero,
    this.reverseDelay = Duration.zero,
  }) : _from = null,
       _to = null,
       motion = null,
       reverseMotion = null;

  Act get act;

  @override
  Widget build(BuildContext context) {
    return Actor(
      motion: motion,
      delay: delay,
      reverseMotion: reverseMotion,
      reverseDelay: reverseDelay,
      acts: [act],
      child: child,
    );
  }
}

extension ActorExtenstion on Widget {
  Widget act(
    List<Act> acts, {
    CueMotion? motion,
    CueMotion? reverseMotion,
    Duration delay = Duration.zero,
    Duration reverseDelay = Duration.zero,
  }) {
    return Actor(
      motion: motion,
      reverseMotion: reverseMotion,
      delay: delay,
      reverseDelay: reverseDelay,
      acts: acts,
      child: this,
    );
  }
}
