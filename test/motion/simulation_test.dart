import 'package:cue/src/motion/simulation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CueSpringSimulation.duration', () {
    // Test basic critically damped spring (zeta = 1.0)
    test('critically damped: zero velocity, 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    // Underdamped springs (zeta < 1.0) - oscillate
    test('underdamped: zero velocity, 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        0.0,
        1.0,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    test('underdamped: positive velocity, 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        0.0,
        1.0,
        2.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    test('underdamped: negative velocity, 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        0.0,
        1.0,
        -1.5,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    // Overdamped springs (zeta > 1.0) - no oscillation, slow
    test('overdamped: zero velocity, 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 50.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    test('overdamped: positive velocity, 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 50.0, damping: 20.0),
        0.0,
        1.0,
        1.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    test('overdamped: negative velocity, 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 50.0, damping: 20.0),
        0.0,
        1.0,
        -2.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    // Different start and end values
    test('underdamped: different range (0.5->2.5)', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        0.5,
        2.5,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    test('overdamped: different range (-1.0->1.0)', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 50.0, damping: 20.0),
        -1.0,
        1.0,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    test('underdamped: reverse direction (1.0->0.0)', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        1.0,
        0.0,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    // Different frame rates: 90 fps = 1/90
    test('underdamped @ 90fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 90,
      );
      expect(refDuration(sim, stepSize: 1 / 90), closeTo(sim.duration, 1 / 90));
    });

    test('critically damped @ 90fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 90,
      );
      expect(refDuration(sim, stepSize: 1 / 90), closeTo(sim.duration, 1 / 90));
    });

    test('overdamped @ 90fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 50.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 90,
      );
      expect(refDuration(sim, stepSize: 1 / 90), closeTo(sim.duration, 1 / 90));
    });

    // Different frame rates: 120 fps = 1/120
    test('underdamped @ 120fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 120,
      );
      expect(refDuration(sim, stepSize: 1 / 120), closeTo(sim.duration, 1 / 120));
    });

    test('critically damped @ 120fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 120,
      );
      expect(refDuration(sim, stepSize: 1 / 120), closeTo(sim.duration, 1 / 120));
    });

    test('overdamped @ 120fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 50.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 120,
      );
      expect(refDuration(sim, stepSize: 1 / 120), closeTo(sim.duration, 1 / 120));
    });

    // Different frame rates: 144 fps = 1/144
    test('underdamped @ 144fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 144,
      );
      expect(refDuration(sim, stepSize: 1 / 144), closeTo(sim.duration, 1 / 144));
    });

    test('critically damped @ 144fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 100.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 144,
      );
      expect(refDuration(sim, stepSize: 1 / 144), closeTo(sim.duration, 1 / 144));
    });

    test('overdamped @ 144fps: 0->1', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 50.0, damping: 20.0),
        0.0,
        1.0,
        0.0,
        samplingStepSize: 1 / 144,
      );
      expect(refDuration(sim, stepSize: 1 / 144), closeTo(sim.duration, 1 / 144));
    });

    // Complex combinations
    test('underdamped + velocity @ 120fps: large displacement', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 2.0, stiffness: 200.0, damping: 15.0),
        0.0,
        5.0,
        3.0,
        samplingStepSize: 1 / 120,
      );
      expect(refDuration(sim, stepSize: 1 / 120), closeTo(sim.duration, 1 / 120));
    });

    test('underdamped: high stiffness', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 1.0, stiffness: 500.0, damping: 30.0),
        0.0,
        1.0,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });

    test('overdamped: high mass', () {
      final sim = CueSpringSimulation(
        SpringDescription(mass: 5.0, stiffness: 50.0, damping: 30.0),
        0.0,
        1.0,
        0.0,
      );
      expect(refDuration(sim), closeTo(sim.duration, 1 / 60));
    });
  });
}



// mimic an actual ticker by incrementing time until the simulation reports it's done, 
//then return the total elapsed time
double refDuration(SpringSimulation sim, {double stepSize = 1 / 60}) {
  double t = 0.0;
  while (t < 100.0) {
    if (sim.isDone(t)) return t;
    t += stepSize;
  }
  return t;
}
