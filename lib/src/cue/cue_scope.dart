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
  /// Creates a CueScope with the given [child], [controller], and [reanimateFromCurrent].
  const CueScope({
    super.key,
    required super.child,
    required this.controller,
    required this.reanimateFromCurrent,
  });

  /// The controller that manages the animation state.
  final CueController controller;

  /// Whether to reanimate from the current position when the animation triggers again.
  final bool reanimateFromCurrent;

  /// Retrieves the [CueScope] from the given [context].
  ///
  /// Throws an assertion error if no [CueScope] is found.
  static CueScope of(BuildContext context) {
    final cue = context.dependOnInheritedWidgetOfExactType<CueScope>();
    assert(cue != null, 'No Cue found in context, make sure to wrap your widget tree with a Cue widget.');
    return cue!;
  }

  /// Retrieves the [CueScope] from the given [context], or null if not found.
  static CueScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CueScope>();
  }

  @override
  bool updateShouldNotify(covariant CueScope oldWidget) {
    return controller != oldWidget.controller || reanimateFromCurrent != oldWidget.reanimateFromCurrent;
  }
}
