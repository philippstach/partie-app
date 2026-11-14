#!/bin/zsh
# Neueste Partie im iPhone-Simulator starten (für Philipps MacBook). Nicht syntaxgeprüft, nicht gelaufen.
# Aufruf im Repo-Ordner:  Werkzeug/simulator-iphone.sh [Gerätename, Standard "Partie Test"] [klar|tinte|salon] [hell|dunkel] [Spiel-Kennung wie im Katalog, z. B. yacht-neu, sudoku-neu, maexchen]
# Beispiele:  Werkzeug/simulator-iphone.sh
#             Werkzeug/simulator-iphone.sh "iPhone 16" tinte dunkel yacht
# Was es tut: baut die App (Scheme Partie) für den Simulator, startet nur das eigene Gerät, installiert und öffnet Partie.
# Regeln: nie ein zweiter xcodebuild gleichzeitig (Regel 9), nie `shutdown all`, nur das eigene Gerät. Am Ende bleibt der Simulator
# offen; Herunterfahren: xcrun simctl shutdown "<Gerätename>"   (oder Simulator-Fenster schließen).
set -e
geraet=${1:-Partie Test}
design=${2:-tinte}
modus=${3:-hell}
spiel=${4:-}
wurzel=${0:A:h:h}
dd="${PARTIE_SIM_BAU:-/tmp/partie-dd-simulator}"
cd "$wurzel"

while pgrep -x xcodebuild >/dev/null 2>&1; do echo "Warte: anderer xcodebuild läuft ..."; sleep 30; done

# Gerät suchen (erstes mit passendem Namen, das verfügbar ist)
udid=$(xcrun simctl list devices available | grep -F "$geraet (" | head -1 | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true)
[ -n "$udid" ] || { echo "Kein Simulator \"$geraet\" gefunden. Vorhandene:"; xcrun simctl list devices available | grep iPhone; exit 2; }

echo "... baue Partie für $geraet ($udid)"
xcodebuild -project Partie.xcodeproj -scheme Partie -destination "platform=iOS Simulator,id=$udid" \
  -derivedDataPath "$dd" -quiet build > /tmp/partie-simulator-bau.log 2>&1 \
  || { echo "Bau rot, Log: /tmp/partie-simulator-bau.log"; grep -E "error:" /tmp/partie-simulator-bau.log | head -10; exit 1; }

app=$(find "$dd/Build/Products" -maxdepth 2 -name 'Partie.app' | head -1)
[ -d "$app" ] || { echo "Partie.app nicht gefunden unter $dd"; exit 1; }
bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist")

xcrun simctl boot "$udid" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$udid" 2>/dev/null || true   # neueres Xcode ohne Simulator.app: Ansicht über das iOS-Simulator-Feld der Claude-App
xcrun simctl bootstatus "$udid" -b > /dev/null
xcrun simctl ui "$udid" appearance "$([ "$modus" = dunkel ] && echo dark || echo light)" > /dev/null 2>&1 || true
xcrun simctl install "$udid" "$app"
xcrun simctl terminate "$udid" "$bundle" > /dev/null 2>&1 || true

args=(-AppleLanguages "(de)" -AppleLocale de_DE -design.art "$design")
[ -n "$spiel" ] && args+=(-startetMit "$spiel")
xcrun simctl launch "$udid" "$bundle" "${args[@]}"
echo "Partie läuft in $geraet ($design, $modus${spiel:+, Spiel $spiel}). Bild: xcrun simctl io $udid screenshot ~/Desktop/partie.png"
