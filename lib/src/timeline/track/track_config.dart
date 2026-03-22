import 'package:cue/cue.dart';

class TrackConfig {
  final CueMotion motion;
  final CueMotion reverseMotion;
  final ReverseBehaviorType reverseType;

  const TrackConfig({
    required this.motion,
    required this.reverseMotion,
    this.reverseType = ReverseBehaviorType.mirror,
  });

  TrackConfig copyWith({
    CueMotion? motion,
    CueMotion? reverseMotion,
    ReverseBehaviorType? reverseType,
  }) {
    return TrackConfig(
      motion: motion ?? this.motion,
      reverseMotion: reverseMotion ?? this.reverseMotion,
      reverseType: reverseType ?? this.reverseType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackConfig &&
        other.motion == motion &&
        other.reverseMotion == reverseMotion &&
        other.reverseType == reverseType;
  }

  @override
  int get hashCode => Object.hash(motion, reverseMotion, reverseType);
}
