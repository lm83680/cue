part of 'cue.dart';

class CueScope extends InheritedWidget {
  const CueScope({
    super.key,
    required super.child,
    required this.animation,
    required this.isBounded,
    this.willReanimateNotifier,
    required this.reanimateFromCurrent,
  });

  final EventNotifier<bool>? willReanimateNotifier;
  final Animation<double> animation;
  final bool isBounded;
  final bool reanimateFromCurrent;

  static CueScope of(BuildContext context) {
    final cue = context.dependOnInheritedWidgetOfExactType<CueScope>();
    assert(cue != null, 'No Cue found in context, make sure to wrap your widget tree with a Cue widget.');
    return cue!;
  }

  bool get isReversing => animation.status == AnimationStatus.reverse;
  bool get isCompleted => animation.status == AnimationStatus.completed;
  bool get isDismissed => animation.status == AnimationStatus.dismissed;
  bool get isAnimating => animation.isAnimating;

  @override
  bool updateShouldNotify(covariant CueScope oldWidget) {
    return animation != oldWidget.animation ||
        isBounded != oldWidget.isBounded ||
        willReanimateNotifier != oldWidget.willReanimateNotifier ||
        reanimateFromCurrent != oldWidget.reanimateFromCurrent;
  }
}

/// A ChangeNotifier that allows listeners to receive data when notified
class EventNotifier<T> extends ChangeNotifier {
  final List<void Function(T)> _eventListeners = [];

  /// Add a listener that receives data when events are fired
  void addEventListener(void Function(T) listener) {
    _eventListeners.add(listener);
  }

  /// Remove an event listener
  void removeEventListener(void Function(T) listener) {
    _eventListeners.remove(listener);
  }

  /// Fire an event with data to all event listeners
  void fireEvent(T data) {
    // Optionally notify regular listeners too
    notifyListeners();

    // Send event to all event listeners
    for (final listener in _eventListeners.toList()) {
      listener(data);
    }
  }

  @override
  void dispose() {
    _eventListeners.clear();
    super.dispose();
  }
}
