import 'package:uuid/uuid.dart';

abstract interface class IdGenerator {
  String next();
}

final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator([this._uuid = const Uuid()]);

  final Uuid _uuid;

  @override
  String next() => _uuid.v4();
}
