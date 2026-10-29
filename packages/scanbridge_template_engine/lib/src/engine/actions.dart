import '../model/key_chord.dart';

/// Effects produced by a template run, executed later by output adapters.
sealed class OutputAction {
  const OutputAction();

  /// Human-readable line for dry-run previews.
  String describe();
}

class TypeTextAction extends OutputAction {
  const TypeTextAction(this.text);
  final String text;
  @override
  String describe() => 'Type "${text.replaceAll('\n', r'\n')}"';
}

class KeyPressAction extends OutputAction {
  const KeyPressAction(this.chord);
  final KeyChord chord;
  @override
  String describe() => 'Press $chord';
}

class DelayAction extends OutputAction {
  const DelayAction(this.duration);
  final Duration duration;
  @override
  String describe() => 'Wait ${duration.inMilliseconds} ms';
}

/// Appends one row/line to a file. Paths are validated by the file adapter.
class FileAppendAction extends OutputAction {
  const FileAppendAction({required this.path, required this.cells, required this.csv, this.header});
  final String path;
  final List<String> cells;
  final bool csv;
  final List<String>? header;
  @override
  String describe() => 'Append to $path: ${cells.join(csv ? ', ' : '')}';
}

class ClipboardAction extends OutputAction {
  const ClipboardAction(this.text);
  final String text;
  @override
  String describe() => 'Copy to clipboard "$text"';
}

class BeepAction extends OutputAction {
  const BeepAction();
  @override
  String describe() => 'Beep';
}

class AlertAction extends OutputAction {
  const AlertAction(this.message);
  final String message;
  @override
  String describe() => 'Alert "$message"';
}

/// Keyboard-bound actions; dropped when output is skipped or paused.
extension OutputActionKind on OutputAction {
  bool get isKeyboard => this is TypeTextAction || this is KeyPressAction || this is DelayAction;
}
