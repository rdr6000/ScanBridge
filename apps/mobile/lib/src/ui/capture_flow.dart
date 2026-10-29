import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../services.dart';
import 'prompt_sheet.dart';

/// Shared path for camera, manual and hardware input: validate, prompt, save.
/// Returns true when a scan was stored.
Future<bool> submitCode(BuildContext context, WidgetRef ref, String value, Symbology symbology, ScanSource source) async {
  final l = context.l10n;
  final capture = ref.read(servicesProvider).capture;
  final messenger = ScaffoldMessenger.of(context);
  final check = await capture.check(value, symbology);
  if (!check.outcome.accepted) {
    await capture.feedback(ok: false);
    messenger.showSnackBar(SnackBar(content: Text(l.scanRejected(check.outcome.reason ?? ''))));
    return false;
  }
  var values = const <String, String>{};
  if (check.needsPrompts) {
    if (!context.mounted) return false;
    final answers = await showPromptSheet(context, check.template!, value);
    if (answers == null) return false;
    values = answers;
  }
  String? quantity;
  final s = ref.read(servicesProvider).settings.current;
  if (s.askQuantity && !values.containsKey('qty') && context.mounted) {
    quantity = await promptText(context, title: l.quantity, initial: s.defaultQuantity);
    if (quantity == null) return false;
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(quantity)) quantity = s.defaultQuantity;
  }
  await capture.save(
    value: value,
    symbology: symbology,
    source: source,
    outcome: check.outcome,
    template: check.template,
    values: values,
    quantity: quantity,
  );
  await capture.feedback(ok: true);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    duration: const Duration(milliseconds: 1200),
    content: Text(check.outcome.status == ValidationStatus.duplicate ? l.savedDuplicate(value) : l.savedScan(value)),
  ));
  return true;
}
