#!/bin/zsh
# Designwechsel: ein Build ohne Simulator, immer nur einer gleichzeitig.
# Wartet, bis kein anderer xcodebuild läuft (höchstens WARTEN Sekunden), prüft den freien Speicher (mindestens 8 GB)
# und baut dann mit eigenem Bau-Ordner (../.bau, außerhalb des Repos). Nach jeder Stufe den Bau-Ordner leeren: rm -rf ../.bau
# Aufruf im Projektordner:
#   Werkzeug/designwechsel_bau.sh app            App (generisches iOS-Simulator-Ziel, wie integrieren-schritt.sh)
#   Werkzeug/designwechsel_bau.sh baukasten      nur das Paket Baukasten für iOS (schnelle Probe der Bausteine)
#   Werkzeug/designwechsel_bau.sh paket <Name>   Paket-Tests unter Mac Catalyst (wie paket-tests.sh, aber mit Warten)
set -u
wurzel=${0:A:h:h}
bau=${wurzel:h}/.bau
warten=${WARTEN:-1500}
cd "$wurzel" || exit 1

frei=$(df -g ~ | tail -1 | awk '{print $4}')
if [ "$frei" -lt 8 ]; then echo "ABBRUCH: nur $frei GB frei (unter 8 GB wird nicht gebaut)."; exit 3; fi

gewartet=0
while pgrep -x xcodebuild >/dev/null 2>&1; do
  if [ $gewartet -ge $warten ]; then echo "Hinweis: nach ${warten}s läuft noch ein anderer Build; baue trotzdem."; break; fi
  sleep 15; gewartet=$((gewartet + 15))
done
[ $gewartet -gt 0 ] && echo "gewartet: ${gewartet}s"

mkdir -p "$bau"
case "${1:-app}" in
  app)
    # Nur arm64 (halber Platz und halbe Zeit); ALLE_ARCH=1 baut wie integrieren-schritt.sh beide Architekturen.
    arch=(ARCHS=arm64 ONLY_ACTIVE_ARCH=NO); [ -n "${ALLE_ARCH:-}" ] && arch=()
    xcodebuild -project Partie.xcodeproj -scheme Partie -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath "$bau/app" $arch build > "$bau/app.log" 2>&1
    grep -E "error:|warning: unre|BUILD (SUCCEEDED|FAILED)" "$bau/app.log" | sort -u | head -${ZEILEN:-60}
    ;;
  baukasten)
    cd "${wurzel:h}/_Gemeinsam/Baukasten" || exit 1
    xcodebuild -scheme KlarGlas -destination 'generic/platform=iOS Simulator' -derivedDataPath "$bau/baukasten" build > "$bau/baukasten.log" 2>&1
    grep -E "error:|BUILD (SUCCEEDED|FAILED)" "$bau/baukasten.log" | sort -u | head -${ZEILEN:-60}
    ;;
  paket)
    p=${2:?Paketname}
    schema=$p; [ "$p" = Spiel10k ] && schema=Spiel10k-Package
    cd "$wurzel/Pakete/$p" || exit 1
    TEST_RUNNER_PARTIE_PARTIEN="$wurzel/App/Ressourcen/Daten" xcodebuild test -scheme $schema \
      -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath "$bau/$p" > "$bau/$p.log" 2>&1
    grep -E "✘|Fatal error|error:|Test run with|Executed [0-9]+ tests|\*\* TEST" "$bau/$p.log" | grep -v CoreData | sort -u | tail -${ZEILEN:-25}
    ;;
esac
