import 'package:cue/cue.dart';
import 'package:cue/src/acts/base/animatable_act.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ValueTransformer<R, T> = R Function(ActContext context, T value);

abstract class TweenActBase<T extends Object?, R extends Object?> extends AnimtableAct<T, R> {
  final T? from;
  final T? to;
  final Keyframes<T>? frames;

  @internal
  const TweenActBase({this.from, this.to, this.frames, super.motion, super.delay, required super.reverse});

  const TweenActBase.tween({
    required T this.from,
    required T this.to,
    super.motion,
    super.delay,
    ReverseBehavior<T> super.reverse = const ReverseBehavior.mirror(),
  }) : frames = null;

  const TweenActBase.keyframed({
    required Keyframes<T> this.frames,
    super.delay,
    this.from,
    KFReverseBehavior<T> super.reverse = const KFReverseBehavior.mirror(),
  }) : to = null;

  bool get isConstant => from != null && to != null && from == to;

  R transform(ActContext context, T value);

  Animatable<R> createSingleTween(R from, R to) {
    return Tween<R>(begin: from, end: to);
  }

  static ActContext resolveMotion<T>(
    ActContext context, {
    CueMotion? motion,
    double delay = 0.0,
    required ReverseBehaviorBase reverse,
    Keyframes<T>? frames,
    bool includeFirstFrame = false,
  }) {
    CueMotion? framesMotion = switch (frames) {
      MotionKeyframes<T> m => SegmentedMotion(m.extractMotion(includeFirst: includeFirstFrame)),
      FractionalKeyframes<T> m => SegmentedMotion(
        m.extractMotion(
          includeFirst: includeFirstFrame,
          duration: m.duration ?? context.motion.baseDuration,
        ),
      ),
      _ => null,
    };

    CueMotion? reverseFramesMotion = switch (reverse.frames?.reversed) {
      MotionKeyframes<T> m => SegmentedMotion(m.extractMotion(includeFirst: true)),
      FractionalKeyframes<T> m => SegmentedMotion(
        m.extractMotion(
          includeFirst: true,
          duration: m.duration ?? context.reverseMotion.baseDuration,
        ),
      ),
      _ => framesMotion,
    };

    final forwardDelay = delay + context.delay;
    final reverseDelay = reverse.delay + context.reverseDelay;

    CueMotion forwardMotion = framesMotion ?? motion ?? context.motion;
    CueMotion reverseMotion = reverseFramesMotion ?? reverse.motion ?? motion ?? context.reverseMotion;

    if (forwardDelay != Duration.zero) {
      forwardMotion = forwardMotion.delayed(forwardDelay);
    }
    if (reverseDelay != Duration.zero) {
      reverseMotion = reverseMotion.delayed(reverseDelay);
    }
    return context.copyWith(motion: forwardMotion, reverseMotion: reverseMotion);
  }

  @override
  ActContext resolve(ActContext context) {
    return resolveMotion(
      context,
      motion: motion,
      delay: delay,
      reverse: reverse,
      frames: frames,
      includeFirstFrame: from != null,
    );
  }

  CueAnimtable<R> resolveTween(
    ActContext context, {
    required T? from,
    required T? to,
    T? iniitalkeyframe,
    R? implicitFrom,
    bool forReverse = false,
    required Keyframes<T>? keyframes,
  }) {
    if (keyframes != null) {
      final phases = switch (keyframes) {
        MotionKeyframes<T>(:final frames) => Phase.resolveMotionFrames<T, R>(
          frames,
          from: iniitalkeyframe,
          forReverse: forReverse,
          transform: (v) => transform(context, v),
        ),
        FractionalKeyframes<T>(:final frames) => Phase.resolveFractionalFrames<T, R>(
          frames,
          from: iniitalkeyframe,
          forReverse: forReverse,
          transform: (v) => transform(context, v),
        ),
      };
      return SegmentedAnimtable([
        for (final phase in phases)
          AnimatableSegment(
            animatable: createSingleTween(phase.begin, phase.end),
          ),
      ]);
    } else {
      final effectiveFrom = implicitFrom ?? transform(context, from as T);
      assert(effectiveFrom != null && to != null, 'From and to values must be provided when not using keyframes');
      if (effectiveFrom == to) {
        return AlwaysStoppedAnimatable<R>(effectiveFrom);
      } else {
        return TweenAnimtable<R>(
          createSingleTween(effectiveFrom, transform(context, to as T)),
        );
      }
    }
  }

