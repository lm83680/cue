import 'package:cue/src/motion/cue_motion.dart';
import 'package:flutter/material.dart';

mixin CueSimulation on Simulation {
  int get phase => 0;

  double get lastX;
  double get duration;

  double valueAtProgress(double progress) {
    return x(progress * duration);
  }
}

class CurvedSimulation extends Simulation with CueSimulation {
  final Curve _curve;
  final double _from;
  final double _to;
  final double _duration;

  double _lastX = 0.0;

  @override
  double get duration => _duration;

  @override
  double get lastX => _lastX;

  CurvedSimulation({
    required Duration baseDuration,
    required Curve curve,
    required double from,
    required double to,
  }) : _duration = (baseDuration.inMicroseconds / Duration.microsecondsPerSecond) * (to - from).abs(),
       _curve = curve,
       _from = from,
       _to = to;

  @override
  double x(double t) {
    final progress = (t / _duration).clamp(0.0, 1.0);
    return _lastX = _from + (_to - _from) * _curve.transform(progress);
  }

  @override
  double dx(double t) {
    final double epsilon = tolerance.time;
    return (x(t + epsilon) - x(t - epsilon)) / (2 * epsilon);
  }

  @override
  bool isDone(double t) => t >= _duration;
}





class SegmentedMotion extends CueMotion {
  final List<CueMotion> motions;
  const SegmentedMotion(this.motions);

  @override
  Duration get baseDuration => motions.fold(Duration.zero, (total, motion) => total + motion.baseDuration);

  @override
  int get totalPhases => motions.length;

  @override
  CueSimulation build(bool forward, int phase, double progress, double? velocity) {
    return SegmentedSimulation(
      motions: motions,
      forward: forward,
      initialPhase: phase,
      initialValue: progress,
      velocity: velocity ?? 0.0,
    );
  }
}

class SegmentedSimulation extends Simulation with CueSimulation {
  final List<CueMotion> _motions;
  final bool _forward;
  late double _duration;

  @override
  double get duration => _duration;

  int _phase;

  late CueSimulation _current;

  @override
  double get lastX => _lastX;

  @override
  int get phase => _phase;

  double _phaseStartTime = 0;

  double _lastX = 0.0;

  late final _seekableSims = List.unmodifiable(_motions.map((m) => m.buildBase()));

  SegmentedSimulation({
    required List<CueMotion> motions,
    required bool forward,
    required double velocity,
    int initialPhase = 0,
    double initialValue = 0,
  }) : _motions = motions,
       _forward = forward,
       _phase = initialPhase {
    _current = motions[initialPhase].build(forward, initialPhase, initialValue, velocity);
    _duration = _current.duration;
    if (_forward) {
      for (int i = initialPhase + 1; i < motions.length; i++) {
        _duration += motions[i].baseDuration.inMicroseconds / Duration.microsecondsPerSecond;
      }
    } else {
      for (int i = 0; i < initialPhase; i++) {
        _duration += motions[i].baseDuration.inMicroseconds / Duration.microsecondsPerSecond;
      }
    }
  }

  @override
  double valueAtProgress(double progress) {
    if (_motions.isEmpty) return 0.0;

    final totalBaseDuration = _seekableSims.fold(0.0, (sum, value) => sum + value.duration);
    if (totalBaseDuration <= 0.0) {
      return _seekableSims.first.valueAtProgress(1.0);
    }
    double elapsed = progress * totalBaseDuration;
    int phase = 0;
    while (phase < _seekableSims.length - 1 && elapsed >= _seekableSims[phase].duration) {
      elapsed -= _seekableSims[phase].duration;
      phase++;
    }

    final segmentDuration = _seekableSims[phase].duration;
    final localProgress = segmentDuration <= 0.0 ? 1.0 : (elapsed / segmentDuration).clamp(0.0, 1.0);
    _phase = phase;
    return _seekableSims[phase].valueAtProgress(localProgress);
  }

  @override
  double x(double time) {
    _advanceIfNeeded(time);
    return _lastX = _current.x(time - _phaseStartTime);
  }

  @override
  double dx(double time) {
    _advanceIfNeeded(time);
    return _current.dx(time - _phaseStartTime);
  }

  @override
  bool isDone(double time) {
    if (_forward) {
      return _phase >= _motions.length - 1 && _current.isDone(time - _phaseStartTime);
    } else {
      return _phase <= 0 && _current.isDone(time - _phaseStartTime);
    }
  }

  void _advanceIfNeeded(double time) {
    final localTime = time - _phaseStartTime;
    final canAdvance = _forward ? _phase < _motions.length - 1 : _phase > 0;
    if (canAdvance && _current.isDone(localTime)) {
      double exitVelocity = _current.dx((localTime).clamp(0.0, double.infinity));
      // Negate velocity when reversing
      if (!_forward) {
        exitVelocity = -exitVelocity;
      }
      _phaseStartTime = time;
      _forward ? _phase++ : _phase--;
      final initialProgress = _forward ? 0.0 : 1.0;
      _current = _motions[_phase].build(_forward, 0, initialProgress, exitVelocity);
    }
  }
}
