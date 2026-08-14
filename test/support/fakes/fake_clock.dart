import 'package:habiter/core/time/clock.dart';

final class FakeClock implements Clock {
  FakeClock(DateTime initial) : _current = initial;

  DateTime _current;

  @override
  DateTime now() => _current;

  void advance(Duration duration) {
    _current = _current.add(duration);
  }

  void set(DateTime value) {
    _current = value;
  }
}
