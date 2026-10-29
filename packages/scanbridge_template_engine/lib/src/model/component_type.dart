/// Component catalog. Wire names are the SCREAMING_CASE `id`.
enum ComponentType {
  barcode('BARCODE'),
  text('TEXT'),
  number('NUMBER', prompts: true),
  selectOption('SELECT_OPTION', prompts: true),
  confirm('CONFIRM', prompts: true),
  pressKey('PRESS_KEY'),
  enter('ENTER'),
  tab('TAB'),
  dateTime('DATE_TIME'),
  timestamp('TIMESTAMP'),
  sessionName('SCAN_SESSION_NAME'),
  deviceName('DEVICE_NAME'),
  delay('DELAY'),
  ifStart('IF'),
  ifEnd('ENDIF'),
  validate('VALIDATE'),
  increment('INCREMENT'),
  uuid('UUID'),
  clipboard('CLIPBOARD'),
  beep('BEEP'),
  alert('ALERT'),
  skipOutput('SKIP_OUTPUT'),
  csvOutput('CSV_OUTPUT'),
  fileOutput('FILE_OUTPUT'),
  csvLookup('CSV_LOOKUP'),
  // Catalogued but not executable in this build; preserved on import.
  csvUpdate('CSV_UPDATE', available: false),
  excelOutput('EXCEL_OUTPUT', available: false),
  httpRequest('HTTP_REQUEST', available: false),
  javascript('JAVASCRIPT_FUNCTION', available: false),
  googleSheets('GOOGLE_SHEETS', available: false),
  image('IMAGE', available: false),
  geolocation('GEOLOCATION', available: false),
  nfc('NFC', available: false),
  wooCommerce('WOOCOMMERCE', available: false),
  run('RUN', available: false);

  const ComponentType(this.id, {this.prompts = false, this.available = true});

  final String id;

  /// Needs an operator answer collected on the phone before submit.
  final bool prompts;

  /// False for catalogued components without an implementation yet.
  final bool available;

  static ComponentType? fromId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Text prompt is a TEXT component with `ask: true`.
  static bool isPrompt(ComponentType? type, Map<String, Object?> config) =>
      type != null && (type.prompts || (type == text && config['ask'] == true));
}
