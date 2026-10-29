import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

enum ThemePreference { system, light, dark }

/// Desktop host preferences, persisted as one JSON document.
class HostSettings {
  const HostSettings({
    this.serverName = 'ScanBridge Desktop',
    this.port = ProtocolLimits.defaultPort,
    this.lanMode = false,
    this.autoStart = false,
    this.keyboardArmed = true,
    this.keyDelayMs = 0,
    this.clipboardFallback = false,
    this.confirmDestructive = true,
    this.activeTemplateId = SampleTemplates.defaultId,
    this.outputDirectory = '',
    this.csvBom = false,
    this.csvFormulaGuard = true,
    this.theme = ThemePreference.system,
    this.firstRunDone = false,
  });

  final String serverName;
  final int port;

  /// False binds loopback only; true listens on all IPv4 interfaces.
  final bool lanMode;
  final bool autoStart;
  final bool keyboardArmed;
  final int keyDelayMs;

  /// Uses paste via clipboard when native typing is unavailable.
  final bool clipboardFallback;
  final bool confirmDestructive;
  final String activeTemplateId;

  /// Directory that FILE/CSV outputs are confined to.
  final String outputDirectory;
  final bool csvBom;
  final bool csvFormulaGuard;
  final ThemePreference theme;
  final bool firstRunDone;

  CsvOptions get csvOptions => CsvOptions(utf8Bom: csvBom, formulaGuard: csvFormulaGuard);

  HostSettings copyWith({
    String? serverName,
    int? port,
    bool? lanMode,
    bool? autoStart,
    bool? keyboardArmed,
    int? keyDelayMs,
    bool? clipboardFallback,
    bool? confirmDestructive,
    String? activeTemplateId,
    String? outputDirectory,
    bool? csvBom,
    bool? csvFormulaGuard,
    ThemePreference? theme,
    bool? firstRunDone,
  }) => HostSettings(
    serverName: serverName ?? this.serverName,
    port: port ?? this.port,
    lanMode: lanMode ?? this.lanMode,
    autoStart: autoStart ?? this.autoStart,
    keyboardArmed: keyboardArmed ?? this.keyboardArmed,
    keyDelayMs: keyDelayMs ?? this.keyDelayMs,
    clipboardFallback: clipboardFallback ?? this.clipboardFallback,
    confirmDestructive: confirmDestructive ?? this.confirmDestructive,
    activeTemplateId: activeTemplateId ?? this.activeTemplateId,
    outputDirectory: outputDirectory ?? this.outputDirectory,
    csvBom: csvBom ?? this.csvBom,
    csvFormulaGuard: csvFormulaGuard ?? this.csvFormulaGuard,
    theme: theme ?? this.theme,
    firstRunDone: firstRunDone ?? this.firstRunDone,
  );

  Map<String, Object?> toJson() => {
    'serverName': serverName,
    'port': port,
    'lanMode': lanMode,
    'autoStart': autoStart,
    'keyboardArmed': keyboardArmed,
    'keyDelayMs': keyDelayMs,
    'clipboardFallback': clipboardFallback,
    'confirmDestructive': confirmDestructive,
    'activeTemplateId': activeTemplateId,
    'outputDirectory': outputDirectory,
    'csvBom': csvBom,
    'csvFormulaGuard': csvFormulaGuard,
    'theme': theme.name,
    'firstRunDone': firstRunDone,
  };

  factory HostSettings.fromJson(Map<String, Object?> j) {
    const d = HostSettings();
    T pick<T>(String k, T fallback) => j[k] is T ? j[k] as T : fallback;
    return HostSettings(
      serverName: pick('serverName', d.serverName),
      port: pick('port', d.port),
      lanMode: pick('lanMode', d.lanMode),
      autoStart: pick('autoStart', d.autoStart),
      keyboardArmed: pick('keyboardArmed', d.keyboardArmed),
      keyDelayMs: pick('keyDelayMs', d.keyDelayMs),
      clipboardFallback: pick('clipboardFallback', d.clipboardFallback),
      confirmDestructive: pick('confirmDestructive', d.confirmDestructive),
      activeTemplateId: pick('activeTemplateId', d.activeTemplateId),
      outputDirectory: pick('outputDirectory', d.outputDirectory),
      csvBom: pick('csvBom', d.csvBom),
      csvFormulaGuard: pick('csvFormulaGuard', d.csvFormulaGuard),
      theme: enumByName(ThemePreference.values, j['theme'] as String?, d.theme),
      firstRunDone: pick('firstRunDone', d.firstRunDone),
    );
  }
}

/// Host settings plus persistent INCREMENT counters.
class HostSettingsStore extends JsonSettingsStore<HostSettings> {
  HostSettingsStore(SettingsRepository repo)
    : super(repo, 'host.settings', initial: const HostSettings(), decode: HostSettings.fromJson, encode: (s) => s.toJson());

  static const _countersKey = 'host.counters';

  Future<void> loadWithDefaults({required String defaultOutputDir}) async {
    await load();
    if (current.outputDirectory.isEmpty) await update((s) => s.copyWith(outputDirectory: defaultOutputDir));
  }

  Future<Map<String, int>> counters() async =>
      (await readJson(_countersKey)).map((k, v) => MapEntry(k, v as int));

  Future<void> saveCounters(Map<String, int> counters) => writeJson(_countersKey, counters);
}
