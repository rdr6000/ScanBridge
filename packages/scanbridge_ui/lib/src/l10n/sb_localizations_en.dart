// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'sb_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SbLocalizationsEn extends SbLocalizations {
  SbLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ScanBridge';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navFeed => 'Live feed';

  @override
  String get navSessions => 'Sessions';

  @override
  String get navDevices => 'Devices';

  @override
  String get navTemplates => 'Templates';

  @override
  String get navKeyboardTest => 'Keyboard test';

  @override
  String get navSettings => 'Settings';

  @override
  String get navDiagnostics => 'Diagnostics';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get rename => 'Rename';

  @override
  String get archive => 'Archive';

  @override
  String get archived => 'Archived';

  @override
  String get restore => 'Restore';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get merge => 'Merge';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get preview => 'Preview';

  @override
  String get approve => 'Approve';

  @override
  String get decline => 'Decline';

  @override
  String get enable => 'Enable';

  @override
  String get change => 'Change';

  @override
  String get back => 'Back';

  @override
  String get forget => 'Forget';

  @override
  String get revoke => 'Revoke';

  @override
  String get moreActions => 'More actions';

  @override
  String get selectAll => 'Select all';

  @override
  String get name => 'Name';

  @override
  String get label => 'Label';

  @override
  String get value => 'Value';

  @override
  String get quantity => 'Quantity';

  @override
  String get quantityShort => 'Qty';

  @override
  String get symbology => 'Format';

  @override
  String get capturedAt => 'Captured';

  @override
  String get receivedAt => 'Received';

  @override
  String get source => 'Source';

  @override
  String get device => 'Device';

  @override
  String get template => 'Template';

  @override
  String get port => 'Port';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get errorCode => 'Error code';

  @override
  String get pressEnterToSave => 'Press Enter to save';

  @override
  String get commaSeparated => 'Comma separated';

  @override
  String get statusCaptured => 'Captured';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusLocalOnly => 'Local only';

  @override
  String get outputNone => 'No output';

  @override
  String get outputPending => 'Output pending';

  @override
  String get outputSucceeded => 'Typed';

  @override
  String get outputFailed => 'Output failed';

  @override
  String get outputSkipped => 'Skipped';

  @override
  String get outputPaused => 'Paused';

  @override
  String get validationValid => 'Valid';

  @override
  String get validationDuplicate => 'Duplicate';

  @override
  String get validationInvalid => 'Invalid';

  @override
  String get validationUnchecked => 'Unchecked';

  @override
  String serverRunning(int port) {
    return 'Server running on port $port';
  }

  @override
  String get serverStarting => 'Server starting…';

  @override
  String get serverError => 'Server error';

  @override
  String get serverStopped => 'Server stopped';

  @override
  String devicesConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phones connected',
      one: '1 phone connected',
      zero: 'No phones connected',
    );
    return '$_temp0';
  }

  @override
  String get lanModeOn => 'LAN mode';

  @override
  String get keyboardArmed => 'Keyboard output armed';

  @override
  String get keyboardPaused => 'Keyboard output paused';

  @override
  String get pauseShortcutHint =>
      'Ctrl+Shift+P toggles output while this window is focused. Scans are still saved while paused.';

  @override
  String get serverTitle => 'Server';

  @override
  String get startServer => 'Start server';

  @override
  String get stopServer => 'Stop server';

  @override
  String get lanModeTitle => 'Allow phones on my local network';

  @override
  String get lanModeOnHint => 'Listening on all network interfaces.';

  @override
  String get lanModeOffHint => 'Only this computer can connect (localhost).';

  @override
  String get lanModeWarning =>
      'Other devices on this network will be able to reach the server. Every phone must still be paired and approved, and messages are signed, but traffic is not encrypted. Use only on networks you trust.';

  @override
  String get recentScans => 'Recent scans';

  @override
  String get openFeed => 'Open feed';

  @override
  String outputFailuresCount(int count) {
    return '$count output failures';
  }

  @override
  String get noScansTitle => 'No scans yet';

  @override
  String get noScansDesktopHint =>
      'Pair a phone and scan a code. Scans appear here as soon as the phone sends them.';

  @override
  String get gettingStarted => 'Getting started';

  @override
  String get stepLan => 'Allow phones on the local network';

  @override
  String get stepStart => 'Start the server';

  @override
  String get stepPair => 'Pair a phone with the QR code';

  @override
  String get stepKeyboard => 'Test keyboard output';

  @override
  String get stepScan => 'Scan your first code';

  @override
  String get pairTitle => 'Pair a phone';

  @override
  String get pairStartServerFirst => 'Start the server to pair a phone.';

  @override
  String get pairHint =>
      'Show a one-time QR code, then scan it with the ScanBridge phone app.';

  @override
  String get pairNeedsLan =>
      'Phones can only reach this computer after you allow the local network above.';

  @override
  String get showPairingQr => 'Show pairing QR';

  @override
  String get pairingQrLabel => 'Pairing QR code';

  @override
  String get pairingCode => 'Pairing code';

  @override
  String pairExpiresIn(int seconds) {
    return 'Expires in $seconds s';
  }

  @override
  String get pairSingleUse => 'Works once. A wrong code also uses it up.';

  @override
  String get regenerate => 'New code';

  @override
  String get pairApproveTitle => 'Approve this phone?';

  @override
  String pairApproveBody(String name, String platform, String address) {
    return '\"$name\" ($platform) at $address wants to send scans to this computer.';
  }

  @override
  String get searchScans => 'Search scans';

  @override
  String get filterAll => 'All';

  @override
  String get filterFailed => 'Output failed';

  @override
  String get filterPaused => 'Paused / needs confirmation';

  @override
  String get filterDuplicates => 'Duplicates';

  @override
  String get selectScanTitle => 'Select a scan';

  @override
  String get selectScanHint => 'Details, preview and resend appear here.';

  @override
  String get resend => 'Resend output';

  @override
  String get resendTitle => 'Run output again?';

  @override
  String get resendWarning =>
      'If the first attempt partly typed into an app, running again may type the value twice. Check the target first.';

  @override
  String get confirmAndRun => 'Confirm and run';

  @override
  String get editValue => 'Edit value';

  @override
  String get editQuantity => 'Edit quantity';

  @override
  String get scanDeleted => 'Scan deleted';

  @override
  String get dryRunTitle => 'Dry run';

  @override
  String get dryRunHalted =>
      'The template stopped without output (confirmation declined or validation skip).';

  @override
  String get dryRunNoActions => 'This template produces no output.';

  @override
  String get searchSessions => 'Search sessions';

  @override
  String get newSession => 'New session';

  @override
  String get sortUpdated => 'Recently updated';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortName => 'Name';

  @override
  String get noSessionsTitle => 'No sessions';

  @override
  String get noSessionsHint =>
      'Sessions are created automatically when a phone sends its first scan, or create one now.';

  @override
  String scansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans',
      one: '1 scan',
    );
    return '$_temp0';
  }

  @override
  String get deleteSessionTitle => 'Delete session?';

  @override
  String deleteSessionBody(String name, int count) {
    return '\"$name\" and its $count scans will be permanently deleted from this device.';
  }

  @override
  String get mergeSessions => 'Merge sessions';

  @override
  String mergeSessionsBody(int count, String name) {
    return 'Move all scans from $count sessions into \"$name\"?';
  }

  @override
  String get deleteScansTitle => 'Delete scans?';

  @override
  String deleteScansBody(int count) {
    return 'Delete $count selected scans? You can undo right after.';
  }

  @override
  String scansDeleted(int count) {
    return '$count scans deleted';
  }

  @override
  String get dedupeTitle => 'Remove duplicates';

  @override
  String get dedupeNone => 'No duplicate values in this session.';

  @override
  String dedupeBody(int count) {
    return '$count extra copies will be removed; the first scan of each value is kept.';
  }

  @override
  String get removeDuplicates => 'Remove duplicates';

  @override
  String exportSelected(int count) {
    return 'Export $count';
  }

  @override
  String exportTitle(int count) {
    return 'Export $count scans';
  }

  @override
  String exportDone(String path) {
    return 'Saved to $path';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error. Your scans are unchanged.';
  }

  @override
  String get csvBom => 'Add UTF-8 BOM (helps Excel detect Unicode)';

  @override
  String get csvFormulaGuard =>
      'Spreadsheet-safe values (prevent formula injection)';

  @override
  String get csvFormulaGuardOffWarning =>
      'Values starting with = + - @ may run as formulas when opened in a spreadsheet.';

  @override
  String get noDevicesTitle => 'No paired phones';

  @override
  String get noDevicesHint =>
      'Start the server and show a pairing QR on the dashboard.';

  @override
  String get deviceOnline => 'Online';

  @override
  String get devicePaired => 'Paired';

  @override
  String get deviceRevoked => 'Revoked';

  @override
  String get devicePending => 'Pending';

  @override
  String lastSeen(String time) {
    return 'last seen $time';
  }

  @override
  String get allowScans => 'Allow this phone to send scans';

  @override
  String revokeBody(String name) {
    return '\"$name\" will be disconnected and must be paired again.';
  }

  @override
  String forgetBody(String name) {
    return 'Remove \"$name\" from this computer. Its scans are kept.';
  }

  @override
  String get forgetAll => 'Forget all';

  @override
  String get forgetAllTitle => 'Forget all paired phones?';

  @override
  String forgetAllBody(int count) {
    return '$count phones will be disconnected and must be paired again. Scans are kept.';
  }

  @override
  String get newTemplate => 'New template';

  @override
  String get templatesHint =>
      'The selected template runs for scans that do not name one. Phones collect prompt answers for it.';

  @override
  String componentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String deleteTemplateBody(String name) {
    return 'Delete template \"$name\" and its version history?';
  }

  @override
  String get importFailed => 'Import failed';

  @override
  String importPreviewTitle(String name) {
    return 'Import \"$name\"?';
  }

  @override
  String importPreviewBody(int count) {
    return '$count steps. Unknown steps are kept but disabled.';
  }

  @override
  String get addComponent => 'Add step';

  @override
  String get notAvailableYet => 'not available yet';

  @override
  String get noComponentsTitle => 'Empty template';

  @override
  String get noComponentsHint =>
      'Add steps such as BARCODE and ENTER. They run top to bottom.';

  @override
  String templateSaved(int version) {
    return 'Saved as version $version';
  }

  @override
  String get skipOutput => 'Skip output (value still available as a variable)';

  @override
  String get sampleBarcode => 'Sample barcode';

  @override
  String get runPreview => 'Run preview';

  @override
  String get variablesHint =>
      'Variables: barcode, quantity, scan.timestamp, session.name, device.name or a step name, each wrapped in double curly braces.';

  @override
  String get formView => 'Form';

  @override
  String get jsonView => 'JSON';

  @override
  String get keyboardCapability => 'Keyboard output on this computer';

  @override
  String get keyboardTestTitle => 'Send a test sequence';

  @override
  String get testSequence => 'Text to type';

  @override
  String get appendEnter => 'Press Enter afterwards';

  @override
  String sequencePreview(String text, String suffix) {
    return 'Preview: type \"$text\" then $suffix';
  }

  @override
  String get testTarget => 'Test field';

  @override
  String get sendTestHere => 'Type into the field above';

  @override
  String get sendTestOtherApp => 'Type into another app in 5 s';

  @override
  String switchWindowCountdown(int seconds) {
    return 'Switch to the target window… $seconds';
  }

  @override
  String get keyboardTestOk => 'Windows accepted every key event.';

  @override
  String get keyboardLimitations =>
      'Typing goes to whichever window has focus. Apps running as administrator, the lock screen and some games block simulated input; use clipboard or file output there.';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsNetwork => 'Network';

  @override
  String get settingsKeyboard => 'Keyboard output';

  @override
  String get settingsFiles => 'Files and exports';

  @override
  String get settingsData => 'Data and backups';

  @override
  String get serverName => 'Computer name shown on phones';

  @override
  String get autoStartServer => 'Start server when the app opens';

  @override
  String get keyDelay => 'Delay between keys (ms)';

  @override
  String get clipboardFallback =>
      'Paste via clipboard when typing is unavailable';

  @override
  String get clipboardFallbackHint =>
      'Overwrites the clipboard briefly and restores previous text afterwards.';

  @override
  String get confirmDestructive =>
      'Confirm before running key combinations like Ctrl+…, Delete';

  @override
  String get confirmDestructiveHint =>
      'Such scans wait in the feed until you confirm them.';

  @override
  String get outputFolder => 'Output folder (file steps can only write here)';

  @override
  String get dataLocation => 'Database';

  @override
  String get databaseSize => 'Size';

  @override
  String get backupDatabase => 'Back up database';

  @override
  String backupDone(String path) {
    return 'Backup saved to $path';
  }

  @override
  String get restoreHint =>
      'To restore: close ScanBridge and replace the database file above with a backup copy.';

  @override
  String get copyDiagnostics => 'Copy diagnostics';

  @override
  String get diagnosticsCopied =>
      'Diagnostics copied (no scan values or secrets included)';

  @override
  String get capabilities => 'Capabilities';

  @override
  String get firewallTitle => 'Firewall and network';

  @override
  String firewallWindows(int port) {
    return 'Windows Defender Firewall asks once when the server first listens on the network; allow it on Private networks. If phones cannot connect, check Windows Security > Firewall > Allow an app, and that TCP port $port is allowed on your private network. ScanBridge never changes firewall rules itself.';
  }

  @override
  String get firewallMac =>
      'macOS may ask to allow incoming connections; choose Allow. Check System Settings > Network > Firewall if phones cannot connect.';

  @override
  String firewallLinux(int port) {
    return 'If a firewall (ufw, firewalld) is active, allow TCP port $port from your local network, for example: sudo ufw allow from 192.168.0.0/16 to any port $port proto tcp';
  }

  @override
  String get recentErrors => 'Recent errors';

  @override
  String get noErrors => 'No errors recorded.';

  @override
  String get auditLog => 'Audit log';

  @override
  String linkConnected(String name) {
    return 'Connected to $name';
  }

  @override
  String get linkConnecting => 'Connecting…';

  @override
  String get linkReconnecting => 'Reconnecting…';

  @override
  String get linkAwaitingApproval => 'Waiting for approval on the computer';

  @override
  String get linkDisconnected => 'Disconnected';

  @override
  String get linkError => 'Connection problem';

  @override
  String get linkNotPaired => 'Not paired — scans stay on this phone';

  @override
  String pendingCount(int count) {
    return '$count waiting to send';
  }

  @override
  String get activeSession => 'Active session';

  @override
  String get noActiveSession => 'A session is created on first scan';

  @override
  String get scanButton => 'Scan';

  @override
  String get scanSingle => 'Single scan';

  @override
  String get scanContinuous => 'Continuous scan';

  @override
  String get manualEntry => 'Manual entry';

  @override
  String get hardwareScanner => 'Hardware scanner';

  @override
  String get noScansMobileHint =>
      'Tap Scan to capture a code. Scans are saved on this phone first, then sent.';

  @override
  String get torch => 'Flashlight';

  @override
  String get switchCamera => 'Switch camera';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String get cameraPermissionDenied =>
      'Camera permission was denied. Allow it in system settings, or use manual entry.';

  @override
  String get scannerHint => 'Place the code inside the frame';

  @override
  String get scannerPaused => 'Paused';

  @override
  String scannedThisRun(int count) {
    return '$count saved';
  }

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String scanRejected(String reason) {
    return 'Not saved: $reason';
  }

  @override
  String savedScan(String value) {
    return 'Saved $value';
  }

  @override
  String savedDuplicate(String value) {
    return 'Saved $value (duplicate)';
  }

  @override
  String get saveScan => 'Save scan';

  @override
  String get manualHint => 'Type or paste a code and press Enter.';

  @override
  String get hardwareHint =>
      'Keep this field focused and scan with a Bluetooth/USB keyboard-wedge scanner configured to send Enter after each code.';

  @override
  String get connectTitle => 'Connect to computer';

  @override
  String get scanPairingQr => 'Scan pairing QR';

  @override
  String get manualPairTitle => 'Or enter details';

  @override
  String get hostAddress => 'Computer IP address';

  @override
  String get pair => 'Pair';

  @override
  String get manualPairInvalid =>
      'Enter the IP address, port and the 10-character code shown on the computer.';

  @override
  String get pairedOk => 'Paired. Scans will now be sent to the computer.';

  @override
  String get approveOnComputer => 'Approve this phone on the computer screen.';

  @override
  String get pairedComputer => 'Paired computer';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get forgetHostBody =>
      'This phone will stop sending to this computer. Scans already on the phone are kept.';

  @override
  String get connectTroubleshooting =>
      'Can\'t connect? Both devices must be on the same Wi-Fi (guest networks often isolate devices), the desktop must allow phones on the local network, and its firewall must allow ScanBridge. On iPhone/iPad, allow Local Network for ScanBridge in Settings > Privacy & Security > Local Network.';

  @override
  String get useSession => 'Use for scanning';

  @override
  String get sessionScans => 'Session scans';

  @override
  String resendUnsent(int count) {
    return 'Send $count unsent scans';
  }

  @override
  String get deviceName => 'Phone name shown on the computer';

  @override
  String get defaultScanMode => 'Default scan mode';

  @override
  String get modeSingle => 'Single';

  @override
  String get modeContinuous => 'Continuous';

  @override
  String get haptics => 'Vibrate on scan';

  @override
  String get sound => 'Sound on scan';

  @override
  String get settingsScanning => 'Scanning';

  @override
  String get defaultQuantity => 'Default quantity';

  @override
  String get askQuantity => 'Ask for quantity on every scan';

  @override
  String get duplicates => 'Duplicates in a session';

  @override
  String get dupAllow => 'Allow';

  @override
  String get dupWarn => 'Warn';

  @override
  String get dupBlock => 'Block';

  @override
  String get formats => 'Accepted formats';

  @override
  String get allFormats => 'All supported formats';

  @override
  String get validation => 'Validation';

  @override
  String get pattern => 'Regular expression';

  @override
  String get minLength => 'Minimum length';

  @override
  String get maxLength => 'Maximum length';

  @override
  String get requiredPrefix => 'Required prefix';

  @override
  String get requiredSuffix => 'Required suffix';

  @override
  String get hardwareDebounce => 'Hardware scanner repeat guard (ms)';

  @override
  String get outputTemplate => 'Output template';

  @override
  String get templatesFromComputer =>
      'Templates arrive from the computer after connecting.';

  @override
  String get templateOverrideHint =>
      'Choose a template or use the computer\'s active one.';

  @override
  String get computerDefault => 'Computer default';

  @override
  String get refreshTemplates => 'Refresh templates from computer';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyMobile =>
      'ScanBridge has no account, no telemetry and no cloud. Scans are stored on this phone and sent only to the computer you paired, on your local network.';
}
