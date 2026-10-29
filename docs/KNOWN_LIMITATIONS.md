# Known limitations

Platform constraints and unfinished work are listed separately, so each one is clear.

## Platform / OS constraints

- **Windows UIPI:** a non-elevated app cannot type into windows that run as administrator. ScanBridge detects this with a heuristic (it cannot open the foreground process token) and reports it. Windows itself gives no error when it blocks the input.
- **Lock screen, UAC and secure desktop:** these cannot receive input. They are reported as "No foreground window".
- **Exactly-once typing:** keyboard injection cannot be exactly-once across a crash at the moment keys are sent. After a restart, interrupted output is marked failed, and resending shows a duplicate-risk warning.
- **iOS:** no background scanning or permanent socket while the app is suspended. The outbox is drained on resume. iOS builds need macOS with Xcode.
- **Android background:** no foreground service. Delivery happens while the app is open; scans stay queued otherwise.
- **Phone clock skew:** `sentAt` is accepted within ±24 h. `capturedAt` comes from the phone clock and may be slightly off from the PC clock.
- **Sound feedback** uses `SystemSound`. On Android this is a click; on iOS it is silent. Haptics work on both.

## Not implemented yet (tracked in FEATURE_MATRIX.md)

- macOS keyboard adapter (Quartz events + Accessibility permission flow).
- Linux keyboard adapter (X11 XTest; Wayland portal or remote-desktop path).
- System tray, close-to-tray, launch at login and a global pause hotkey. Ctrl+Shift+P works only while the ScanBridge window is focused.
- mDNS/Bonjour discovery. QR and manual IP are the supported paths.
- TLS transport. Messages are HMAC-authenticated but not encrypted.
- Components `HTTP_REQUEST`, `JAVASCRIPT_FUNCTION`, `CSV_UPDATE`, `EXCEL_OUTPUT`, `GOOGLE_SHEETS`, `WOOCOMMERCE`, `IMAGE`, `GEOLOCATION`, `NFC` and `RUN`. They are catalogued and kept on import, but run as disabled steps.
- XLSX export. CSV, TSV, JSON and TXT are available.
- Restore from backup inside the app. The manual file-replace procedure is documented in Settings.
- Per-device template locking and template selection by window title (reference features).
- Data-retention auto-purge. Nothing is deleted automatically.
- Localized strings exist only in English and Hindi.

## Not verified in this environment

- macOS, Linux and iOS builds (no native host was available).
- A physical keyboard-wedge scanner on Android or iOS.
- Long sessions with more than 10,000 scans (list queries are limited, but not profiled).
