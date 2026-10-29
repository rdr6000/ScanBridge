import 'package:intl/intl.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import '../model/component_type.dart';
import '../model/key_chord.dart';
import '../model/template_component.dart';
import 'actions.dart';
import 'context.dart';
import 'interpolation.dart';

/// What one component produced.
class ComponentOutput {
  const ComponentOutput({this.value, this.actions = const [], this.failure, this.halt = false, this.warning});
  final String? value;
  final List<OutputAction> actions;
  final String? failure;
  final bool halt;
  final String? warning;

  factory ComponentOutput.typed(String value) =>
      ComponentOutput(value: value, actions: value.isEmpty ? const [] : [TypeTextAction(value)]);
}

const maxDelay = Duration(seconds: 10);
final _decimal = RegExp(r'^-?\d+(\.\d+)?$');

String _cfg(TemplateComponent c, String key, [String fallback = '']) => (c.config[key] ?? fallback).toString();

Future<ComponentOutput> evaluate(
  TemplateComponent c,
  ComponentType type,
  ExecutionContext ctx,
  Map<String, String> vars,
  Map<String, int> counters,
) async {
  String fill(String key, [String fallback = '']) => interpolate(_cfg(c, key, fallback), vars);
  final answer = ctx.values[c.id];

  switch (type) {
    case ComponentType.barcode:
      return ComponentOutput.typed(ctx.barcode);
    case ComponentType.text:
      return ComponentOutput.typed(c.config['ask'] == true ? (answer ?? _cfg(c, 'default')) : fill('text'));
    case ComponentType.number:
      return _number(c, answer ?? _cfg(c, 'default'));
    case ComponentType.selectOption:
      return _select(c, answer ?? _cfg(c, 'default'));
    case ComponentType.confirm:
      return answer == 'yes'
          ? const ComponentOutput(value: 'yes')
          : const ComponentOutput(value: 'no', halt: true, warning: 'Operator did not confirm');
    case ComponentType.pressKey:
      final chord = KeyChord.fromJson(c.config);
      if (!chord.isValid) return ComponentOutput(failure: 'Unknown key "${chord.key}"');
      return ComponentOutput(value: '', actions: [KeyPressAction(chord)]);
    case ComponentType.enter:
      return const ComponentOutput(value: '', actions: [KeyPressAction(KeyChord.enter)]);
    case ComponentType.tab:
      return const ComponentOutput(value: '', actions: [KeyPressAction(KeyChord.tab)]);
    case ComponentType.dateTime:
      final base = _cfg(c, 'source', 'now') == 'scan' ? ctx.capturedAt : ctx.now;
      final dt = c.config['utc'] == true ? base.toUtc() : base.toLocal();
      try {
        return ComponentOutput.typed(DateFormat(_cfg(c, 'format', 'yyyy-MM-dd HH:mm:ss')).format(dt));
      } on Object {
        return const ComponentOutput(failure: 'Invalid date format');
      }
    case ComponentType.timestamp:
      final t = _cfg(c, 'source', 'scan') == 'now' ? ctx.now : ctx.capturedAt;
      return ComponentOutput.typed(switch (_cfg(c, 'format', 'iso')) {
        'unix' => '${t.millisecondsSinceEpoch ~/ 1000}',
        'unixMs' => '${t.millisecondsSinceEpoch}',
        _ => t.toUtc().toIso8601String(),
      });
    case ComponentType.sessionName:
      return ComponentOutput.typed(ctx.sessionName);
    case ComponentType.deviceName:
      return ComponentOutput.typed(ctx.deviceName);
    case ComponentType.delay:
      final ms = int.tryParse(_cfg(c, 'ms', '100')) ?? 100;
      final d = Duration(milliseconds: ms.clamp(0, maxDelay.inMilliseconds));
      return ComponentOutput(value: '', actions: [DelayAction(d)]);
    case ComponentType.validate:
      return _validate(c, fill('value', '{{barcode}}'));
    case ComponentType.increment:
      final name = _cfg(c, 'counter', c.id);
      final step = int.tryParse(_cfg(c, 'step', '1')) ?? 1;
      final start = int.tryParse(_cfg(c, 'start', '1')) ?? 1;
      final next = counters.containsKey(name) ? counters[name]! + step : start;
      counters[name] = next;
      final pad = int.tryParse(_cfg(c, 'pad', '0')) ?? 0;
      return ComponentOutput.typed('$next'.padLeft(pad, '0'));
    case ComponentType.uuid:
      return ComponentOutput.typed(newId());
    case ComponentType.clipboard:
      final text = fill('text', '{{barcode}}');
      return ComponentOutput(value: text, actions: [ClipboardAction(text)]);
    case ComponentType.beep:
      return const ComponentOutput(value: '', actions: [BeepAction()]);
    case ComponentType.alert:
      return ComponentOutput(value: '', actions: [AlertAction(fill('message', '{{barcode}}'))]);
    case ComponentType.skipOutput:
      return const ComponentOutput(value: '');
    case ComponentType.csvOutput:
      final columns = (c.config['columns'] as List? ?? const ['{{barcode}}', '{{quantity}}', '{{scan.timestamp}}'])
          .map((e) => interpolate('$e', vars))
          .toList();
      final header = (c.config['header'] as List?)?.map((e) => '$e').toList();
      return ComponentOutput(value: '', actions: [FileAppendAction(path: fill('path'), cells: columns, csv: true, header: header)]);
    case ComponentType.fileOutput:
      return ComponentOutput(value: '', actions: [FileAppendAction(path: fill('path'), cells: [fill('line', '{{barcode}}')], csv: false)]);
    case ComponentType.csvLookup:
      return _lookup(c, ctx, fill('key', '{{barcode}}'), fill('path'));
    case ComponentType.ifStart:
    case ComponentType.ifEnd:
    case ComponentType.csvUpdate:
    case ComponentType.excelOutput:
    case ComponentType.httpRequest:
    case ComponentType.javascript:
    case ComponentType.googleSheets:
    case ComponentType.image:
    case ComponentType.geolocation:
    case ComponentType.nfc:
    case ComponentType.wooCommerce:
    case ComponentType.run:
      return ComponentOutput(warning: '${c.displayLabel} is not available in this build');
  }
}

