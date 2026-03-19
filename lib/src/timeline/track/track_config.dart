import 'package:cue/cue.dart';
import 'package:cue/src/motion/cue_motion.dart';

class TrackConfig {
  final CueMotion motion;
  final CueMotion? reverseMotion;
  final double delay;
  final double reverseDelay;
  final ReverseBehaviorType reverseType;

  const TrackConfig({
    required this.motion,
    this.reverseMotion,
    this.delay = 0.0,
    this.reverseDelay = 0.0,
    this.reverseType = ReverseBehaviorType.mirror,
  });

  TrackConfig copyWith({
    CueMotion? motion,
    CueMotion? reverseMotion,
    double? delay,
    double? reverseDelay,
    ReverseBehaviorType? reverseType,
  }) {
    return TrackConfig(
      motion: motion ?? this.motion,
      reverseMotion: reverseMotion ?? this.reverseMotion,
      delay: delay ?? this.delay,
      reverseDelay: reverseDelay ?? this.reverseDelay,
      reverseType: reverseType ?? this.reverseType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackConfig &&
        other.motion == motion &&
        other.reverseMotion == reverseMotion &&
        other.delay == delay &&
        other.reverseType == reverseType &&
        other.reverseDelay == reverseDelay;
  }

  @override
  int get hashCode => Object.hash(motion, reverseMotion, delay, reverseDelay, reverseType);
}
