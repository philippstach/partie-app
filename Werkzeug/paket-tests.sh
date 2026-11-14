#!/bin/bash
# Testet ein Einzel-Spielpaket auf dem Mac, ohne Simulator (Mac Catalyst, UIKit steht dort zur Verfügung).
# Aufruf: Werkzeug/paket-tests.sh SpielYacht   (auch SpielRauswurf, SpielSchocken, SpielSolitaer)
# Bau-Zwischenstände landen in .bau/ und werden mit `rm -rf .bau` entfernt.
set -euo pipefail
P="${1:?Paketname, z. B. SpielYacht}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BAU="$ROOT/.bau"; mkdir -p "$BAU"
if [ "$P" = "SpielSolitaer" ]; then
  # Partienlisten als echtes Bundle bereitstellen (ein loser Ordner wird unter Mac Catalyst nicht gefunden).
  B="$BAU/Partien.bundle"; rm -rf "$B"; mkdir -p "$B/Contents/Resources"
  cp -R "$ROOT/Pakete/SpielSolitaer/Shared/partien/"* "$B/Contents/Resources/"
  cp -R "$ROOT/Pakete/SpielSolitaer/Shared/partien/"* "$B/"
  printf '<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleIdentifier</key><string>de.partie.partien</string><key>CFBundlePackageType</key><string>BNDL</string></dict></plist>' > "$B/Contents/Info.plist"
  export TEST_RUNNER_PARTIE_PARTIEN="$B"
fi
cd "$ROOT/Pakete/$P"
xcodebuild test -scheme "$P" -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath "$BAU/$P" 2>&1 \
  | grep -E "Test run with|Executed [0-9]+ tests|Test Case.*failed|error:|\*\* TEST" | grep -v "CoreData" | tail -20
