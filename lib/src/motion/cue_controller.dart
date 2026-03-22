import 'package:cue/src/motion/cue_motion.dart';
import 'package:cue/src/timeline/timeline.dart';
import 'package:cue/src/timeline/track/track.dart';
import 'package:cue/src/timeline/track/track_config.dart';
import 'package:flutter/material.dart';

class CueController extends AnimationController {
  final CueTimeline _timeline;

  CueTimeline get timeline => _timeline;

  CueController({
    super.debugLabel,
    super.value = 0.0,
    super.animationBehavior,
    required super.vsync,
    required CueMotion motion,
    CueMotion? reverseMotion,
  }) : _timeline = CueTimelineImpl(
         CueTrackImpl(motion, reverseMotion: reverseMotion ?? motion),
       ),
       super.unbounded();

  void updateMotion(CueMotion newMotion, {CueMotion? newReverseMotion}) {
    final mainTrack = timeline.mainTrack;
    if (newMotion != mainTrack.motion || newReverseMotion != mainTrack.reverseMotion) {
      timeline.resetTracks(TrackConfig(motion: newMotion, reverseMotion: newReverseMotion ?? newMotion));
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  set value(double newValue) {
    final forward = newValue >= value;
    setProgress(newValue, forward: forward);
  }

  void setProgress(double newValue, {bool forward = true}) {
    assert(newValue >= 0.0 && newValue <= 1.0, 'The animation value must be between 0.0 and 1.0. Received: $newValue');
    timeline.setProgress(newValue, forward: forward);
    super.value = newValue;
  }

  @override
  AnimationStatus get status => timeline.status;

  @override
  void addStatusListener(AnimationStatusListener listener) {
    timeline.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    timeline.removeStatusListener(listener);
  }

  @override
  Animation<double> get view => _timeline.mainTrack;

  @override
  TickerFuture forward({double? from}) {
    _timeline.willAnimate(forward: true);
    if (from != null) {
      assert(from >= 0.0 && from <= 1.0, 'The "from" value must be between 0.0 and 1.0. Received: $from');
      value = from;
    }
    _timeline.prepare(forward: true, from: from);
    return super.animateWith(_timeline);
  }

  @override
  TickerFuture reverse({double? from}) {
    _timeline.willAnimate(forward: false);
    if (from != null) {
      assert(from >= 0.0 && from <= 1.0, 'The "from" value must be between 0.0 and 1.0. Received: $from');
      value = from;
    }
    _timeline.prepare(forward: false, from: from);
    return super.animateBackWith(_timeline);
  }

  @override
  TickerFuture animateWith(Simulation simulation) {
    throw UnsupportedError('animateWith is not supported by CueAnimationController. Use forward instead.');
  }

  @override
  TickerFuture animateBackWith(Simulation simulation) {
    throw UnsupportedError('animateBackWith is not supported by CueAnimationController. Use reverse instead.');
  }

  @override
  void reset() => timeline.reset();

  @override
  TickerFuture repeat({double? min, double? max, bool reverse = false, int? count, Duration? period}) {
    if (period != null || min != null || max != null) {
      throw UnsupportedError(
        'CueController does does not support time-based repetitio because physics-based animations is a first-class citizen. You may only specify count and reverse parameters. Received: period: $period, min: $min, max: $max',
      );
    }
    assert(count == null || count > 0, 'The "count" value must be greater than 0. Received: $count');
    _timeline.willAnimate(forward: true);
    _timeline.prepareForRepeat(RepeatConfig(reverse: reverse, count: count));
    return super.animateWith(_timeline);
  }

  @override
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) {
    throw UnsupportedError(
      'fling is not supported by CueController. Use forward or reverse instead.',
    );
  }
}
