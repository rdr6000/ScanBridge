import 'enums.dart';

enum DuplicatePolicy { allow, warn, block }

/// User-configurable acceptance rules for a scanned value.
class ScanRules {
  const ScanRules({
    this.allowedFormats = const {},
    this.pattern,
    this.minLength,
    this.maxLength,
    this.requiredPrefix,
    this.requiredSuffix,
    this.duplicatePolicy = DuplicatePolicy.warn,
  });

  /// Empty means every format is accepted.
  final Set<Symbology> allowedFormats;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final String? requiredPrefix;
  final String? requiredSuffix;
  final DuplicatePolicy duplicatePolicy;

  Map<String, Object?> toJson() => {
    'allowedFormats': allowedFormats.map((f) => f.name).toList(),
    'pattern': pattern,
    'minLength': minLength,
    'maxLength': maxLength,
    'requiredPrefix': requiredPrefix,
    'requiredSuffix': requiredSuffix,
    'duplicatePolicy': duplicatePolicy.name,
  };

  factory ScanRules.fromJson(Map<String, Object?> json) => ScanRules(
    allowedFormats: {
      for (final f in (json['allowedFormats'] as List? ?? const [])) Symbology.parse(f as String),
    },
    pattern: _blankToNull(json['pattern']),
    minLength: json['minLength'] as int?,
    maxLength: json['maxLength'] as int?,
    requiredPrefix: _blankToNull(json['requiredPrefix']),
    requiredSuffix: _blankToNull(json['requiredSuffix']),
    duplicatePolicy: enumByName(
      DuplicatePolicy.values,
      json['duplicatePolicy'] as String?,
      DuplicatePolicy.warn,
    ),
  );
}

String? _blankToNull(Object? v) => (v is String && v.isNotEmpty) ? v : null;

class ValidationOutcome {
  const ValidationOutcome(this.status, [this.reason]);
  final ValidationStatus status;
  final String? reason;
  bool get accepted => status == ValidationStatus.valid || status == ValidationStatus.duplicate;
}

class ScanValidator {
  ScanValidator(this.rules) : _regex = _compile(rules.pattern);

  final ScanRules rules;
  final RegExp? _regex;

  static RegExp? _compile(String? p) {
    if (p == null) return null;
    try {
      return RegExp(p);
    } on FormatException {
      return null;
    }
  }

  /// Bad user regex is reported rather than silently accepting everything.
  bool get hasInvalidPattern => rules.pattern != null && _regex == null;

  ValidationOutcome validate(String value, Symbology symbology, {bool isDuplicate = false}) {
    if (value.isEmpty) return const ValidationOutcome(ValidationStatus.invalid, 'empty');
    final formats = rules.allowedFormats;
    if (formats.isNotEmpty && symbology != Symbology.unknown && !formats.contains(symbology)) {
      return ValidationOutcome(ValidationStatus.invalid, 'format ${symbology.name} not allowed');
    }
    if (rules.minLength != null && value.length < rules.minLength!) {
      return ValidationOutcome(ValidationStatus.invalid, 'shorter than ${rules.minLength}');
    }
    if (rules.maxLength != null && value.length > rules.maxLength!) {
      return ValidationOutcome(ValidationStatus.invalid, 'longer than ${rules.maxLength}');
    }
    if (rules.requiredPrefix != null && !value.startsWith(rules.requiredPrefix!)) {
      return const ValidationOutcome(ValidationStatus.invalid, 'missing prefix');
    }
    if (rules.requiredSuffix != null && !value.endsWith(rules.requiredSuffix!)) {
      return const ValidationOutcome(ValidationStatus.invalid, 'missing suffix');
    }
    if (hasInvalidPattern) {
      return const ValidationOutcome(ValidationStatus.invalid, 'invalid pattern setting');
    }
    if (_regex != null && !_regex.hasMatch(value)) {
      return const ValidationOutcome(ValidationStatus.invalid, 'pattern mismatch');
    }
    if (isDuplicate) {
      return switch (rules.duplicatePolicy) {
        DuplicatePolicy.block => const ValidationOutcome(ValidationStatus.invalid, 'duplicate'),
        DuplicatePolicy.warn => const ValidationOutcome(ValidationStatus.duplicate, 'duplicate'),
        DuplicatePolicy.allow => const ValidationOutcome(ValidationStatus.valid),
      };
    }
    return const ValidationOutcome(ValidationStatus.valid);
  }
}
