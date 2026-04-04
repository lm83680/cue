import 'package:cue/cue.dart';
import 'package:cue/src/timeline/event_notifier.dart';
import 'package:cue/src/timeline/track/track.dart';
import 'package:cue/src/timeline/track/track_config.dart';
import 'package:flutter/material.dart';

class CueTimelineImpl extends CueTimeline with AnimationLocalStatusListenersMixin {
  @override
  final TrackConfig defaultConfig;

  @override
  Map<TrackConfig, TrackEntry> get tracks => _tracks;

  late final Map<TrackConfig, TrackEntry> _tracks;

  CueTimelineImpl(this.defaultConfig) {
    _tracks = {
      defaultConfig: TrackEntry(buildTrack(defaultConfig)),
    };
  }

  @override
  CueTrack get mainTrack => _tracks[defaultConfig]!.track;

  factory CueTimelineImpl.fromMotion(CueMotion motion, {CueMotion? reverseMotion}) {
    final config = TrackConfig(motion: motion, reverseMotion: reverseMotion ?? motion);
    return CueTimelineImpl(config);
  }

  @override
  void willAnimate({required bool forward}) {
    _eventsNotifier.fireEvent(TimelineWillAnimateEvent(forward));
  }

  final _eventsNotifier = EventNotifier<TimelineEvent>();

  double _lastT = 0.0;
  double _cycleOffset = 0.0;
  int _listenres = 0;
  RepeatConfig? _repeatConfig;

  double? _forwardDuration;
  double? _reverseDuration;

  double _calculateForwardDuration() {
    double maxDuration = 0.0;
    for (final entry in tracks.values) {
      if (entry.track.forwardDuration > maxDuration) {
        maxDuration = entry.track.forwardDuration;
      }
    }
    return maxDuration;
  }

  double _calculateReverseDuration() {
    double maxDuration = 0.0;
    for (final entry in tracks.values) {
      if (entry.track.reverseDuration > maxDuration) {
        maxDuration = entry.track.reverseDuration;
      }
    }
    return maxDuration;
  }

  @override
  double get forwardDuration => _forwardDuration ??= _calculateForwardDuration();

  @override
  double get reverseDuration => _reverseDuration ??= _calculateReverseDuration();

  @override
  void reset() {
    _repeatConfig = null;
    _cycleOffset = 0.0;
    setProgress(0.0, forward: true);
  }

  @override
  void resetTracks(TrackConfig newDefaultConfig) {
    // Note: defaultConfig is final so we can't change it.
    // This implementation clears extra tracks but doesn't change the main track.
    _tracks.clear();
    _forwardDuration = null;
    _reverseDuration = null;
    // Recreate default track
    _tracks[defaultConfig] = TrackEntry(buildTrack(defaultConfig));
  }

  @override
  (CueTrack track, ReleaseToken token) obtainTrack(TrackConfig config) {
    final entry = tracks.putIfAbsent(
      config,
      () => TrackEntry(buildTrack(config)),
    );
    _forwardDuration = null;
    _reverseDuration = null;
    entry.track.prepare(
      forward: status.isForwardOrCompleted,
      from: progress,
      exteranlVelocity: dx(_lastT),
    );
    final token = ReleaseToken(config, this);
    entry.addToken(token);
    return (entry.track, token);
  }

  @override
  void release(ReleaseToken token) {
    final entry = tracks[token.config];
    if (entry == null) return;
    entry.removeToken(token);
    if (token.config != defaultConfig && entry.canRelease) {
      tracks.remove(token.config);
      _forwardDuration = null;
      _reverseDuration = null;
    }
  }

  @override
  AnimationStatus get status => _status;

  AnimationStatus _status = AnimationStatus.dismissed;

  @override
  double get progress {
    if (tracks.isEmpty) {
      return 0.0;
    }
    final isForward = status.isForwardOrCompleted;
    var longest = tracks.values.first;
    for (final entry in tracks.values) {
      if ((isForward ? entry.track.forwardDuration : entry.track.reverseDuration) >
          (isForward ? longest.track.forwardDuration : longest.track.reverseDuration)) {
        longest = entry;
      }
    }
    return longest.track.progress.clamp(0.0, 1.0);
  }

  @override
  void setProgress(double value, {bool forward = true, bool forceLinear = false}) {
    _repeatConfig = null;
    if (forward) {
      _setForwardProgress(value, forceLinear: forceLinear);
    } else {
      _setReverseProgress(value, forceLinear: forceLinear);
    }
    _updateStatus();
  }

  void _setForwardProgress(double value, {bool forceLinear = false}) {
    final timelineDuration = forwardDuration;
    for (final entry in tracks.entries) {
      final track = entry.value.track;
      final normalized = (value * timelineDuration / track.forwardDuration).clamp(0.0, 1.0);
      track.setProgress(normalized, forward: true, forceLinear: forceLinear);
    }
  }

  void _setReverseProgress(double value, {bool forceLinear = false}) {
    final timelineDuration = reverseDuration;
    for (final entry in tracks.entries) {
      final track = entry.value.track;
      final idleRatio = (1.0 - (track.reverseDuration / timelineDuration));
      final adjustedValue = (value - idleRatio);
      final normalized = (adjustedValue / (track.reverseDuration / timelineDuration)).clamp(0.0, 1.0);
      track.setProgress(normalized, forward: false, forceLinear: forceLinear);
    }
  }

