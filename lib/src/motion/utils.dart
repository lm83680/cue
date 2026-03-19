extension DurationExtension on int {
  Duration get ms => Duration(milliseconds: this);
  Duration get sec => Duration(seconds: this);
  Duration get m => Duration(minutes: this);
}
