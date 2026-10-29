# Test plan and results

## Automated (run 2026-10-30 on Windows 11, Flutter 3.47.7)

| Suite | Command | Result |
|---|---|---|
| Domain (CSV, export, validation, backoff) | `cd packages/scanbridge_domain && dart test` | 11 passed |
| Protocol (signing, codec limits, replay, pairing) | `cd packages/scanbridge_protocol && dart test` | 9 passed |
| Template engine (IF, prompts, skip output, delays, import errors) | `cd packages/scanbridge_template_engine && dart test` | 12 passed |
| Storage (idempotent receive, outbox, versions, reopen, backup) | `cd packages/scanbridge_storage && dart test` | 9 passed |
| Desktop host over real WebSocket (pair, ack, resend, tamper, revoke, pause, path traversal) | `cd apps/desktop && flutter test` | 6 passed |
| Static analysis | `dart analyze packages apps` | No issues |

## Builds

| Target | Result |
|---|---|
| Windows release (`flutter build windows --release`) | ✅ `scanbridge_desktop.exe`. Needs VS Build Tools with the C++ and **ATL** components |
| Android debug (`flutter run -d <device>`) | ✅ installed and ran on an Android 12 phone |
| macOS, Linux, iOS | Not tested: no native host available |

## Manual device run (Windows host + Android 12 phone)

| Scenario | Result |
|---|---|
| LAN mode warning → start server → firewall prompt (answered by the user) | ✅ |
| Manual pairing with IP, port and code → approval on desktop → connected | ✅ |
| Keyboard test panel types Unicode `✓` + Enter into its own field | ✅ |
| Phone manual entry `00012345678905` → typed into the focused desktop field, leading zeros kept, Enter | ✅ |
| Pause output → stop server → 2 offline scans queued ("2 waiting to send") → restart → both delivered once, status `paused` | ✅ |
| Camera scanner screen and permission prompt | ✅ After a phone reboot: live preview, scan window and torch/switch controls. Before the reboot the device HAL returned `ERROR_CAMERA_DEVICE` (device fault, not app) |
| Phone reboot → app relaunch → auto-reconnect with stored credentials | ✅ |
| Real Code 128 barcode `6937448826340` scanned with the camera (by the user) → delivered; first copy stored `paused` (output paused), second typed and flagged `duplicate` | ✅ |

## Still to run

- Camera pairing via the desktop QR code
- Two phones at once
- A physical wedge scanner
- macOS, Linux and iOS acceptance scenarios (spec §10.4)
- Import of a malformed template through the UI
- A 10,000-scan session
