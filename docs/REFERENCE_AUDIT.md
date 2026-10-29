# ScanBridge Reference Audit (Phase 0)

- Audit date: 2026-10-30
- Method: public, user-facing info only (README, release notes, docs pages, issue titles, pricing/FAQ pages)
- No upstream source code was read, copied, or ported; all notes are paraphrased
- Reference product: Barcode to PC (BTPC), https://barcodetopc.com/
- Sources and facts: see `docs/REFERENCE_SOURCES.md`
- Re-audit before every major ScanBridge release against a recorded upstream version

## 1. Versions and licenses reviewed

### 1.1 Server (desktop) - fttx/barcode-to-pc-server
- License: GPL-3.0 (GitHub license metadata and README; LICENSE file text not re-read in full)
- Latest public release reviewed: v5.0.0-beta.4 (2026-10-28, pre-release)
- Prior pre-releases: beta.3 (2026-10-20), beta.2 (2026-09-03), beta.1 (2026-09-01)
- Latest stable reviewed: v4.9.0 (2025-10-27)
- Stable history reviewed: v4.8.0 (2025-02-15) .. v4.8.10 (2025-10-25); v4.7.0 (2024-07-30); v4.6.x (2023-11); older tags listed back to v3.17.0 (2021-07)
- Release assets in beta: Windows installer, macOS dmg/zip (x64 + arm64), Linux AppImage/deb/rpm (per beta.2 notes)
- Latest default-branch commit seen via API: 5d7952c (dated 2025-10-26); beta releases appear to ship without matching public source commits (Unverified, observation only)
- Repo state: not archived; ~158 open issues (API count includes PRs)

### 1.2 Mobile app - fttx/barcode-to-pc-app
- License: GPL-3.0 (GitHub license metadata and README)
- Latest release reviewed: v4.9.0 (2025-10-27)
- Prior: v4.8.10 (2025-10-25), v4.7.5 (2024-09-19), v4.6.5/4.6.6 (2024-07-09), v4.6.0 (2023-11-03), v4.5.0 (2023-05-08)
- Latest default-branch commit seen via API: 56f183a (dated 2025-10-31)
- Tech stack per README: Ionic/Cordova; Firebase config required to build (implies Firebase use, Unverified scope)
- Repo state: not archived; ~111 open issues (API count includes PRs)

### 1.3 Licensing notes for ScanBridge
- Both repos GPL-3.0: ScanBridge must remain independent, no code reuse (see PROVENANCE.md)
- Product site terms/trademark not reviewed; do not use BTPC name, logo, or text
- Re-check dependency licenses before distribution (DEPENDENCY_LICENSES.md)

## 2. Commercial model observed (informs "no limits" differentiation)
- Free tier: 1 phone, 1 template, 4 components, 300 scans (trial-style; page wording inconsistent)
- Starter/Pro: capped scans/month, phones, templates, components
- Unlimited: one-time license; Enterprise: custom
- Paid gates: NUMBER component, real-time CSV, real-time Excel
- Enterprise-only: faster scan engine, ID/OCR scanning, selective barcode scanning, AI scanning, custom branding
- v5 beta: account sign-in or licence key required; licence works offline for 30 days; scans queue on phone until licensed
- v5 beta: phones over plan limit wait for another to disconnect
- ScanBridge decision: none of these gates; no account, quotas, or licence checks

## 3. Classification legend
- PR = Parity Required
- EN = ScanBridge Enhancement
- OI = Optional Integration
- PL = Platform-Limited
- OOS = Out of Scope
- C = Confirmed (stated in public docs/release notes); U = Unverified (inferred or title-only)

## 4. Feature inventory - Desktop host

