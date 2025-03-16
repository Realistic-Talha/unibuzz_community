
import 'dart:async';

extension TimerExtensions on Timer {
  static Timer? safeTick(Timer? timer, Duration duration, void Function() callback) {
    timer?.cancel();
    return Timer(duration, callback);
  }
}