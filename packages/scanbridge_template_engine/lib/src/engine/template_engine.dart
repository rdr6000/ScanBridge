import 'package:scanbridge_domain/scanbridge_domain.dart';

import '../model/component_type.dart';
import '../model/output_template.dart';
import '../model/template_component.dart';
import 'actions.dart';
import 'context.dart';
import 'evaluators.dart';
import 'interpolation.dart';

class TemplateRunResult {
  const TemplateRunResult({
    required this.actions,
    required this.variables,
    required this.counters,
    this.warnings = const [],
    this.failure,
    this.halted = false,
  });

  final List<OutputAction> actions;
  final Map<String, String> variables;
  final Map<String, int> counters;
  final List<String> warnings;
  final AppFailure? failure;

  /// Stopped intentionally (CONFIRM declined / VALIDATE skip); no output.
  final bool halted;

  bool get ok => failure == null;

  /// Plain text the keyboard would type, for previews and clipboard fallback.
  String get typedText => actions.map((a) => switch (a) {
    TypeTextAction(:final text) => text,
    KeyPressAction(:final chord) when chord.key == 'enter' && !chord.hasModifiers => '\n',
    KeyPressAction(:final chord) when chord.key == 'tab' && !chord.hasModifiers => '\t',
    _ => '',
  }).join();
}

/// Executes components in order with bounded steps and delays. Deterministic
/// for a given context except UUID/now-based components.
class TemplateEngine {
  const TemplateEngine();

  static const maxSteps = 1000;
  static const maxTotalDelay = Duration(seconds: 60);

  Future<TemplateRunResult> run(OutputTemplate template, ExecutionContext ctx) async {
    final vars = <String, String>{
      'barcode': ctx.barcode,
      'quantity': ctx.quantity,
      'symbology': ctx.symbology.name,
      'scan.timestamp': ctx.capturedAt.toUtc().toIso8601String(),
      'session.name': ctx.sessionName,
      'device.name': ctx.deviceName,
    };
    final counters = {...ctx.counters};
    final actions = <OutputAction>[];
    final warnings = <String>[];
    final branch = <bool>[];
    var totalDelay = Duration.zero;
    var skipKeyboard = false;
    var steps = 0;

    TemplateRunResult result({AppFailure? failure, bool halted = false}) => TemplateRunResult(
      actions: (failure != null || halted)
          ? const []
          : skipKeyboard
              ? actions.where((a) => !a.isKeyboard).toList()
              : actions,
      variables: vars,
      counters: counters,
      warnings: warnings,
      failure: failure,
      halted: halted,
    );

    for (final c in template.components) {
      if (++steps > maxSteps) return result(failure: templateFailure('Template exceeded $maxSteps steps'));
      final type = c.type;
      final running = branch.every((b) => b);
      if (type == ComponentType.ifStart) {
        branch.add(running && c.enabled ? _condition(c, vars) : running);
        continue;
      }
      if (type == ComponentType.ifEnd) {
        if (branch.isEmpty) {
          warnings.add('ENDIF without IF ignored');
        } else {
          branch.removeLast();
        }
        continue;
      }
      if (!running || !c.enabled) continue;
      if (type == null || !type.available) {
        warnings.add('${c.displayLabel} skipped: not available in this build');
        continue;
      }
      final out = await evaluate(c, type, ctx, vars, counters);
      if (out.warning != null) warnings.add(out.warning!);
      if (out.failure != null) return result(failure: templateFailure(out.failure!));
      if (out.halt) return result(halted: true);
      if (out.value != null) vars[c.variable] = out.value!;
      if (type == ComponentType.skipOutput) skipKeyboard = true;
      if (c.skipOutput) continue;
      for (final a in out.actions) {
        if (a is DelayAction) {
          totalDelay += a.duration;
          if (totalDelay > maxTotalDelay) return result(failure: templateFailure('Total delay exceeds ${maxTotalDelay.inSeconds}s'));
        }
        actions.add(a);
      }
    }
    if (branch.isNotEmpty) warnings.add('IF without matching ENDIF');
    return result();
  }

  bool _condition(TemplateComponent c, Map<String, String> vars) {
    final left = interpolate((c.config['left'] ?? '{{barcode}}').toString(), vars);
    final right = interpolate((c.config['right'] ?? '').toString(), vars);
    final l = num.tryParse(left);
    final r = num.tryParse(right);
    bool numeric(bool Function(num, num) f) => l != null && r != null && f(l, r);
    return switch ((c.config['op'] ?? 'notEmpty').toString()) {
      'equals' => left == right,
      'notEquals' => left != right,
      'contains' => left.contains(right),
      'startsWith' => left.startsWith(right),
      'endsWith' => left.endsWith(right),
      'matches' => _safeMatch(right, left),
      'empty' => left.isEmpty,
      'gt' => numeric((a, b) => a > b),
      'gte' => numeric((a, b) => a >= b),
      'lt' => numeric((a, b) => a < b),
      'lte' => numeric((a, b) => a <= b),
      _ => left.isNotEmpty,
    };
  }

  bool _safeMatch(String pattern, String input) {
    try {
      return RegExp(pattern).hasMatch(input);
    } on FormatException {
      return false;
    }
  }

  /// Editor-time structural problems (unbalanced IF, unknown types, bad keys).
  List<String> lint(OutputTemplate template) {
    final issues = <String>[];
    var depth = 0;
    for (final (i, c) in template.components.indexed) {
      if (c.type == ComponentType.ifStart) depth++;
      if (c.type == ComponentType.ifEnd && --depth < 0) {
        issues.add('Step ${i + 1}: ENDIF without IF');
        depth = 0;
      }
      if (!c.isKnown) issues.add('Step ${i + 1}: unknown component "${c.typeId}" kept disabled');
      if (c.type?.available == false) issues.add('Step ${i + 1}: ${c.typeId} is not available in this build');
    }
    if (depth > 0) issues.add('$depth IF without ENDIF');
    return issues;
  }
}
