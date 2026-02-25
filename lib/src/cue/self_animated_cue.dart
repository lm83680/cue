part of 'cue.dart';

class _SelfAnimatedCue extends Cue {
  const _SelfAnimatedCue({
    super.key,
    required super.child,
    this.motion = const CueMotion.timed(Duration(milliseconds: 300)),
    super.debugLabel,
    this.loop = false,
    this.reverseOnLoop = false,
    this.delay,
  }) : super._();

  final CueMotion motion;
  final Duration? delay;
  final bool loop;
  final bool reverseOnLoop;

  @override
  State<StatefulWidget> createState() => _SelfAnimatedCueState();
}

class _SelfAnimatedCueState extends _SelfAnimatedState<_SelfAnimatedCue> {
  @override
  void onControllerReady() async {
    if (widget.delay case final delay?) {
      await Future.delayed(delay);
    }
    if (widget.loop) {
      controller.playLoop(reverseOnLoop: widget.reverseOnLoop);
    } else {
      controller.playForward();
    }
  }

  @override
  Animation<double> getAnimation(BuildContext context) => animation;

  @override
  void didUpdateWidget(covariant _SelfAnimatedCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loop != oldWidget.loop || widget.reverseOnLoop != oldWidget.reverseOnLoop) {
      controller.stop();
      if (widget.loop) {
        controller.playLoop(reverseOnLoop: widget.reverseOnLoop);
      } else {
        controller.playForward();
      }
    }
  }
}

abstract class _SelfAnimatedState<T extends _SelfAnimatedCue> extends _CueState<T> with TickerProviderStateMixin {
  late CueAnimationController controller;
  Animation<double> _animation = const AlwaysStoppedAnimation(0.0);

  Animation<double> get animation => _animation;

  CueMotion get motion => widget.motion;

  @override
  bool get isBounded => controller.isBounded;

  @override
  Animation<double> getAnimation(BuildContext context) => _animation;

  @override
  void initState() {
    super.initState();
    _createController();
    _buildAnimation();
    onControllerReady();
  }

  void _createController() {
    controller = switch (motion) {
      TimedMotion m => CueAnimationController(
        duration: m.duration,
        reverseDuration: m.reverseDuration,
        vsync: this,
        debugLabel: 'Cue Controller',
      ),
      SimulationMotion m => CueAnimationController.withSimulation(
        simulation: m.simulation,
        reverseSimulation: m.reverse,
        vsync: this,
        debugLabel: 'Unbounded Cue Controller',
      ),
    };
  }

  void _buildAnimation() {
    _animation = switch (motion) {
      TimedMotion m => m.applyCurve(controller),
      SimulationMotion() => controller.view,
    };
  }

  @override
  void didUpdateWidget(covariant _SelfAnimatedCue oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.motion != motion) {
      final m = motion;
      if (m is SimulationMotion) {
        // old controller is timed, new one is simulation, need to recreate the controller.
        if (controller.isBounded) {
          controller.stop();
          controller.dispose();
          _createController();
          _buildAnimation();
          onControllerReady();
        } else {
          // both are simulation, just update the simulation of the controller.
          controller.simulation = m.simulation;
          controller.reverseSimulation = m.reverse;
        }
      } else if (m is TimedMotion) {
        // old controller is simulation, new one is timed, need to recreate the controller.
        if (!controller.isBounded) {
          controller.stop();
          controller.dispose();
          _createController();
          _buildAnimation();
          onControllerReady();
        } else {
          // both are timed, just update the duration and curve of the controller.
          controller.duration = m.duration;
          controller.reverseDuration = m.reverseDuration;
          _buildAnimation();
        }
      }
    }
  }

  void onControllerReady() {}

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
