import 'package:cue/src/motion/simulation.dart';
import 'package:flutter/material.dart';
import 'spring_motion.dart';

abstract class CueMotion {
  const CueMotion();

  int get totalPhases => 1;

  Duration get baseDuration;

  CueSimulation build(bool forward, int phase, double progress, double? velocity);

  CueSimulation buildBase([bool forward = true]) => build(forward, 0, forward ? 0.0 : 1.0, 0.0);

  bool get isTimed => this is TimedMotion;

  bool get isSimulation => this is SimulationMotion;

  const factory CueMotion.curved(
    Duration duration, {
    required Curve curve,
  }) = TimedMotion.curved;

  const factory CueMotion.linear(Duration duration) = TimedMotion;

  static const none = TimedMotion(Duration.zero);

  static const CueMotion defaultTime = TimedMotion(Duration(milliseconds: 300));

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
  final Curve? curve;
  const TimedMotion(this.baseDuration) : curve = null;
  const TimedMotion.curved(this.baseDuration, {required Curve this.curve});

  @override
  final Duration baseDuration;

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
  CueSimulation build(bool forward, int phase, double progress, double? velocity) {
    return CurvedSimulation(
      baseDuration: baseDuration,
      curve: curve ?? Curves.linear,
      from: progress,
      to: forward ? 1.0 : 0.0,
    );
  }
}

abstract class SimulationMotion<S extends CueSimulation> extends CueMotion {
  const SimulationMotion();
}
