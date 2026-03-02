import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

class CueAnimationController extends AnimationController {
  CueMotion _motion;
  final double _lowerBound;
  final double _upperBound;

  @override
  double get lowerBound {
    return _motion.isSimulation ? double.negativeInfinity : _lowerBound;
  }

  @override
  double get upperBound {
    return _motion.isSimulation ? double.infinity : _upperBound;
  }

  set motion(CueMotion newValue) {
    if (_motion != newValue) {
      _motion = newValue;
      if (newValue is TimedMotion) {
        duration = newValue.duration;
        reverseDuration = newValue.reverseDuration;
      }
    }
  }

  CueAnimationController({
    required CueMotion motion,
    super.debugLabel,
    super.value = 0.0,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    super.animationBehavior,
    required super.vsync,
  }) : _motion = motion,
       _lowerBound = lowerBound,
       _upperBound = upperBound {
    if (motion is TimedMotion) {
      duration = motion.duration;
      reverseDuration = motion.reverseDuration;
    }
  }

  bool get usesSimulation => _motion.isSimulation;

  AnimationStatusListener? _statusListener;

  @override
  void dispose() {
    if (_statusListener != null) {
      removeStatusListener(_statusListener!);
    }
    super.dispose();
  }

  Simulation _createSimulation(CueSimulation cueSimulation, bool forward) {
    return cueSimulation.build(
      SimulationBuildData(
        velocity: velocity,
        forward: forward,
        progress: value.clamp(0.0, 1.0),
      ),
    );
  }

  @override
  TickerFuture forward({double? from}) {
    if (from != null) {
      value = from;
    }
    switch (_motion) {
      case TimedMotion():
        return super.animateTo(_upperBound);
      case SimulationMotion(simulation: final simulation):
        return animateWith(_createSimulation(simulation, true));
    }
  }

  @override
  TickerFuture reverse({double? from}) {
    if (from != null) {
      value = from;
    }
    switch (_motion) {
      case TimedMotion():
        return super.animateBack(_lowerBound);
      case SimulationMotion(reverse: final reverse, simulation: final simulation):
        final effectiveSim = reverse ?? simulation;
        return animateWith(_createSimulation(effectiveSim, false));
    }
  }

  void playLoop({bool reverseOnLoop = false, int? count}) {
    if (_motion.isTimed) {
      super.repeat(reverse: reverseOnLoop, count: count);
    } else {
      if (_statusListener != null) {
        removeStatusListener(_statusListener!);
      }
      int loopCount = 0;
      _statusListener = (status) {
        if (status == AnimationStatus.completed) {
          loopCount++;
          if (count != null && loopCount >= count) {
            return;
          }
          if (reverseOnLoop) {
            reverse();
          } else {
            forward();
          }
        } else if (status == AnimationStatus.dismissed && reverseOnLoop) {
          forward();
        }
      };
      addStatusListener(_statusListener!);
      forward();
    }
  }
}

sealed class CueMotion {
  const CueMotion();
  const factory CueMotion.timed(
    Duration duration, {
    Duration? reverseDuration,
    Curve? curve,
    Curve? reverseCurve,
  }) = TimedMotion;

  static const CueMotion defaultDuration = CueMotion.timed(
    Duration(milliseconds: 300),
  );

  const factory CueMotion.simulation(
    CueSimulation simulation, {
    CueSimulation? reverse,
  }) = SimulationMotion;

  bool get isTimed => this is TimedMotion;
  bool get isSimulation => this is SimulationMotion;
}

class TimedMotion extends CueMotion {
  final Duration duration;
  final Duration? reverseDuration;
  final Curve? curve;
  final Curve? reverseCurve;
  const TimedMotion(this.duration, {this.reverseDuration, this.curve, this.reverseCurve});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimedMotion &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          reverseDuration == other.reverseDuration &&
          curve == other.curve &&
          reverseCurve == other.reverseCurve;

  @override
  int get hashCode => duration.hashCode ^ reverseDuration.hashCode ^ curve.hashCode ^ reverseCurve.hashCode;

  Animation<double> applyCurve(Animation<double> animation, {bool reverse = false}) {
    final curve = reverse ? reverseCurve : this.curve;
    if (curve case final curve?) {
      return CurvedAnimation(parent: animation, curve: curve);
    } else {
      return animation;
    }
  }
}

class SimulationMotion extends CueMotion {
  final CueSimulation simulation;
  final CueSimulation? reverse;
  const SimulationMotion(this.simulation, {this.reverse});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimulationMotion &&
          runtimeType == other.runtimeType &&
          simulation == other.simulation &&
          reverse == other.reverse;

  @override
  int get hashCode => simulation.hashCode ^ reverse.hashCode;
}
