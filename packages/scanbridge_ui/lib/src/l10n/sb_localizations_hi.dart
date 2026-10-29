// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'sb_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class SbLocalizationsHi extends SbLocalizations {
  SbLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'स्कैनब्रिज';

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navFeed => 'लाइव फ़ीड';

  @override
  String get navSessions => 'सत्र';

  @override
  String get navDevices => 'डिवाइस';

  @override
  String get navTemplates => 'टेम्पलेट';

  @override
  String get navKeyboardTest => 'कीबोर्ड परीक्षण';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get navDiagnostics => 'निदान';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get apply => 'लागू करें';

  @override
  String get close => 'बंद करें';

  @override
  String get retry => 'फिर से प्रयास करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get edit => 'संपादित करें';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get redo => 'फिर से करें';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get archive => 'संग्रहित करें';

  @override
  String get archived => 'संग्रहित';

  @override
  String get restore => 'पुनर्स्थापित करें';

  @override
  String get export => 'निर्यात करें';

  @override
  String get import => 'आयात करें';

  @override
  String get merge => 'मिलाएँ';

  @override
  String get duplicate => 'प्रतिलिपि बनाएँ';

  @override
  String get preview => 'पूर्वावलोकन';

  @override
  String get approve => 'स्वीकृत करें';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get enable => 'सक्षम करें';

  @override
  String get change => 'बदलें';

  @override
  String get back => 'वापस';

  @override
  String get forget => 'भूल जाएँ';

  @override
  String get revoke => 'रद्द करें (पहुँच)';

  @override
  String get moreActions => 'और क्रियाएँ';

  @override
  String get selectAll => 'सभी चुनें';

  @override
  String get name => 'नाम';

  @override
  String get label => 'लेबल';

  @override
  String get value => 'मान';

  @override
  String get quantity => 'मात्रा';

  @override
  String get quantityShort => 'मात्रा';

  @override
  String get symbology => 'प्रारूप';

  @override
  String get capturedAt => 'कैप्चर किया गया';

  @override
  String get receivedAt => 'प्राप्त हुआ';

  @override
  String get source => 'स्रोत';

  @override
  String get device => 'डिवाइस';

  @override
  String get template => 'टेम्पलेट';

  @override
  String get port => 'पोर्ट';

  @override
  String get theme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'हल्की';

  @override
  String get themeDark => 'गहरी';

  @override
  String get errorCode => 'त्रुटि कोड';

  @override
  String get pressEnterToSave => 'सहेजने के लिए Enter दबाएँ';

  @override
  String get commaSeparated => 'अल्पविराम से अलग';

  @override
  String get statusCaptured => 'कैप्चर किया गया';

  @override
  String get statusQueued => 'कतार में';

  @override
  String get statusDelivered => 'पहुँचाया गया';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get statusFailed => 'विफल';

  @override
  String get statusLocalOnly => 'केवल स्थानीय';

  @override
  String get outputNone => 'कोई आउटपुट नहीं';

  @override
  String get outputPending => 'आउटपुट लंबित';

  @override
  String get outputSucceeded => 'टाइप किया गया';

  @override
  String get outputFailed => 'आउटपुट विफल';

  @override
  String get outputSkipped => 'छोड़ा गया';

  @override
  String get outputPaused => 'रुका हुआ';

  @override
  String get validationValid => 'मान्य';

  @override
  String get validationDuplicate => 'डुप्लिकेट';

  @override
  String get validationInvalid => 'अमान्य';

  @override
  String get validationUnchecked => 'अजाँचा';

  @override
  String serverRunning(int port) {
    return 'सर्वर पोर्ट $port पर चल रहा है';
  }

  @override
  String get serverStarting => 'सर्वर शुरू हो रहा है…';

  @override
  String get serverError => 'सर्वर त्रुटि';

  @override
  String get serverStopped => 'सर्वर बंद है';

  @override
  String devicesConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ोन जुड़े',
      one: '1 फ़ोन जुड़ा',
      zero: 'कोई फ़ोन जुड़ा नहीं',
    );
    return '$_temp0';
  }

  @override
  String get lanModeOn => 'LAN मोड';

  @override
  String get keyboardArmed => 'कीबोर्ड आउटपुट सक्रिय';

  @override
  String get keyboardPaused => 'कीबोर्ड आउटपुट रुका हुआ';

  @override
  String get pauseShortcutHint =>
      'यह विंडो सक्रिय होने पर Ctrl+Shift+P आउटपुट चालू/बंद करता है। रुके रहने पर भी स्कैन सहेजे जाते हैं।';

  @override
  String get serverTitle => 'सर्वर';

  @override
  String get startServer => 'सर्वर शुरू करें';

  @override
  String get stopServer => 'सर्वर बंद करें';

  @override
  String get lanModeTitle => 'मेरे स्थानीय नेटवर्क के फ़ोन को अनुमति दें';

  @override
  String get lanModeOnHint => 'सभी नेटवर्क इंटरफ़ेस पर सुन रहा है।';

  @override
  String get lanModeOffHint => 'केवल यही कंप्यूटर जुड़ सकता है (localhost)।';

  @override
  String get lanModeWarning =>
      'इस नेटवर्क के अन्य डिवाइस सर्वर तक पहुँच सकेंगे। हर फ़ोन को फिर भी जोड़ना और स्वीकृत करना होगा और संदेश हस्ताक्षरित होते हैं, पर ट्रैफ़िक एन्क्रिप्टेड नहीं है। केवल भरोसेमंद नेटवर्क पर उपयोग करें।';

  @override
  String get recentScans => 'हाल के स्कैन';

  @override
  String get openFeed => 'फ़ीड खोलें';

  @override
  String outputFailuresCount(int count) {
    return '$count आउटपुट विफलताएँ';
  }

  @override
  String get noScansTitle => 'अभी कोई स्कैन नहीं';

  @override
  String get noScansDesktopHint =>
      'एक फ़ोन जोड़ें और कोड स्कैन करें। फ़ोन के भेजते ही स्कैन यहाँ दिखेंगे।';

  @override
  String get gettingStarted => 'शुरुआत करें';

  @override
  String get stepLan => 'स्थानीय नेटवर्क पर फ़ोन को अनुमति दें';

  @override
  String get stepStart => 'सर्वर शुरू करें';

  @override
  String get stepPair => 'QR कोड से फ़ोन जोड़ें';

  @override
  String get stepKeyboard => 'कीबोर्ड आउटपुट जाँचें';

  @override
  String get stepScan => 'अपना पहला कोड स्कैन करें';

  @override
  String get pairTitle => 'फ़ोन जोड़ें';

  @override
  String get pairStartServerFirst => 'फ़ोन जोड़ने के लिए सर्वर शुरू करें।';

  @override
  String get pairHint =>
      'एक बार उपयोग वाला QR कोड दिखाएँ, फिर स्कैनब्रिज फ़ोन ऐप से स्कैन करें।';

  @override
  String get pairNeedsLan =>
      'ऊपर स्थानीय नेटवर्क की अनुमति देने के बाद ही फ़ोन इस कंप्यूटर तक पहुँच सकते हैं।';

  @override
  String get showPairingQr => 'पेयरिंग QR दिखाएँ';

  @override
  String get pairingQrLabel => 'पेयरिंग QR कोड';

  @override
  String get pairingCode => 'पेयरिंग कोड';

  @override
  String pairExpiresIn(int seconds) {
    return '$seconds सेकंड में समाप्त';
  }

  @override
  String get pairSingleUse =>
      'केवल एक बार काम करता है। गलत कोड से भी यह समाप्त हो जाता है।';

  @override
  String get regenerate => 'नया कोड';

  @override
  String get pairApproveTitle => 'क्या इस फ़ोन को स्वीकृत करें?';

  @override
  String pairApproveBody(String name, String platform, String address) {
    return '$address पर \"$name\" ($platform) इस कंप्यूटर पर स्कैन भेजना चाहता है।';
  }

  @override
  String get searchScans => 'स्कैन खोजें';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterFailed => 'आउटपुट विफल';

  @override
  String get filterPaused => 'रुका / पुष्टि आवश्यक';

  @override
  String get filterDuplicates => 'डुप्लिकेट';

  @override
  String get selectScanTitle => 'एक स्कैन चुनें';

  @override
  String get selectScanHint => 'विवरण, पूर्वावलोकन और पुनः भेजना यहाँ दिखेगा।';

  @override
  String get resend => 'आउटपुट फिर भेजें';

  @override
  String get resendTitle => 'आउटपुट फिर से चलाएँ?';

  @override
  String get resendWarning =>
      'यदि पहले प्रयास ने आंशिक रूप से टाइप किया था, तो फिर चलाने पर मान दो बार टाइप हो सकता है। पहले लक्ष्य जाँचें।';

  @override
  String get confirmAndRun => 'पुष्टि करें और चलाएँ';

  @override
  String get editValue => 'मान संपादित करें';

  @override
  String get editQuantity => 'मात्रा संपादित करें';

  @override
  String get scanDeleted => 'स्कैन हटाया गया';

  @override
  String get dryRunTitle => 'परीक्षण रन';

  @override
  String get dryRunHalted =>
      'टेम्पलेट बिना आउटपुट के रुक गया (पुष्टि अस्वीकार या सत्यापन छोड़ा गया)।';

  @override
  String get dryRunNoActions => 'यह टेम्पलेट कोई आउटपुट नहीं बनाता।';

  @override
  String get searchSessions => 'सत्र खोजें';

  @override
  String get newSession => 'नया सत्र';

  @override
  String get sortUpdated => 'हाल में अपडेट';

  @override
  String get sortNewest => 'नवीनतम पहले';

  @override
  String get sortOldest => 'सबसे पुराने पहले';

  @override
  String get sortName => 'नाम';

  @override
  String get noSessionsTitle => 'कोई सत्र नहीं';

  @override
  String get noSessionsHint =>
      'फ़ोन के पहला स्कैन भेजने पर सत्र अपने आप बनते हैं, या अभी एक बनाएँ।';

  @override
  String scansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्कैन',
      one: '1 स्कैन',
    );
    return '$_temp0';
  }

  @override
  String get deleteSessionTitle => 'सत्र हटाएँ?';

  @override
  String deleteSessionBody(String name, int count) {
    return '\"$name\" और इसके $count स्कैन इस डिवाइस से स्थायी रूप से हट जाएँगे।';
  }

  @override
  String get mergeSessions => 'सत्र मिलाएँ';

  @override
  String mergeSessionsBody(int count, String name) {
    return '$count सत्रों के सभी स्कैन \"$name\" में ले जाएँ?';
  }

  @override
  String get deleteScansTitle => 'स्कैन हटाएँ?';

  @override
  String deleteScansBody(int count) {
    return '$count चुने गए स्कैन हटाएँ? आप तुरंत पूर्ववत कर सकते हैं।';
  }

  @override
  String scansDeleted(int count) {
    return '$count स्कैन हटाए गए';
  }

  @override
  String get dedupeTitle => 'डुप्लिकेट हटाएँ';

  @override
  String get dedupeNone => 'इस सत्र में कोई डुप्लिकेट मान नहीं।';

  @override
  String dedupeBody(int count) {
    return '$count अतिरिक्त प्रतियाँ हटेंगी; हर मान का पहला स्कैन रखा जाएगा।';
  }

  @override
  String get removeDuplicates => 'डुप्लिकेट हटाएँ';

  @override
  String exportSelected(int count) {
    return '$count निर्यात करें';
  }

  @override
  String exportTitle(int count) {
    return '$count स्कैन निर्यात करें';
  }

  @override
  String exportDone(String path) {
    return '$path में सहेजा गया';
  }

  @override
  String exportFailed(String error) {
    return 'निर्यात विफल: $error। आपके स्कैन अपरिवर्तित हैं।';
  }

  @override
  String get csvBom => 'UTF-8 BOM जोड़ें (Excel को यूनिकोड पहचानने में मदद)';

  @override
  String get csvFormulaGuard =>
      'स्प्रेडशीट-सुरक्षित मान (फ़ॉर्मूला इंजेक्शन रोकें)';

  @override
  String get csvFormulaGuardOffWarning =>
      '= + - @ से शुरू होने वाले मान स्प्रेडशीट में खुलने पर फ़ॉर्मूला की तरह चल सकते हैं।';

  @override
  String get noDevicesTitle => 'कोई जुड़ा फ़ोन नहीं';

  @override
  String get noDevicesHint =>
      'सर्वर शुरू करें और डैशबोर्ड पर पेयरिंग QR दिखाएँ।';

  @override
  String get deviceOnline => 'ऑनलाइन';

  @override
  String get devicePaired => 'जुड़ा हुआ';

  @override
  String get deviceRevoked => 'रद्द';

  @override
  String get devicePending => 'लंबित';

  @override
  String lastSeen(String time) {
    return 'अंतिम बार देखा $time';
  }

  @override
  String get allowScans => 'इस फ़ोन को स्कैन भेजने दें';

  @override
  String revokeBody(String name) {
    return '\"$name\" डिस्कनेक्ट हो जाएगा और इसे फिर से जोड़ना होगा।';
  }

  @override
  String forgetBody(String name) {
    return '\"$name\" को इस कंप्यूटर से हटाएँ। इसके स्कैन रखे जाएँगे।';
  }

  @override
  String get forgetAll => 'सभी भूल जाएँ';

  @override
  String get forgetAllTitle => 'सभी जुड़े फ़ोन भूल जाएँ?';

  @override
  String forgetAllBody(int count) {
    return '$count फ़ोन डिस्कनेक्ट होंगे और फिर से जोड़ने होंगे। स्कैन रखे जाएँगे।';
  }

  @override
  String get newTemplate => 'नया टेम्पलेट';

  @override
  String get templatesHint =>
      'चुना गया टेम्पलेट उन स्कैन के लिए चलता है जिनमें कोई टेम्पलेट नहीं है। फ़ोन इसके प्रश्नों के उत्तर लेते हैं।';

  @override
  String componentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चरण',
      one: '1 चरण',
    );
    return '$_temp0';
  }

  @override
  String deleteTemplateBody(String name) {
    return 'टेम्पलेट \"$name\" और इसका संस्करण इतिहास हटाएँ?';
  }

  @override
  String get importFailed => 'आयात विफल';

  @override
  String importPreviewTitle(String name) {
    return '\"$name\" आयात करें?';
  }

  @override
  String importPreviewBody(int count) {
    return '$count चरण। अज्ञात चरण रखे जाएँगे पर अक्षम रहेंगे।';
  }

  @override
  String get addComponent => 'चरण जोड़ें';

  @override
  String get notAvailableYet => 'अभी उपलब्ध नहीं';

  @override
  String get noComponentsTitle => 'खाली टेम्पलेट';

  @override
  String get noComponentsHint =>
      'BARCODE और ENTER जैसे चरण जोड़ें। ये ऊपर से नीचे चलते हैं।';

  @override
  String templateSaved(int version) {
    return 'संस्करण $version के रूप में सहेजा गया';
  }

  @override
  String get skipOutput =>
      'आउटपुट छोड़ें (मान फिर भी वेरिएबल के रूप में उपलब्ध)';

  @override
  String get sampleBarcode => 'नमूना बारकोड';

  @override
  String get runPreview => 'पूर्वावलोकन चलाएँ';

  @override
  String get variablesHint =>
      'वेरिएबल: barcode, quantity, scan.timestamp, session.name, device.name या किसी चरण का नाम, प्रत्येक को दोहरे घुंघराले कोष्ठकों में लिखें।';

  @override
  String get formView => 'फ़ॉर्म';

  @override
  String get jsonView => 'JSON';

  @override
  String get keyboardCapability => 'इस कंप्यूटर पर कीबोर्ड आउटपुट';

  @override
  String get keyboardTestTitle => 'परीक्षण अनुक्रम भेजें';

  @override
  String get testSequence => 'टाइप करने का पाठ';

  @override
  String get appendEnter => 'बाद में Enter दबाएँ';

  @override
  String sequencePreview(String text, String suffix) {
    return 'पूर्वावलोकन: \"$text\" टाइप करें फिर $suffix';
  }

  @override
  String get testTarget => 'परीक्षण फ़ील्ड';

  @override
  String get sendTestHere => 'ऊपर के फ़ील्ड में टाइप करें';

  @override
  String get sendTestOtherApp => '5 सेकंड में दूसरे ऐप में टाइप करें';

  @override
  String switchWindowCountdown(int seconds) {
    return 'लक्ष्य विंडो पर जाएँ… $seconds';
  }

  @override
  String get keyboardTestOk => 'Windows ने हर कुंजी इवेंट स्वीकार किया।';

  @override
  String get keyboardLimitations =>
      'टाइपिंग उसी विंडो में जाती है जिस पर फ़ोकस है। एडमिनिस्ट्रेटर के रूप में चल रहे ऐप, लॉक स्क्रीन और कुछ गेम नकली इनपुट रोकते हैं; वहाँ क्लिपबोर्ड या फ़ाइल आउटपुट उपयोग करें।';

  @override
  String get settingsGeneral => 'सामान्य';

  @override
  String get settingsNetwork => 'नेटवर्क';

  @override
  String get settingsKeyboard => 'कीबोर्ड आउटपुट';

  @override
  String get settingsFiles => 'फ़ाइलें और निर्यात';

  @override
  String get settingsData => 'डेटा और बैकअप';

  @override
  String get serverName => 'फ़ोन पर दिखने वाला कंप्यूटर नाम';

  @override
  String get autoStartServer => 'ऐप खुलने पर सर्वर शुरू करें';

  @override
  String get keyDelay => 'कुंजियों के बीच विलंब (ms)';

  @override
  String get clipboardFallback =>
      'टाइपिंग उपलब्ध न होने पर क्लिपबोर्ड से पेस्ट करें';

  @override
  String get clipboardFallbackHint =>
      'क्लिपबोर्ड को कुछ समय के लिए बदलता है और बाद में पिछला पाठ लौटाता है।';

  @override
  String get confirmDestructive =>
      'Ctrl+…, Delete जैसे कुंजी संयोजन चलाने से पहले पुष्टि करें';

  @override
  String get confirmDestructiveHint =>
      'ऐसे स्कैन आपकी पुष्टि तक फ़ीड में प्रतीक्षा करते हैं।';

  @override
  String get outputFolder =>
      'आउटपुट फ़ोल्डर (फ़ाइल चरण केवल यहीं लिख सकते हैं)';

  @override
  String get dataLocation => 'डेटाबेस';

  @override
  String get databaseSize => 'आकार';

  @override
  String get backupDatabase => 'डेटाबेस का बैकअप लें';

  @override
  String backupDone(String path) {
    return 'बैकअप $path में सहेजा गया';
  }

  @override
  String get restoreHint =>
      'पुनर्स्थापित करने के लिए: स्कैनब्रिज बंद करें और ऊपर की डेटाबेस फ़ाइल को बैकअप प्रति से बदलें।';

  @override
  String get copyDiagnostics => 'निदान कॉपी करें';

  @override
  String get diagnosticsCopied =>
      'निदान कॉपी हुआ (कोई स्कैन मान या गुप्त जानकारी शामिल नहीं)';

  @override
  String get capabilities => 'क्षमताएँ';

  @override
  String get firewallTitle => 'फ़ायरवॉल और नेटवर्क';

  @override
  String firewallWindows(int port) {
    return 'सर्वर पहली बार नेटवर्क पर सुनते समय Windows Defender Firewall एक बार पूछता है; Private नेटवर्क पर अनुमति दें। फ़ोन न जुड़ें तो Windows Security > Firewall > Allow an app जाँचें और देखें कि TCP पोर्ट $port निजी नेटवर्क पर अनुमत है। स्कैनब्रिज स्वयं फ़ायरवॉल नियम नहीं बदलता।';
  }

  @override
  String get firewallMac =>
      'macOS आने वाले कनेक्शन की अनुमति माँग सकता है; Allow चुनें। फ़ोन न जुड़ें तो System Settings > Network > Firewall जाँचें।';

  @override
  String firewallLinux(int port) {
    return 'यदि फ़ायरवॉल (ufw, firewalld) सक्रिय है, तो स्थानीय नेटवर्क से TCP पोर्ट $port की अनुमति दें, उदाहरण: sudo ufw allow from 192.168.0.0/16 to any port $port proto tcp';
  }

  @override
  String get recentErrors => 'हाल की त्रुटियाँ';

  @override
  String get noErrors => 'कोई त्रुटि दर्ज नहीं।';

  @override
  String get auditLog => 'ऑडिट लॉग';

  @override
  String linkConnected(String name) {
    return '$name से जुड़ा';
  }

  @override
  String get linkConnecting => 'जुड़ रहा है…';

  @override
  String get linkReconnecting => 'फिर से जुड़ रहा है…';

  @override
  String get linkAwaitingApproval => 'कंप्यूटर पर स्वीकृति की प्रतीक्षा';

  @override
  String get linkDisconnected => 'डिस्कनेक्ट';

  @override
  String get linkError => 'कनेक्शन समस्या';

  @override
  String get linkNotPaired => 'जुड़ा नहीं — स्कैन इसी फ़ोन पर रहेंगे';

  @override
  String pendingCount(int count) {
    return '$count भेजने की प्रतीक्षा में';
  }

  @override
  String get activeSession => 'सक्रिय सत्र';

  @override
  String get noActiveSession => 'पहले स्कैन पर सत्र बनेगा';

  @override
  String get scanButton => 'स्कैन करें';

  @override
  String get scanSingle => 'एकल स्कैन';

  @override
  String get scanContinuous => 'लगातार स्कैन';

  @override
  String get manualEntry => 'मैन्युअल प्रविष्टि';

  @override
  String get hardwareScanner => 'हार्डवेयर स्कैनर';

  @override
  String get noScansMobileHint =>
      'कोड लेने के लिए स्कैन दबाएँ। स्कैन पहले इसी फ़ोन पर सहेजे जाते हैं, फिर भेजे जाते हैं।';

  @override
  String get torch => 'टॉर्च';

  @override
  String get switchCamera => 'कैमरा बदलें';

  @override
  String get cameraUnavailable => 'कैमरा उपलब्ध नहीं';

  @override
  String get cameraPermissionDenied =>
      'कैमरा अनुमति अस्वीकार हुई। सिस्टम सेटिंग्स में अनुमति दें, या मैन्युअल प्रविष्टि उपयोग करें।';

  @override
  String get scannerHint => 'कोड को फ़्रेम के अंदर रखें';

  @override
  String get scannerPaused => 'रुका हुआ';

  @override
  String scannedThisRun(int count) {
    return '$count सहेजे गए';
  }

  @override
  String get pause => 'रोकें';

  @override
  String get resume => 'जारी रखें';

  @override
  String scanRejected(String reason) {
    return 'सहेजा नहीं गया: $reason';
  }

  @override
  String savedScan(String value) {
    return '$value सहेजा गया';
  }

  @override
  String savedDuplicate(String value) {
    return '$value सहेजा गया (डुप्लिकेट)';
  }

  @override
  String get saveScan => 'स्कैन सहेजें';

  @override
  String get manualHint => 'कोड टाइप या पेस्ट करें और Enter दबाएँ।';

  @override
  String get hardwareHint =>
      'इस फ़ील्ड पर फ़ोकस रखें और ऐसे ब्लूटूथ/USB कीबोर्ड-वेज स्कैनर से स्कैन करें जो हर कोड के बाद Enter भेजे।';

  @override
  String get connectTitle => 'कंप्यूटर से जोड़ें';

  @override
  String get scanPairingQr => 'पेयरिंग QR स्कैन करें';

  @override
  String get manualPairTitle => 'या विवरण दर्ज करें';

  @override
  String get hostAddress => 'कंप्यूटर का IP पता';

  @override
  String get pair => 'जोड़ें';

  @override
  String get manualPairInvalid =>
      'कंप्यूटर पर दिखाया IP पता, पोर्ट और 10 अक्षरों का कोड दर्ज करें।';

  @override
  String get pairedOk => 'जुड़ गया। अब स्कैन कंप्यूटर पर भेजे जाएँगे।';

  @override
  String get approveOnComputer =>
      'कंप्यूटर स्क्रीन पर इस फ़ोन को स्वीकृत करें।';

  @override
  String get pairedComputer => 'जुड़ा कंप्यूटर';

  @override
  String get connect => 'जोड़ें';

  @override
  String get disconnect => 'डिस्कनेक्ट करें';

  @override
  String get forgetHostBody =>
      'यह फ़ोन इस कंप्यूटर पर भेजना बंद करेगा। फ़ोन पर मौजूद स्कैन रखे जाएँगे।';

  @override
  String get connectTroubleshooting =>
      'जुड़ नहीं रहा? दोनों डिवाइस एक ही वाई-फ़ाई पर हों (गेस्ट नेटवर्क अक्सर डिवाइस अलग रखते हैं), डेस्कटॉप स्थानीय नेटवर्क पर फ़ोन की अनुमति दे, और उसका फ़ायरवॉल स्कैनब्रिज को अनुमति दे। iPhone/iPad पर Settings > Privacy & Security > Local Network में स्कैनब्रिज को अनुमति दें।';

  @override
  String get useSession => 'स्कैनिंग के लिए उपयोग करें';

  @override
  String get sessionScans => 'सत्र के स्कैन';

  @override
  String resendUnsent(int count) {
    return '$count न भेजे गए स्कैन भेजें';
  }

  @override
  String get deviceName => 'कंप्यूटर पर दिखने वाला फ़ोन नाम';

  @override
  String get defaultScanMode => 'डिफ़ॉल्ट स्कैन मोड';

  @override
  String get modeSingle => 'एकल';

  @override
  String get modeContinuous => 'लगातार';

  @override
  String get haptics => 'स्कैन पर कंपन';

  @override
  String get sound => 'स्कैन पर ध्वनि';

  @override
  String get settingsScanning => 'स्कैनिंग';

  @override
  String get defaultQuantity => 'डिफ़ॉल्ट मात्रा';

  @override
  String get askQuantity => 'हर स्कैन पर मात्रा पूछें';

  @override
  String get duplicates => 'सत्र में डुप्लिकेट';

  @override
  String get dupAllow => 'अनुमति दें';

  @override
  String get dupWarn => 'चेतावनी दें';

  @override
  String get dupBlock => 'रोकें';

  @override
  String get formats => 'स्वीकृत प्रारूप';

  @override
  String get allFormats => 'सभी समर्थित प्रारूप';

  @override
  String get validation => 'सत्यापन';

  @override
  String get pattern => 'रेगुलर एक्सप्रेशन';

  @override
  String get minLength => 'न्यूनतम लंबाई';

  @override
  String get maxLength => 'अधिकतम लंबाई';

  @override
  String get requiredPrefix => 'आवश्यक उपसर्ग';

  @override
  String get requiredSuffix => 'आवश्यक प्रत्यय';

  @override
  String get hardwareDebounce => 'हार्डवेयर स्कैनर दोहराव सुरक्षा (ms)';

  @override
  String get outputTemplate => 'आउटपुट टेम्पलेट';

  @override
  String get templatesFromComputer =>
      'जुड़ने के बाद टेम्पलेट कंप्यूटर से आते हैं।';

  @override
  String get templateOverrideHint =>
      'एक टेम्पलेट चुनें या कंप्यूटर का सक्रिय टेम्पलेट उपयोग करें।';

  @override
  String get computerDefault => 'कंप्यूटर डिफ़ॉल्ट';

  @override
  String get refreshTemplates => 'कंप्यूटर से टेम्पलेट ताज़ा करें';

  @override
  String get privacy => 'गोपनीयता';

  @override
  String get privacyMobile =>
      'स्कैनब्रिज में कोई खाता, टेलीमेट्री या क्लाउड नहीं है। स्कैन इसी फ़ोन पर रहते हैं और केवल आपके जोड़े गए कंप्यूटर पर, स्थानीय नेटवर्क से भेजे जाते हैं।';
}
