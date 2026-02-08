sealed class Phase<T> {
  const Phase._({required this.weight}) : assert(weight > 0.0);
  final double weight;

  const factory Phase({
    required T begin,
    required T end,
    required double weight,
  }) = FullPhase<T>;

  const factory Phase.to(T begin, {required double weight}) = _EndPhase<T>;
  const factory Phase.from(T end, {required double weight}) = _BeginPhase<T>;
  const factory Phase.hold(T value, {required double weight}) = _ConstantPhase<T>;

  static List<FullPhase<T>> convert<T>(List<Phase<T>> partialPhase) {
    final List<FullPhase<T>> fullPhases = [];
    for (int i = 0; i < partialPhase.length; i++) {
      final phase = partialPhase[i];
      if (phase is FullPhase<T>) {
        fullPhases.add(phase);
      } else if (phase is _EndPhase<T>) {
        final begin = i > 0 ? fullPhases.last.end : phase.end;
        fullPhases.add(FullPhase(begin: begin, end: phase.end, weight: phase.weight));
      } else if (phase is _BeginPhase<T>) {
        final end = i < partialPhase.length - 1
            ? (partialPhase[i + 1] is FullPhase<T>
                  ? (partialPhase[i + 1] as FullPhase<T>).begin
                  : (partialPhase[i + 1] is _BeginPhase<T>
                        ? (partialPhase[i + 1] as _BeginPhase<T>).begin
                        : (partialPhase[i + 1] as _EndPhase<T>).end))
            : phase.begin;
        fullPhases.add(FullPhase(begin: phase.begin, end: end, weight: phase.weight));
      } else if (phase is _ConstantPhase<T>) {
        final value = phase.value;
        fullPhases.add(FullPhase(begin: value, end: value, weight: phase.weight));
      }
    }
    return fullPhases;
  }
}

class FullPhase<T> extends Phase<T> {
  final T begin;
  final T end;

  const FullPhase({
    required this.begin,
    required this.end,
    required super.weight,
  }) : super._();
}

class _EndPhase<T> extends Phase<T> {
  final T end;

  const _EndPhase(this.end, {required super.weight}) : super._();
}

class _BeginPhase<T> extends Phase<T> {
  final T begin;
  const _BeginPhase(this.begin, {required super.weight}) : super._();
}

class _ConstantPhase<T> extends Phase<T> {
  final T value;
  const _ConstantPhase(this.value, {required super.weight}) : super._();
}
