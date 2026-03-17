
import 'package:flutter/material.dart';
import 'spring_motion.dart';

abstract class CueMotion {
  const CueMotion();

  Duration get duration;

  int get totalPhases => 1;


  CueSimulation build(bool forward, int phase, double progress, double? velocity);

  bool get isTimed => this is TimedMotion;
  bool get isSimulation => this is SimulationMotion;

  const factory CueMotion.curved(
    Duration duration, {
    required Curve curve,
  }) = TimedMotion.curved;

  const factory CueMotion.linear(Duration duration) = TimedMotion;

  static const jump = TimedMotion(Duration.zero);

  static const CueMotion defaultDuration = TimedMotion(
    Duration(milliseconds: 300),
  );

  factory CueMotion.spring({
    Duration duration,
    double bounce,
  }) = Spring;

  const factory CueMotion.smooth({
    double mass,
    double stiffness,
    double damping,
    Tolerance tolerance,
    bool snapToEnd,
  }) = Spring.smooth;

  const factory CueMotion.gentle({
    double mass,
    double stiffness,
    double damping,
    Tolerance tolerance,
    bool snapToEnd,
  }) = Spring.gentle;

  const factory CueMotion.iosDefaultSpring({
    double mass,
    double stiffness,
    double damping,
    Tolerance tolerance,
    bool snapToEnd,
  }) = Spring.iosDefault;

  const factory CueMotion.bouncy({
    double mass,
    double stiffness,
    double damping,
    Tolerance tolerance,
    bool snapToEnd,
  }) = Spring.bouncy;

  const factory CueMotion.wobbly({
    double mass,
    double stiffness,
    double damping,
    Tolerance tolerance,
    bool snapToEnd,
  }) = Spring.wobbly;

  const factory CueMotion.stiff({
    double mass,
    double stiffness,
    double damping,
    Tolerance tolerance,
    bool snapToEnd,
  }) = Spring.stiff;
}

class TimedMotion extends CueMotion {
  @override
  final Duration duration;
  final Curve? curve;
  const TimedMotion(this.duration) : curve = null;
  const TimedMotion.curved(this.duration, {required Curve this.curve});

 @override double calculateDuration() => duration.inMicroseconds / Duration.microsecondsPerSecond;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimedMotion && runtimeType == other.runtimeType && duration == other.duration && curve == other.curve;

  @override
  int get hashCode => duration.hashCode ^ curve.hashCode;

  @override
  CueSimulation build(bool forward, int phase, double progress, double? velocity) {
    return CurvedSimulation(
      duration: duration,
      curve: curve ?? Curves.linear,
      from: progress,
      to: forward ? 1.0 : 0.0,
    );
  }
}

mixin CueSimulation on Simulation {
  int get phase => 0;

  double get lastX;
  double get duration;
}

class CurvedSimulation extends Simulation with CueSimulation {
  final double _durationSeconds;
  final Curve _curve;
  final double _from;
  final double _to;

  double _lastX = 0.0;
  
  @override
  double get duration => _durationSeconds;

  @override
  double get lastX => _lastX;

  CurvedSimulation({
    required Duration duration,
    required Curve curve,
    required double from,
    required double to,
  }) : _durationSeconds = duration.inMicroseconds / Duration.microsecondsPerSecond,
       _curve = curve,
       _from = from,
       _to = to;

  @override
  double x(double t) {
    final progress = (t / _durationSeconds).clamp(0.0, 1.0);
    return _lastX = _from + (_to - _from) * _curve.transform(progress);
  }

  @override
  double dx(double t) {
    final double epsilon = tolerance.time;
    return (x(t + epsilon) - x(t - epsilon)) / (2 * epsilon);
  }

  @override
  bool isDone(double t) => t >= _durationSeconds;
}

abstract class SimulationMotion<S extends CueSimulation> extends CueMotion {
  const SimulationMotion();
}

extension DurationExtension on int {
  Duration get ms => Duration(milliseconds: this);
  Duration get sec => Duration(seconds: this);
  Duration get m => Duration(minutes: this);
}

class SegmentedMotion extends CueMotion {
  final List<CueMotion> motions;
  const SegmentedMotion(this.motions);


  @override
  int get totalPhases => motions.length;


  @override
  CueSimulation build(bool forward, int phase, double progress, double? velocity) {
    return SegmentedSimulation(
      motions: motions,
      forward: forward,
      initialPhase: phase,
      initialProgress: progress,
      initialVelocity: velocity ?? 0.0,
    );
  }

  @override
  Duration get duration => motions.fold(Duration.zero, (acc, a) => acc + a.duration);
}

class SegmentedSimulation extends Simulation with CueSimulation {
  final List<CueMotion> _motions;
  final bool _forward;

  @override
   double get duration => _motions.fold(0.0, (acc, motion) => acc + motion.duration.inMicroseconds / Duration.microsecondsPerSecond);

  int _phase;
  double _phaseStartTime = 0;
  late CueSimulation _current;
  double _progress = 0.0;

  @override
  double get lastX => _progress;

  @override
  int get phase => _phase;

  SegmentedSimulation({
    required List<CueMotion> motions,
    required bool forward,
    required double initialVelocity,
    int initialPhase = 0,
    double initialProgress = 0,
  }) : _motions = motions,
       _forward = forward,
       _phase = initialPhase {
    _current = motions[initialPhase].build(
      forward,
      initialPhase,
      initialProgress,
      initialVelocity,
    );
  }

  @override
  double x(double time) {
    _advanceIfNeeded(time);
    return _progress = _current.x(time - _phaseStartTime);
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
      double exitVelocity = _current.dx((localTime - 0.016).clamp(0.0, double.infinity));
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

