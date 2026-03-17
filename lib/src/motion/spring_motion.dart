import 'package:cue/src/motion/cue_motion.dart';
import 'package:flutter/physics.dart';

// holds default values for spring simulation
const double _kStandardIosStiffness = 522.35;
const double _kStandardIosDamping = 45.7099552;
const Tolerance _kStandardIosTolerance = Tolerance(velocity: 0.03);
const Tolerance _kDefaultTolerance = Tolerance(distance: 0.01, velocity: 0.03);

class CueSpringSimulation extends SpringSimulation with CueSimulation {
  CueSpringSimulation(
    super.spring,
    super.start,
    super.end,
    super.velocity, {
    super.tolerance,
    super.snapToEnd,
  });

  double? _duration;

  @override
  double get duration => _duration ??= calculateSettleDuration();

  double calculateSettleDuration({double stepSize = 1 / 60}) {
    double t = 0.0;
    final tolerance = this.tolerance;
    while (t < 100.0) {
      final x = this.x(t);
      final v = dx(t);
      if ((x - 1.0).abs() < tolerance.distance && v.abs() < tolerance.velocity) return t;
      t += stepSize;
    }
    return t;
  }

  @override
  int get phase => 0;

  double _progress = 0.0;

  @override
  double get lastX => _progress;

  @override
  double x(double time) {
    return _progress = super.x(time);
  }
}

final class Spring extends SimulationMotion<CueSpringSimulation> {
  final double mass;
  final double stiffness;
  final double damping;
  final Tolerance tolerance;
  final bool snapToEnd;

  const Spring.custom({
    this.mass = 1.0,
    required this.stiffness,
    required this.damping,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  SpringDescription get springDescription => SpringDescription(
    mass: mass,
    stiffness: stiffness,
    damping: damping,
  );

  @override
  CueSpringSimulation build(bool forward, int phase, double progress, double? velocity) {
    return CueSpringSimulation(
      springDescription,
      progress,
      forward ? 1.0 : 0.0,
      velocity ?? 0.0,
      tolerance: tolerance,
      snapToEnd: snapToEnd,
    );
  }

  Spring copyWith({
    double? mass,
    double? stiffness,
    double? damping,
    Tolerance? tolerance,
    bool? snapToEnd,
  }) {
    return Spring.custom(
      mass: mass ?? this.mass,
      stiffness: stiffness ?? this.stiffness,
      damping: damping ?? this.damping,
      tolerance: tolerance ?? this.tolerance,
      snapToEnd: snapToEnd ?? this.snapToEnd,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Spring &&
        other.mass == mass &&
        other.stiffness == stiffness &&
        other.damping == damping &&
        other.tolerance == tolerance &&
        other.snapToEnd == snapToEnd;
  }

  @override
  int get hashCode {
    return Object.hash(mass, stiffness, damping, tolerance, snapToEnd);
  }

  const Spring.iosDefault({
    this.mass = 1.0,
    this.stiffness = _kStandardIosStiffness,
    this.damping = _kStandardIosDamping,
    this.tolerance = _kStandardIosTolerance,
    this.snapToEnd = true,
  });

  const Spring.smooth({
    this.mass = 1.0,
    this.stiffness = 157.91,
    this.damping = 25.13,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  const Spring.stiff({
    this.mass = 1.0,
    this.stiffness = 438.65,
    this.damping = 41.89,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  const Spring.soft({
    this.mass = 1.0,
    this.stiffness = 100.0,
    this.damping = 10.0,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  const Spring.interactive({
    this.mass = 1.0,
    this.stiffness = 1754.17,
    this.damping = 72.11,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  const Spring.bouncy({
    this.mass = 1.0,
    this.stiffness = 157.91,
    this.damping = 15.08,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  const Spring.wobbly({
    this.mass = 1.0,
    this.stiffness = 180.0,
    this.damping = 12.0,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  const Spring.gentle({
    this.mass = 1.0,
    this.stiffness = 61.69,
    this.damping = 15.71,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  });

  factory Spring({
    Duration duration = const Duration(milliseconds: 500),
    double bounce = 0,
  }) {
    final desc = SpringDescription.withDurationAndBounce(
      duration: duration,
      bounce: bounce,
    );
    return Spring.custom(
      mass: desc.mass,
      stiffness: desc.stiffness,
      damping: desc.damping,
    );
  }

  @override
  Duration get duration {
    final sim = build(true, 0, 0.0, 0.0);
    return Duration(milliseconds: (sim.calculateSettleDuration() * 1000).round());
  }

  // double calculateSettleDurationHybrid(SpringSimulation sim, SpringDescription desc, {int samples = 60}) {
  //   final stepSize = 1 / samples;
  //   final s = desc;
  //   final m = s.mass;
  //   final k = s.stiffness;
  //   final c = s.damping;

  //   final x0 = sim.x(0);
  //   final target = 1.0;
  //   final deltaX = (x0 - target).abs();
  //   final tol = sim.tolerance.distance;

  //   if (deltaX < tol) return 0.0;

  //   // damping ratio
  //   final zeta = c / (2 * sqrt(k * m));
  //   final omegaN = sqrt(k / m);

  //   double tEstimate;

  //   if (zeta < 1.0) {
  //     // underdamped: use envelope to estimate
  //     tEstimate = -log(tol / (deltaX * sqrt(1 - zeta * zeta))) / (zeta * omegaN);
  //   } else {
  //     // critically or overdamped
  //     tEstimate = -log(tol / deltaX) / (c / (2 * m));
  //   }

  //   // clamp estimate to positive
  //   tEstimate = tEstimate.clamp(0.0, double.infinity);

  //   // now step a few ticks from tEstimate - 2*stepSize to capture exact Flutter settle
  //   double t = max(0.0, tEstimate - 2 * stepSize);
  //   final maxTime = tEstimate + 2.0; // safety cap

  //   while (t < maxTime) {
  //     final x = sim.x(t);
  //     final v = sim.dx(t);
  //     if ((x - target).abs() < tol && v.abs() < sim.tolerance.velocity) {
  //       return t;
  //     }
  //     t += stepSize;
  //   }

  //   // fallback
  //   return t;
  // }
}
