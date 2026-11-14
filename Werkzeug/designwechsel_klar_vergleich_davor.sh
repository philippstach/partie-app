#!/bin/zsh
# Designwechsel: Klar-Vergleich „Commit davor gegen jetzt“ für selbst gezeichnete Karten (und später Würfel) der Spiele.
# Alt = Commit $1 in einem Hilfs-Worktree Partie/DesignWechsel/_Vergleich-alt (wird danach wieder entfernt), neu = diese Arbeitskopie (muss sauber sein).
# Beide Seiten zeichnen dieselben Szenen in „Klar & Glas“ (hell, dunkel) aus den Tests KlarKartenTests der Spielpakete und
# vergleichen sie Punkt für Punkt (designwechsel_klar_vergleich.py). Ergebnis wird an Doku/DESIGNWECHSEL-KLAR-VERGLEICH.txt angehängt.
# Aufruf im Projektordner: Werkzeug/designwechsel_klar_vergleich_davor.sh <Commit davor> [Bezeichnung]   z. B. … 1b4d856c "D2 Karten"
# Kein Simulator (Mac Catalyst), immer nur ein Build gleichzeitig, Bau-Ordner ../.bau.
set -u
wurzel=${0:A:h:h}
basis=${1:?Commit davor}
titel=${2:-$basis}
bau=${wurzel:h}/.bau
alt=${wurzel:h}/_Vergleich-alt
ziel=${wurzel:h}/Bilder/klar-vergleich-davor
# Paket:Testziel:Testklasse. Mit NUR="SpielYacht Spiel10k" lassen sich Pakete auswählen (spart Bauzeit und Platz).
alle=(SpielSolitaer:SpielSolitaerTests:KlarKartenTests SpielRomme:RommeKartenBilderTests:KlarKartenTests SpielMogeln:MogelnKartenBilderTests:KlarKartenTests SpielHerzensjagd:HerzensjagdKartenBilderTests:KlarKartenTests
      SpielSudoku:SpielSudokuTests:KlarFeldTests SpielYacht:SpielYachtTests:KlarWuerfelTests Spiel10k:Spiel10kTests:KlarWuerfelTests SpielSchocken:SpielSchockenTests:KlarWuerfelTests SpielViererreihe:SpielViererreiheTests:KlarSpielTests
      SpielKakuro:KakuroKlarTests:KlarSpielTests SpielIrrgang:IrrgangKlarTests:KlarSpielTests SpielMuehle:MuehleKlarTests:KlarSpielTests SpielGalgenmaennchen:SpielGalgenmaennchenTests:KlarTastaturTests SpielWortpfeil:WortpfeilKlarTests:KlarSpielTests SpielElferRaus:SpielElferRausTests:KlarSpielTests)
pakete=()
for pt in $alle; do p=${pt%%:*}; if [ -z "${NUR:-}" ] || [[ " ${NUR} " == *" $p "* ]]; then pakete+=($pt); fi; done
frei=$(df -g ~ | tail -1 | awk '{print $4}')
if [ "$frei" -lt 8 ]; then echo "ABBRUCH: nur $frei GB frei."; exit 3; fi
if [ -n "$(git -C "$wurzel" status --porcelain)" ]; then echo "ABBRUCH: Arbeitskopie nicht sauber (erst committen)."; exit 4; fi
gewartet=0
while pgrep -x xcodebuild >/dev/null 2>&1; do
  if [ $gewartet -ge ${WARTEN:-1500} ]; then echo "Hinweis: anderer Build läuft noch; starte trotzdem."; break; fi
  sleep 15; gewartet=$((gewartet + 15))
done
neuCommit=$(git -C "$wurzel" rev-parse --short HEAD)

# Alter Stand als Hilfs-Worktree innerhalb von Partie/DesignWechsel (gleiche Paketpfade wie die Arbeitskopie)
[ -e "$alt" ] && { echo "ABBRUCH: $alt gibt es schon."; exit 5; }
git -C "$wurzel" worktree add --detach "$alt" "$basis" >/dev/null 2>&1 || { echo "ABBRUCH: Worktree für $basis nicht möglich."; exit 6; }
# Die Vergleichstests (und die dafür nötigen Manifeste) stehen erst im neuen Stand; sie kommen in den alten Baum.
for pt in $pakete; do
  p=${pt%%:*}; t=${${pt#*:}%%:*}; k=${pt##*:}
  if [ ! -d "$alt/Pakete/$p/Tests/$t" ] && [ -d "$wurzel/Pakete/$p/Tests/$t" ]; then   # eigenes Testziel, das es im alten Stand noch nicht gibt: Manifest und Tests kommen mit
    cp "$wurzel/Pakete/$p/Package.swift" "$alt/Pakete/$p/Package.swift"; cp -R "$wurzel/Pakete/$p/Tests/$t" "$alt/Pakete/$p/Tests/"
  else mkdir -p "$alt/Pakete/$p/Tests/$t"; cp "$wurzel/Pakete/$p/Tests/$t/$k.swift" "$alt/Pakete/$p/Tests/$t/"; fi
done
# RBild ist im alten Stand noch privat: für den Test sichtbar machen (nur im Hilfs-Worktree)
sed -i '' 's/^private struct RBild/struct RBild/' "$alt/Pakete/SpielRomme/Sources/SpielRomme/Romme.swift"

mkdir -p "$bau" "$ziel/alt" "$ziel/neu"; rm -f "$ziel"/alt/*.png(N) "$ziel"/neu/*.png(N)
lauf() {  # $1 = alt|neu, $2 = Wurzel des Baums
  for pt in $pakete; do
    p=${pt%%:*}; t=${${pt#*:}%%:*}; k=${pt##*:}
    ( cd "$2/Pakete/$p" && TEST_RUNNER_KLAR_ZIEL="$ziel/$1" xcodebuild test -scheme ${${p:#Spiel10k}:-Spiel10k-Package} -only-testing:$t/$k \
        -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath "$bau/davor/$1-$p" CODE_SIGNING_ALLOWED=NO > "$bau/davor-$1-$p.log" 2>&1 )
    echo "== $1 $p: $(grep -E 'Executed [0-9]+ test|\*\* TEST' "$bau/davor-$1-$p.log" | tail -1 | cut -c1-120) $(grep -E '\.swift:[0-9]+:[0-9]*:? error' "$bau/davor-$1-$p.log" | head -2 | cut -c1-200)"
    rm -rf "$bau/davor/$1-$p"
  done
}
lauf alt "$alt"
lauf neu "$wurzel"
git -C "$wurzel" worktree remove --force "$alt"
erg=$(python3 "$wurzel/Werkzeug/designwechsel_klar_vergleich.py" "$ziel" 2>&1 | tail -3)
echo "$erg"
{ echo "$(date '+%d.%m.%Y %H:%M') · $titel · alt $basis, neu $neuCommit · $(echo "$erg" | tail -1)"; } >> "$wurzel/Doku/DESIGNWECHSEL-KLAR-VERGLEICH.txt"
