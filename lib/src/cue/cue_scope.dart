part of 'cue.dart';

/// An [InheritedWidget] that exposes a [CueController] to the subtree.
///
/// [CueScope] is the bridge between a [Cue] widget and the [Actor] widgets nested
/// inside it. Every [Cue] wraps its child in a [CueScope], and every [Actor]
/// reads from it to drive its animations.
///
/// You rarely need to interact with [CueScope] directly. Use [CueScope.of] or
/// [CueScope.maybeOf] when building custom acts or widgets that need access to
/// the current animation controller.
class CueScope extends InheritedWidget {
  const CueScope({
    super.key,
    required super.child,
    required this.controller,
    required this.reanimateFromCurrent,
  });

  final CueController controller;
  final bool reanimateFromCurrent;

  static CueScope of(BuildContext context) {
    final cue = context.dependOnInheritedWidgetOfExactType<CueScope>();
    assert(cue != null, 'No Cue found in context, make sure to wrap your widget tree with a Cue widget.');
    return cue!;
  }

  static CueScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CueScope>();
  }

  @override
  bool updateShouldNotify(covariant CueScope oldWidget) {
    return controller != oldWidget.controller ||
        reanimateFromCurrent != oldWidget.reanimateFromCurrent;
  }
}

