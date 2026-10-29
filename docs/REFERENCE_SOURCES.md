# Reference Sources

Audit date: 2026-10-30. Public pages only; paraphrased. See `docs/REFERENCE_AUDIT.md`.

## Product site
- https://barcodetopc.com/
  - Feature set, plan gates (NUMBER, real-time CSV/Excel paid), Enterprise-only items, local-network/no-cloud claim
  - Pricing display inconsistent ($0.00 values); no changelog link
- https://barcodetopc.com/pricing/
  - Free/Starter/Pro/Unlimited/Enterprise limits (scans, phones, templates, components)
  - One-month, 300-scan free trial; 15-day refund
- https://barcodetopc.com/supported-barcode-formats
  - Format list per OS; Android-only Codabar/RSS; MSI unsupported; PDF417 off by default
- https://barcodetopc.com/frequently-asked-questions/
  - Same-network requirement, TCP 57891 and UDP 5353, manual pairing, hotspot use, Bonjour error fix, offline operation

## Docs
- https://docs.barcodetopc.com/
  - Getting-started structure; docs nav
- https://docs.barcodetopc.com/keyboard-emulation/
  - Types into active window; macOS Accessibility; Windows admin note; enable toggle
- https://docs.barcodetopc.com/output-template/how-it-works/
  - Template = ordered components; Skip output; outputs feed typing and CSV/Excel
- https://docs.barcodetopc.com/output-template/components/number/
  - NUMBER numeric keyboard, regex filter, paid
- https://docs.barcodetopc.com/output-template/components/date_time/
  - DATE_TIME format tokens; neighbors PRESS KEY and TIMESTAMP
- https://docs.barcodetopc.com/csv-files/method1/
  - Real-time CSV append, path variables, paid; next page "Save a Scan session"
- https://docs.barcodetopc.com/excel/write-to-excel-files/
  - Excel append, file must be closed, "Map Columns" page exists
- https://docs.barcodetopc.com/examples/android-pda-devices/
  - PDA via broadcast intent (DataWedge), manual-input scan mode fix
- Not reachable (HTTP 404): https://docs.barcodetopc.com/sitemap.xml, https://docs.barcodetopc.com/examples/ai-template-generator/
- Not found by search: component reference index (DELAY, RUN, HTTP, CSV_LOOKUP, FOCUS_WINDOW pages) - Unverified

## Server repo (fttx/barcode-to-pc-server)
- https://github.com/fttx/barcode-to-pc-server
  - GPL-3.0; Electron core plus Ionic UI; Win/macOS/Linux; no feature list in README
- https://github.com/fttx/barcode-to-pc-server/releases
  - v5.0.0-beta.1..4 (2026-09-01..2026-10-28): redesign, templates page, preview/history, Phones page, sign-in/licence, Linux packages, .btps/.btpt files, join password
  - v4.9.0 (2025-10-27), v4.8.x: Google Sheets, template locking, scan aggregation, JS function UI, phone-side HTTP, Excel output (4.7.0)
- https://github.com/fttx/barcode-to-pc-server/issues
  - Pain points: discovery/firewall, launch failures, Linux special chars, Excel header/update bugs, counters, relay server request

## Mobile repo (fttx/barcode-to-pc-app)
- https://github.com/fttx/barcode-to-pc-app
  - GPL-3.0; Ionic/Cordova; Android + iOS; Firebase config needed to build
- https://github.com/fttx/barcode-to-pc-app/releases
  - v4.9.0 (2025-10-27), v4.8.10; v4.6.x: GEOLOCATION, keyboard delay, clipboard-only, PDA intent action, alert timeout; v4.5.0: IMAGE, inverted barcodes
- https://github.com/fttx/barcode-to-pc-app/issues
  - Pain points: duplicate CSV after iOS sync, offline remote components, camera bugs, unsynced indicators, ROI/zoom/orientation requests

## Data access note
- Release and issue lists read via the public GitHub REST API (unauthenticated); counts include pull requests
