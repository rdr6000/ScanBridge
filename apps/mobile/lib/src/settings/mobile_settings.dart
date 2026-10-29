import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';

enum ScanMode { single, continuous }

enum ThemeChoice { system, light, dark }

/// Phone preferences persisted as JSON in SQLite.
class MobileSettings {
  const MobileSettings({
    this.deviceName = 'My phone',
    this.scanMode = ScanMode.continuous,
    this.haptics = true,
    this.sound = true,
    this.rules = const ScanRules(),
    this.defaultQuantity = '1',
    this.askQuantity = false,
    this.activeSessionId,
    this.templateOverrideId,
    this.hostActiveTemplateId,
    this.hardwareDebounceMs = 300,
    this.theme = ThemeChoice.system,
  });

  final String deviceName;
  final ScanMode scanMode;
  final bool haptics;
  final bool sound;
  final ScanRules rules;
  final String defaultQuantity;
  final bool askQuantity;
  final String? activeSessionId;

  /// Null means "use the computer's active template".
  final String? templateOverrideId;
  final String? hostActiveTemplateId;
  final int hardwareDebounceMs;
  final ThemeChoice theme;

  String? get effectiveTemplateId => templateOverrideId ?? hostActiveTemplateId;

  MobileSettings copyWith({
    String? deviceName,
    ScanMode? scanMode,
    bool? haptics,
    bool? sound,
    ScanRules? rules,
    String? defaultQuantity,
    bool? askQuantity,
    String? Function()? activeSessionId,
    String? Function()? templateOverrideId,
    String? Function()? hostActiveTemplateId,
    int? hardwareDebounceMs,
    ThemeChoice? theme,
  }) => MobileSettings(
    deviceName: deviceName ?? this.deviceName,
    scanMode: scanMode ?? this.scanMode,
    haptics: haptics ?? this.haptics,
    sound: sound ?? this.sound,
    rules: rules ?? this.rules,
    defaultQuantity: defaultQuantity ?? this.defaultQuantity,
    askQuantity: askQuantity ?? this.askQuantity,
    activeSessionId: activeSessionId != null ? activeSessionId() : this.activeSessionId,
    templateOverrideId: templateOverrideId != null ? templateOverrideId() : this.templateOverrideId,
    hostActiveTemplateId: hostActiveTemplateId != null ? hostActiveTemplateId() : this.hostActiveTemplateId,
    hardwareDebounceMs: hardwareDebounceMs ?? this.hardwareDebounceMs,
    theme: theme ?? this.theme,
  );

  Map<String, Object?> toJson() => {
    'deviceName': deviceName,
    'scanMode': scanMode.name,
    'haptics': haptics,
    'sound': sound,
    'rules': rules.toJson(),
    'defaultQuantity': defaultQuantity,
    'askQuantity': askQuantity,
    'activeSessionId': activeSessionId,
    'templateOverrideId': templateOverrideId,
    'hostActiveTemplateId': hostActiveTemplateId,
    'hardwareDebounceMs': hardwareDebounceMs,
    'theme': theme.name,
  };

  factory MobileSettings.fromJson(Map<String, Object?> j) {
    const d = MobileSettings();
    T pick<T>(String k, T fallback) => j[k] is T ? j[k] as T : fallback;
    return MobileSettings(
      deviceName: pick('deviceName', d.deviceName),
      scanMode: enumByName(ScanMode.values, j['scanMode'] as String?, d.scanMode),
      haptics: pick('haptics', d.haptics),
      sound: pick('sound', d.sound),
      rules: j['rules'] is Map ? ScanRules.fromJson((j['rules'] as Map).cast()) : d.rules,
      defaultQuantity: pick('defaultQuantity', d.defaultQuantity),
      askQuantity: pick('askQuantity', d.askQuantity),
      activeSessionId: j['activeSessionId'] as String?,
      templateOverrideId: j['templateOverrideId'] as String?,
      hostActiveTemplateId: j['hostActiveTemplateId'] as String?,
      hardwareDebounceMs: pick('hardwareDebounceMs', d.hardwareDebounceMs),
      theme: enumByName(ThemeChoice.values, j['theme'] as String?, d.theme),
    );
  }
}

class MobileSettingsStore extends JsonSettingsStore<MobileSettings> {
  MobileSettingsStore(SettingsRepository repo)
    : super(repo, 'mobile.settings', initial: const MobileSettings(), decode: MobileSettings.fromJson, encode: (s) => s.toJson());
}
