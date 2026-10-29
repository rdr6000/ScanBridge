import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Random v4 UUID used for every entity id.
String newId() => _uuid.v4();

/// Current time in UTC; all persisted timestamps are UTC.
DateTime nowUtc() => DateTime.now().toUtc();
