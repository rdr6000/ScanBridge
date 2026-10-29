# Dependency licenses

Versions are resolved in `pubspec.lock` (Dart pub workspace). The license type was read from each package's LICENSE file in the pub cache on 2026-10-30. Re-check before every release.

| Package | Version | License | Used by | Notes |
|---|---|---|---|---|
| drift | 2.35.3 | MIT | storage | SQLite ORM and migrations |
| sqlite3 | 3.8.0 | MIT | storage | Bundles the SQLite library (public domain) through build hooks |
| crypto | 3.0.8 | BSD-3-Clause | protocol | HMAC-SHA256 |
| uuid | 4.6.0 | MIT | domain | v4 ids |
| intl | 0.20.3 | BSD-3-Clause | engine, ui | Date formats, localization |
| path | 1.9.1 | BSD-3-Clause | storage, apps | Path normalization |
| flutter_riverpod | 3.4.3 | MIT | apps | Dependency injection and state |
| go_router | 18.1.2 | BSD-3-Clause | apps | Navigation |
| win32 | 6.4.0 | BSD-3-Clause | desktop | `SendInput` FFI bindings |
| ffi | 2.2.0 | BSD-3-Clause | desktop | Native memory |
| qr_flutter | 4.1.0 | BSD-3-Clause | desktop | Pairing QR code |
| file_selector | 1.1.0 | BSD-3-Clause | desktop | Native open, save and folder dialogs |
| path_provider | 2.1.6 | BSD-3-Clause | apps | App data folders |
| flutter_secure_storage | 11.2.0 | BSD-3-Clause | apps | Keychain, Keystore, DPAPI, libsecret. The Windows build needs the MSVC ATL component |
| mobile_scanner | 7.4.2 | BSD-3-Clause | mobile | Decodes with Google ML Kit on Android and Apple Vision on iOS. ML Kit is subject to Google's ML Kit terms |
| share_plus | 13.3.1 | BSD-3-Clause | mobile | Share sheet for exports |
| async | 2.13.1 | BSD-3-Clause | desktop tests | `StreamQueue` |
| Flutter SDK | 3.47.7 | BSD-3-Clause | all | |

No GPL code is included. Barcode to PC (GPL-3.0) was used only as a feature reference; see `PROVENANCE.md`.
