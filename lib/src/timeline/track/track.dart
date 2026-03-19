import 'package:cue/cue.dart';
import 'package:cue/src/motion/cue_motion.dart';
import 'package:cue/src/motion/simulation.dart';
import 'package:flutter/material.dart';

class CueTrackImpl extends CueTrack with AnimationLocalStatusListenersMixin {
  @override
  final CueMotion motion;

  @override
  final CueMotion? reverseMotion;

  @override
  final double delay;

  @override
  final double reverseDelay;

  final ReverseBehaviorType reverseType;

  double _progress = 0.0;

  int _phase = 0;

  @override
  double get progress => _progress;

  CueSimulation? _activeSim;

  bool _needsPrepare = false;

  late final CueSimulation _seekableSim = motion.buildBase();
  late final CueSimulation _seekableReverseSim = reverseMotion?.buildBase(false) ?? _seekableSim;

  @override
  double get baseDuration {
    if (_forward) {
      return delay + _seekableSim.duration;
    } else {
      return reverseDelay + _seekableReverseSim.duration;
    }
  }

  double _value = 0.0;
  double _localT = 0.0;
  double _startProgress = 0.0;
  double _delaySeconds = 0.0;
  bool _done = true;

  AnimationStatus _status = AnimationStatus.dismissed;

  CueTrackImpl(
    this.motion, {
    this.reverseMotion,
    this.delay = 0.0,
    this.reverseDelay = 0.0,
    this.reverseType = ReverseBehaviorType.mirror,
  });

  @override
  double get value => _value;

  @override
  AnimationStatus get status => _status;

  bool _forward = true;

  double _valueAtProgress(double progress, bool forward) {
    final sim = forward ? _seekableSim : _seekableReverseSim;
    final delaySeconds = (forward ? delay : reverseDelay);

    final simDuration = sim.duration;
    final totalDuration = delaySeconds + simDuration;
    final delayProgress = totalDuration <= 0 ? 0.0 : delaySeconds / totalDuration;

    final localProgress = progress <= delayProgress
        ? 0.0
        : ((progress - delayProgress) / (1.0 - delayProgress)).clamp(0.0, 1.0);

    final value = sim.valueAtProgress(localProgress);
    _phase = sim.phase;
    return value;
  }

  @override
  void setProgress(double t, {bool forward = true}) {
    assert(t >= 0.0 && t <= 1.0, 'Progress value must be between 0.0 and 1.0. Received: $t');
    _forward = forward;
    _needsPrepare = true;
    _progress = t;
    double newValue = _value;
    if (forward && !reverseType.isExclusive) {
      newValue = _valueAtProgress(t, true);
      _done = t >= 1.0;
    } else if (!forward && !reverseType.isNone) {
      print('Setting progress to $t ');
      newValue = _valueAtProgress(1, false);
      _done = t <= 0.0;
    } else {
      _done = true;
    }
    _localT = 0.0;
    _activeSim = null;
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
    _upateStatus();
  }

  @override
  void prepare({required bool forward, double? from, double? exteranlVelocity}) {
    _needsPrepare = false;
    _forward = forward;

    if (forward && reverseType.isExclusive) {
      // this drive should only drive reverse animation
      _done = true;
      _upateStatus();
      return;
    }
    if (!forward && reverseType.isNone) {
      // this drive should not drive reverse animation
      _done = true;
      _upateStatus();
      return;
    }

    final active = forward ? motion : (reverseMotion ?? motion);

    _startProgress = from ?? _progress;

    _value = _activeSim?.lastX ?? _valueAtProgress(_startProgress, forward);

    if (reverseType.isExclusive) {
      _value = 1.0;
      _phase = motion.totalPhases - 1;
    } else if (forward && reverseType.isNone) {
      _value = 0.0;
      _phase = 0;
    }
    _activeSim = active.build(forward, _phase, _value, exteranlVelocity ?? velocity);

    final rawDelaySeconds = (forward ? delay : reverseDelay);
    final fullSimDuration = (forward ? _seekableSim : _seekableReverseSim).duration;
    final totalDuration = rawDelaySeconds + fullSimDuration;
    final elapsedTime = forward ? _startProgress * totalDuration : (1.0 - _startProgress) * totalDuration;
    _delaySeconds = (rawDelaySeconds - elapsedTime).clamp(0.0, double.infinity);

    _localT = 0.0;
    _done = false;
    _upateStatus();
  }

  void _upateStatus([AnimationStatus? newStatus]) {
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
    assert(!_needsPrepare || _done, 'Tick() is called before prepare().');
    if (_done || _activeSim == null) return;
    _localT += td;

    final t = (_localT - _delaySeconds);
    final target = _forward ? 1.0 : 0.0;

    final simT = (_localT - _delaySeconds).clamp(0.0, double.infinity);
    final simDuration = _activeSim!.duration;

    final fraction = simDuration <= 0 ? 1.0 : (simT / simDuration).clamp(0.0, 1.0);
    _progress = _startProgress + (target - _startProgress) * fraction;

    if (_localT < _delaySeconds) return;

    if (_activeSim!.isDone(t)) {
      _value = _activeSim!.x(t);
      _phase = _activeSim!.phase;
      _done = true;
      _progress = target;
      notifyListeners();
      _upateStatus(_forward ? .completed : .dismissed);
      return;
    }
    _value = _activeSim!.x(t);
    _phase = _activeSim!.phase;
    notifyListeners();
  }

  @override
  bool get isDone => _done;

  @override
  double get velocity {
    if (_activeSim == null) return 0.0;
    final t = (_localT - _delaySeconds).clamp(0.0, double.infinity);
    return _activeSim!.dx(t);
  }

  @override
  int get phase => _phase;
}

abstract class CueTrack extends Animation<double> with AnimationLocalListenersMixin {
  void prepare({required bool forward, double? from, double? exteranlVelocity});

  CueMotion get motion;
  CueMotion? get reverseMotion;

  double get baseDuration;

  double get delay;
  double get reverseDelay;

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
