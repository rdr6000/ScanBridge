import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'sb_localizations_en.dart';
import 'sb_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SbLocalizations
/// returned by `SbLocalizations.of(context)`.
///
/// Applications need to include `SbLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/sb_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SbLocalizations.localizationsDelegates,
///   supportedLocales: SbLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SbLocalizations.supportedLocales
/// property.
abstract class SbLocalizations {
  SbLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SbLocalizations of(BuildContext context) {
    return Localizations.of<SbLocalizations>(context, SbLocalizations)!;
  }

  static const LocalizationsDelegate<SbLocalizations> delegate =
      _SbLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ScanBridge'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Live feed'**
  String get navFeed;

  /// No description provided for @navSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get navSessions;

  /// No description provided for @navDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get navDevices;

  /// No description provided for @navTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get navTemplates;

  /// No description provided for @navKeyboardTest.
  ///
  /// In en, this message translates to:
  /// **'Keyboard test'**
  String get navKeyboardTest;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get navDiagnostics;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quantityShort.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantityShort;

  /// No description provided for @symbology.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get symbology;

  /// No description provided for @capturedAt.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get capturedAt;

  /// No description provided for @receivedAt.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedAt;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'Error code'**
  String get errorCode;

  /// No description provided for @pressEnterToSave.
  ///
  /// In en, this message translates to:
  /// **'Press Enter to save'**
  String get pressEnterToSave;

  /// No description provided for @commaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Comma separated'**
  String get commaSeparated;

  /// No description provided for @statusCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get statusCaptured;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get statusLocalOnly;

  /// No description provided for @outputNone.
  ///
  /// In en, this message translates to:
  /// **'No output'**
  String get outputNone;

  /// No description provided for @outputPending.
  ///
  /// In en, this message translates to:
  /// **'Output pending'**
  String get outputPending;

  /// No description provided for @outputSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Typed'**
  String get outputSucceeded;

  /// No description provided for @outputFailed.
  ///
  /// In en, this message translates to:
  /// **'Output failed'**
  String get outputFailed;

  /// No description provided for @outputSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get outputSkipped;

  /// No description provided for @outputPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get outputPaused;

  /// No description provided for @validationValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get validationValid;

  /// No description provided for @validationDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get validationDuplicate;

  /// No description provided for @validationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get validationInvalid;

  /// No description provided for @validationUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Unchecked'**
  String get validationUnchecked;

  /// No description provided for @serverRunning.
  ///
  /// In en, this message translates to:
  /// **'Server running on port {port}'**
  String serverRunning(int port);

  /// No description provided for @serverStarting.
  ///
  /// In en, this message translates to:
  /// **'Server starting…'**
  String get serverStarting;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @serverStopped.
  ///
  /// In en, this message translates to:
  /// **'Server stopped'**
  String get serverStopped;

  /// No description provided for @devicesConnected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No phones connected} =1{1 phone connected} other{{count} phones connected}}'**
  String devicesConnected(int count);

  /// No description provided for @lanModeOn.
  ///
  /// In en, this message translates to:
  /// **'LAN mode'**
  String get lanModeOn;

  /// No description provided for @keyboardArmed.
  ///
  /// In en, this message translates to:
  /// **'Keyboard output armed'**
  String get keyboardArmed;

  /// No description provided for @keyboardPaused.
  ///
  /// In en, this message translates to:
  /// **'Keyboard output paused'**
  String get keyboardPaused;

  /// No description provided for @pauseShortcutHint.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Shift+P toggles output while this window is focused. Scans are still saved while paused.'**
  String get pauseShortcutHint;

  /// No description provided for @serverTitle.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverTitle;

  /// No description provided for @startServer.
  ///
  /// In en, this message translates to:
  /// **'Start server'**
  String get startServer;

  /// No description provided for @stopServer.
  ///
  /// In en, this message translates to:
  /// **'Stop server'**
  String get stopServer;

  /// No description provided for @lanModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow phones on my local network'**
  String get lanModeTitle;

  /// No description provided for @lanModeOnHint.
  ///
  /// In en, this message translates to:
  /// **'Listening on all network interfaces.'**
  String get lanModeOnHint;

