import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

abstract class CueTimeline extends Simulation {
  CueTrack trackFor(TrackConfig config);
  void prepare({required bool forward, double? from});
  void setProgress(double value, {bool forward = true});

  void release(CueTrack anim);

  AnimationStatus get status;

  double get progress => mainTrack.progress;

  final Map<TrackConfig, CueTrack> tracks;

  CueTimeline(this.tracks);

  CueTrack buildTrack(TrackConfig config);

  TrackConfig get mainTrackConfig => tracks.keys.first;

  CueTrack get mainTrack;

  void reset(TrackConfig config) {
    tracks.clear();
    tracks[config] = buildTrack(config);
  }

  void addOnPrepareListener(ValueChanged<bool> listener);
  void removeOnPrepareListener(ValueChanged<bool> listener);
  void addStatusListener(AnimationStatusListener listener);
  void removeStatusListener(AnimationStatusListener listener);
}

class CueTimelineImpl extends CueTimeline with AnimationLocalStatusListenersMixin {
  @override
  void addOnPrepareListener(ValueChanged<bool> listener) {
    _onPrepareNotifier.addEventListener(listener);
  }

  @override
  void removeOnPrepareListener(ValueChanged<bool> listener) {
    _onPrepareNotifier.removeEventListener(listener);
  }

  final _onPrepareNotifier = EventNotifier<bool>();

  CueTimelineImpl(CueTrack main)
    : super({
        TrackConfig(
          motion: main.motion,
          reverseMotion: main.reverseMotion,
        ): main,
      });

  double _lastT = 0.0;

  double get elapsedSeconds => _lastT;

  @override
  CueTrack get mainTrack => tracks.values.first;

  @override
  CueTrack trackFor(TrackConfig config) {
    if (config == mainTrackConfig) {
      return mainTrack;
    }
    final animation = tracks.putIfAbsent(config, () => buildTrack(config));
    if (mainTrack.isAnimating) {
      animation.prepare(
        forward: mainTrack.isForwardOrCompleted,
        from: mainTrack.progress,
        exteranlVelocity: mainTrack.velocity,
      );
      _onPrepareNotifier.fireEvent(mainTrack.isForwardOrCompleted);
    } else {
      animation.setProgress(mainTrack.progress);
    }
    return animation;
  }

  @override
  AnimationStatus get status => _status;

  AnimationStatus _status = AnimationStatus.dismissed;

  @override
  void release(CueTrack anim) {}

  @override
  void setProgress(double value, {bool forward = true}) {
    for (final anim in tracks.values) {
      anim.setProgress(value, forward: forward);
    }
    _updateStatus();
  }

  void _updateStatus() {
    bool allCompleted = true;
    bool allDismissed = true;

    AnimationStatus currentStatus = _status;

    for (final d in tracks.values) {
      final s = d.status;

      if (s != AnimationStatus.completed) {
        allCompleted = false;
      }
      if (s != AnimationStatus.dismissed) {
        allDismissed = false;
      }

      if (s == AnimationStatus.forward) {
        currentStatus = AnimationStatus.forward;
        break;
      }
      if (s == AnimationStatus.reverse) {
        currentStatus = AnimationStatus.reverse;
        break;
      }
    }

    if (allCompleted) currentStatus = AnimationStatus.completed;
    if (allDismissed) currentStatus = AnimationStatus.dismissed;

    if (currentStatus != _status) {
      _status = currentStatus;
      notifyStatusListeners(_status);
    }
  }

  @override
  void prepare({required bool forward, double? from}) {
    _onPrepareNotifier.fireEvent(forward);
    _lastT = 0.0;
    for (final anim in tracks.values) {
      anim.prepare(forward: forward, from: from);
    }
    _updateStatus();
  }

  @override
  double x(double time) {
    final dt = time - _lastT;
    _lastT = time;
    if (dt > 0) {
      for (final anim in tracks.values) {
        anim.tick(dt);
      }
    }
    _updateStatus();
    return mainTrack.progress;
  }

  @override
  double dx(double time) => mainTrack.velocity;

  @override
  bool isDone(double time) => tracks.values.every((anim) => anim.isDone);

 
  @override
  CueTrack buildTrack(TrackConfig config) {
    return CueTrackImpl(
      config.motion,
      reverseMotion: config.reverseMotion,
      delay: config.delay,
      reverseDelay: config.reverseDelay,
      reverseType: config.reverseType,
    );
  }

  @override
  void didRegisterListener() {
    // TODO: implement didRegisterListener
  }

  @override
  void didUnregisterListener() {
    // TODO: implement didUnregisterListener
  }
}

abstract class CueTrack extends Animation<double> with AnimationLocalListenersMixin {
  void prepare({required bool forward, double? from, double? exteranlVelocity});

  CueMotion get motion;
  CueMotion? get reverseMotion;

  Duration get delay;
  Duration get reverseDelay;

  double get duration;
  double get reverseDuration;

  void tick(double td);

  void setProgress(double t, {bool forward = true});

  bool get isDone;

  double get velocity;

  double get progress;

  int get phase;

  @override
  void didRegisterListener() {}

  @override
  void didUnregisterListener() {}

  bool get isReverseOrDismissed => status == AnimationStatus.reverse || status == AnimationStatus.dismissed;
}

class CueTrackImpl extends CueTrack with AnimationLocalStatusListenersMixin {
  @override
  final CueMotion motion;

  @override
  final CueMotion? reverseMotion;

  @override
  final Duration delay;

  @override
  final Duration reverseDelay;

  final ReverseBehaviorType reverseType;

