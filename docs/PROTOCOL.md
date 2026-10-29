# ScanBridge protocol v1

Original protocol designed for ScanBridge. It is not compatible with Barcode to PC.
Implementation: `packages/scanbridge_protocol`.

## Transport

- WebSocket over TCP at `ws://<host>:<port>/ws`. The default port is **57900**.
- The host binds to `127.0.0.1` by default. It binds to `0.0.0.0` only when **LAN mode** is on, and the UI warns before it does.
- Frames are UTF-8 JSON text. Binary frames are rejected. The maximum frame size is 64 KiB.
- TCP keep-alive uses WebSocket ping every 15 s (`pingInterval`). The phone also sends `device.heartbeat` every 30 s.
- TLS is not implemented in v1. Messages are authenticated but **not encrypted** (see `SECURITY.md`). The envelope and signing do not depend on the transport, so a later `wss://` transport needs no domain changes.

## Envelope

```json
{
  "protocolVersion": 1,
  "messageId": "uuid",
  "type": "scan.submit",
  "deviceId": "uuid | null",
  "sentAt": "2026-10-29T00:00:00.000Z",
  "payload": { },
  "auth": { "keyId": "…", "signature": "base64" }
}
```

- `signature` is `HMAC-SHA256(key, canonical(envelope without auth))`.
- Canonical JSON uses recursively sorted keys and no whitespace (`canonicalJson`).
- Signatures are compared in constant time.
- Validation:
  - `protocolVersion` must equal 1. Any other value is answered with `server.error` and code `protocolVersionMismatch`, and the socket is closed.
  - `type` must be in the list below.
  - `messageId` and `deviceId` are limited to 64 characters.
- Replay protection:
  - The host keeps a bounded LRU of the 10,000 most recent `messageId`s.
  - `sentAt` must be within ±24 h of the receiver's clock.
  - `scan.submit` is also idempotent by `scanId`.

### Keys

| Phase | `keyId` | Key |
|---|---|---|
| Pairing (`pair.request`, `pair.accept`, `pair.reject` after a verified request) | `pairing` | UTF-8 bytes of the one-time pairing token |
| Phone → host after pairing | the phone's `deviceId` | device secret |
| Host → phone after authentication | `server` | device secret |

## Pairing

1. The desktop creates an offer containing a random 10-character Crockford base32 token (50 bits). The offer is valid for 3 minutes and works once.
2. The desktop shows the offer as a QR code and as a typed code `ABCDE-12345`:
   `scanbridge://pair?v=1&h=<ip1,ip2>&p=<port>&t=<token>&n=<name>&id=<serverId>`
3. The phone connects and receives `server.hello {serverId, serverName, nonce, serverTime}`. This message is unsigned.
4. The phone sends `pair.request {deviceName, platform, clientNonce}`, signed with the token.
   - The host consumes the offer whether the signature is right or wrong. A wrong code therefore invalidates the QR code.
   - Failed attempts are rate-limited to 10 per minute.
5. The operator approves or declines on the desktop. The decision times out after 2 minutes.
6. On approval, the host replies `pair.accept {serverId, serverName, serverNonce}`, signed with the token. On decline it replies `pair.reject`.
7. Both sides derive the device secret:
   `secret = HMAC-SHA256(token, "scanbridge/v1/device-secret|deviceId|clientNonce|serverNonce")`.
   The secret is never sent over the network.
8. Secrets are stored in OS secure storage: Windows Credential Manager/DPAPI, macOS/iOS Keychain, Android Keystore, or libsecret on Linux.

## Session start (every connection)

```text
host  -> server.hello            (unsigned)
phone -> device.status           {deviceName, platform, pendingScans}   signed
host  -> device.status           {serverName, accepted}                 signed
host  -> template.list           {templates[], activeTemplateId}        signed
```

The host closes the connection with `server.error` code `authenticationFailed` in any of these cases:

- the device is unknown or revoked
- the signature is wrong
- the message is stale

## Message types

| Type | Direction | Payload |
|---|---|---|
| `server.hello` | H→P | `serverId, serverName, nonce, serverTime` |
| `pair.request` | P→H | `deviceName, platform, clientNonce` |
| `pair.accept` / `pair.reject` | H→P | `serverId, serverName, serverNonce` / `code, message` |
| `device.status` | both | phone: `deviceName, platform, pendingScans`; host: `serverName, accepted` |
| `device.heartbeat` | both | `{}` |
| `device.revoke` | H→P | `{}`; the host closes the socket afterwards |
| `scan.submit` | P→H | see below |
| `scan.ack` | H→P | `scanId, duplicateSubmit, receivedAt` |
| `scan.reject` | H→P | `scanId, code, message` |
| `delivery.status` | H→P | `scanId, outputStatus, error?` |
| `session.update` | P→H | `sessionId, name` |
| `template.list` | P→H request, H→P response | `templates[]` (template JSON), `activeTemplateId` |
| `server.error` | H→P | `code, message` |

### `scan.submit`

```json
{
  "scanId": "uuid",
  "sessionId": "uuid",
  "sessionName": "Shelf A",
  "rawValue": "00012345678905",
  "symbology": "ean13",
  "quantity": "1",
  "capturedAt": "ISO-8601 UTC",
  "source": "camera|manual|hardware|imported",
  "templateId": "uuid|null",
  "templateVersion": 3,
  "values": { "<componentId>": "<answer>" }
}
```

- `rawValue` is a string of at most 4,096 characters and must not be empty.
- `quantity` is a decimal string that must match `^-?\d+(\.\d+)?$`. Floats are never used.
- `values` has at most 64 entries, and each value is a string of at most 4,096 characters.
- `values` holds the operator's answers to template prompts. The phone collects the answers and the host executes the template, so both sides always use one exact template version.

## Delivery and idempotency

1. The phone stores the scan and its outbox row in **one SQLite transaction** before any network attempt.
2. The phone sends `scan.submit` with a stable `scanId`.
3. The host validates the scan and stores it in a transaction, then acknowledges.
   - The ack is sent **only after** the scan is stored.
   - If storage fails, the host replies `scan.reject` with code `storageFailure`. The phone keeps the item queued.
4. The host runs output asynchronously and reports it with `delivery.status`. Delivery status and output status are tracked separately.
5. If the phone resends a `scanId` the host already has, the host replies `scan.ack` with `duplicateSubmit=true` and **does not run output again**.
6. If no ack arrives within 10 s, the phone records a failure and backs off:
   - The backoff is exponential with equal jitter, starting at 1 s and capped at 2 min.
   - After 50 attempts the item becomes dead-letter and the scan is marked `failed`.
   - "Send unsent" re-queues failed items with the same ids.
7. Keyboard output cannot be exactly-once across a crash at the moment keys are injected.
   - When the host restarts, it marks in-flight output `failed` ("Interrupted by restart").
   - Manual resend shows a warning that the value may be typed twice.

Status values:

- Delivery: `captured`, `queued`, `received`, `rejected`, `failed`, `localOnly`
- Output: `none`, `pending`, `succeeded`, `failed`, `skipped`, `paused`