  /// No description provided for @lanModeOffHint.
  ///
  /// In en, this message translates to:
  /// **'Only this computer can connect (localhost).'**
  String get lanModeOffHint;

  /// No description provided for @lanModeWarning.
  ///
  /// In en, this message translates to:
  /// **'Other devices on this network will be able to reach the server. Every phone must still be paired and approved, and messages are signed, but traffic is not encrypted. Use only on networks you trust.'**
  String get lanModeWarning;

  /// No description provided for @recentScans.
  ///
  /// In en, this message translates to:
  /// **'Recent scans'**
  String get recentScans;

  /// No description provided for @openFeed.
  ///
  /// In en, this message translates to:
  /// **'Open feed'**
  String get openFeed;

  /// No description provided for @outputFailuresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} output failures'**
  String outputFailuresCount(int count);

  /// No description provided for @noScansTitle.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get noScansTitle;

  /// No description provided for @noScansDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'Pair a phone and scan a code. Scans appear here as soon as the phone sends them.'**
  String get noScansDesktopHint;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get gettingStarted;

  /// No description provided for @stepLan.
  ///
  /// In en, this message translates to:
  /// **'Allow phones on the local network'**
  String get stepLan;

  /// No description provided for @stepStart.
  ///
  /// In en, this message translates to:
  /// **'Start the server'**
  String get stepStart;

  /// No description provided for @stepPair.
  ///
  /// In en, this message translates to:
  /// **'Pair a phone with the QR code'**
  String get stepPair;

  /// No description provided for @stepKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Test keyboard output'**
  String get stepKeyboard;

  /// No description provided for @stepScan.
  ///
  /// In en, this message translates to:
  /// **'Scan your first code'**
  String get stepScan;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a phone'**
  String get pairTitle;

  /// No description provided for @pairStartServerFirst.
  ///
  /// In en, this message translates to:
  /// **'Start the server to pair a phone.'**
  String get pairStartServerFirst;

  /// No description provided for @pairHint.
  ///
  /// In en, this message translates to:
  /// **'Show a one-time QR code, then scan it with the ScanBridge phone app.'**
  String get pairHint;

  /// No description provided for @pairNeedsLan.
  ///
  /// In en, this message translates to:
  /// **'Phones can only reach this computer after you allow the local network above.'**
  String get pairNeedsLan;

  /// No description provided for @showPairingQr.
  ///
  /// In en, this message translates to:
  /// **'Show pairing QR'**
  String get showPairingQr;

  /// No description provided for @pairingQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairing QR code'**
  String get pairingQrLabel;

  /// No description provided for @pairingCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get pairingCode;

  /// No description provided for @pairExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {seconds} s'**
  String pairExpiresIn(int seconds);

  /// No description provided for @pairSingleUse.
  ///
  /// In en, this message translates to:
  /// **'Works once. A wrong code also uses it up.'**
  String get pairSingleUse;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get regenerate;

  /// No description provided for @pairApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this phone?'**
  String get pairApproveTitle;

  /// No description provided for @pairApproveBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" ({platform}) at {address} wants to send scans to this computer.'**
  String pairApproveBody(String name, String platform, String address);

  /// No description provided for @searchScans.
  ///
  /// In en, this message translates to:
  /// **'Search scans'**
  String get searchScans;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterFailed.
  ///
  /// In en, this message translates to:
  /// **'Output failed'**
  String get filterFailed;

  /// No description provided for @filterPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused / needs confirmation'**
  String get filterPaused;

  /// No description provided for @filterDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get filterDuplicates;

  /// No description provided for @selectScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a scan'**
  String get selectScanTitle;

  /// No description provided for @selectScanHint.
  ///
  /// In en, this message translates to:
  /// **'Details, preview and resend appear here.'**
  String get selectScanHint;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend output'**
  String get resend;

  /// No description provided for @resendTitle.
  ///
  /// In en, this message translates to:
  /// **'Run output again?'**
  String get resendTitle;