ComponentOutput _number(TemplateComponent c, String raw) {
  final v = raw.trim();
  if (v.isEmpty) return c.config['required'] == true ? ComponentOutput(failure: '${c.displayLabel} is required') : ComponentOutput.typed('');
  if (!_decimal.hasMatch(v)) return ComponentOutput(failure: '${c.displayLabel} must be a number');
  final n = num.parse(v);
  final min = num.tryParse(_cfg(c, 'min'));
  final max = num.tryParse(_cfg(c, 'max'));
  if (min != null && n < min) return ComponentOutput(failure: '${c.displayLabel} must be >= $min');
  if (max != null && n > max) return ComponentOutput(failure: '${c.displayLabel} must be <= $max');
  final decimals = int.tryParse(_cfg(c, 'decimals'));
  final places = v.contains('.') ? v.split('.').last.length : 0;
  if (decimals != null && places > decimals) return ComponentOutput(failure: '${c.displayLabel} allows $decimals decimals');
  return ComponentOutput.typed(v);
}

ComponentOutput _select(TemplateComponent c, String raw) {
  final options = (c.config['options'] as List? ?? const []).map((e) => '$e').toList();
  final picked = c.config['multi'] == true ? raw.split('|').where((e) => e.isNotEmpty).toList() : [if (raw.isNotEmpty) raw];
  if (picked.isEmpty && c.config['required'] == true) return ComponentOutput(failure: '${c.displayLabel} is required');
  if (options.isNotEmpty && picked.any((p) => !options.contains(p))) {
    return ComponentOutput(failure: '${c.displayLabel} has an option that is not allowed');
  }
  return ComponentOutput.typed(picked.join(_cfg(c, 'separator', ',')));
}

ComponentOutput _validate(TemplateComponent c, String value) {
  String? problem;
  final pattern = _cfg(c, 'pattern');
  if (pattern.isNotEmpty) {
    try {
      if (!RegExp(pattern).hasMatch(value)) problem = 'does not match pattern';
    } on FormatException {
      problem = 'has an invalid pattern';
    }
  }
  final minLen = int.tryParse(_cfg(c, 'minLength'));
  final maxLen = int.tryParse(_cfg(c, 'maxLength'));
  if (minLen != null && value.length < minLen) problem = 'is shorter than $minLen';
  if (maxLen != null && value.length > maxLen) problem = 'is longer than $maxLen';
  final min = num.tryParse(_cfg(c, 'min'));
  final max = num.tryParse(_cfg(c, 'max'));
  if (min != null || max != null) {
    final n = num.tryParse(value);
    if (n == null || (min != null && n < min) || (max != null && n > max)) problem = 'is out of range';
  }
  if (problem == null) return ComponentOutput(value: value);
  final message = '"$value" $problem';
  return switch (_cfg(c, 'onFail', 'stop')) {
    'continue' => ComponentOutput(value: value, warning: message),
    'skip' => ComponentOutput(value: value, halt: true, warning: message),
    _ => ComponentOutput(failure: message),
  };
}

Future<ComponentOutput> _lookup(TemplateComponent c, ExecutionContext ctx, String key, String path) async {
  final source = ctx.lookup;
  if (source == null) return ComponentOutput(value: '', warning: 'CSV lookup unavailable here');
  final found = await source.lookup(
    path: path,
    keyColumn: _cfg(c, 'keyColumn', '0'),
    key: key,
    valueColumn: _cfg(c, 'valueColumn', '1'),
  );
  if (found == null) {
    return _cfg(c, 'notFound', 'empty') == 'stop'
        ? ComponentOutput(failure: 'No row for "$key" in lookup file')
        : ComponentOutput.typed(_cfg(c, 'fallback'));
  }
  return ComponentOutput.typed(found);
}

/// Shared failure factory so codes stay consistent.
AppFailure templateFailure(String message) => AppFailure(
  FailureCode.templateValidationFailure,
  message,
  nextStep: 'Check the template configuration or the operator input.',
);
