# Architecture

## Layout (Dart pub workspace)

```text
pubspec.yaml                      workspace root (one lockfile)
apps/
  desktop/  Flutter: Windows, macOS, Linux host (server, output, UI)
  mobile/   Flutter: Android, iOS scanner client
packages/
  scanbridge_domain/            pure Dart: entities, enums, failures, validation, CSV/JSON export, backoff
  scanbridge_protocol/          pure Dart: envelope, canonical JSON, HMAC, pairing, payload DTOs, codec
  scanbridge_template_engine/   pure Dart: component catalog, template JSON schema, engine, samples
  scanbridge_storage/           Drift/SQLite schema + repositories + JSON settings store
  scanbridge_ui/                Flutter design system, status widgets, l10n (en, hi)
docs/  scripts/
```

### Deviation from the spec layout (ADR 0001)

- There is no separate `scanbridge_application` package. The use cases differ between host and phone, so they live in each app's service classes:
  - Host: `HostController` and `OutputService`
  - Phone: `CaptureService` and `SyncService`
- There are no `native/*` folders. Windows input goes through `win32` FFI from Dart, so no C++ plugin is needed.
- macOS and Linux keyboard adapters are not built yet (see `KNOWN_LIMITATIONS.md`).

## Layers

- **Domain**: no Flutter, IO or networking.
  - Failures are typed (`AppFailure` + `FailureCode`) and returned as `Result<T>`.
- **Protocol and engine**: pure Dart.
  - Fully unit-tested.
  - Shared by both apps, so the phone dry-runs the same engine to validate prompt answers.
- **Storage**: repositories over Drift.
  - Each scan and its outbox row are written in one transaction.
  - Host receive is idempotent by scan id.
  - Template edits create new versions and never overwrite old ones.
- **Apps**:
  - The composition roots are `DesktopServices` and `MobileServices`, exposed through Riverpod `Provider` overrides.
  - Widgets read state through `StreamProvider`s or repository streams. SQL, protocol code and key injection never live in widgets.

## Desktop host flow

```text
WebSocket -> ClientConnection (decode, auth, replay, pairing)
          -> HostController.onMessage
               scan.submit -> ScanRepository.receive (txn) -> scan.ack
                            -> OutputService.enqueue (serial queue)
                                 TemplateEngine.run -> actions
                                 KeyboardOutputAdapter / FileOutput / Clipboard
                                 status -> SQLite + delivery.status to phone
```

- Output is serialized across all phones because the keyboard is a single shared resource.
- Ingest and acks run per connection, so one phone does not block another phone's acknowledgements.

## Phone flow

```text
camera / manual / wedge -> CaptureService.check (rules, duplicates, template prompts)
                        -> prompt sheet (engine dry run validates answers)
                        -> ScanRepository.captureWithOutbox (txn)  [persist first]
                        -> SyncService.kick -> ConnectionManager.send (signed)
                        <- scan.ack / scan.reject / delivery.status / template.list
```

ConnectionManager behaviour:

- Reconnects with exponential backoff and jitter.
- Reconnects immediately when the app returns to the foreground.
- The outbox is drained on connect and every 10 s.

## Platform capabilities

The Diagnostics page shows these entries, including the reason for each. Unavailable features are listed, not hidden:

- `os`, `osVersion` and `desktopSession`
- `keyboardInjection` and `keyboardReason`
- `clipboardOutput` and `fileOutput`
- `lanServer`
- `systemTray` and `discovery`

| Capability | Windows | macOS | Linux | Android | iOS |
|---|---|---|---|---|---|
| LAN server | ✅ | builds, not tested | builds, not tested | — | — |
| Keyboard injection | ✅ `SendInput` (Unicode) | ❌ not built | ❌ not built | — | — |
| Clipboard fallback | ✅ | ✅ (copy; paste needs keyboard) | ✅ (copy) | — | — |
| File/CSV output | ✅ | ✅ | ✅ | — | — |
| Camera scanning | — | — | — | ✅ ML Kit | config only, not built here |
| Secure storage | DPAPI (needs ATL to build) | Keychain | libsecret | Keystore | Keychain |
| Tray / login start / mDNS | ❌ deferred | ❌ | ❌ | — | — |

## State management

- **Riverpod 3:** `servicesProvider` is overridden in `main`. Host state, link state and settings use `StreamProvider`s.
- **Navigation:** `go_router`. The desktop uses a `ShellRoute` with a navigation rail; the phone uses stacked routes.
- **Settings:** `JsonSettingsStore<T>` keeps one JSON document per app in `app_settings` and emits changes.
