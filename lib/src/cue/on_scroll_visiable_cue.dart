part of 'cue.dart';

class _OnScrollVisibleCue extends Cue {
  const _OnScrollVisibleCue({
    required Key super.key,
    required super.child,
    super.debugLabel,
    this.enabled = true,
    super.acts,
  }) : super._();

  final bool enabled;

  @override
  State<StatefulWidget> createState() => _OnVisibleCueState();
}

class _OnVisibleCueState extends _CueState<_OnScrollVisibleCue> with SingleTickerProviderStateMixin {
  @override
  String get debugName => 'OnScrollVisibleCue';

  @override
  CueTimeline get timeline => _progressTimeline;

  late final _progressTimeline = CueTimelineImpl.fromMotion(.defaultTime);

  ScrollPosition? _scrollPosition;
  double? _cachedRevealedOffset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedRevealedOffset = null;
    if (!widget.enabled) return;

    _subscribeToScrollPosition();
  }

  void _subscribeToScrollPosition() {
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null) {
      throw FlutterError('Cue.onScrollVisible must be used inside a scrollable widget');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackViiblity();
    });
    if (_scrollPosition != position) {
      _scrollPosition?.removeListener(_trackViiblity);
      _scrollPosition = position;
      _scrollPosition!.addListener(_trackViiblity);
    }
  }

  @override
  void didUpdateWidget(covariant _OnScrollVisibleCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (!widget.enabled) {
        _progressTimeline.setProgress(1.0, forward: true);
        _scrollPosition?.removeListener(_trackViiblity);
      } else {
        _subscribeToScrollPosition();
      }
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_trackViiblity);
    super.dispose();
  }


  AnimationStatus? _committedStatus;
  void _trackViiblity() async {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;
    if (!renderObject.attached || _scrollPosition == null) return;

    final revealedOffset = _cachedRevealedOffset ??= RenderAbstractViewport.of(
      renderObject,
    ).getOffsetToReveal(renderObject, 0.0).offset;

    // Widget is visible if its revealed offset is within current scroll range
    final scrollOffset = _scrollPosition!.pixels;
    final viewportDimension = _scrollPosition!.viewportDimension;

    final itemExtent = _scrollPosition!.axis == Axis.horizontal ? renderObject.size.width : renderObject.size.height;

    // Compute how many pixels of the widget overlap with the viewport
    final visibleStart = math.max(revealedOffset, scrollOffset);
    final visibleEnd = math.min(revealedOffset + itemExtent, scrollOffset + viewportDimension);
    final visibleExtent = visibleEnd - visibleStart;

    // Widget is considered visible when the visible fraction meets or exceeds the threshold.
    // A threshold of 0.0 means any overlap counts as visible.

    final visibleFraction = itemExtent > 0 ? (visibleExtent / itemExtent) : 0.0;

    final scrollDirection = _scrollPosition!.userScrollDirection;
    final isScrollingForward = scrollDirection == ScrollDirection.forward || (scrollDirection == ScrollDirection.idle);

    AnimationStatus status = _progressTimeline.status;

    if (visibleFraction == 0.0 || visibleFraction == 1.0) {
      _committedStatus = null;
      status = AnimationStatus.completed;
    } else if (_committedStatus == null) {
      // First frame mid-transition — commit direction now
      if (visibleFraction > _progressTimeline.progress) {
        _committedStatus = isScrollingForward ? AnimationStatus.reverse : AnimationStatus.forward;
      } else if (visibleFraction < _progressTimeline.progress) {
        _committedStatus = isScrollingForward ? AnimationStatus.forward : AnimationStatus.reverse;
      }
      status = _committedStatus ?? _progressTimeline.status;
    } else {
      status = _committedStatus!;
    }
    final target = visibleFraction.clamp(0.0, 1.0);

    
      _progressTimeline.setProgress(target, forward: status.isForwardOrCompleted);
    
  }
}
