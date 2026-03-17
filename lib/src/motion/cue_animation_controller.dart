import 'package:cue/src/motion/cue_motion.dart';
import 'package:cue/src/motion/timeline.dart';
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
         CueTrackImpl(motion, reverseMotion: reverseMotion),
       ),
       super.unbounded();

  AnimationStatusListener? _statusListener;

  void updateMotion(CueMotion newMotion, {CueMotion? newReverseMotion}) {
    final mainTrack = timeline.mainTrack;
    if (newMotion != mainTrack.motion || newReverseMotion != mainTrack.reverseMotion) {
      timeline.reset(TrackConfig(motion: newMotion, reverseMotion: newReverseMotion));
    }
  }

  @override
  void dispose() {
    if (_statusListener != null) {
      removeStatusListener(_statusListener!);
    }
    super.dispose();
  }

  @override
  set value(double newValue) {
    if (newValue == value) return;
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
    if (from != null) {
      assert(from >= 0.0 && from <= 1.0, 'The "from" value must be between 0.0 and 1.0. Received: $from');
      value = from;
    }
    _timeline.prepare(forward: true, from: from);
    return super.animateWith(_timeline);
  }

  @override
  TickerFuture reverse({double? from}) {
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
  void reset() => timeline.setProgress(0.0);

  @override
  void stop({bool canceled = true}) {
    if (_statusListener != null) {
      super.removeStatusListener(_statusListener!);
    }
    super.stop(canceled: canceled);
  }

  @override
  TickerFuture repeat({double? min, double? max, bool reverse = false, int? count, Duration? period}) {
    if (_statusListener != null) {
      super.removeStatusListener(_statusListener!);
    }
    int loopCount = 0;
    _statusListener = (status) {
      if (status == AnimationStatus.completed) {
        loopCount++;
        if (count != null && loopCount >= count) {
          return;
        }
        if (reverse) {
          this.reverse();
        } else {
          forward();
        }
      } else if (status == AnimationStatus.dismissed && reverse) {
        forward();
      }
    };
    super.addStatusListener(_statusListener!);
    forward();
    return TickerFuture.complete();
  }
}
