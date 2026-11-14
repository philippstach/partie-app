#!/bin/zsh
# Designwechsel: Beweis „Klar & Glas sieht aus wie Build 12“ ohne Simulator (Mac Catalyst).
# Zeichnet die Szenen des Pakets Test/KlarVergleich zweimal: mit dem alten Stand (Baukasten 2.16 aus
# ../_Baukasten-2.16-Original, SpieleKern und ArcadeKern aus dem Commit $BASIS) und mit dem Stand dieser Arbeitskopie
# (Design „klar“). Danach vergleicht Werkzeug/designwechsel_klar_vergleich.py die Bilder Punkt für Punkt.
# Aufruf im Projektordner: Werkzeug/designwechsel_klar_vergleich.sh      Ergebnis: ../Bilder/klar-vergleich/
set -u
wurzel=${0:A:h:h}
bau=${wurzel:h}/.bau
basis=${BASIS:-e405298e}
ziel=${wurzel:h}/Bilder/klar-vergleich
frei=$(df -g ~ | tail -1 | awk '{print $4}')
if [ "$frei" -lt 8 ]; then echo "ABBRUCH: nur $frei GB frei."; exit 3; fi
gewartet=0
while pgrep -x xcodebuild >/dev/null 2>&1; do
  if [ $gewartet -ge ${WARTEN:-1500} ]; then echo "Hinweis: anderer Build läuft noch; starte trotzdem."; break; fi
  sleep 15; gewartet=$((gewartet + 15))
done

# Alter Stand als eigener Baum mit denselben Paketpfaden
alt=$bau/vergleich/alt
rm -rf "$alt"; mkdir -p "$alt/_Gemeinsam" "$alt/Arbeit/Test" "$ziel/alt" "$ziel/neu"
cp -R "${wurzel:h}/_Baukasten-2.16-Original" "$alt/_Gemeinsam/Baukasten"
rm -rf "$alt/_Gemeinsam/Baukasten/.build" "$alt/_Gemeinsam/Baukasten/.swiftpm"
git -C "$wurzel" archive "$basis" Pakete/SpieleKern Pakete/ArcadeKern | tar -x -C "$alt/Arbeit" || exit 1
rsync -a --exclude .build --exclude .swiftpm "$wurzel/Test/KlarVergleich" "$alt/Arbeit/Test/"

lauf() {  # $1 = alt|neu, $2 = Paketordner
  rm -f "$ziel/$1"/*.png(N)
  ( cd "$2" && TEST_RUNNER_KLAR_ZIEL="$ziel/$1" xcodebuild test -scheme KlarVergleich \
      -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath "$bau/vergleich/dd-$1" \
      CODE_SIGNING_ALLOWED=NO > "$bau/vergleich-$1.log" 2>&1 )
  echo "== $1 =="
  grep -E "\.swift:[0-9]+:[0-9]*:? error|Test Case .*failed|Executed [0-9]+ tests|\*\* TEST" "$bau/vergleich-$1.log" | cut -c1-220 | tail -20
  ls "$ziel/$1" | wc -l | xargs echo "Bilder:"
}
lauf alt "$alt/Arbeit/Test/KlarVergleich"
lauf neu "$wurzel/Test/KlarVergleich"
python3 "$wurzel/Werkzeug/designwechsel_klar_vergleich.py" "$ziel"
