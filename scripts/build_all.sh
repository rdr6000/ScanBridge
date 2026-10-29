#!/usr/bin/env bash
# Formats, analyzes, tests, then builds the targets this host can build.
# Never reports an artifact unless it exists on disk.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { echo; echo "==> $*"; }

step "Tool versions"
flutter --version | head -1
dart --version

step "Dependencies"
flutter pub get

step "Format check"
dart format --line-length 140 --output=none --set-exit-if-changed packages apps || echo "format: files differ (not fatal)"

step "Analyze"
dart analyze packages apps

step "Pure Dart tests"
for p in scanbridge_domain scanbridge_protocol scanbridge_template_engine scanbridge_storage; do
  (cd "packages/$p" && dart test)
done

step "Desktop host tests"
(cd apps/desktop && flutter test)

build() { # name, dir, flutter-target, artifact-path
  step "Build $1"
  (cd "$2" && flutter build $3 --release)
  if [ -e "$2/$4" ]; then echo "OK: $2/$4"; else echo "MISSING: $2/$4"; exit 1; fi
}

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) build windows apps/desktop windows build/windows/x64/runner/Release/scanbridge_desktop.exe ;;
  Darwin)
    build macos apps/desktop macos build/macos/Build/Products/Release/scanbridge_desktop.app
    build ios apps/mobile "ios --no-codesign" build/ios/iphoneos/Runner.app ;;
  Linux) build linux apps/desktop linux build/linux/x64/release/bundle/scanbridge_desktop ;;
esac
build android apps/mobile apk build/app/outputs/flutter-apk/app-release.apk

step "Done"