  /// No description provided for @resendWarning.
  ///
  /// In en, this message translates to:
  /// **'If the first attempt partly typed into an app, running again may type the value twice. Check the target first.'**
  String get resendWarning;

  /// No description provided for @confirmAndRun.
  ///
  /// In en, this message translates to:
  /// **'Confirm and run'**
  String get confirmAndRun;

  /// No description provided for @editValue.
  ///
  /// In en, this message translates to:
  /// **'Edit value'**
  String get editValue;

  /// No description provided for @editQuantity.
  ///
  /// In en, this message translates to:
  /// **'Edit quantity'**
  String get editQuantity;

  /// No description provided for @scanDeleted.
  ///
  /// In en, this message translates to:
  /// **'Scan deleted'**
  String get scanDeleted;

  /// No description provided for @dryRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Dry run'**
  String get dryRunTitle;

  /// No description provided for @dryRunHalted.
  ///
  /// In en, this message translates to:
  /// **'The template stopped without output (confirmation declined or validation skip).'**
  String get dryRunHalted;

  /// No description provided for @dryRunNoActions.
  ///
  /// In en, this message translates to:
  /// **'This template produces no output.'**
  String get dryRunNoActions;

  /// No description provided for @searchSessions.
  ///
  /// In en, this message translates to:
  /// **'Search sessions'**
  String get searchSessions;

  /// No description provided for @newSession.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSession;

  /// No description provided for @sortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get sortUpdated;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @noSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get noSessionsTitle;

  /// No description provided for @noSessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Sessions are created automatically when a phone sends its first scan, or create one now.'**
  String get noSessionsHint;

  /// No description provided for @scansCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scan} other{{count} scans}}'**
  String scansCount(int count);

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and its {count} scans will be permanently deleted from this device.'**
  String deleteSessionBody(String name, int count);

  /// No description provided for @mergeSessions.
  ///
  /// In en, this message translates to:
  /// **'Merge sessions'**
  String get mergeSessions;

  /// No description provided for @mergeSessionsBody.
  ///
  /// In en, this message translates to:
  /// **'Move all scans from {count} sessions into \"{name}\"?'**
  String mergeSessionsBody(int count, String name);

  /// No description provided for @deleteScansTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete scans?'**
  String get deleteScansTitle;

  /// No description provided for @deleteScansBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected scans? You can undo right after.'**
  String deleteScansBody(int count);

  /// No description provided for @scansDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} scans deleted'**
  String scansDeleted(int count);

  /// No description provided for @dedupeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicates'**
  String get dedupeTitle;

  /// No description provided for @dedupeNone.
  ///
  /// In en, this message translates to:
  /// **'No duplicate values in this session.'**
  String get dedupeNone;

  /// No description provided for @dedupeBody.
  ///
  /// In en, this message translates to:
  /// **'{count} extra copies will be removed; the first scan of each value is kept.'**
  String dedupeBody(int count);

  /// No description provided for @removeDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicates'**
  String get removeDuplicates;

  /// No description provided for @exportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export {count}'**
  String exportSelected(int count);

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export {count} scans'**
  String exportTitle(int count);

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String exportDone(String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}. Your scans are unchanged.'**
  String exportFailed(String error);

  /// No description provided for @csvBom.
  ///
  /// In en, this message translates to:
  /// **'Add UTF-8 BOM (helps Excel detect Unicode)'**
  String get csvBom;

  /// No description provided for @csvFormulaGuard.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet-safe values (prevent formula injection)'**
  String get csvFormulaGuard;

  /// No description provided for @csvFormulaGuardOffWarning.
  ///
  /// In en, this message translates to:
  /// **'Values starting with = + - @ may run as formulas when opened in a spreadsheet.'**
  String get csvFormulaGuardOffWarning;

  /// No description provided for @noDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No paired phones'**
  String get noDevicesTitle;

  /// No description provided for @noDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Start the server and show a pairing QR on the dashboard.'**
  String get noDevicesHint;

  /// No description provided for @deviceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get deviceOnline;

  /// No description provided for @devicePaired.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get devicePaired;

  /// No description provided for @deviceRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get deviceRevoked;

