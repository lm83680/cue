import 'package:cue/cue.dart';
import 'package:cue/src/timeline/track/track.dart';
import 'package:flutter/material.dart';

class CueValueAnimator<T> extends Animation<T> with AnimationWithParentMixin<double> {
  final CueController _controller;

  final TweenBuilder<T> _tweenBuilder;

  CueValueAnimator(
    T initialValue, {
    required TickerProvider vsync,
    required CueMotion motion,
    Duration delay = Duration.zero,
    TweenBuilder<T>? tweenBuilder,
  }) : _tweenBuilder = tweenBuilder ?? Tween<T>.new,
       _animatable = _AlwaysStoppedAnimtable<T>(initialValue),
       _controller = CueController(
         vsync: vsync,
         motion: delay == Duration.zero ? motion : motion.delayed(delay),
       );

  late final CueTrack _track = _controller.timeline.obtainDefaultTrack().$1;

  late CueAnimtable<T> _animatable;

  @override
  Animation<double> get parent => _track;

  set value(T newValue) {
    if (newValue == value) return;
    _controller.stop();
    _animatable = _AlwaysStoppedAnimtable<T>(newValue);
    _track.setProgress(0.0, alwaysNotify: true);
  }

  void animateTo(T newTarget, {double? velocity}) {
    final currentValue = _animatable.evaluate(_track);
    _animatable = TweenAnimtable<T>(_tweenBuilder(begin: currentValue, end: newTarget));
    _controller.forward(from: 0.0, velocity: velocity);
  }

  @override
  T get value => _animatable.evaluate(_track);

  void dispose() {
    _controller.dispose();
  }
}

class _AlwaysStoppedAnimtable<T> extends CueAnimtable<T> {
  final T value;
  _AlwaysStoppedAnimtable(this.value);
  @override
  T evaluate(CueTrack track) => value;
}
