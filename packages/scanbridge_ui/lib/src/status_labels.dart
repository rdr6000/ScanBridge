import 'package:flutter/material.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'l10n/sb_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

/// Localized label + tone for domain statuses; one place for consistency.
extension DeliveryStatusUi on DeliveryStatus {
  Tone get tone => switch (this) {
    DeliveryStatus.received => Tone.success,
    DeliveryStatus.queued || DeliveryStatus.captured => Tone.info,
    DeliveryStatus.failed || DeliveryStatus.rejected => Tone.error,
    DeliveryStatus.localOnly => Tone.neutral,
  };

  String label(SbLocalizations l) => switch (this) {
    DeliveryStatus.captured => l.statusCaptured,
    DeliveryStatus.queued => l.statusQueued,
    DeliveryStatus.received => l.statusDelivered,
    DeliveryStatus.rejected => l.statusRejected,
    DeliveryStatus.failed => l.statusFailed,
    DeliveryStatus.localOnly => l.statusLocalOnly,
  };
}

extension OutputStatusUi on OutputStatus {
  Tone get tone => switch (this) {
    OutputStatus.succeeded => Tone.success,
    OutputStatus.pending => Tone.info,
    OutputStatus.failed => Tone.error,
    OutputStatus.paused || OutputStatus.skipped => Tone.warning,
    OutputStatus.none => Tone.neutral,
  };

  String label(SbLocalizations l) => switch (this) {
    OutputStatus.none => l.outputNone,
    OutputStatus.pending => l.outputPending,
    OutputStatus.succeeded => l.outputSucceeded,
    OutputStatus.failed => l.outputFailed,
    OutputStatus.skipped => l.outputSkipped,
    OutputStatus.paused => l.outputPaused,
  };
}

extension ValidationStatusUi on ValidationStatus {
  Tone get tone => switch (this) {
    ValidationStatus.valid => Tone.success,
    ValidationStatus.duplicate => Tone.warning,
    ValidationStatus.invalid => Tone.error,
    ValidationStatus.unchecked => Tone.neutral,
  };

  String label(SbLocalizations l) => switch (this) {
    ValidationStatus.valid => l.validationValid,
    ValidationStatus.duplicate => l.validationDuplicate,
    ValidationStatus.invalid => l.validationInvalid,
    ValidationStatus.unchecked => l.validationUnchecked,
  };
}

/// Ready-made chips for a scan row.
class ScanStatusChips extends StatelessWidget {
  const ScanStatusChips(this.scan, {super.key, this.showOutput = true});
  final ScanRecord scan;
  final bool showOutput;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(spacing: Sb.xs, runSpacing: Sb.xs, children: [
      StatusChip(scan.deliveryStatus.label(l), scan.deliveryStatus.tone),
      if (scan.validationStatus != ValidationStatus.valid && scan.validationStatus != ValidationStatus.unchecked)
        StatusChip(scan.validationStatus.label(l), scan.validationStatus.tone),
      if (showOutput && scan.outputStatus != OutputStatus.none) StatusChip(scan.outputStatus.label(l), scan.outputStatus.tone),
    ]);
  }
}

String formatLocal(BuildContext context, DateTime utc) {
  final local = utc.toLocal();
  final loc = MaterialLocalizations.of(context);
  return '${loc.formatShortDate(local)} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
}
