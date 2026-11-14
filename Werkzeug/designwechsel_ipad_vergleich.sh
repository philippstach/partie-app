#!/bin/zsh
# Designwechsel iPad: Bildvergleich „Stand davor gegen jetzt“ der Seiten Sieger, Zwischenstand, Spiel-Startseite, Neues Spiel, Einführung, Start
# in drei Designs, hell und dunkel, in vier Größen (iPhone, iPad hoch, quer, Split View). Alt = Commit $1 in einem Hilfs-Worktree UND der Baukasten
# `_Baukasten-2.18-Vergleich` (der Baukasten liegt außerhalb von Git; für den alten Lauf wird er in MEINER Kopie Partie/DesignWechsel/_Gemeinsam/Baukasten
# vorübergehend ersetzt und danach zurückgelegt). Neu = diese Arbeitskopie (muss sauber sein). Kein Simulator (Mac Catalyst).
# Erwartung: klar in allen Größen gleich; Tinte und Salon in „iphone“ gleich (sonst Fehler); „split“ in Tinte und Salon gleich oder bewusst anders;
# Tinte und Salon in iPad-Größen dürfen sich ändern (werden aufgelistet). Ergebnis wird an Doku/DESIGNWECHSEL-KLAR-VERGLEICH.txt angehängt.
# Aufruf: Werkzeug/designwechsel_ipad_vergleich.sh <Commit davor> [Bezeichnung]
set -u
wurzel=${0:A:h:h}; pw=${wurzel:h}
basis=${1:?Commit davor}; titel=${2:-iPad $basis}
bau=$pw/.bau; alt=$pw/_Vergleich-alt; ziel=$pw/Bilder/ipad-vergleich
frei=$(df -g ~ | tail -1 | awk '{print $4}'); [ "$frei" -lt 8 ] && { echo "ABBRUCH: nur $frei GB frei."; exit 3; }
[ -n "$(git -C "$wurzel" status --porcelain)" ] && { echo "ABBRUCH: Arbeitskopie nicht sauber."; exit 4; }
while pgrep -x xcodebuild >/dev/null 2>&1; do sleep 15; done
[ -e "$alt" ] && { echo "ABBRUCH: $alt gibt es schon."; exit 5; }
[ -e "$pw/_Gemeinsam/Baukasten.neu" ] && { echo "ABBRUCH: _Gemeinsam/Baukasten.neu gibt es schon (früherer Lauf abgebrochen?)."; exit 7; }
git -C "$wurzel" worktree add --detach "$alt" "$basis" >/dev/null 2>&1 || { echo "ABBRUCH: Worktree nicht möglich."; exit 6; }
cp "$wurzel/Test/DesignBilder/Tests/DesignBilderTests/IPadVergleich.swift" "$alt/Test/DesignBilder/Tests/DesignBilderTests/IPadVergleich.swift"; cp "$wurzel/Test/DesignBilder/Package.swift" "$alt/Test/DesignBilder/Package.swift"; cp "$wurzel/Test/DesignBilder/Sources/DesignBilder/Aufnahme.swift" "$alt/Test/DesignBilder/Sources/DesignBilder/Aufnahme.swift"   # gleiche Abhängigkeiten wie im neuen Stand
mkdir -p "$bau" "$ziel/alt" "$ziel/neu"; rm -f "$ziel"/alt/*.png(N) "$ziel"/neu/*.png(N)
neuCommit=$(git -C "$wurzel" rev-parse --short HEAD)
lauf() {  # $1 = alt|neu, $2 = Baum
  ( cd "$2/Test/DesignBilder" && TEST_RUNNER_DESIGN_VERGLEICH="$ziel/$1" xcodebuild test -scheme DesignBilder -only-testing:DesignBilderTests/IPadVergleich \
      -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath "$bau/iv-$1" CODE_SIGNING_ALLOWED=NO > "$bau/iv-$1.log" 2>&1 )
  echo "== $1: $(grep -E 'Executed [0-9]+ test|\*\* TEST' "$bau/iv-$1.log" | tail -1 | cut -c1-120) $(grep -E '\.swift:[0-9]+:[0-9]*:? error' "$bau/iv-$1.log" | head -3 | cut -c1-240)"
  rm -rf "$bau/iv-$1"
}
wiederherstellen() { if [ -e "$pw/_Gemeinsam/Baukasten.neu" ]; then rm -rf "$pw/_Gemeinsam/Baukasten"; mv "$pw/_Gemeinsam/Baukasten.neu" "$pw/_Gemeinsam/Baukasten"; fi }
trap wiederherstellen EXIT INT TERM
mv "$pw/_Gemeinsam/Baukasten" "$pw/_Gemeinsam/Baukasten.neu" && cp -R "$pw/_Baukasten-2.18-Vergleich" "$pw/_Gemeinsam/Baukasten"
lauf alt "$alt"
wiederherstellen
lauf neu "$wurzel"
git -C "$wurzel" worktree remove --force "$alt"
python3 - "$ziel" <<'PY' | tee "$bau/ipad-vergleich.txt"
import sys
from pathlib import Path
from PIL import Image, ImageChops
z = Path(sys.argv[1]); gleich = {"klar": [0, 0], "iphone": [0, 0], "split": [0, 0]}; muss = []; darf = []
for a in sorted((z / "alt").glob("*.png")):
    n = a.name; b = z / "neu" / n
    if not b.exists(): muss.append(f"FEHLT neu: {n}"); continue
    ia, ib = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
    gl = ia.size == ib.size and ImageChops.difference(ia, ib).getbbox() is None
    design = n.split("-")[0]; groesse = n.rsplit("-", 1)[1].replace(".png", "") if not n.endswith("hoch.png") and not n.endswith("quer.png") else "-".join(n[:-4].split("-")[-2:])
    pflicht = design == "klar" or groesse == "iphone"
    if pflicht:
        gleich["klar" if design == "klar" else "iphone"][0 if gl else 1] += 1
        if not gl: muss.append(f"ANDERS (Pflicht gleich): {n}")
    else:
        (darf if not gl else []).append(n)
        if groesse == "split": gleich["split"][0 if gl else 1] += 1
neu = {p.name for p in (z / "neu").glob("*.png")} - {p.name for p in (z / "alt").glob("*.png")}
print(f"Pflicht gleich (klar alle Größen, Tinte/Salon iPhone): {sum(v[0] for k,v in gleich.items() if k!='split')} gleich, {len(muss)} Abweichungen")
for m in muss: print(" ", m)
print(f"Tinte/Salon iPad und Split: {len(darf)} Bilder anders (erwartet bei Umbau)")
print("alt/neu:", len(list((z/'alt').glob('*.png'))), len(list((z/'neu').glob('*.png'))))
PY
erg=$(head -1 "$bau/ipad-vergleich.txt")
echo "$(date '+%d.%m.%Y %H:%M') · $titel · alt $basis (Baukasten 2.18), neu $neuCommit · $erg" >> "$wurzel/Doku/DESIGNWECHSEL-KLAR-VERGLEICH.txt"
