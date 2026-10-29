# Security and privacy model

## Principles

- No accounts, telemetry, cloud services or licence checks. The core features work without Internet access.
- Barcode values are never written to logs. The diagnostics report leaves out scan values, tokens, secrets and device ids.
- Data stays on the devices: SQLite on each device, plus files the user exports explicitly.

## Network threat model (LAN mode)

| Threat | Mitigation in v1 |
|---|---|
| A stranger on the LAN sends fake scans | Every message after pairing is HMAC-SHA256 signed with a per-device secret. Unsigned or wrongly signed messages are rejected and the socket is closed. |
| Replay of captured messages | Replayed `messageId`s are dropped (LRU of 10,000). `sentAt` must be within ±24 h. `scan.submit` is idempotent by `scanId`. |
| Pairing code brute force | The 50-bit token works once and expires after 3 min. A wrong code consumes the offer. Auth failures are limited to 10 per minute. The operator must approve each pairing on screen. |
| Passive eavesdropping | **Not mitigated.** Traffic is plaintext WebSocket, so scan values are visible to anyone who can sniff the LAN. The device secret is derived and never transmitted. Use trusted networks only. TLS with certificate pinning is planned. |
| A compromised device already on the LAN | LAN-only mode does not protect against this. Authentication still prevents unpaired devices from submitting scans. |
| Exposure beyond the LAN | The server binds to loopback unless LAN mode is enabled, and enabling it shows a warning. ScanBridge never changes firewall rules. |
| Path traversal through templates | File output is confined to one approved output folder. Absolute paths outside it and `..` escapes are rejected (covered by tests). |
| Arbitrary code from imported templates | Not possible. `RUN`, `JAVASCRIPT_FUNCTION` and `HTTP_REQUEST` are catalogued but not executable in this build. Unknown components are kept but disabled. |
| Destructive key sequences | Chords such as Ctrl+…, Delete and Backspace wait for operator confirmation (on by default). |
| Typing into the wrong window | A visible armed/paused toggle (Ctrl+Shift+P while focused). ScanBridge never steals or changes focus. |

## Secrets

- Device secrets and the host id are kept in OS secure storage through `flutter_secure_storage`. They are cached in memory while the app runs.
- On Linux, secure storage needs libsecret and a running Secret Service. Without it, storing secrets fails visibly; there is no plaintext fallback.
- "Forget"/"Revoke" deletes the device secret.

## Not claimed

- The database is not encrypted at rest (it relies on OS user-account protection).
- Transport encryption is not provided in v1.
