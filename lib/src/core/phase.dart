import 'package:cue/cue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class KeyframeBase<T extends Object?> {
  final T value;
  const KeyframeBase._(this.value);
}

class FractionalKeyframe<T> extends KeyframeBase<T> {
  final double at;
  final Curve? curve;

  const FractionalKeyframe(super.value, {required this.at, this.curve})
    : assert(at >= 0.0 && at <= 1.0, 'Relative Keyframe time must be between 0 and 1'),
      super._();

  const FractionalKeyframe.key(super.value, {required this.at, this.curve})
    : assert(at >= 0.0 && at <= 1.0, 'Relative Keyframe time must be between 0 and 1'),
      super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FractionalKeyframe &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          at == other.at &&
          curve == other.curve;

  @override
  int get hashCode => Object.hash(value, at, curve);

  FractionalKeyframe<T> copyWith({T? value, double? at, Curve? curve}) {
    return FractionalKeyframe<T>(
      value ?? this.value,
      at: at ?? this.at,
      curve: curve ?? this.curve,
    );
  }

  @override
  String toString() {
    return 'FractionalKeyframe(value: $value, at: $at, curve: $curve)';
  }
}

class Keyframe<T> extends KeyframeBase<T> {
  final CueMotion motion;

  const Keyframe(super.value, {required this.motion}) : super._();

  const Keyframe.key(super.value, {required this.motion}) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Keyframe && runtimeType == other.runtimeType && value == other.value && motion == other.motion;

  @override
  int get hashCode => Object.hash(value, motion);

  Keyframe<T> copyWith({T? value, CueMotion? motion}) {
    return Keyframe<T>(
      value ?? this.value,
      motion: motion ?? this.motion,
    );
  }

  @override
  String toString() {
    return 'Keyframe(value: $value, motion: $motion)';
  }
}

sealed class Keyframes<T> {
  const factory Keyframes(List<Keyframe<T>> frames) = MotionKeyframes<T>;

  const factory Keyframes.fractional(
    List<FractionalKeyframe<T>> frames, {
    Duration? duration,
  }) = FractionalKeyframes<T>;

  T get lastTarget;

  Keyframes<E> mapValues<E>(E Function(T value) transform);

  List<T> get values;

  Keyframes<T> get reversed;
}

final class MotionKeyframes<T> implements Keyframes<T> {
  final List<Keyframe<T>> frames;
  const MotionKeyframes(this.frames);

  @override
  List<T> get values => List.unmodifiable(frames.map((f) => f.value));

  List<CueMotion> extractMotion({bool includeFirst = false}) {
    final motions = frames.map((f) => f.motion);
    return List.unmodifiable(includeFirst ? motions : motions.skip(1));
  }

  @override
  MotionKeyframes<E> mapValues<E>(E Function(T value) transform) {
    return MotionKeyframes<E>(
      List.unmodifiable(
        frames.map(
          (frame) => Keyframe<E>(
            transform(frame.value),
            motion: frame.motion,
          ),
        ),
      ),
    );
  }

  @override
  MotionKeyframes<T> get reversed {
    return MotionKeyframes<T>(List.unmodifiable(frames.reversed));
  }

  @override
  T get lastTarget {
    assert(frames.isNotEmpty, 'Keyframes must have at least one frame to determine last target');
    return frames.last.value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionKeyframes && runtimeType == other.runtimeType && listEquals(frames, other.frames);

  @override
  int get hashCode => Object.hashAll(frames);

  @override
  String toString() {
    return 'MotionKeyframes(frames: $frames)';
  }
}

final class FractionalKeyframes<T> implements Keyframes<T> {
  final List<FractionalKeyframe<T>> frames;
  final Duration? duration;
  const FractionalKeyframes(this.frames, {this.duration});

  @override
  List<T> get values => List.unmodifiable(frames.map((f) => f.value));

  @override
  FractionalKeyframes<E> mapValues<E>(E Function(T value) transform) {
    return FractionalKeyframes<E>(
      List.unmodifiable(
        frames.map(
          (frame) => FractionalKeyframe<E>(
            transform(frame.value),
            at: frame.at,
            curve: frame.curve,
          ),
        ),
      ),
      duration: duration,
    );
  }

  @override
  FractionalKeyframes<T> get reversed {
    return FractionalKeyframes<T>(
      List.unmodifiable(
        frames.reversed.map((frame) => frame.copyWith(at: 1.0 - frame.at)),
      ),
      duration: duration,
    );
  }

  @override
  T get lastTarget {
    assert(frames.isNotEmpty, 'Keyframes must have at least one frame to determine last target');
    return frames.last.value;
  }

