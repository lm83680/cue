part of 'cue.dart';

class _OnHoverCue extends _SelfAnimatedCue {
  const _OnHoverCue({
    super.key,
    required super.child,
    super.debugLabel,
    super.motion = const CueMotion.timed(Duration(milliseconds: 200)),
    this.cursor = MouseCursor.defer,
    this.opaque = false,
  }) : super();

  final MouseCursor cursor;
  final bool opaque;

  @override
  State<StatefulWidget> createState() => _OnHoverStageState();
}

class _OnHoverStageState extends _SelfAnimatedState<_OnHoverCue> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      opaque: widget.opaque,
      onEnter: (_) => controller.playForward(),
      onExit: (_) => controller.playReverse(),
      child: super.build(context),
    );
  }
}
