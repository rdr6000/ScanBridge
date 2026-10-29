import 'package:drift/drift.dart';

// Timestamps are stored as UTC ISO strings via drift's text date mode.

@DataClassName('DeviceRow')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get platform => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get pairedAt => dateTime().nullable()();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  TextColumn get status => text()();
  IntColumn get protocolVersion => integer().withDefault(const Constant(1))();
  BoolColumn get canSubmitScans => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get sourceDeviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ScanRow')
@TableIndex(name: 'scans_session', columns: {#sessionId})
@TableIndex(name: 'scans_captured', columns: {#capturedAt})
@TableIndex(name: 'scans_value', columns: {#normalizedValue})
@TableIndex(name: 'scans_delivery', columns: {#deliveryStatus})
@TableIndex(name: 'scans_device', columns: {#deviceId})
class Scans extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get deviceId => text()();
  TextColumn get rawValue => text()();
  TextColumn get normalizedValue => text()();
  TextColumn get symbology => text()();
  TextColumn get quantity => text().withDefault(const Constant('1'))();
  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  TextColumn get source => text()();
  TextColumn get validationStatus => text()();
  TextColumn get deliveryStatus => text()();
  TextColumn get outputStatus => text()();
  TextColumn get outputError => text().nullable()();
  TextColumn get templateId => text().nullable()();
  IntColumn get templateVersion => integer().nullable()();
  TextColumn get valuesJson => text().withDefault(const Constant('{}'))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OutboxRow')
@TableIndex(name: 'outbox_state', columns: {#state, #nextAttemptAt})
class DeliveryOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get aggregateId => text()();
  TextColumn get messageType => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  /// pending | done | dead
  TextColumn get state => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TemplateRow')
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get currentVersion => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TemplateVersionRow')
class TemplateVersions extends Table {
  TextColumn get templateId => text().references(Templates, #id, onDelete: KeyAction.cascade)();
  IntColumn get version => integer()();
  IntColumn get schemaVersion => integer()();
  TextColumn get json => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {templateId, version};
}

@DataClassName('TemplateRunRow')
@TableIndex(name: 'runs_scan', columns: {#scanId})
class TemplateRuns extends Table {
  TextColumn get id => text()();
  TextColumn get scanId => text()();
  TextColumn get templateId => text()();
  IntColumn get templateVersion => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get outputSummary => text().withDefault(const Constant(''))();
  TextColumn get errorCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('AuditRow')
@TableIndex(name: 'audit_time', columns: {#timestamp})
class AuditEvents extends Table {
  TextColumn get id => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get category => text()();
  TextColumn get action => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get details => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
