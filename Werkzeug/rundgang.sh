#!/bin/zsh
# UI-Rundgang: ein Befehl, ~300+ Screenshots (alle Spiele, Einstellungen, Startseiten; 3 Designs, hell/dunkel, normale/größte Schrift).
# Aufruf (im Repo-Ordner, auf dem Test-Mac, NICHT auf Philipps Mac, Regel 14):
#   Werkzeug/rundgang.sh <Build-Nummer> [Gerätename, Standard "iPhone 16"] [kurz|voll]
# Ergebnis: ~/Ergebnisse/<Gerät>/rundgang-<build>/*.png  (Dateinamen Spiel_Design_Modus_Schrift_Schritt.png)
# Phasen (Umgebungsvariable RUNDGANG_PHASE): bauen = nur build-for-testing; lauf = test-without-building (gleicher Bau, je Gerät/Design
# mehrfach, mit RUNDGANG_DESIGN=klar|tinte|salon); alles (Standard) = beides. Bau-Ordner mit RUNDGANG_BAU.
# Nur der Export (ohne neuen Lauf): Werkzeug/rundgang.sh <Build> <Gerät> export <pfad-zum.xcresult>
set -e
mkdir -p "${RUNDGANG_BAU:-${0:A:h:h}/../.bau-rundgang}"
wurzel=${0:A:h:h}
build=${1:?Build-Nummer fehlt}
geraet=${2:-iPhone 16}
umfang=${3:-voll}
ziel="$HOME/Ergebnisse/${geraet// /-}/rundgang-$build"
bau="${RUNDGANG_BAU:-$wurzel/../.bau-rundgang}"
mkdir -p "$ziel"
cd "$wurzel"

if [ "$umfang" = export ]; then
  ergebnis=${4:?xcresult-Pfad fehlt}
else
  phase=${RUNDGANG_PHASE:-alles}
  ziel_geraet="platform=iOS Simulator,name=$geraet"
  if [ "$phase" != lauf ]; then
    while pgrep -x xcodebuild >/dev/null 2>&1; do echo "Warte: anderer xcodebuild läuft ..."; sleep 30; done
    rc=0
    xcodebuild build-for-testing -project Partie.xcodeproj -scheme Rundgang -destination "$ziel_geraet" \
      -derivedDataPath "$bau/dd" > "$bau/bau.log" 2>&1 || rc=$?
    grep -E "error:|BUILD|TEST BUILD" "$bau/bau.log" | head -30
    [ $rc -eq 0 ] || { echo "BAU FEHLGESCHLAGEN (rc=$rc), Log: $bau/bau.log"; exit $rc; }
  fi
  [ "$phase" = bauen ] && { echo "Bau fertig: $bau/dd"; exit 0; }
  ergebnis="$bau/rundgang-$build${RUNDGANG_DESIGN:+-$RUNDGANG_DESIGN}.xcresult"
  rm -rf "$ergebnis"
  rc=0
  TEST_RUNNER_RUNDGANG_UMFANG=$umfang TEST_RUNNER_RUNDGANG_DESIGN=${RUNDGANG_DESIGN:-} \
  xcodebuild test-without-building -project Partie.xcodeproj -scheme Rundgang -destination "$ziel_geraet" \
    -derivedDataPath "$bau/dd" -resultBundlePath "$ergebnis" -parallel-testing-enabled NO > "$bau/lauf.log" 2>&1 || rc=$?
  grep -E "error:|Test Case|TEST |Executed" "$bau/lauf.log" | tail -40
  # Testfehler (rc=65) sind erwartet: Bilder und Bericht werden trotzdem exportiert. Ohne Ergebnisbündel: Abbruch.
  [ -d "$ergebnis" ] || { echo "LAUF FEHLGESCHLAGEN (rc=$rc), kein Ergebnisbündel, Log: $bau/lauf.log"; exit ${rc:-1}; }
fi

# Export: Anhänge aus dem Ergebnisbündel holen und nach dem Namen der Anhänge benennen
tmp=$(mktemp -d)
xcrun xcresulttool export attachments --path "$ergebnis" --output-path "$tmp"
python3 -I - "$tmp" "$ziel" <<'PY'
import json, os, re, shutil, sys
tmp, ziel = sys.argv[1:3]
manifest = json.load(open(os.path.join(tmp, "manifest.json")))
n = 0
for test in manifest:
    for a in test.get("attachments", []):
        name = a.get("suggestedHumanReadableName", a["exportedFileName"])
        name = re.sub(r"_\d+_[0-9A-Fa-f-]{36}(\.\w+)?$", "", name)      # Anhang-Zähler und UUID entfernen
        ext = os.path.splitext(a["exportedFileName"])[1] or ".png"
        name = re.sub(r"\.\w{2,4}$", "", name)
        name = re.sub(r"[^\w\-.]+", "-", name) + ext
        dest = os.path.join(ziel, name)
        shutil.copy(os.path.join(tmp, a["exportedFileName"]), dest); n += 1
print(f"{n} Bilder nach {ziel}")
PY
rm -rf "$tmp"
