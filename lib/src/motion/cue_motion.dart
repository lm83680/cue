import 'package:cue/cue.dart';
import 'package:cue/src/motion/simulation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'spring_motion.dart';

abstract class CueMotion {
  const CueMotion();

  int get totalPhases => 1;

  double get baseDuration;

  CueSimulation build(SimulationBuildData data);

  CueSimulation buildBase({bool forward = true, int? phase}) => switch (forward) {
    true => build(SimulationBuildData.forward(phase: phase ?? 0)),
    false => build(SimulationBuildData.reverse(phase: phase ?? totalPhases - 1)),
  };

  bool get isTimed => this is TimedMotion;

  bool get isSimulation => this is SimulationMotion;

  CueMotion delayed(double delay) => DelayedMotion(this, delay);

  const factory CueMotion.curved(
    double duration, {
    required Curve curve,
  }) = TimedMotion.curved;

  const factory CueMotion.linear(double duration) = TimedMotion;

  static const none = TimedMotion(0.0);

  static const CueMotion defaultTime = TimedMotion(0.3);

  factory CueMotion.spring({
    double duration,
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
  final Curve? curve;
  const TimedMotion(this.baseDuration) : curve = null;
  const TimedMotion.curved(this.baseDuration, {required Curve this.curve});

  @override
  final double baseDuration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimedMotion &&
          runtimeType == other.runtimeType &&
          baseDuration == other.baseDuration &&
          curve == other.curve;

  @override
  int get hashCode => baseDuration.hashCode ^ curve.hashCode;

  @override
  CueSimulation build(SimulationBuildData data) {
    return CurvedSimulation(
      baseDuration: baseDuration,
      curve: curve ?? Curves.linear,
      from: data.startValue,
      to: data.endValue,
    );
  }

  @override
  String toString() {
    if (curve == null) {
      return 'TimedMotion(duration: $baseDuration)';
    } else {
      return 'TimedMotion(duration: $baseDuration, curve: $curve)';
    }
  }
}

abstract class SimulationMotion<S extends CueSimulation> extends CueMotion {
  const SimulationMotion();
}

class SegmentedMotion extends CueMotion {
  final List<CueMotion> motions;
  const SegmentedMotion(this.motions);

  @override
  double get baseDuration => motions.fold(
    0.0,
    (total, motion) => total + motion.baseDuration,
  );

  @override
  int get totalPhases => motions.length;

  @override
  CueSimulation build(SimulationBuildData data) {
    return SegmentedSimulation(
      motions: motions,
      forward: data.forward,
      initialPhase: data.phase,
      startValue: data.startValue,
      velocity: data.velocity ?? 0.0,
      endPhase: data.endPhase ?? (data.forward ? motions.length - 1 : 0),
      endValue: data.endValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentedMotion && runtimeType == other.runtimeType && listEquals(motions, other.motions);

  @override
  int get hashCode => Object.hashAll(motions);
}

@visibleForTesting
class DelayedMotion extends CueMotion {
  final CueMotion base;
  final double delay;
  const DelayedMotion(this.base, this.delay);

  @override
  CueMotion delayed(double delay) => DelayedMotion(base, delay + this.delay);

  @override
  double get baseDuration => base.baseDuration + delay;

  @override
  CueSimulation build(SimulationBuildData data) {
    final baseSim = base.build(data);
     double delay = this.delay;
    if (data.startProgress case final progress?) {
      final totalDuration = delay + baseSim.duration;
      final elapsedTime = data.forward ? progress * totalDuration : (1.0 - progress) * totalDuration;
      delay = (delay - elapsedTime).clamp(0.0, double.infinity);
    }
    return DelayedSimulation(base: baseSim, delay: delay);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DelayedMotion && runtimeType == other.runtimeType && base == other.base && delay == other.delay;

  @override
  int get hashCode => Object.hash(base, delay);

  @override
  String toString() => 'DelayedMotion(base: $base, delay: $delay)';
}

class SimulationBuildData {
  final bool forward;
  final int phase;
  final int? endPhase;
  final double? _endValue;
  final double startValue;
  final double? startProgress;
  final double? velocity;

  double get endValue => _endValue ?? (forward ? 1.0 : 0.0);

  const SimulationBuildData({
    required this.forward,
    required this.startValue,
    this.phase = 0,
    this.endPhase,
    this.velocity,
    this.startProgress,

    double? endValue,
  }) : _endValue = endValue;

  const SimulationBuildData.forward({
    this.phase = 0,
    this.endPhase,
    this.startValue = 0.0,
    this.velocity,
    this.startProgress,
    double? endValue,
  }) : forward = true,
       _endValue = endValue;

  const SimulationBuildData.reverse({
    this.phase = 0,
    this.endPhase,
    this.startValue = 1.0,
    this.velocity,
    this.startProgress,
    double? endValue,
  }) : forward = false,
       _endValue = endValue;
}
