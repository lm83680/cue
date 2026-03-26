import 'dart:math' as math;

import 'package:cue/src/motion/cue_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

mixin CueSimulation on Simulation {
  int get phase => 0;

  double get duration;

  (double value, int phase) valueAtProgress(double progress) {
    return (x(progress * duration), phase);
  }
}

class DelayedSimulation extends Simulation with CueSimulation {
  final CueSimulation _base;
  final double _delay;

  DelayedSimulation({
    required CueSimulation base,
    required double delay,
  }) : _base = base,
       _delay = delay;

  @override
  double get duration => _delay + _base.duration;

  @override
  int get phase => _base.phase;

  // Core progress mapping - delay is first portion of progress
  @override
  (double value, int phase) valueAtProgress(double progress) {
    final totalDuration = duration;
    final delayProgress = totalDuration <= 0 ? 0.0 : _delay / totalDuration;

    final localProgress = progress <= delayProgress
        ? 0.0
        : ((progress - delayProgress) / (1.0 - delayProgress)).clamp(0.0, 1.0);

    return _base.valueAtProgress(localProgress);
  }

  @override
  double x(double t) {
    final tAfterDelay = (t - _delay).clamp(0.0, double.infinity);
    return _base.x(tAfterDelay);
  }

  @override
  double dx(double t) => t <= _delay ? 0.0 : _base.dx(t - _delay);

  @override
  bool isDone(double t) => t > _delay && _base.isDone(t - _delay);
}

class CurvedSimulation extends Simulation with CueSimulation {
  final Curve _curve;
  final double _from;
  final double _to;
  final double _duration;

  @override
  double get duration => _duration;

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
    return _from + (_to - _from) * _curve.transform(progress);
  }

  @override
  double dx(double t) {
    final double epsilon = tolerance.time;
    return (x(t + epsilon) - x(t - epsilon)) / (2 * epsilon);
  }

  @override
  bool isDone(double t) => t >= _duration;
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
  int get phase => _phase;

  double _phaseStartTime = 0;

  List<CueSimulation> _buildSeekableSegments() {
    if (_forward) {
      return List.unmodifiable(_motions.map((m) => m.buildBase()));
    }
    return List.unmodifiable(_motions.reversed.map((m) => m.buildBase(forward: false)));
  }

  late final _seekableSegments = _buildSeekableSegments();

  SegmentedSimulation({
    required List<CueMotion> motions,
    required bool forward,
    required double velocity,
    int initialPhase = 0,
    double startValue = 0,
  }) : _motions = motions,
       _forward = forward,
       _phase = initialPhase {
    _current = motions[initialPhase].build(
      SimulationBuildData(
        forward: forward,
        startValue: startValue,
        phase: initialPhase,
        velocity: velocity.abs(),
      ),
    );
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
  double x(double time) {
    _advanceIfNeeded(time);
    return _current.x(time - _phaseStartTime);
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

  @override
  (double value, int phase) valueAtProgress(double progress) {
    if (_motions.isEmpty) return (0.0, 0);
    final totalBaseDuration = _seekableSegments.fold(0.0, (sum, value) => sum + value.duration);
    if (totalBaseDuration <= 0.0) {
      return _seekableSegments.first.valueAtProgress(1.0);
    }
    double elapsed = progress * totalBaseDuration;
    int phase = 0;
    while (phase < _seekableSegments.length - 1 && elapsed >= _seekableSegments[phase].duration) {
      elapsed -= _seekableSegments[phase].duration;
      phase++;
    }

    final segmentDuration = _seekableSegments[phase].duration;

    final localProgress = segmentDuration <= 0.0 ? 1.0 : (elapsed / segmentDuration).clamp(0.0, 1.0);
    final (value, _) = _seekableSegments[phase].valueAtProgress(localProgress);
    _phase = _forward ? phase : _motions.length - 1 - phase;

    return (value, _phase);
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
      _current = _motions[phase].build(
        SimulationBuildData(
          forward: _forward,
          startValue: initialProgress,
          velocity: exitVelocity,
        ),
      );
    }
  }
}

class CueSpringSimulation extends SpringSimulation with CueSimulation {
  CueSpringSimulation(
    super.spring,
    super.start,
    super.end,
    super.velocity, {
    super.tolerance,
    super.snapToEnd,
    this.samplingStepSize = 1 / 60,
  }) : _end = end,
       _start = start,
       _spring = spring;
  final double samplingStepSize;
  final SpringDescription _spring;
  SpringDescription get spring => _spring;
  final double _start;
  final double _end;

  @override
  late final double duration = calculateSettleDuration(spring: _spring, stepSize: samplingStepSize);


  double calculateSettleDuration({
    double stepSize = 1 / 60,
    required SpringDescription spring,
  }) {
    final omega0 = math.sqrt(spring.stiffness / spring.mass);
    final zeta = spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));
    final amplitude = (_start - _end).abs();

    final estimate = math.max(0.0, -math.log(tolerance.distance / amplitude) / (zeta * omega0));
    double t = (estimate / stepSize).floor() * stepSize;
    while (t < 100.0) {
      if (isDone(t)) return t;
      t += stepSize;
    }

    return t;
  }
}
