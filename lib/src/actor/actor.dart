part of 'actor_impl.dart';

abstract class Actor extends Widget {
  const factory Actor({
    required List<Act> acts,
    required Widget child,
    Curve? curve,
    Timing? timing,
    BoxOverflow overflow,
  }) = ActorBase;

  const factory Actor.rotate({
    required double from,
    required double to,
    AlignmentGeometry alignment,
    required Widget child,
    Curve? curve,
    Timing? timing,
    BoxOverflow overflow,
  }) = RotateActorFactory;

  const factory Actor.rotateTurns({
    required double from,
    required double to,
    AlignmentGeometry alignment,
    required Widget child,
    Curve? curve,
    Timing? timing,
    BoxOverflow overflow,
  }) = RotateActorFactory.turns;
}
