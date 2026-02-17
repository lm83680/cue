import 'package:flutter/material.dart';

typedef SimulationBuilder = Simulation Function(SimulationBuildData data);

class Timing {
  final double start;
  final double end;
  static const full = Timing();

  const Timing({this.start = 0.0, this.end = 1.0})
    : assert(start >= 0 && start <= 1, 'start must be between 0 and 1'),
      assert(end >= 0 && end <= 1, 'end must be between 0 and 1'),
      assert(start <= end, 'start must be less than or equal to end');

  const Timing.endAt(this.end)
    : assert(end >= 0 && end <= 1, 'end must be between 0 and 1'),
      start = 0.0;
  const Timing.startAt(this.start)
    : assert(start >= 0 && start <= 1, 'start must be between 0 and 1'),
      end = 1.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Timing &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Timing(start: $start, end: $end)';
}

class SimulationBuildData {
  final double? velocity;
  final bool forward;
  final double progress;
  double get end => forward ? 1.0 : 0.0;

  SimulationBuildData({
    this.velocity,
    required this.forward,
    required this.progress,
  });
}