  void _updateStatus() {
    bool allCompleted = true;
    bool allDismissed = true;

    AnimationStatus currentStatus = _status;

    for (final entry in tracks.values) {
      final s = entry.track.status;

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
  void prepare({required bool forward, double? from, double? target, double? velocity}) {
    _repeatConfig = null;
    _cycleOffset = 0.0;
    fireEvent(TimelinePrepareEvent(forward));
    _lastT = 0.0;
    _prepareInternal(forward, from, target, velocity);
  }

  void _prepareInternal(bool forward, [double? from, double? target, double? velocity]) {
    for (final entry in tracks.values) {
      entry.track.prepare(
        forward: forward,
        from: from,
        target: target,
        exteranlVelocity: velocity,
      );
    }
    _updateStatus();
  }

  @override
  void prepareForRepeat(RepeatConfig config) {
    _repeatConfig = config;
    _lastT = 0.0;
    _cycleOffset = 0.0;
    _prepareInternal(true, config.from ?? 0.0, config.target);
  }

  @override
  double x(double time) {
    final adjustedTime = time - _cycleOffset;
    final dt = adjustedTime - _lastT;
    _lastT = adjustedTime;
    if (dt > 0) {
      for (final entry in tracks.values) {
        entry.track.tick(dt);
      }
    }
    _updateStatus();
    return progress;
  }

  @override
  double dx(double time) {
    if (tracks.isEmpty) {
      return 0.0;
    }
    double maxVelocity = 0.0;
    for (final entry in tracks.values) {
      final velocity = entry.track.velocity;
      if (velocity.abs() > maxVelocity.abs()) {
        maxVelocity = velocity;
      }
    }
    return maxVelocity;
  }

  @override
  bool isDone(double time) {
    if (tracks.isEmpty) {
      return true;
    }
    final cycleDone = tracks.values.every((entry) => entry.track.isDone);
    if (!cycleDone) return false;

    final config = _repeatConfig;

    if (config == null) return true;

    if (config.count != null) {
      final nextCount = config.count! - 1;
      _repeatConfig = config.updateCount(nextCount);

      if (nextCount == 0) {
        return true;
      }
    }

    _cycleOffset = time;
    _lastT = 0.0;

    if (config.reverse) {
      if (status.isForwardOrCompleted) {
        _prepareInternal(false, config.target, config.from ?? 0.0);
      } else {
        _prepareInternal(true, config.from ?? 0.0, config.target);
      }
    } else {
      _prepareInternal(true, config.from ?? 0.0, config.target);
    }

    return false;
  }

  @override
  CueTrack buildTrack(TrackConfig config) {
    return CueTrackImpl(config);
  }

  @override
  void didRegisterListener() => _listenres++;

  @override
  void didUnregisterListener() => _listenres--;

  bool get hasListeners => _listenres > 0;

  @override
  void dispose() {
    super.dispose();
    _eventsNotifier.dispose();
  }
}

abstract class CueTimeline extends Simulation with EventNotifier<TimelineEvent> {
  void prepare({required bool forward, double? from, double? target, double? velocity});

  void prepareForRepeat(RepeatConfig config);

  void willAnimate({required bool forward});

  void setProgress(double value, {bool forward = true, bool forceLinear = false});

  void reset();

  (CueTrack, ReleaseToken) obtainTrack(TrackConfig config);

  (CueTrack, ReleaseToken) obtainDefaultTrack() => obtainTrack(defaultConfig);

  void release(ReleaseToken token);

  AnimationStatus get status;

  double get forwardDuration;

  double get reverseDuration;

  double get progress;

  Map<TrackConfig, TrackEntry> get tracks;

  CueTrack buildTrack(TrackConfig config);

  TrackConfig get defaultConfig;

  CueTrack get mainTrack;

  void resetTracks(TrackConfig newDefaultConfig);

  @override
  void dispose();

  void addStatusListener(AnimationStatusListener listener);

  void removeStatusListener(AnimationStatusListener listener);
}

sealed class TimelineEvent {
  const TimelineEvent();
}

class TimelineWillAnimateEvent extends TimelineEvent {
  final bool forward;

  const TimelineWillAnimateEvent(this.forward);
}

class TimelinePrepareEvent extends TimelineEvent {
  final bool forward;

  const TimelinePrepareEvent(this.forward);
}

class RepeatConfig {
  final int? count;
  final bool reverse;
  final double? target;
  final double? from;

  RepeatConfig({
    this.count,
    required this.reverse,
    this.target,
    this.from,
  });

  RepeatConfig updateCount(int newCount) {
    return RepeatConfig(
      count: newCount,
      reverse: reverse,
      target: target,
      from: from,
    );
  }
}

class ReleaseToken {
  final TrackConfig config;
  final CueTimeline _timeline;
  const ReleaseToken(this.config, this._timeline);

  void release() => _timeline.release(this);
}

class TrackEntry {
  final CueTrack track;
  final List<ReleaseToken> tokens;
  TrackEntry(this.track) : tokens = [];

  void addToken(ReleaseToken token) {
    tokens.add(token);
  }

  bool removeToken(ReleaseToken token) {
    return tokens.remove(token);
  }

  bool get canRelease => tokens.isEmpty;
}