  /// No description provided for @devicePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get devicePending;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'last seen {time}'**
  String lastSeen(String time);

  /// No description provided for @allowScans.
  ///
  /// In en, this message translates to:
  /// **'Allow this phone to send scans'**
  String get allowScans;

  /// No description provided for @revokeBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be disconnected and must be paired again.'**
  String revokeBody(String name);

  /// No description provided for @forgetBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from this computer. Its scans are kept.'**
  String forgetBody(String name);

  /// No description provided for @forgetAll.
  ///
  /// In en, this message translates to:
  /// **'Forget all'**
  String get forgetAll;

  /// No description provided for @forgetAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget all paired phones?'**
  String get forgetAllTitle;

  /// No description provided for @forgetAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count} phones will be disconnected and must be paired again. Scans are kept.'**
  String forgetAllBody(int count);

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newTemplate;

  /// No description provided for @templatesHint.
  ///
  /// In en, this message translates to:
  /// **'The selected template runs for scans that do not name one. Phones collect prompt answers for it.'**
  String get templatesHint;

  /// No description provided for @componentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String componentsCount(int count);

  /// No description provided for @deleteTemplateBody.
  ///
  /// In en, this message translates to:
  /// **'Delete template \"{name}\" and its version history?'**
  String deleteTemplateBody(String name);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @importPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Import \"{name}\"?'**
  String importPreviewTitle(String name);

  /// No description provided for @importPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'{count} steps. Unknown steps are kept but disabled.'**
  String importPreviewBody(int count);

  /// No description provided for @addComponent.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addComponent;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'not available yet'**
  String get notAvailableYet;

  /// No description provided for @noComponentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty template'**
  String get noComponentsTitle;

  /// No description provided for @noComponentsHint.
  ///
  /// In en, this message translates to:
  /// **'Add steps such as BARCODE and ENTER. They run top to bottom.'**
  String get noComponentsHint;

  /// No description provided for @templateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as version {version}'**
  String templateSaved(int version);

  /// No description provided for @skipOutput.
  ///
  /// In en, this message translates to:
  /// **'Skip output (value still available as a variable)'**
  String get skipOutput;

  /// No description provided for @sampleBarcode.
  ///
  /// In en, this message translates to:
  /// **'Sample barcode'**
  String get sampleBarcode;

  /// No description provided for @runPreview.
  ///
  /// In en, this message translates to:
  /// **'Run preview'**
  String get runPreview;

  /// No description provided for @variablesHint.
  ///
  /// In en, this message translates to:
  /// **'Variables: barcode, quantity, scan.timestamp, session.name, device.name or a step name, each wrapped in double curly braces.'**
  String get variablesHint;

  /// No description provided for @formView.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get formView;

  /// No description provided for @jsonView.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get jsonView;

  /// No description provided for @keyboardCapability.
  ///
  /// In en, this message translates to:
  /// **'Keyboard output on this computer'**
  String get keyboardCapability;

  /// No description provided for @keyboardTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a test sequence'**
  String get keyboardTestTitle;

  /// No description provided for @testSequence.
  ///
  /// In en, this message translates to:
  /// **'Text to type'**
  String get testSequence;

  /// No description provided for @appendEnter.
  ///
  /// In en, this message translates to:
  /// **'Press Enter afterwards'**
  String get appendEnter;

  /// No description provided for @sequencePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview: type \"{text}\" then {suffix}'**
  String sequencePreview(String text, String suffix);

  /// No description provided for @testTarget.
  ///
  /// In en, this message translates to:
  /// **'Test field'**
  String get testTarget;

  /// No description provided for @sendTestHere.
  ///
  /// In en, this message translates to:
  /// **'Type into the field above'**
  String get sendTestHere;

  /// No description provided for @sendTestOtherApp.
  ///
  /// In en, this message translates to:
  /// **'Type into another app in 5 s'**
  String get sendTestOtherApp;

  /// No description provided for @switchWindowCountdown.
  ///
  /// In en, this message translates to:
  /// **'Switch to the target window… {seconds}'**
  String switchWindowCountdown(int seconds);

