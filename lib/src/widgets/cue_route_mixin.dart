import 'package:cue/cue.dart';
import 'package:cue/src/core/curves.dart';
import 'package:flutter/material.dart';

mixin CueModalRouteMixin<T extends Object?> on ModalRoute<T> {
  CueMotion get motion;
  CueMotion? get reverseMotion;
  AnimationStatusListener? get onAnimationStatusChanged;
  bool get hideOnPushNext;

  @override
  Curve get barrierCurve => BoundedCurve(curve: Curves.easeIn);

  @override
  AnimationController createAnimationController() {
    final ctrl = CueController(
      motion: motion,
      reverseMotion: reverseMotion,
      vsync: navigator!,
    );
    if (onAnimationStatusChanged != null) {
      ctrl.addStatusListener(onAnimationStatusChanged!);
    }
    willDisposeAnimationController = false;
    return ctrl;
  }

  final _isCurrentNotifer = ValueNotifier<bool>(true);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Cue(
      timeline: (controller as CueController).timeline,
      child: ListenableBuilder(
        listenable: _isCurrentNotifer,
        child: super.buildPage(context, animation, secondaryAnimation),
        builder: (context, child) {
          return Visibility.maintain(visible: _isCurrentNotifer.value, child: child!);
        },
      ),
    );
  }

  @override
  void didChangeNext(Route? nextRoute) {
    super.didChangeNext(nextRoute);
    if (hideOnPushNext && nextRoute is CueModalRouteMixin) {
      _isCurrentNotifer.value = false;
    }
  }

 

  @override
  void dispose() async{
    if (onAnimationStatusChanged != null) {
        onAnimationStatusChanged!.call(AnimationStatus.dismissed);
      controller?.removeStatusListener(onAnimationStatusChanged!);
    }
    controller?.dispose();
    _isCurrentNotifer.dispose();
    super.dispose();
  }

  @override
  Simulation? createSimulation({required bool forward}) {
    return null;
  }
}
