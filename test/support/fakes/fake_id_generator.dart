import 'dart:collection';

import 'package:habiter/core/ids/id_generator.dart';

final class FakeIdGenerator implements IdGenerator {
  FakeIdGenerator(Iterable<String> values) : _values = Queue<String>.of(values);

  final Queue<String> _values;

  @override
  String next() {
    if (_values.isEmpty) {
      throw StateError('No programmed ID remains.');
    }
    return _values.removeFirst();
  }
}
