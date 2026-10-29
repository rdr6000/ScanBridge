# ADR 0001 — Platform, workspace and packages

**Status:** accepted · 2026-10-30

## Context

The spec asks for a Flutter monorepo with:

- two apps: a desktop host and a mobile client
- separate domain, application, protocol, storage, engine and UI packages
- native keyboard adapters for each desktop OS

The build machine is Windows 11, with an Android phone attached over adb and no macOS host.

## Decisions

1. **Dart pub workspace.** A root `pubspec.yaml` lists all members with `resolution: workspace`. This gives one lockfile and pins every version together.
2. **Five packages instead of six.**
   - `scanbridge_application` is folded into each app's services. Host and phone use cases share almost nothing, so a shared package would be empty.
   - Shared logic lives in the domain, protocol and engine packages instead.
3. **Storage: Drift 2.35 + sqlite3 3.8.**
   - sqlite3 3.x bundles SQLite through build hooks, with no system library needed.
   - Dates are stored as ISO text so milliseconds and UTC survive.
   - Settings: WAL mode, `foreign_keys=ON`, `busy_timeout`. Backups use `VACUUM INTO`.
4. **Transport: `dart:io` WebSocket.** It is the same API on both sides and needs no extra package.
5. **Windows keyboard: `win32` FFI `SendInput` with `KEYEVENTF_UNICODE`.**
   - It does not depend on the keyboard layout and needs no C++ plugin.
   - Before typing it runs a heuristic check for an elevated foreground window, because UIPI blocks input silently.
6. **Camera: `mobile_scanner` 7.4.** It covers all required symbologies on Android (ML Kit) and iOS (Vision).
7. **Secrets: `flutter_secure_storage` 11.2.** It uses Keychain, Keystore, DPAPI or libsecret. The Windows build needs the MSVC ATL component.
8. **State/DI: Riverpod 3. Routing: go_router 18.**
9. **Localization:** shared ARB files in `scanbridge_ui` (`SbLocalizations`), with English and Hindi only.

## Consequences

- macOS, Linux and iOS builds need their own native hosts. They are not built or tested here (see `KNOWN_LIMITATIONS.md`).
- Adding a macOS (Quartz) or Linux (XTest/portal) adapter only means implementing `KeyboardOutputAdapter`.
