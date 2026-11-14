#!/bin/zsh
# Designwechsel F.1: Vorschaubilder ohne Simulator (Mac Catalyst, wie catalyst-tests.sh).
# Zeichnet die Szenen des Pakets Test/DesignBilder als PNG nach ../Bilder (Partie/DesignWechsel/Bilder).
# Aufruf im Projektordner: Werkzeug/designwechsel_bilder.sh [Testname, z. B. BausteinBilder]
set -u
wurzel=${0:A:h:h}
bau=${wurzel:h}/.bau
frei=$(df -g ~ | tail -1 | awk '{print $4}')
if [ "$frei" -lt 8 ]; then echo "ABBRUCH: nur $frei GB frei."; exit 3; fi
gewartet=0
while pgrep -x xcodebuild >/dev/null 2>&1; do
  if [ $gewartet -ge ${WARTEN:-1500} ]; then echo "Hinweis: anderer Build läuft noch; starte trotzdem."; break; fi
  sleep 15; gewartet=$((gewartet + 15))
done
mkdir -p "$bau" "${BILDER:-${wurzel:h}/Bilder}"
cd "$wurzel/Test/DesignBilder" || exit 1
nur=()
# Mehrere Namen möglich. Der erste Lauf eines UIKit-gestützten Bildes richtet unter Mac Catalyst die App-Umgebung ein;
# deshalb läuft BausteinBilder immer mit (alphabetisch vor den anderen Klassen).
for n in "$@"; do nur+=(-only-testing:"DesignBilderTests/$n"); done
[ $# -ge 1 ] && nur+=(-only-testing:"DesignBilderTests/BausteinBilder")
TEST_RUNNER_DESIGN_BILDER="${BILDER:-${wurzel:h}/Bilder}" TEST_RUNNER_PARTIE_PARTIEN="$wurzel/App/Ressourcen/Daten" \
xcodebuild test -scheme DesignBilder -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath "$bau/bilder" \
  CODE_SIGNING_ALLOWED=NO $nur > "$bau/bilder.log" 2>&1
grep -E "^BILD |\.swift:[0-9]+:[0-9]*:? error|Test Case .*failed|Executed [0-9]+ tests|\*\* TEST" "$bau/bilder.log" | cut -c1-220 | tail -${ZEILEN:-80}
ls "${BILDER:-${wurzel:h}/Bilder}" | wc -l | xargs echo "Bilder im Ordner:"