  @override
  double get duration {
    return _duration ??= (motion.duration + delay).inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  double get reverseDuration {
    return _reverseDuration ??=
        (reverseMotion?.duration ?? motion.duration + reverseDelay).inMicroseconds / Duration.microsecondsPerSecond;
  }

  double _progress = 0.0;

  @override
  double get progress => _progress;

  double? _duration;
  double? _reverseDuration;

  CueSimulation? _sim;

  CueSimulation? _seekableForwardSim;
  CueSimulation? _seekableReverseSim;

  double _value = 0.0;
  double _localT = 0.0;
  double _startProgress = 0.0;
  double _delaySeconds = 0.0;
  bool _done = true; // idle until prepared

  AnimationStatus _status = AnimationStatus.dismissed;

  CueTrackImpl(
    this.motion, {
    this.reverseMotion,
    this.delay = Duration.zero,
    this.reverseDelay = Duration.zero,
    this.reverseType = ReverseBehaviorType.mirror,
  });

  @override
  double get value => _value;

  @override
  AnimationStatus get status => _status;

  bool _forward = true;

  @override
  void setProgress(double t, {bool forward = true}) {
    assert(t >= 0.0 && t <= 1.0, 'Progress value must be between 0.0 and 1.0. Received: $t');
    _forward = forward;
    _progress = t;
    double newValue = _value;
    if (forward && !reverseType.isExclusive) {
      final sim = _seekableForwardSim ??= motion.build(true, 0, 0, 0);
      final targetT = duration * t;
      newValue = sim.x(targetT);
      _done = sim.isDone(targetT);
    } else if (!forward && !reverseType.isNone) {
      final sim = _seekableReverseSim ??= (reverseMotion ?? motion).build(false, 0, 0, 0);
      final targetT = reverseDuration * t;
      newValue = sim.x(targetT);
      _done = sim.isDone(targetT);
    }
    _sim = null; // invalidate current simulation since we're jumping to a new progress
    _localT = 0.0;
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  @override
  void prepare({required bool forward, double? from, double? exteranlVelocity}) {
    _forward = forward;

    if (forward && reverseType.isExclusive) {
      // this drive should only drive reverse animation
      _done = true;
      return;
    }
    if (!forward && reverseType.isNone) {
      // this drive should not drive reverse animation
      _done = true;
      return;
    }

    final active = forward ? motion : (reverseMotion ?? motion);

    int phase = _sim?.phase ?? 0;
    double progress = from ?? _progress;
    _startProgress = progress;

    if (reverseType.isExclusive) {
      _value = 1.0;
      progress = 1.0;
      phase = motion.totalPhases - 1;
    } else if (forward && reverseType.isNone) {
      _value = 0.0;
      progress = 0.0;
      phase = 0;
    }

    _sim = active.build(forward, phase, progress, exteranlVelocity ?? velocity);
    _value = _sim!.x(0);
    _delaySeconds = (forward ? delay : reverseDelay).inMicroseconds / Duration.microsecondsPerSecond;
    _localT = 0.0;
    _done = false;
    _updateStatue();
  }

  void _updateStatue([AnimationStatus? newStatus]) {
    newStatus ??= switch ((_forward, _done)) {
      (true, true) => AnimationStatus.completed,
      (true, false) => AnimationStatus.forward,
      (false, true) => AnimationStatus.dismissed,
      (false, false) => AnimationStatus.reverse,
    };
    if (newStatus != _status) {
      _status = newStatus;
      notifyStatusListeners(_status);
    }
  }

  @override
  void tick(double td) {
    if (_done || _sim == null) return;
    _localT += td;
    final target = _forward ? 1.0 : 0.0;
    final fraction = (_localT / _sim!.duration).clamp(0.0, 1.0);
    _progress = _startProgress + (target - _startProgress) * fraction;

    final t = _localT - _delaySeconds;
    if (t < 0) return; // still in delay

    if (_sim!.isDone(t)) {
      _value = _sim!.x(t);
      _done = true;
      _progress = target;
      notifyListeners();
      _updateStatue(_forward ? AnimationStatus.completed : AnimationStatus.dismissed);
      return;
    }
    _value = _sim!.x(t);
    notifyListeners();
  }

  @override
  bool get isDone => _done;

  @override
  double get velocity {
    if (_sim == null) return 0.0;
    final t = (_localT - _delaySeconds).clamp(0.0, double.infinity);
    return _sim!.dx(t);
  }

  @override
  int get phase => _sim?.phase ?? 0;
}

class TrackConfig {
  final CueMotion motion;
  final CueMotion? reverseMotion;
  final Duration delay;
  final Duration reverseDelay;
  final ReverseBehaviorType reverseType;

  const TrackConfig({
    required this.motion,
    this.reverseMotion,
    this.delay = Duration.zero,
    this.reverseDelay = Duration.zero,
    this.reverseType = ReverseBehaviorType.mirror,
  });

  TrackConfig copyWith({
    CueMotion? motion,
    CueMotion? reverseMotion,
    Duration? delay,
    Duration? reverseDelay,
    ReverseBehaviorType? reverseType,
  }) {
    return TrackConfig(
      motion: motion ?? this.motion,
      reverseMotion: reverseMotion ?? this.reverseMotion,
      delay: delay ?? this.delay,
      reverseDelay: reverseDelay ?? this.reverseDelay,
      reverseType: reverseType ?? this.reverseType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackConfig &&
        other.motion == motion &&
        other.reverseMotion == reverseMotion &&
        other.delay == delay &&
        other.reverseType == reverseType &&
        other.reverseDelay == reverseDelay;
  }

  @override
  int get hashCode => Object.hash(motion, reverseMotion, delay, reverseDelay, reverseType);
}
