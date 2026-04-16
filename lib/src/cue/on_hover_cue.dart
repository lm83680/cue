part of 'cue.dart';

/// {@template cue.on_hover}
/// A [Cue] that animates on mouse hover.
///
/// Animates forward when the cursor enters and reverses when it exits.
/// Wraps [child] in a [MouseRegion] internally.
///
/// [cursor] sets the pointer cursor. [opaque] controls whether the region
/// absorbs pointer events from widgets below (default `false`).
///
/// ```dart
/// Cue.onHover(
///   motion: Spring.smooth(damping: 23),
///   acts: [.scale(from: 1.0, to: 1.05)],
///   child: MyButton(),
/// )
/// ```
/// {@endtemplate}
class OnHoverCue extends SelfAnimatedCue {
  /// Default constructor.
  const OnHoverCue({
    super.key,
    required super.child,
    super.debugLabel,
    super.motion = CueMotion.defaultTime,
    this.cursor = MouseCursor.defer,
    this.opaque = false,
    super.onEnd,
    super.acts,
  }) : super();

  /// The mouse cursor to display when hovering over the widget. Defaults to [MouseCursor.defer], which defers to the next region.
  final MouseCursor cursor;

  /// Whether the hover region is opaque, meaning it will block pointer events from widgets below it. Defaults to `false`, allowing events to pass through.
  final bool opaque;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MouseCursor>('cursor', cursor, defaultValue: MouseCursor.defer));
    properties.add(FlagProperty('opaque', value: opaque, ifTrue: 'opaque'));
  }

  @override
  State<StatefulWidget> createState() => _OnHoverStageState();
}

class _OnHoverStageState extends SelfAnimatedCueState<OnHoverCue> {
  @override
  String get debugName => 'OnHoverCue';

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      opaque: widget.opaque,
      onEnter: (_) => controller.forward(),
      onExit: (_) => controller.reverse(),
      child: super.build(context),
    );
  }
}
