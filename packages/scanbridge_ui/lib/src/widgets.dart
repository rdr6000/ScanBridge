import 'package:flutter/material.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'l10n/sb_localizations.dart';
import 'theme.dart';

extension L10nX on BuildContext {
  SbLocalizations get l10n => SbLocalizations.of(this);
}

/// Compact colored status label with an accessible text.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.tone, {super.key, this.icon});
  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = context.statusColors.of(tone);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sb.s, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(Sb.radius),
          border: Border.all(color: color.withValues(alpha: .5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: Sb.xs)],
          Text(label, style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// Explains why a list is empty and what to do next.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Sb.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: context.colors.outline),
        const SizedBox(height: Sb.m),
        Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: Sb.s),
        Text(message, style: context.text.bodyMedium, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: Sb.m), action!],
      ]),
    ),
  );
}

/// What failed, likely cause / next step, and error code.
class FailureBanner extends StatelessWidget {
  const FailureBanner(this.failure, {super.key, this.onRetry});
  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final color = context.statusColors.error;
    return Card(
      color: color.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.all(Sb.m),
        child: Row(children: [
          Icon(Icons.error_outline, color: color),
          const SizedBox(width: Sb.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(failure.message, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (failure.nextStep != null) Text(failure.nextStep!, style: context.text.bodySmall),
              Text('${context.l10n.errorCode}: ${failure.code.name}', style: context.text.labelSmall),
            ]),
          ),
          if (onRetry != null && failure.retryable) TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ]),
      ),
    );
  }
}

/// Section with a title and content, used on settings/dashboard pages.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(Sb.m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          ?trailing,
        ]),
        const SizedBox(height: Sb.s),
        child,
      ]),
    ),
  );
}

Future<bool> confirmAction(BuildContext context, {required String title, required String message, required String confirmLabel, bool destructive = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Text(message)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l10n.cancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: c.statusColors.error) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> promptText(BuildContext context, {required String title, String initial = '', String? label}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(c, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(c.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: Text(c.l10n.save)),
      ],
    ),
  );
}