  @override
  (CueAnimtable<R> animtable, CueAnimtable<R>? reverseAnimtable) buildTweens(ActContext context) {
    if (reverse.type == ReverseBehaviorType.exclusive) {
      return (
        resolveTween(
          context,
          from: to,
          to: from,
          iniitalkeyframe: from,
          keyframes: frames?.reversed,
          implicitFrom: context.implicitFrom as R?,
        ),
        null,
      );
    }

    final animtable = resolveTween(
      context,
      from: from,
      iniitalkeyframe: from,
      to: to,
      keyframes: frames,
      implicitFrom: context.implicitFrom as R?,
    );

    if (reverse.type == ReverseBehaviorType.to) {
      final reverseTo = reverse.to ?? reverse.frames?.lastTarget;
      final reverseAnimtable = resolveTween(
        context,
        from: reverseTo,
        to: to,
        iniitalkeyframe: frames?.lastTarget ?? to,
        keyframes: reverse.frames?.reversed,
        forReverse: true,
      );
      return (animtable, reverseAnimtable);
    }

    return (animtable, null);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is TweenActBase<T, R> &&
        other.from == from &&
        other.to == to &&
        other.delay == delay &&
        other.motion == motion &&
        other.reverse == reverse &&
        frames == other.frames;
  }

  @override
  int get hashCode => Object.hash(from, to, frames, reverse, motion, delay);
}

enum ReverseBehaviorType {
  mirror,
  exclusive,
  none,
  to
  ;

  bool get needsReverseTween => this == ReverseBehaviorType.to;
  bool get isMirror => this == ReverseBehaviorType.mirror;
  bool get isExclusive => this == ReverseBehaviorType.exclusive;
  bool get isNone => this == ReverseBehaviorType.none;
}

class KFReverseBehavior<T> extends ReverseBehaviorBase<T> {
  const KFReverseBehavior.mirror({super.delay}) : super._(type: ReverseBehaviorType.mirror);

  const KFReverseBehavior.exclusive() : super._(type: ReverseBehaviorType.exclusive);

  const KFReverseBehavior.none() : super._(type: ReverseBehaviorType.none);

  const KFReverseBehavior.to(Keyframes<T> frames, {super.delay})
    : super._(type: ReverseBehaviorType.to, frames: frames);
}

class ReverseBehavior<T> extends ReverseBehaviorBase<T> {
  const ReverseBehavior.mirror({super.motion, super.delay}) : super._(type: ReverseBehaviorType.mirror);

  const ReverseBehavior.exclusive() : super._(type: ReverseBehaviorType.exclusive);

  const ReverseBehavior.none() : super._(type: ReverseBehaviorType.none);

  const ReverseBehavior.to(T to, {super.motion, super.delay}) : super._(type: ReverseBehaviorType.to, to: to);
}

class ReverseBehaviorBase<T> {
  final ReverseBehaviorType type;
  final T? to;
  final Keyframes<T>? frames;
  final CueMotion? motion;
  final double delay;

  const ReverseBehaviorBase._({
    required this.type,
    this.to,
    this.frames,
    this.motion,
    this.delay = 0.0,
  });

  bool get needsReverseTween => type == ReverseBehaviorType.to;

  ReverseBehaviorBase<E> mapValues<E>(E Function(T value) transform) {
    return ReverseBehaviorBase<E>._(
      type: type,
      to: to == null ? null : transform(to as T),
      frames: frames?.mapValues(transform),
      motion: motion,
      delay: delay,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ReverseBehaviorBase<T> &&
        other.type == type &&
        other.to == to &&
        frames == other.frames &&
        other.motion == motion &&
        other.delay == delay;
  }

  @override
  int get hashCode => Object.hash(type, to, frames, motion, delay);
}

abstract class TweenAct<T> extends TweenActBase<T, T> {
  @internal
  const TweenAct({
    super.from,
    super.to,
    super.frames,
    super.motion,
    super.delay,
    super.reverse = const ReverseBehavior.mirror(),
  });

  const TweenAct.tween({
    required super.from,
    required super.to,
    super.motion,
    super.delay,
    super.reverse,
  }) : super.tween();

  const TweenAct.keyframed({
    required super.frames,
    super.delay,
    super.reverse,
    super.from,
  }) : super.keyframed();

  @override
  T transform(_, T value) => value;
}

class AnimatableValue<T> {
  final T from;
  final T to;

  const AnimatableValue({
    required this.from,
    required this.to,
  });

  const AnimatableValue.fixed(T value) : from = value, to = value;

  const AnimatableValue.tween({required this.from, required this.to});

  bool get isConstant => from == to;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is AnimatableValue<T> && other.from == from && other.to == to;
  }

  @override
  int get hashCode => Object.hash(from, to);
}

@internal
class TweensBuildHelper<T extends Object?> extends TweenAct<T> {
  TweensBuildHelper({super.reverse, super.from, super.to, super.frames, required this.tweenBuilder});

  final Animatable<T> Function(T from, T to) tweenBuilder;

  @override
  Animatable<T> createSingleTween(T from, T to) {
    return tweenBuilder(from, to);
  }

  @override
  Widget apply(BuildContext context, covariant CueAnimation<T> animation, Widget child) {
    throw UnimplementedError(
      'TempTweenBuilder is a utility class for building tweens and should not be used directly in the widget tree.',
    );
  }

  @override
  ActKey get key => throw UnimplementedError();
}
