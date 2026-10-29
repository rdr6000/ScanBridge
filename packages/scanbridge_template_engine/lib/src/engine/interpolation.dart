import 'dart:convert';

enum EscapeMode { none, json, url }

final _placeholder = RegExp(r'\{\{\s*([A-Za-z0-9_.\-]+)\s*\}\}');

/// Replaces `{{name}}` with variable values; unknown names become empty.
String interpolate(String template, Map<String, String> vars, {EscapeMode escape = EscapeMode.none}) =>
    template.replaceAllMapped(_placeholder, (m) {
      final v = vars[m[1]!] ?? '';
      return switch (escape) {
        EscapeMode.none => v,
        EscapeMode.json => _jsonInner(v),
        EscapeMode.url => Uri.encodeComponent(v),
      };
    });

String _jsonInner(String v) {
  final quoted = jsonEncode(v);
  return quoted.substring(1, quoted.length - 1);
}

/// Names referenced by a template string, for editor validation.
Set<String> referencedVariables(String template) => _placeholder.allMatches(template).map((m) => m[1]!).toSet();