  /// No description provided for @keyboardTestOk.
  ///
  /// In en, this message translates to:
  /// **'Windows accepted every key event.'**
  String get keyboardTestOk;

  /// No description provided for @keyboardLimitations.
  ///
  /// In en, this message translates to:
  /// **'Typing goes to whichever window has focus. Apps running as administrator, the lock screen and some games block simulated input; use clipboard or file output there.'**
  String get keyboardLimitations;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsNetwork;

  /// No description provided for @settingsKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard output'**
  String get settingsKeyboard;

  /// No description provided for @settingsFiles.
  ///
  /// In en, this message translates to:
  /// **'Files and exports'**
  String get settingsFiles;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data and backups'**
  String get settingsData;

  /// No description provided for @serverName.
  ///
  /// In en, this message translates to:
  /// **'Computer name shown on phones'**
  String get serverName;

  /// No description provided for @autoStartServer.
  ///
  /// In en, this message translates to:
  /// **'Start server when the app opens'**
  String get autoStartServer;

  /// No description provided for @keyDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay between keys (ms)'**
  String get keyDelay;

  /// No description provided for @clipboardFallback.
  ///
  /// In en, this message translates to:
  /// **'Paste via clipboard when typing is unavailable'**
  String get clipboardFallback;

  /// No description provided for @clipboardFallbackHint.
  ///
  /// In en, this message translates to:
  /// **'Overwrites the clipboard briefly and restores previous text afterwards.'**
  String get clipboardFallbackHint;

  /// No description provided for @confirmDestructive.
  ///
  /// In en, this message translates to:
  /// **'Confirm before running key combinations like Ctrl+…, Delete'**
  String get confirmDestructive;

  /// No description provided for @confirmDestructiveHint.
  ///
  /// In en, this message translates to:
  /// **'Such scans wait in the feed until you confirm them.'**
  String get confirmDestructiveHint;

  /// No description provided for @outputFolder.
  ///
  /// In en, this message translates to:
  /// **'Output folder (file steps can only write here)'**
  String get outputFolder;

  /// No description provided for @dataLocation.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get dataLocation;

  /// No description provided for @databaseSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get databaseSize;

  /// No description provided for @backupDatabase.
  ///
  /// In en, this message translates to:
  /// **'Back up database'**
  String get backupDatabase;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to {path}'**
  String backupDone(String path);

  /// No description provided for @restoreHint.
  ///
  /// In en, this message translates to:
  /// **'To restore: close ScanBridge and replace the database file above with a backup copy.'**
  String get restoreHint;

  /// No description provided for @copyDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get copyDiagnostics;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied (no scan values or secrets included)'**
  String get diagnosticsCopied;

  /// No description provided for @capabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get capabilities;

  /// No description provided for @firewallTitle.
  ///
  /// In en, this message translates to:
  /// **'Firewall and network'**
  String get firewallTitle;

  /// No description provided for @firewallWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows Defender Firewall asks once when the server first listens on the network; allow it on Private networks. If phones cannot connect, check Windows Security > Firewall > Allow an app, and that TCP port {port} is allowed on your private network. ScanBridge never changes firewall rules itself.'**
  String firewallWindows(int port);

  /// No description provided for @firewallMac.
  ///
  /// In en, this message translates to:
  /// **'macOS may ask to allow incoming connections; choose Allow. Check System Settings > Network > Firewall if phones cannot connect.'**
  String get firewallMac;

  /// No description provided for @firewallLinux.
  ///
  /// In en, this message translates to:
  /// **'If a firewall (ufw, firewalld) is active, allow TCP port {port} from your local network, for example: sudo ufw allow from 192.168.0.0/16 to any port {port} proto tcp'**
  String firewallLinux(int port);

  /// No description provided for @recentErrors.
  ///
  /// In en, this message translates to:
  /// **'Recent errors'**
  String get recentErrors;

  /// No description provided for @noErrors.
  ///
  /// In en, this message translates to:
  /// **'No errors recorded.'**
  String get noErrors;

  /// No description provided for @auditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditLog;