  List<CueMotion> extractMotion({bool includeFirst = false, required Duration duration}) {
    // Remove duplicates (keep last) and track curves
    final Map<double, Curve?> frameCurves = {};

    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final clampedTime = frame.at.clamp(0.0, 1.0);
      frameCurves[clampedTime] = frame.curve;
    }

    // Sort by time
    final sortedTimes = frameCurves.keys.toList()..sort();

    // Handle edge cases
    if (sortedTimes.isEmpty) {
      return [];
    }

    if (!includeFirst && sortedTimes.length < 2) {
      return [];
    }

    final List<CueMotion> motions = [];

    // Add motion to first frame if requested
    if (includeFirst) {
      final firstTime = sortedTimes.first;
      final firstCurve = frameCurves[firstTime] ?? Curves.linear;
      motions.add(CueMotion.curved(duration * firstTime, curve: firstCurve));
    }

    // Add motions between consecutive frames
    for (int i = 0; i < sortedTimes.length - 1; i++) {
      final currentTime = sortedTimes[i];
      final nextTime = sortedTimes[i + 1];
      final weight = nextTime - currentTime;
      final curve = frameCurves[nextTime] ?? Curves.linear;
      motions.add(CueMotion.curved(duration * weight, curve: curve));
    }

    return motions;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FractionalKeyframes &&
          runtimeType == other.runtimeType &&
          listEquals(frames, other.frames) &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(Object.hashAll(frames), duration);

  @override
  String toString() {
    return 'FractionalKeyframes(frames: $frames, duration: $duration)';
  }
}

class Phase<T extends Object?> {
  final T begin;
  final T end;

  const Phase({
    required this.begin,
    required this.end,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Phase && runtimeType == other.runtimeType && begin == other.begin && end == other.end;

  @override
  int get hashCode => Object.hash(begin, end);

  bool get isAlwaysStopped => begin == end;

  static List<Phase<R>> resolveFractionalFrames<T extends Object?, R extends Object?>(
    List<FractionalKeyframe<T>> frames, {
    T? from,
    bool forReverse = false,
    required R Function(T value) transform,
  }) {
    if (frames.isEmpty) {
      return [];
    }

    // Remove duplicates (keep last) and track curves
    final Map<double, T> uniqueFrames = {};
    final Map<double, Curve?> frameCurves = {};

    // Without an explicit starting value, the first frame is the starting point at t=0.
    if (from == null) {
      uniqueFrames[0.0] = frames[0].value;
      frameCurves[0.0] = null;
    }

    for (int i = from == null ? 1 : 0; i < frames.length; i++) {
      final frame = frames[i];
      final clampedTime = frame.at.clamp(0.0, 1.0);
      uniqueFrames[clampedTime] = frame.value;
      frameCurves[clampedTime] = frame.curve;
    }

    // Sort by time
    final sortedTimes = uniqueFrames.keys.toList()..sort();

    // Handle single keyframe case without an explicit starting value.
    if (from == null && sortedTimes.length < 2) {
      final time = sortedTimes.first;
      final value = transform(uniqueFrames[time] as T);

      return [
        Phase(begin: value, end: value),
      ];
    }

    final resolvedFrames = <FractionalKeyframe<T>>[
      for (final time in sortedTimes)
        FractionalKeyframe<T>(
          uniqueFrames[time] as T,
          at: time,
          curve: frameCurves[time],
        ),
    ];

    if (from != null) {
      final fromFrame = FractionalKeyframe<T>(
        from,
        at: forReverse ? 1.0 : 0.0,
      );
      if (forReverse) {
        resolvedFrames.add(fromFrame);
      } else {
        resolvedFrames.insert(0, fromFrame);
      }
    }

    final List<Phase<R>> phases = [];
    for (int i = 1; i < resolvedFrames.length; i++) {
      phases.add(
        Phase(
          begin: transform(resolvedFrames[i - 1].value),
          end: transform(resolvedFrames[i].value),
        ),
      );
    }

    return phases;
  }

  static List<Phase<R>> resolveMotionFrames<T extends Object?, R extends Object?>(
    List<Keyframe<T>> frames, {
    T? from,
    bool forReverse = false,
    required R Function(T value) transform,
  }) {
    if (frames.isEmpty) {
      return [];
    }
    final mFrames = List.from(frames);
    final List<Phase<R>> phases = [];
    if (from != null) {
      if (forReverse) {
        mFrames.add(Keyframe(from, motion: CueMotion.none));
      } else {
        mFrames.insert(0, Keyframe(from, motion: CueMotion.none));
      }
    }

    for (int i = 1; i < mFrames.length; i++) {
      final currentFrame = mFrames[i];
      phases.add(
        Phase(
          begin: transform(mFrames[i - 1].value),
          end: transform(currentFrame.value),
        ),
      );
    }

    return phases;
  }
}
