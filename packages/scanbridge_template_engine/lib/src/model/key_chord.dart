/// Platform-neutral key + modifiers. Adapters map `key` to native codes.
class KeyChord {
  const KeyChord(this.key, {this.ctrl = false, this.shift = false, this.alt = false, this.meta = false});

  /// Named key (see [namedKeys]) or a single printable character.
  final String key;
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;

  static const namedKeys = {
    'enter', 'tab', 'escape', 'backspace', 'delete', 'space', 'up', 'down', 'left', 'right', //
    'home', 'end', 'pageUp', 'pageDown', 'insert',
    'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
  };

  static const enter = KeyChord('enter');
  static const tab = KeyChord('tab');

  bool get isValid => namedKeys.contains(key) || key.runes.length == 1;

  bool get hasModifiers => ctrl || shift || alt || meta;

  /// Chords that may change or remove data in the focused app.
  bool get isDestructive => key == 'delete' || key == 'backspace' || ((ctrl || meta || alt) && key != 'tab');

  @override
  String toString() => [if (ctrl) 'Ctrl', if (alt) 'Alt', if (shift) 'Shift', if (meta) 'Meta', key].join('+');

  Map<String, Object?> toJson() => {'key': key, 'ctrl': ctrl, 'shift': shift, 'alt': alt, 'meta': meta};

  factory KeyChord.fromJson(Map<String, Object?> j) => KeyChord(
    j['key'] as String? ?? 'enter',
    ctrl: j['ctrl'] == true,
    shift: j['shift'] == true,
    alt: j['alt'] == true,
    meta: j['meta'] == true,
  );

  @override
  bool operator ==(Object other) => other is KeyChord && other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;
}
