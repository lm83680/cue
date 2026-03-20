import 'dart:math';

import 'package:cue/cue.dart';
import 'package:cue/src/timeline/track/track.dart';
import 'package:cue/src/timeline/track/track_config.dart';
import 'package:flutter/material.dart';

class CueTimelineImpl extends CueTimeline with AnimationLocalStatusListenersMixin {
  CueTimelineImpl(CueTrack main)
    : super({
        TrackConfig(
          motion: main.motion,
          reverseMotion: main.reverseMotion,
        ): main,
      });

  @override
  void addOnPrepareListener(ValueChanged<bool> listener) {
    _onPrepareNotifier.addEventListener(listener);
  }

  @override
  void removeOnPrepareListener(ValueChanged<bool> listener) {
    _onPrepareNotifier.removeEventListener(listener);
  }

  final _onPrepareNotifier = EventNotifier<bool>();

  double _lastT = 0.0;

  @override
  CueTrack get mainTrack => tracks.values.first;

  @override
  CueTrack trackFor(TrackConfig config) {
    if (config == mainTrackConfig) {
      return mainTrack;
    }
    final animation = tracks.putIfAbsent(config, () => buildTrack(config));
    animation.prepare(
      forward: mainTrack.isForwardOrCompleted,
      from: mainTrack.progress,
      exteranlVelocity: mainTrack.velocity,
    );
    return animation;
  }

  @override
  AnimationStatus get status => _status;

  AnimationStatus _status = AnimationStatus.dismissed;

  @override
  void release(CueTrack anim) {}

  @override
  void setProgress(double value, {bool forward = true}) {
    for (final anim in tracks.values) {
      anim.setProgress(value, forward: forward);
    }
    _updateStatus();
  }

  void _updateStatus() {
    bool allCompleted = true;
    bool allDismissed = true;

    AnimationStatus currentStatus = _status;

    for (final d in tracks.values) {
      final s = d.status;

      if (s != AnimationStatus.completed) {
        allCompleted = false;
      }
      if (s != AnimationStatus.dismissed) {
        allDismissed = false;
      }

      if (s == AnimationStatus.forward) {
        currentStatus = AnimationStatus.forward;
        break;
      }
      if (s == AnimationStatus.reverse) {
        currentStatus = AnimationStatus.reverse;
        break;
      }
    }

    if (allCompleted) currentStatus = AnimationStatus.completed;
    if (allDismissed) currentStatus = AnimationStatus.dismissed;

    if (currentStatus != _status) {
      _status = currentStatus;
      notifyStatusListeners(_status);
    }
  }

  @override
  void prepare({required bool forward, double? from}) {
    _onPrepareNotifier.fireEvent(forward);
    _lastT = 0.0;
    for (final anim in tracks.values) {
      anim.prepare(forward: forward, from: from);
    }
    _updateStatus();
  }

  @override
  double x(double time) {
    final dt = time - _lastT;
    _lastT = time;
    if (dt > 0) {
      for (final anim in tracks.values) {
        anim.tick(dt);
      }
    }
    _updateStatus();
    return progress;
  }

  @override
  double dx(double time) => mainTrack.velocity;

  @override
  bool isDone(double time) => tracks.values.every((anim) => anim.isDone);

  @override
  CueTrack buildTrack(TrackConfig config) {
    return CueTrackImpl(
      config.motion,
      reverseMotion: config.reverseMotion,
      reverseType: config.reverseType,
    );
  }

  @override
  void didRegisterListener() {
    // TODO: implement didRegisterListener
  }

  @override
  void didUnregisterListener() {
    // TODO: implement didUnregisterListener
  }
}

abstract class CueTimeline extends Simulation {
  CueTrack trackFor(TrackConfig config);

  void prepare({required bool forward, double? from});

  void setProgress(double value, {bool forward = true});

  void release(CueTrack anim);

  AnimationStatus get status;

  double get progress {
    final progressList = tracks.values.map((track) => track.progress);
     if (status == AnimationStatus.reverse) {
      return progressList.fold(0.0, max).clamp(0.0, 1.0);
    } else {
      return progressList.fold(double.infinity, min).clamp(0.0, 1.0);
    }
  }

  final Map<TrackConfig, CueTrack> tracks;

  CueTimeline(this.tracks);

  CueTrack buildTrack(TrackConfig config);

  TrackConfig get mainTrackConfig => tracks.keys.first;

  CueTrack get mainTrack;

  void reset(TrackConfig config) {
    tracks.clear();
    tracks[config] = buildTrack(config);
  }

  void addOnPrepareListener(ValueChanged<bool> listener);
  void removeOnPrepareListener(ValueChanged<bool> listener);
  void addStatusListener(AnimationStatusListener listener);
  void removeStatusListener(AnimationStatusListener listener);
}
