import 'package:cue/cue.dart';
import 'package:cue/src/timeline/track/track.dart';
import 'package:cue/src/timeline/track/track_config.dart';
import 'package:flutter/widgets.dart';

abstract class CueAnimation<T> extends Animation<T> with AnimationWithParentMixin<double> {

  @override
  final CueTrack parent;

  ReleaseToken get token;

  TrackConfig get trackConfig => parent.config;

  CueAnimation({required this.parent});

  bool get isReverseOrDismissed =>
      parent.status == AnimationStatus.reverse || parent.status == AnimationStatus.dismissed;

  CueAnimtable<T> get animtable;

  @override
  T get value => animtable.evaluate(parent);
}

class CueAnimationImpl<T> extends CueAnimation<T> {
  @override
  final CueAnimtable<T> animtable;

  @override
  final ReleaseToken token;



  CueAnimationImpl({required super.parent, required this.token, required this.animtable});
}

class DeferredCueAnimation<T> extends CueAnimation<T> {
  ActContext context;
 
  @override
  final ReleaseToken token;

  DeferredCueAnimation({
    required super.parent,
    required this.context,
    required this.token,
  });

  CueAnimtable<T>? _animatable;

  @override
  CueAnimtable<T> get animtable {
    if (_animatable == null) {
      throw StateError('Animatable is not set yet');
    }
    return _animatable!;
  }

  bool get hasAnimatable => _animatable != null;

  void setAnimatable(CueAnimtable<T>? animatable) {
    _animatable = animatable;
  }
}