### D1. Pairing and connection
- D1.1 Server auto-discovery via mDNS/Bonjour: phone finds PC on LAN. In: same network. Out: server list on phone. C (FAQ). PR; ScanBridge adds manual fallback and clear diagnostics
- D1.2 Manual pairing by QR code or IP address: fallback when discovery fails. C. PR
- D1.3 Fixed ports (TCP 57891, UDP 5353 mDNS): firewall rules needed. C. EN: show required ports and a connectivity self-test; own versioned protocol
- D1.4 Phone hotspot as network when no Wi-Fi: C. PR (document in help)
- D1.5 External network by public IP: C (FAQ). OOS for core (needs port forwarding); revisit as optional relay. Issue asks for relay server (#442)
- D1.6 Multiple phones to one PC: C. PR (unlimited)
- D1.7 Phones page: lists phones online/offline, remove unused (v5 beta.3): C. PR
- D1.8 Join password for phones (v5 beta.3/4): C. EN (pairing token + optional passcode)
- D1.9 Block a phone; push one setup to all phones (paid, v5): C. EN (device trust list, config push)
- D1.10 Phones show host computer name (v5 beta.4): C. PR
- D1.11 Multi-NIC machines reachable (fixed in beta.1): C. EN (advertise on all interfaces, pick preferred)
- D1.12 Device-name-pattern template locking (v4.8.9): restrict a template to certain devices. C. EN
- D1.13 Bonjour dependency removed in 4.8.0; older FAQ mentions "Apple Bonjour missing" error: C. EN (bundle mDNS natively, no external install)

### D2. Keyboard emulation
- D2.1 Type scan into focused window: In: scan text. Out: keystrokes. C. PR (core)
- D2.2 Enable/disable toggle in settings: C. PR
- D2.3 macOS needs Accessibility permission: C. PL (guided permission flow + test screen)
- D2.4 Windows: run as Administrator for elevated target apps: C. PL (UIPI note; explain limit)
- D2.5 Linux typing (X11 vs Wayland): issue on special chars (#271). U for current state. PL (Wayland limits documented)
- D2.6 Special/control characters, GS/RS/EOT replacement in barcode output (issues #112, #323): U. EN (configurable control-char mapping)
- D2.7 Keyboard delay option (app v4.6.5): C. PR
- D2.8 Clipboard (copy only) output mode: C. PR
- D2.9 Enter and Tab (with modifier keys) steps: C. PR
- D2.10 Non-US layouts: issue "number entry problem Azerty" (#166): U. EN (layout-aware typing, Unicode injection fallback)
- D2.11 "Web safe" typed string idea (#161): U. EN

### D3. Output templates and components
- D3.1 Template = ordered list of components run per scan session: C. PR
- D3.2 Templates page: enable/disable, reorder, ready-made starters (v5 beta.1): C. PR
- D3.3 Live preview, undo, saved version history (v5 beta.1/3): C. EN (template versioning is a spec item)
- D3.4 Import/export template file (.btpt) and whole setup (.btps): C. PR (own formats, no compatibility promise)
- D3.5 AI template generator from plain-language description (free with sign-in): C. OI (optional, off by default, no account)
- D3.6 Component "Skip output" flag: C. PR
- D3.7 Variables injected into fields and file paths (device name, date, static text): C. PR; variable injector directive added in 4.8.10
- D3.8 Conditions on components / template selection by active window title (issues #196, #215): U. EN
- D3.9 Output template locking by device name pattern: C. EN
- D3.10 Scan aggregation (v4.8.8): groups/combines scans; exact behavior U. PR pending research task
- D3.11 Components observed in docs/notes (purpose, C unless noted):
  - BARCODE: capture scan on phone. PR
  - TEXT: free text entry. PR
  - NUMBER: numeric keyboard, regex filter (paid in BTPC). PR (free)
  - SELECT_OPTION: choose from list; advanced variant requested (#433). PR
  - DATE_TIME / TIMESTAMP: formatted date and time tokens, locale. PR
  - IMAGE: capture photo (v4.5.0); quality definition unclear (#314). PR
  - GEOLOCATION (v4.6.0): PR, PL (permission rules)
  - ALERT (with timeout): message on phone. PR
  - BEEP: sound; not working on iOS per issue #220. PR (U on current state)
  - DELAY: pause between steps. PR
  - ENTER / PRESS_KEY / Tab: key presses on PC. PR
  - FOCUS_WINDOW: bring named window to front before typing (issue #283). U current. PR, PL
  - RUN: execute a program on PC. Optional Integration; security-gated. OI
  - HTTP request (PC-side; phone-side since 4.8.5): OI
  - CSV_LOOKUP / CSV_UPDATE: look up or update rows in a CSV. PR (named in v5 beta.4 fixes)
  - WooCommerce step (named in v5 beta.4 fixes): OI
  - JAVASCRIPT_FUNCTION (UI improved in 4.8.4): custom script step; sandboxing needed. OI, EN (restricted sandbox)
  - Google Sheets component (v4.8.10): OI
- D3.12 Component/template quotas (4 components free): C. OOS (explicitly unlimited)

### D4. Outputs and exports
- D4.1 Append scans to CSV in real time, path with variables (paid in BTPC): C. PR (free)
- D4.2 Append to Excel in real time; Excel must be closed; "Map Columns" page exists: C. PR; EN (no lock failure, queued write)
- D4.3 Excel update/lookup mode: issue #435 "update values doesn't work": U. EN
- D4.4 Export scan session to CSV (all plans): C. PR
- D4.5 CSV headers support in sessions (#286): U. EN
- D4.6 Excel headers breaking on commas (#434): C (issue title). EN (RFC 4180 quoting, tested)
- D4.7 Google Sheets output: C. OI
- D4.8 Export from smartphone (docs nav title): U details. PR
- D4.9 Default CSV export folder improvement (#183): U. EN
- D4.10 "Execute again when syncing" option misbehaves (#436): C (issue title). EN (idempotent replay)

### D5. Sessions and history
- D5.1 Scan sessions list per phone/PC: C. PR
- D5.2 Cross-session search (v5 beta.1): C. PR
- D5.3 Rename, archive, delete, export sessions (v5 beta.1): C. PR
- D5.4 Session name from device name (#189): U. EN
- D5.5 Max sessions counter off-by-one (#331): U. EN (no session cap)
- D5.6 Scan counter bugs (reconnect decreases #306; pairing scans counted #440): C titles. EN (no counter/quota)

### D6. App shell and settings
- D6.1 Settings apply live, icon plus one-line help (v5 beta.1): C. PR
- D6.2 Light/dark following system: C. PR
- D6.3 Tray icon, minimize-to-tray choice (#441), launch at startup: C/U. PR
- D6.4 Auto-update in background, release notes shown after update: C. EN (signed updates, opt-in)
- D6.5 Nine UI languages in v5: C. PR scope: English and Hindi only per project rule
- D6.6 Reset settings keeping templates/scans: C. PR
- D6.7 Migration from v4 data: C. OOS (no ScanBridge predecessor); backup/restore is EN
- D6.8 Crash reporter / telemetry (issue #91): U. OOS (no telemetry)
- D6.9 Linux packaging: AppImage, deb, rpm; .desktop file and flatpak asks (#286, #204): C. PR (AppImage + deb), OI (flatpak)
- D6.10 Platforms: Windows 10/11 64-bit (v5), macOS x64+arm64, Linux; Windows 7/8/32-bit stay on v4.9: C. PR (Win10/11, macOS, Linux)

## 5. Feature inventory - Mobile app

### M1. Scanning
- M1.1 Camera scan, 1D and 2D: C. PR
- M1.2 Formats both OS: QR, Data Matrix, PDF417, Aztec, UPC-A/E, EAN-8/13, Code 39/93/128, ITF: C. PR
- M1.3 Android-only formats: Codabar, RSS14, RSS Expanded; MSI unsupported: C. PR (aim for MSI and Codabar on both via own decoder choice; PL where engine lacks)
- M1.4 Some formats (e.g. PDF417) disabled by default; enable in settings: C. EN (visible format filter, sensible defaults)
- M1.5 Inverted-color barcode option (v4.5.0): C. PR
- M1.6 Continuous scanning and "Continue scanning?" prompt (issue #56): U. PR (no prompt, configurable)
- M1.7 Manual input with focus issues on iPhone 8+ (#174): U. PR
- M1.8 Zoom (#213), region of interest (#222), preferred orientation (#239), viewfinder toggle (#323): U requests. EN
- M1.9 Torch/flash, beep/vibrate feedback: U (not in public notes). PR (expected in spec)
- M1.10 Strip non-printable chars option (#307), special-char disable option (fixed 4.6.0): C/U. EN
- M1.11 Adjacent duplicate barcode detection (fixed 4.6.1): C. PR (configurable duplicate window)
- M1.12 NFC (only an APK filename hint, "4.2.0-beta-nfc"): U. OOS for v1, candidate OI
- M1.13 OCR (#305 request) and ID/OCR (Enterprise): C as plan item. OI (on-device, future)
- M1.14 Selective barcode scanning, AI scanning (Enterprise): C as plan item only. OI (selective: ScanBridge rule filters)

### M2. Hardware scanners and PDAs
- M2.1 Android PDA laser scanners via broadcast intent (action name configured in scanner profile; Zebra DataWedge documented): C. PR (own action name; keyboard-wedge also)
- M2.2 Scan mode setting: camera vs manual input (for PDAs): C. PR
- M2.3 Improve PDA intents (#326, 2026-07): U. EN (preset profiles for common vendors)
- M2.4 Keyboard-wedge scanner input in app field: U. PR (spec item)

### M3. Sessions, sync, offline
- M3.1 Scan sessions on phone; sync to PC: C. PR
- M3.2 Offline mode; remote components (RUN/HTTP/CSV_LOOKUP) fail offline (#238): C title. EN (queue, replay later, explicit state)
- M3.3 Unsynced indicator on sessions/scans (#232, #321): U requests. EN (visible delivery states)
- M3.4 Auto reconnect on host IP change (#178): U. EN (rediscover by stable host ID)
- M3.5 iOS sync causes duplicate CSV appends (#318): C title. EN (idempotent IDs)
- M3.6 Autosend option (#253): U. PR
- M3.7 Session auto-deletion (#317), comments on scans (#15), session photo (#129), multi-select (#53): U requests. EN
- M3.8 Template binding to server (#308): U. EN
- M3.9 Sync button not preserving DELAY order (#322): C title. EN (ordered replay test)
- M3.10 Saved servers, grouped by network (#28), localhost in server list (#315): U. EN
- M3.11 Settings pushed from PC on connect; "Settings updated" dialog: C. PR
- M3.12 Restrict phones by authentication (#309): U. EN (trusted-device list)

### M4. App shell
- M4.1 Android and iOS apps: C. PR (plus iPadOS)
- M4.2 Welcome/connect page, welcome UI fixes: C. PR
- M4.3 Language support; pipe character mistranslation (#313): C title. PR (English, Hindi)
- M4.4 Rating-dialog and upgrade-nudge behavior (#291, #324): U. OOS (no nags)
- M4.5 Privacy policy links: C. PR
- M4.6 Min Android version unclear (#226): U. EN (document min OS)

## 6. Known pain points from issues (titles only; not all verified)
- Connection and install
  - Discovery fails behind firewalls/AV; Bonjour missing errors (#162, #188, FAQ)
  - Server fails to launch on macOS (#418) and some Linux distros (#111, #177)
  - Unclear default listening port (#417); websocket timeouts on iOS (#388)
- Typing correctness
  - Special characters on Linux (#271); Azerty number entry (#166); control chars (#112)
- Data integrity
  - Duplicate CSV appends after iOS sync (#318); counter drift (#306, #440)
  - Excel header/comma mismatch (#434); Excel update not working (#435)
  - Remote components fail offline (#238); sync ordering (#322)
- Camera/UI
  - Camera icon disappears (#327, 2026-08); camera fails after returning to session (#264)
  - Blank screen on iPhone (#297); split-screen broken (#268); toast covers scan button (#316)
- Governance/commercial
  - Device-limit reached stops server (#230); scan caps; request for relay server (#442) and client mode (#224)
  - Security contact and passcode requests (#368, #124)
- Candidate improvements: durable queue, idempotent IDs, visible states, native mDNS, diagnostics screen, no quotas

## 7. Gap analysis

| Reference behavior | ScanBridge requirement | Planned improvement | Platforms | Acceptance test | Status |
|---|---|---|---|---|---|
| Type scan into active window | Keyboard emulation with per-OS adapters | Test screen, permission guide, delivery ack | Win/mac/Linux | Scan arrives in Notepad/TextEdit/gedit field; failure shows reason | see FEATURE_MATRIX |
| Auto-discovery by mDNS plus QR/IP fallback | Pair under 30 s | Native mDNS, QR token pairing, connectivity self-test, port display | All | Pair on fresh LAN; firewall-blocked case shows actionable error | see FEATURE_MATRIX |
| Duplicates after iOS sync (#318) | Never duplicate on lost ack | Unique scan ID, idempotent host intake | All | Drop ack mid-send; replay yields one row/keystroke set | see FEATURE_MATRIX |
| Scan counter drift (#306, #440) | No quotas or counters gating use | Remove counters; per-session counts derived from log | All | Reconnect 10x; count equals stored scans | see FEATURE_MATRIX |
| Remote steps fail offline (#238) | Offline capture then replay | Persist-first queue with states (queued/sent/acked/failed) | Mobile, desktop | Airplane mode scan, restore network, delivered once | see FEATURE_MATRIX |
| Real-time CSV append, paid | Free CSV output with safe quoting | RFC 4180 writer, leading zeros preserved | All desktop | Export commas, quotes, newlines, Unicode, 00123 intact | see FEATURE_MATRIX |
| Real-time Excel append; file must be closed | Excel output without lock failure | Write queue with retry and lock notice | Win/mac/Linux | Open file, scan, close, rows appear in order | see FEATURE_MATRIX |
| Excel headers break on commas (#434) | Correct column mapping | Column mapper tests with delimiter chars | Desktop | Header with comma maps to one column | see FEATURE_MATRIX |
| Template/component caps (1/4 free) | Unlimited templates and components | No limit checks; storage bound only | All | Create 100 templates, 50 components each | see FEATURE_MATRIX |
| Phone count cap, phone waits in v5 | Unlimited paired devices | Remove cap; trusted-device list | Desktop | Connect 8 simulated devices concurrently | see FEATURE_MATRIX |
| v5 requires sign-in/licence | No account or licence | Local-first, zero online checks | All | App works with network disabled from first launch | see FEATURE_MATRIX |
| Template editor with preview and history | Versioned templates, undo | Version snapshots, restore, diff-lite | Desktop | Edit 3 times, restore v1, output matches v1 | see FEATURE_MATRIX |
| Template/setup export files | Backup/restore | Own versioned bundle (templates, settings, sessions) | Desktop | Export, wipe, import, identical config | see FEATURE_MATRIX |
| Component set (BARCODE, TEXT, NUMBER, SELECT_OPTION, DATE_TIME, IMAGE, GEOLOCATION, ALERT, BEEP, DELAY, keys, FOCUS_WINDOW) | Equivalent steps, independent schema | Typed component registry with validation | Mobile+desktop | Each component has unit test and workflow run test | see FEATURE_MATRIX |
| RUN, HTTP, CSV_LOOKUP/UPDATE, JAVASCRIPT_FUNCTION, WooCommerce | Optional integrations, safe by default | Disabled until enabled; allowlist; sandboxed script | Desktop | Disabled step cannot execute; enabled HTTP posts with timeout | see FEATURE_MATRIX |
| Google Sheets component | Optional integration | Opt-in, user-supplied credentials, off by default | Desktop | Works only after explicit connect; none otherwise | see FEATURE_MATRIX |
| AI template generator | Optional helper | Off by default; template presets ship offline | Desktop | App fully usable with feature absent | see FEATURE_MATRIX |
| PDA intent broadcast (Zebra DataWedge etc.) | PDA support | Documented ScanBridge intent action plus wedge mode, vendor presets | Android | Simulated broadcast creates a scan | see FEATURE_MATRIX |
| Scan mode camera vs manual | Scanner source setting | Source selector incl. hardware | Mobile | Switching source routes input correctly | see FEATURE_MATRIX |
| Format list, some off by default, MSI missing | Configurable format filter | Visible toggles, sensible defaults, documented gaps | Mobile | Disabled format ignored; enabled decoded | see FEATURE_MATRIX |
| Adjacent duplicate detection | Configurable duplicate policy | Window in seconds, warn/ignore/allow | Mobile | Same code twice within window follows policy | see FEATURE_MATRIX |
| Keyboard delay, clipboard-only | Typing speed and clipboard modes | Per-template delay, clipboard fallback | Desktop | Delay honoured; clipboard mode leaves focus untouched | see FEATURE_MATRIX |
| Special chars on Linux; Azerty issue | Layout-safe typing | Unicode injection fallback, layout test screen | Desktop | Type "é@#|" and digits on non-US layout | see FEATURE_MATRIX |
| GS/RS/control chars | Control-char policy | Map or strip per template | Desktop | GS1 barcode types agreed output | see FEATURE_MATRIX |
| Cross-session search, archive, rename | Session management | Search, archive, rename, delete with undo | Desktop | Search finds scan across sessions | see FEATURE_MATRIX |
| Settings push to all phones; join password | Controlled pairing | Trusted devices, optional passcode, config push | Desktop+mobile | Untrusted phone rejected; push applies | see FEATURE_MATRIX |
| Device-name template locking | Per-device template rules | Rules by device ID/name pattern | Desktop | Template hidden from non-matching device | see FEATURE_MATRIX |
| Active-window-based template selection (#215) | Context-aware routing | Optional rule by window title | Win/mac (Linux limited) | Title match selects template | see FEATURE_MATRIX |
| Auto reconnect on IP change (#178) | Resilient reconnection | Stable host ID, rediscovery, backoff | All | Change host IP; phone reconnects without action | see FEATURE_MATRIX |
| Unsynced indicators requested (#232, #321) | Visible delivery states | State chips per scan, per session | Mobile | Offline scans show queued; after sync show acked | see FEATURE_MATRIX |
| Background auto-update | Safe update path | Opt-in, signature verified | Desktop | Tampered update rejected | see FEATURE_MATRIX |
| Linux AppImage/deb/rpm | Linux build | AppImage and deb baseline | Linux | Install and launch on Ubuntu LTS | see FEATURE_MATRIX |
| Nine languages | English and Hindi | i18n scaffolding, others by user | All | Language switch covers all strings | see FEATURE_MATRIX |
| Camera zoom/ROI/orientation/torch requests | Camera controls | Zoom, torch, ROI, orientation lock | Mobile | Controls change camera state in test | see FEATURE_MATRIX |
| Keystroke-level insight absent | Diagnostics | Connection and typing diagnostics screen, logs | All | Diagnostics flags blocked port | see FEATURE_MATRIX |

## 8. Items likely missing from a basic parity checklist (add to FEATURE_MATRIX)
- Template locking by device pattern; variable injection in paths/fields
- Scan aggregation; "execute again on sync" semantics
- JAVASCRIPT_FUNCTION, GEOLOCATION, IMAGE, BEEP, ALERT timeout, FOCUS_WINDOW, CSV_UPDATE
- Excel "map columns"; Google Sheets output
- Join password, block device, push settings to all devices
- Template version history, preview, ready-made starters, setup bundle file
- Inverted barcode option; disabled-by-default formats; format availability notes
- Keyboard delay, clipboard-only mode
- Adjacent duplicate detection
- Multi-NIC advertisement, host name shown on phone
- Tray/startup behavior; post-update release notes

## 9. Open research tasks (Unverified items)
- Confirm component list and options from component reference pages (only a subset reachable in this audit)
- Confirm scan aggregation behavior (v4.8.8 notes are one line)
- Confirm torch, beep, vibrate, zoom availability in current app (not in notes)
- Confirm Linux typing backend limits under Wayland
- Confirm NFC status (filename hint only)
- Confirm TIMESTAMP, PRESS_KEY, BEEP details via user-supplied screenshots
- Re-verify license files in full and the beta source availability before any distribution decision
