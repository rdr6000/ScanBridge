import 'dart:convert';

import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'template_component.dart';

/// Versioned template. Every saved edit bumps [version]; old versions are kept.
class OutputTemplate {
  const OutputTemplate({
    required this.id,
    required this.name,
    required this.version,
    required this.components,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.schemaVersion = currentSchema,
  });

  static const currentSchema = 1;
  static const maxComponents = 200;

  final String id;
  final String name;
  final String description;
  final int version;
  final int schemaVersion;
  final List<TemplateComponent> components;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<TemplateComponent> get prompts => components.where((c) => c.enabled && c.isPrompt).toList();

  OutputTemplate copyWith({String? name, String? description, List<TemplateComponent>? components, int? version, DateTime? updatedAt}) =>
      OutputTemplate(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        version: version ?? this.version,
        schemaVersion: schemaVersion,
        components: components ?? this.components,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// New version for a saved edit.
  OutputTemplate nextVersion(DateTime now) => copyWith(version: version + 1, updatedAt: now);

  Map<String, Object?> toJson() => {
    'format': 'scanbridge.template',
    'schemaVersion': schemaVersion,
    'id': id,
    'name': name,
    'description': description,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'components': [for (final c in components) c.toJson()],
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Strict parse; throws [TemplateFormatException] naming the bad field.
  factory OutputTemplate.fromJson(Map<String, Object?> j) {
    final schema = j['schemaVersion'];
    if (schema is! int) throw TemplateFormatException('schemaVersion', 'must be an integer');
    if (schema > currentSchema) throw TemplateFormatException('schemaVersion', 'is newer than supported ($currentSchema)');
    final name = j['name'];
    if (name is! String || name.trim().isEmpty) throw TemplateFormatException('name', 'must be a non-empty string');
    final list = j['components'];
    if (list is! List) throw TemplateFormatException('components', 'must be an array');
    if (list.length > maxComponents) throw TemplateFormatException('components', 'more than $maxComponents items');
    final components = <TemplateComponent>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) throw TemplateFormatException('components[$i]', 'must be an object');
      components.add(TemplateComponent.fromJson(item.cast<String, Object?>(), 'components[$i]'));
    }
    final ids = <String>{};
    for (var i = 0; i < components.length; i++) {
      if (!ids.add(components[i].id)) throw TemplateFormatException('components[$i].id', 'duplicate id');
    }
    final now = nowUtc();
    final version = j['version'];
    return OutputTemplate(
      id: (j['id'] is String && (j['id'] as String).isNotEmpty) ? j['id'] as String : newId(),
      name: name.trim(),
      description: j['description'] as String? ?? '',
      version: version is int && version > 0 ? version : 1,
      schemaVersion: schema,
      components: components,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toUtc() ?? now,
      updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '')?.toUtc() ?? now,
    );
  }

  /// Parses user-provided text; returns a typed failure instead of throwing.
  static Result<OutputTemplate> tryParse(String text) {
    try {
      final json = jsonDecode(text);
      if (json is! Map) return _fail('root', 'must be a JSON object');
      return Ok(OutputTemplate.fromJson(json.cast<String, Object?>()));
    } on FormatException catch (e) {
      return _fail('json', e.message);
    } on TemplateFormatException catch (e) {
      return _fail(e.field, e.reason);
    }
  }

  static Err<OutputTemplate> _fail(String field, String reason) => Err(AppFailure(
    FailureCode.templateValidationFailure,
    'Template field "$field" $reason',
    nextStep: 'Fix the field and import again.',
  ));
}
