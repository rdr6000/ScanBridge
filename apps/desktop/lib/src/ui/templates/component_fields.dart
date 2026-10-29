import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

enum FieldKind { text, integer, number, boolean, choice, list }

/// Declarative config schema per component; drives the generic config form.
class ConfigField {
  const ConfigField(this.key, this.kind, {this.choices = const []});
  final String key;
  final FieldKind kind;
  final List<String> choices;
}

const _name = ConfigField('name', FieldKind.text);
const _ops = ['notEmpty', 'empty', 'equals', 'notEquals', 'contains', 'startsWith', 'endsWith', 'matches', 'gt', 'gte', 'lt', 'lte'];

List<ConfigField> fieldsFor(ComponentType? type) => switch (type) {
  ComponentType.text => const [_name, ConfigField('text', FieldKind.text), ConfigField('ask', FieldKind.boolean), ConfigField('default', FieldKind.text)],
  ComponentType.number => const [
    _name, ConfigField('default', FieldKind.text), ConfigField('min', FieldKind.number), ConfigField('max', FieldKind.number), //
    ConfigField('decimals', FieldKind.integer), ConfigField('required', FieldKind.boolean),
  ],
  ComponentType.selectOption => const [
    _name, ConfigField('options', FieldKind.list), ConfigField('default', FieldKind.text), //
    ConfigField('multi', FieldKind.boolean), ConfigField('required', FieldKind.boolean),
  ],
  ComponentType.pressKey => [
    ConfigField('key', FieldKind.choice, choices: KeyChord.namedKeys.toList()),
    const ConfigField('ctrl', FieldKind.boolean), const ConfigField('shift', FieldKind.boolean),
    const ConfigField('alt', FieldKind.boolean), const ConfigField('meta', FieldKind.boolean),
  ],
  ComponentType.dateTime => const [
    _name, ConfigField('format', FieldKind.text), ConfigField('source', FieldKind.choice, choices: ['now', 'scan']), //
    ConfigField('utc', FieldKind.boolean),
  ],
  ComponentType.timestamp => const [
    _name, ConfigField('format', FieldKind.choice, choices: ['iso', 'unix', 'unixMs']), //
    ConfigField('source', FieldKind.choice, choices: ['scan', 'now']),
  ],
  ComponentType.delay => const [ConfigField('ms', FieldKind.integer)],
  ComponentType.ifStart => const [ConfigField('left', FieldKind.text), ConfigField('op', FieldKind.choice, choices: _ops), ConfigField('right', FieldKind.text)],
  ComponentType.validate => const [
    ConfigField('value', FieldKind.text), ConfigField('pattern', FieldKind.text), ConfigField('minLength', FieldKind.integer), //
    ConfigField('maxLength', FieldKind.integer), ConfigField('min', FieldKind.number), ConfigField('max', FieldKind.number),
    ConfigField('onFail', FieldKind.choice, choices: ['stop', 'skip', 'continue']),
  ],
  ComponentType.increment => const [
    _name, ConfigField('counter', FieldKind.text), ConfigField('start', FieldKind.integer), //
    ConfigField('step', FieldKind.integer), ConfigField('pad', FieldKind.integer),
  ],
  ComponentType.clipboard => const [ConfigField('text', FieldKind.text)],
  ComponentType.alert => const [ConfigField('message', FieldKind.text)],
  ComponentType.csvOutput => const [ConfigField('path', FieldKind.text), ConfigField('columns', FieldKind.list), ConfigField('header', FieldKind.list)],
  ComponentType.fileOutput => const [ConfigField('path', FieldKind.text), ConfigField('line', FieldKind.text)],
  ComponentType.csvLookup => const [
    _name, ConfigField('path', FieldKind.text), ConfigField('key', FieldKind.text), ConfigField('keyColumn', FieldKind.text), //
    ConfigField('valueColumn', FieldKind.text), ConfigField('notFound', FieldKind.choice, choices: ['empty', 'stop']),
    ConfigField('fallback', FieldKind.text),
  ],
  ComponentType.barcode || ComponentType.confirm || ComponentType.uuid || ComponentType.sessionName || ComponentType.deviceName =>
    const [_name],
  _ => const [],
};

/// Converts form text into the stored JSON type; null removes the key.
Object? parseField(ConfigField f, String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  return switch (f.kind) {
    FieldKind.integer => int.tryParse(t),
    FieldKind.number => num.tryParse(t),
    FieldKind.list => t.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    _ => t,
  };
}

String formatField(ConfigField f, Object? value) => switch (value) {
  null => '',
  List() => value.join(', '),
  _ => '$value',
};
