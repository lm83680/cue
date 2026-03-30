extension DurationExtension on int {
  Duration get ms => Duration(milliseconds: this);
  Duration get s => Duration(seconds: this);
}

extension DoubleDurationExtension on double {
  Duration get s => Duration(microseconds: (this * 1e6).round());
}