  /// No description provided for @linkConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}'**
  String linkConnected(String name);

  /// No description provided for @linkConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get linkConnecting;

  /// No description provided for @linkReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get linkReconnecting;

  /// No description provided for @linkAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval on the computer'**
  String get linkAwaitingApproval;

  /// No description provided for @linkDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get linkDisconnected;

  /// No description provided for @linkError.
  ///
  /// In en, this message translates to:
  /// **'Connection problem'**
  String get linkError;

  /// No description provided for @linkNotPaired.
  ///
  /// In en, this message translates to:
  /// **'Not paired — scans stay on this phone'**
  String get linkNotPaired;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting to send'**
  String pendingCount(int count);

  /// No description provided for @activeSession.
  ///
  /// In en, this message translates to:
  /// **'Active session'**
  String get activeSession;

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'A session is created on first scan'**
  String get noActiveSession;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanButton;

  /// No description provided for @scanSingle.
  ///
  /// In en, this message translates to:
  /// **'Single scan'**
  String get scanSingle;

  /// No description provided for @scanContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous scan'**
  String get scanContinuous;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get manualEntry;

  /// No description provided for @hardwareScanner.
  ///
  /// In en, this message translates to:
  /// **'Hardware scanner'**
  String get hardwareScanner;

  /// No description provided for @noScansMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan to capture a code. Scans are saved on this phone first, then sent.'**
  String get noScansMobileHint;

  /// No description provided for @torch.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get torch;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get switchCamera;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission was denied. Allow it in system settings, or use manual entry.'**
  String get cameraPermissionDenied;

  /// No description provided for @scannerHint.
  ///
  /// In en, this message translates to:
  /// **'Place the code inside the frame'**
  String get scannerHint;

  /// No description provided for @scannerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get scannerPaused;

  /// No description provided for @scannedThisRun.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String scannedThisRun(int count);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @scanRejected.
  ///
  /// In en, this message translates to:
  /// **'Not saved: {reason}'**
  String scanRejected(String reason);

  /// No description provided for @savedScan.
  ///
  /// In en, this message translates to:
  /// **'Saved {value}'**
  String savedScan(String value);

  /// No description provided for @savedDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Saved {value} (duplicate)'**
  String savedDuplicate(String value);

  /// No description provided for @saveScan.
  ///
  /// In en, this message translates to:
  /// **'Save scan'**
  String get saveScan;

  /// No description provided for @manualHint.
  ///
  /// In en, this message translates to:
  /// **'Type or paste a code and press Enter.'**
  String get manualHint;

  /// No description provided for @hardwareHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this field focused and scan with a Bluetooth/USB keyboard-wedge scanner configured to send Enter after each code.'**
  String get hardwareHint;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to computer'**
  String get connectTitle;

  /// No description provided for @scanPairingQr.
  ///
  /// In en, this message translates to:
  /// **'Scan pairing QR'**
  String get scanPairingQr;

  /// No description provided for @manualPairTitle.
  ///
  /// In en, this message translates to:
  /// **'Or enter details'**
  String get manualPairTitle;

  /// No description provided for @hostAddress.
  ///
  /// In en, this message translates to:
  /// **'Computer IP address'**
  String get hostAddress;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @manualPairInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the IP address, port and the 10-character code shown on the computer.'**
  String get manualPairInvalid;

  /// No description provided for @pairedOk.
  ///
  /// In en, this message translates to:
  /// **'Paired. Scans will now be sent to the computer.'**
  String get pairedOk;

  /// No description provided for @approveOnComputer.
  ///
  /// In en, this message translates to:
  /// **'Approve this phone on the computer screen.'**
  String get approveOnComputer;

  /// No description provided for @pairedComputer.
  ///
  /// In en, this message translates to:
  /// **'Paired computer'**
  String get pairedComputer;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @forgetHostBody.
  ///
  /// In en, this message translates to:
  /// **'This phone will stop sending to this computer. Scans already on the phone are kept.'**
  String get forgetHostBody;

