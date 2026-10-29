import 'dart:math';

/// Bounded exponential backoff with "equal jitter" (half fixed, half random).
class Backoff {
  const Backoff({this.base = const Duration(seconds: 1), this.max = const Duration(minutes: 2)});

  final Duration base;
  final Duration max;

  Duration delayFor(int attempt, [Random? random]) {
    final exp = base.inMilliseconds * pow(2, min(attempt, 20)).toInt();
    final capped = min(max.inMilliseconds, exp);
    final half = capped ~/ 2;
    return Duration(milliseconds: half + (random ?? Random()).nextInt(half + 1));
  }
}
