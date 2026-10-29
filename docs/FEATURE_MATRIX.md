# Feature matrix

This is the source of truth for status. The reference is Barcode to PC server v5.0.0-beta.4 and app v4.9.0, audited 2026-10-30 (see `REFERENCE_AUDIT.md`).

| Status | Meaning |
|---|---|
| ✅ Done | Implemented, has a test or a verified UI path |
| 🟡 Partial | Partly implemented; the missing part is noted |
| ⏳ Deferred | Not built yet; the reason is in the notes or `KNOWN_LIMITATIONS.md` |
| 🔒 Platform | Limited by the OS, not by this app |

| Area | Feature | Class | Status | Evidence |
|---|---|---|---|---|
| Scanning | Single and continuous camera scan | Parity | ✅ | Live preview verified on an Android 12 phone after a device reboot (an earlier HAL fault was device-side) |
| Scanning | Manual entry (+Enter) | Parity | ✅ | Verified on the device |
| Scanning | Hardware keyboard-wedge input + debounce | Parity | 🟡 | UI built; no physical scanner tested |
| Scanning | Torch, camera switch, pause/resume, scan window overlay | Parity | ✅ | `scanner_page.dart` |
| Scanning | 13 symbologies + format filter | Parity | ✅ | `formatMap`, `ScanRules.allowedFormats` |
| Scanning | Regex, length, prefix/suffix validation | Parity | ✅ | `domain_test` |
| Scanning | Duplicate allow/warn/block per session | Parity | ✅ | `domain_test`, `storage_test` |
| Scanning | Quantity (default / ask / prompt) and editing | Parity | ✅ | `capture_flow.dart`, session detail |
| Scanning | Haptic/sound feedback | Parity | 🟡 | Haptics yes; sound is a system click (Android only) |
| Scanning | Values kept as strings (leading zeros) | Enhancement | ✅ | Device test `00012345678905` |
| Scanning | Image / OCR / NFC / geolocation | Optional | ⏳ | Catalogued only |
| Sessions | Create, rename, search, sort, archive, restore, delete | Parity | ✅ | Desktop + mobile pages, `storage_test` |
| Sessions | Merge, dedupe preview, bulk select/delete, undo | Enhancement | ✅ | `session_detail_page.dart`, `storage_test` |
| Sessions | Export CSV/TSV/JSON/TXT (selected or all) | Parity | ✅ | `domain_test` |
| Sessions | XLSX export | Parity | ⏳ | |
| Sessions | Resend with the original scan id | Enhancement | ✅ | `host_protocol_test`, device offline test |
| Desktop | Start/stop server, LAN-mode warning, IPs/port | Parity | ✅ | Verified on Windows |
| Desktop | One-time expiring QR + typed code, approval | Enhancement | ✅ | `host_protocol_test`, device pairing |
| Desktop | Devices: rename, revoke, forget, allow scans, last seen | Parity | ✅ | `devices_page.dart`, revoke test |
| Desktop | Tray, login start, close-to-tray | Parity | ⏳ | |
| Desktop | mDNS discovery | Parity | ⏳ | QR/manual work |
| Desktop | Diagnostics, firewall guidance, redacted report | Enhancement | ✅ | `diagnostics_page.dart` |
| Desktop | Auto-start server option | Parity | ✅ | Settings |
| Keyboard | Windows SendInput (Unicode, Enter/Tab/F-keys/modifiers) | Parity | ✅ | Verified on Windows (typing `✓`) |
| Keyboard | macOS / Linux adapters | Parity | ⏳ | Report "unavailable" with a reason |
| Keyboard | Armed/paused toggle, scans saved while paused | Enhancement | ✅ | Test + device verified |
| Keyboard | Elevated-target detection | Enhancement | ✅ | `checkTarget` |
| Keyboard | Clipboard paste fallback with restore | Parity | ✅ | `clipboard_output.dart` |
| Keyboard | Key delay | Parity | ✅ | Settings |
| Keyboard | Confirm destructive sequences | Enhancement | ✅ | `OutputService` |
| Keyboard | Test panel + preview | Enhancement | ✅ | Verified |
| Keyboard | Global pause hotkey | Enhancement | 🟡 | In-window Ctrl+Shift+P only |
| Templates | Versioned JSON, history, import/export, unknown kept | Enhancement | ✅ | `engine_test`, `storage_test` |
| Templates | Builder: add/reorder/enable/skip/duplicate/delete/undo/redo | Parity | ✅ | `template_editor_page.dart` |
| Templates | Dry run | Enhancement | ✅ | Editor + feed |
| Templates | BARCODE TEXT NUMBER SELECT CONFIRM PRESS_KEY ENTER TAB DATE_TIME TIMESTAMP SESSION DEVICE DELAY IF/ENDIF VALIDATE INCREMENT UUID CLIPBOARD BEEP ALERT SKIP_OUTPUT CSV_OUTPUT FILE_OUTPUT CSV_LOOKUP | Parity | ✅ | `engine_test` |
| Templates | HTTP, JS, CSV_UPDATE, EXCEL, Sheets, WooCommerce, RUN | Optional | ⏳ | Disabled placeholders |
| Templates | Phone collects prompts; host runs the exact version | Enhancement | ✅ | Protocol `values` + `templateVersion` |
| Templates | Samples: Inventory Intake, POS Lookup, Stocktake | Parity | ✅ | `samples.dart` |
| Templates | Lock template by device / pick by window title | Parity | ⏳ | From the audit |
| Output | Real-time CSV/text append, path confinement, locking | Parity | ✅ | `host_protocol_test` |
| Output | Formula-injection guard, BOM, quoting | Enhancement | ✅ | `domain_test` |
| Reliability | Persist-before-send outbox, ack after persist, backoff, dead-letter | Enhancement | ✅ | `storage_test`, device offline test |
| Reliability | Separate delivery and output status | Enhancement | ✅ | Device verified |
| Reliability | Restart marks in-flight output failed | Enhancement | ✅ | `storage_test` |
| Reliability | DB backup (`VACUUM INTO`) | Enhancement | ✅ | `storage_test` |
| Reliability | In-app restore, retention policy | Enhancement | ⏳ | |
| Security | HMAC per device, replay guard, rate limit, revoke | Enhancement | ✅ | `protocol_test`, `host_protocol_test` |
| Security | TLS | Enhancement | ⏳ | |
| Security | Secrets in OS secure storage | Parity | ✅ | `flutter_secure_storage` |
| UX | Light/dark/system theme, accessible status labels | Enhancement | ✅ | |
| UX | Shortcuts Ctrl+N/F/E, Ctrl+Shift+P | Enhancement | ✅ | `shell.dart` |
| UX | English + Hindi localization | Enhancement | ✅ | `scanbridge_ui/lib/l10n` |
| Mobile | QR + manual pairing, reconnect, resume drain | Parity | ✅ | Device verified (manual pairing) |
| Mobile | Share export via share sheet | Parity | ✅ | `session_detail_page.dart` |
| Mobile | iOS build | Platform | 🔒 | Needs macOS + Xcode; Info.plist configured |
| Mobile | Vendor PDA SDK integration | Optional | ⏳ | Keyboard-wedge path only |
