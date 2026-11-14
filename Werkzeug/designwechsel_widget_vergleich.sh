#!/bin/zsh
# Designwechsel: Bildvergleich der Widget-Ansichten in „Klar & Glas“, Commit davor ($1) gegen jetzt (diese Arbeitskopie, muss sauber sein).
# Die Widget-Quellen jedes Baums werden nach Test/WidgetVergleich/Sources/WidgetKopie kopiert (ohne @main-Bündel; `containerBackground(for: .widget)`
# wird zu `background`, damit der Hintergrund im Bild erscheint; die Sperrbildschirm-Ansicht wird sichtbar gemacht) und im Test zusammen mit den Szenen gezeichnet.
# Kein Simulator (Mac Catalyst). Ergebnis wird an Doku/DESIGNWECHSEL-KLAR-VERGLEICH.txt angehängt.
# Aufruf im Projektordner: Werkzeug/designwechsel_widget_vergleich.sh <Commit davor> [Bezeichnung]
set -u
wurzel=${0:A:h:h}
basis=${1:?Commit davor}
titel=${2:-Widgets $basis}
bau=${wurzel:h}/.bau
alt=${wurzel:h}/_Vergleich-alt
ziel=${wurzel:h}/Bilder/klar-widgets
frei=$(df -g ~ | tail -1 | awk '{print $4}')
[ "$frei" -lt 8 ] && { echo "ABBRUCH: nur $frei GB frei."; exit 3; }
[ -n "$(git -C "$wurzel" status --porcelain)" ] && { echo "ABBRUCH: Arbeitskopie nicht sauber."; exit 4; }
while pgrep -x xcodebuild >/dev/null 2>&1; do sleep 15; done
[ -e "$alt" ] && { echo "ABBRUCH: $alt gibt es schon."; exit 5; }
git -C "$wurzel" worktree add --detach "$alt" "$basis" >/dev/null 2>&1 || { echo "ABBRUCH: Worktree nicht möglich."; exit 6; }
neuCommit=$(git -C "$wurzel" rev-parse --short HEAD)
mkdir -p "$bau" "$ziel/alt" "$ziel/neu"; rm -f "$ziel"/alt/*.png(N) "$ziel"/neu/*.png(N)
vorbereiten() {  # $1 = Baum
  local t="$1" pk="$1/Test/WidgetVergleich"
  mkdir -p "$pk/Tests" "$pk/Sources/WidgetKopie"
  if [ "$t" != "$wurzel" ]; then
    cp "$wurzel/Test/WidgetVergleich/Package.swift" "$pk/Package.swift"; rm -rf "$pk/Tests/WidgetVergleichTests"; cp -R "$wurzel/Test/WidgetVergleich/Tests/WidgetVergleichTests" "$pk/Tests/"; rm -f "$pk"/Tests/WidgetVergleichTests/*Neu.swift(N)   # Tinte und Salon gibt es im alten Stand nicht
    cp "$wurzel/Test/WidgetVergleich/Sources/WidgetKopie/Stub.swift" "$pk/Sources/WidgetKopie/Stub.swift"
  fi
  rm -f "$pk"/Sources/WidgetKopie/Partie*.swift(N) "$pk"/Sources/WidgetKopie/WidgetAnsichten.swift(N)
  python3 - "$t" <<'PY'
import sys, re
from pathlib import Path
t = Path(sys.argv[1]); ziel = t / "Test/WidgetVergleich/Sources/WidgetKopie"
for q in ["Widget/PartieWidget.swift", "Widget/PartieAktivitaetWidget.swift"] + sorted(str(p.relative_to(t)) for p in (t / "Widget/Geteilt").glob("*.swift")):
    s = (t / q).read_text()
    if q.endswith("PartieWidget.swift"):
        s = re.sub(r"@main\nstruct PartieWidgetBundle: WidgetBundle \{.*?\n\}\n", "", s, flags=re.S)
        s = s.replace("        if #available(iOS 16.2, *) { PartieAktivitaetWidget() }", "")
    # ActivityKit gibt es unter Mac Catalyst nicht: nur die Sperrbildschirm-Ansicht bleibt (ohne Widget-Konfiguration und Dynamic Island)
    s = s.replace("import ActivityKit\n", "").replace("struct PartieAktivitaet: ActivityAttributes {", "struct PartieAktivitaet {")
    if q.endswith("PartieAktivitaetWidget.swift"):
        s = re.sub(r"struct PartieAktivitaetWidget: Widget \{.*?\n\}\n(?=\n/// „Anna ist dran)", "", s, flags=re.S)
    s = s.replace(".containerBackground(for: .widget) {", ".background {")
    s = s.replace("\\.widgetFamily", "\\.testFamilie")
    s = s.replace("private struct SperrbildschirmAnsicht", "struct SperrbildschirmAnsicht")
    (ziel / Path(q).name).write_text(s)
PY
}
lauf() {  # $1 = alt|neu, $2 = Baum
  vorbereiten "$2"
  ( cd "$2/Test/WidgetVergleich" && TEST_RUNNER_KLAR_ZIEL="$ziel/$1" xcodebuild test -scheme WidgetVergleich -only-testing:WidgetVergleichTests -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath "$bau/wv-$1" CODE_SIGNING_ALLOWED=NO > "$bau/wv-$1.log" 2>&1 )
  echo "== $1: $(grep -E 'Executed [0-9]+ test|\*\* TEST' "$bau/wv-$1.log" | tail -1 | cut -c1-120) $(grep -E '\.swift:[0-9]+:[0-9]*:? error' "$bau/wv-$1.log" | head -3 | cut -c1-240)"
  rm -rf "$bau/wv-$1"
}
lauf alt "$alt"
lauf neu "$wurzel"
git -C "$wurzel" worktree remove --force "$alt"
git -C "$wurzel" checkout -q -- . 2>/dev/null; git -C "$wurzel" clean -q -fd Test/WidgetVergleich/Sources 2>/dev/null
erg=$(python3 "$wurzel/Werkzeug/designwechsel_klar_vergleich.py" "$ziel" 2>&1 | tail -3)
echo "$erg"
echo "$(date '+%d.%m.%Y %H:%M') · $titel · alt $basis, neu $neuCommit · $(echo "$erg" | tail -1)" >> "$wurzel/Doku/DESIGNWECHSEL-KLAR-VERGLEICH.txt"