  /// No description provided for @connectTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect? Both devices must be on the same Wi-Fi (guest networks often isolate devices), the desktop must allow phones on the local network, and its firewall must allow ScanBridge. On iPhone/iPad, allow Local Network for ScanBridge in Settings > Privacy & Security > Local Network.'**
  String get connectTroubleshooting;

  /// No description provided for @useSession.
  ///
  /// In en, this message translates to:
  /// **'Use for scanning'**
  String get useSession;

  /// No description provided for @sessionScans.
  ///
  /// In en, this message translates to:
  /// **'Session scans'**
  String get sessionScans;

  /// No description provided for @resendUnsent.
  ///
  /// In en, this message translates to:
  /// **'Send {count} unsent scans'**
  String resendUnsent(int count);

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Phone name shown on the computer'**
  String get deviceName;

  /// No description provided for @defaultScanMode.
  ///
  /// In en, this message translates to:
  /// **'Default scan mode'**
  String get defaultScanMode;

  /// No description provided for @modeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get modeSingle;

  /// No description provided for @modeContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get modeContinuous;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on scan'**
  String get haptics;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound on scan'**
  String get sound;

  /// No description provided for @settingsScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get settingsScanning;

  /// No description provided for @defaultQuantity.
  ///
  /// In en, this message translates to:
  /// **'Default quantity'**
  String get defaultQuantity;

  /// No description provided for @askQuantity.
  ///
  /// In en, this message translates to:
  /// **'Ask for quantity on every scan'**
  String get askQuantity;

  /// No description provided for @duplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates in a session'**
  String get duplicates;

  /// No description provided for @dupAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get dupAllow;

  /// No description provided for @dupWarn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get dupWarn;

  /// No description provided for @dupBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get dupBlock;

  /// No description provided for @formats.
  ///
  /// In en, this message translates to:
  /// **'Accepted formats'**
  String get formats;

  /// No description provided for @allFormats.
  ///
  /// In en, this message translates to:
  /// **'All supported formats'**
  String get allFormats;

  /// No description provided for @validation.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get validation;

  /// No description provided for @pattern.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get pattern;

  /// No description provided for @minLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum length'**
  String get minLength;

  /// No description provided for @maxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum length'**
  String get maxLength;

  /// No description provided for @requiredPrefix.
  ///
  /// In en, this message translates to:
  /// **'Required prefix'**
  String get requiredPrefix;

  /// No description provided for @requiredSuffix.
  ///
  /// In en, this message translates to:
  /// **'Required suffix'**
  String get requiredSuffix;

  /// No description provided for @hardwareDebounce.
  ///
  /// In en, this message translates to:
  /// **'Hardware scanner repeat guard (ms)'**
  String get hardwareDebounce;

  /// No description provided for @outputTemplate.
  ///
  /// In en, this message translates to:
  /// **'Output template'**
  String get outputTemplate;

  /// No description provided for @templatesFromComputer.
  ///
  /// In en, this message translates to:
  /// **'Templates arrive from the computer after connecting.'**
  String get templatesFromComputer;

  /// No description provided for @templateOverrideHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a template or use the computer\'s active one.'**
  String get templateOverrideHint;

  /// No description provided for @computerDefault.
  ///
  /// In en, this message translates to:
  /// **'Computer default'**
  String get computerDefault;

  /// No description provided for @refreshTemplates.
  ///
  /// In en, this message translates to:
  /// **'Refresh templates from computer'**
  String get refreshTemplates;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyMobile.
  ///
  /// In en, this message translates to:
  /// **'ScanBridge has no account, no telemetry and no cloud. Scans are stored on this phone and sent only to the computer you paired, on your local network.'**
  String get privacyMobile;
}

class _SbLocalizationsDelegate extends LocalizationsDelegate<SbLocalizations> {
  const _SbLocalizationsDelegate();

  @override
  Future<SbLocalizations> load(Locale locale) {
    return SynchronousFuture<SbLocalizations>(lookupSbLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SbLocalizationsDelegate old) => false;
}

SbLocalizations lookupSbLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SbLocalizationsEn();
    case 'hi':
      return SbLocalizationsHi();
  }

  throw FlutterError(
    'SbLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
