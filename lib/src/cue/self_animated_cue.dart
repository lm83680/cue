part of 'cue.dart';

/// Base class for [Cue] variants that own and manage their [CueController].
///
/// [SelfAnimatedCue] creates a [CueController] internally using [motion] and
/// [reverseMotion], and drives it in response to some trigger (toggling,
/// hovering, mounting, etc.).
///
/// Supports optional looping via [repeat], [reverseOnRepeat], and [repeatCount],
/// as well as an [onEnd] callback that fires when the animation completes in
/// either direction.
abstract class SelfAnimatedCue extends Cue {
  const SelfAnimatedCue({
    super.key,
    required super.child,
    this.motion = CueMotion.defaultTime,
    this.reverseMotion,
    super.debugLabel,
    this.repeat = false,
    this.reverseOnRepeat = false,
    this.repeatCount,
    this.onEnd,
    super.acts,
  }) : super._();

  final CueMotion motion;
  final CueMotion? reverseMotion;
  final bool repeat;
  final int? repeatCount;
  final bool reverseOnRepeat;
  final ValueChanged<bool>? onEnd;
}

/// Base [State] for [SelfAnimatedCue] subclasses.
///
/// Creates and owns the [CueController], wires up the [onEnd] status listener,
/// and rebuilds the timeline when [motion] or [reverseMotion] change.
///
/// Subclasses override [onControllerReady] to start their animation logic
/// once the controller has been initialised.
abstract class SelfAnimatedCueState<T extends SelfAnimatedCue> extends CueState<T> with SingleTickerProviderStateMixin {
  
  @override
  late final CueController controller;

  CueMotion get motion => widget.motion;

  CueMotion? get reverseMotion => widget.reverseMotion;

  AnimationStatusListener? _statusListener;

  @override
  void initState() {
    super.initState();
    _createController();
    if (widget.onEnd != null) {
      _updateStatusListener();
    }
    _updateStatusListener();
    onControllerReady();
  }

  void _updateStatusListener() {
    if (_statusListener != null) {
      controller.removeStatusListener(_statusListener!);
    }
    _statusListener = (status) {
      if (status.isCompleted) {
        widget.onEnd?.call(true);
      } else if (status.isDismissed) {
        widget.onEnd?.call(false);
      }
    };
    controller.addStatusListener(_statusListener!);
  }

  void _createController() {
    controller = CueController(
      motion: motion,
      reverseMotion: widget.reverseMotion,
      vsync: this,
      debugLabel: 'Cue Controller for ${widget.debugLabel ?? widget.runtimeType}',
    );
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != motion || oldWidget.reverseMotion != reverseMotion) {
      controller.rebuildTimeline(motion, reverseMotion: reverseMotion);
    }
    if (oldWidget.onEnd != widget.onEnd) {
      _updateStatusListener();
    }
  }

  bool _devToolControlled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kDebugMode) {
      final devToolScope = CueDebugTools.maybeOf(context);
      final isDevToolControlled = devToolScope?.activeTargetId == _debugId && devToolScope?.isMinimized == false;
      if (!_devToolControlled && isDevToolControlled) {
        controller.stop();
      } else if (_devToolControlled && !isDevToolControlled && widget.repeat) {
        controller.repeat(reverse: widget.reverseOnRepeat, count: widget.repeatCount);
      }
      _devToolControlled = isDevToolControlled;
    }
  }

  void onControllerReady() {}

  @override
  void dispose() {
    if (_statusListener != null) {
      controller.removeStatusListener(_statusListener!);
    }
    controller.dispose();
    super.dispose();
  }
}
