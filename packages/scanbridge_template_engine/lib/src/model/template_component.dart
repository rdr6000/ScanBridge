import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'component_type.dart';

/// One step of a template. Unknown `typeId`s are kept verbatim but disabled.
class TemplateComponent {
  const TemplateComponent({
    required this.id,
    required this.typeId,
    this.enabled = true,
    this.skipOutput = false,
    this.label = '',
    this.config = const {},
  });

  factory TemplateComponent.create(ComponentType type, {Map<String, Object?> config = const {}, String label = ''}) =>
      TemplateComponent(id: newId().substring(0, 8), typeId: type.id, config: config, label: label);

  final String id;
  final String typeId;
  final bool enabled;
  final bool skipOutput;
  final String label;
  final Map<String, Object?> config;

  ComponentType? get type => ComponentType.fromId(typeId);

  bool get isKnown => type != null;

  bool get isPrompt => ComponentType.isPrompt(type, config);

  /// Variable name other components reference as `{{name}}`.
  String get variable => (config['name'] as String?)?.trim().isNotEmpty == true ? config['name'] as String : id;

  String get displayLabel => label.isNotEmpty ? label : (type?.id ?? typeId);

  TemplateComponent copyWith({bool? enabled, bool? skipOutput, String? label, Map<String, Object?>? config, String? id}) =>
      TemplateComponent(
        id: id ?? this.id,
        typeId: typeId,
        enabled: enabled ?? this.enabled,
        skipOutput: skipOutput ?? this.skipOutput,
        label: label ?? this.label,
        config: config ?? this.config,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'type': typeId,
    'enabled': enabled,
    'skipOutput': skipOutput,
    'label': label,
    'config': config,
  };

  factory TemplateComponent.fromJson(Map<String, Object?> j, String path) {
    final id = j['id'];
    final type = j['type'];
    final config = j['config'] ?? const <String, Object?>{};
    if (id is! String || id.isEmpty) throw TemplateFormatException('$path.id', 'must be a non-empty string');
    if (type is! String || type.isEmpty) throw TemplateFormatException('$path.type', 'must be a non-empty string');
    if (config is! Map) throw TemplateFormatException('$path.config', 'must be an object');
    final known = ComponentType.fromId(type) != null;
    return TemplateComponent(
      id: id,
      typeId: type,
      enabled: known && j['enabled'] != false,
      skipOutput: j['skipOutput'] == true,
      label: j['label'] as String? ?? '',
      config: config.cast<String, Object?>(),
    );
  }
}

/// Import error naming the exact JSON field that failed.
class TemplateFormatException implements Exception {
  TemplateFormatException(this.field, this.reason);
  final String field;
  final String reason;
  @override
  String toString() => '$field: $reason';
}
