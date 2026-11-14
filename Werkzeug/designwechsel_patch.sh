#!/bin/zsh
# Designwechsel: schreibt den Patch des Baukastens nach Doku/Patches.
#  - klarglas-2.18-designwechsel.patch ist EINGEFROREN (Stand Commit 2c5e0274; der Integrator spielt ihn laufend ein). Dieses Skript prüft nur,
#    dass er auf _Baukasten-2.17-Vergleich noch genau _Baukasten-2.18-Vergleich ergibt, und schreibt ihn nie neu.
#  - klarglas-2.19-designwechsel.patch: alle weiteren Änderungen der Arbeitskopie gegen _Baukasten-2.18-Vergleich (setzt auf 2.18 auf).
#    Gibt es keine, entsteht keine Datei.
# Der gemeinsame Baukasten (Partie/_Gemeinsam/Baukasten) wird nicht angefasst.
# Aufruf im Projektordner: Werkzeug/designwechsel_patch.sh
set -u
wurzel=${0:A:h:h}
cd "${wurzel:h}" || exit 1
ausschluss=(-x .build -x .swiftpm -x '*.orig' -x .DS_Store)
# 1) eingefrorener Patch 2.18: Probe
p218="$wurzel/Doku/Patches/klarglas-2.18-designwechsel.patch"
probe=$(mktemp -d); cp -R _Baukasten-2.17-Vergleich "$probe/b"
(cd "$probe/b" && patch -p1 -s < "$p218") && diff -rq $ausschluss "$probe/b" _Baukasten-2.18-Vergleich >/dev/null && echo "2.18 (eingefroren): Patch auf 2.17 ergibt genau _Baukasten-2.18-Vergleich." || echo "FEHLER: Patch 2.18 passt nicht mehr zu _Baukasten-2.18-Vergleich"
rm -rf "$probe"
# 2) Patch 2.19 gegen den Stand 2.18
ziel="$wurzel/Doku/Patches/klarglas-2.19-designwechsel.patch"
diff -ruN $ausschluss _Baukasten-2.18-Vergleich _Gemeinsam/Baukasten \
  | sed -e 's#^--- _Baukasten-2.18-Vergleich/#--- a/#' -e 's#^+++ _Gemeinsam/Baukasten/#+++ b/#' \
        -e 's#^diff -ruN .* _Baukasten-2.18-Vergleich/\(.*\) _Gemeinsam/Baukasten/.*#diff -ruN a/\1 b/\1#' > "$ziel"
if [ ! -s "$ziel" ]; then rm -f "$ziel"; echo "2.19: keine Baukasten-Änderung seit 2.18, keine Patch-Datei."; exit 0; fi
echo "Patch 2.19: $ziel ($(grep -c '^diff -ruN' "$ziel") Dateien, $(wc -l < "$ziel" | tr -d ' ') Zeilen)"
probe=$(mktemp -d); cp -R _Baukasten-2.18-Vergleich "$probe/b"
(cd "$probe/b" && patch -p1 -s < "$ziel") && diff -rq $ausschluss "$probe/b" _Gemeinsam/Baukasten && echo "Probe: Patch 2.19 auf 2.18 ergibt genau die Arbeitskopie."
rm -rf "$probe"
# 3) Patch 2.21 (Voreinstellung, Auswahl öffentlich): gegen den Stand 2.20 (= 2.18 + Patch 2.19 + Patch 2.20, als _Baukasten-2.20-Vergleich)
#    Neu schreiben: cd .. ; diff -ruN _Baukasten-2.20-Vergleich _Gemeinsam/Baukasten mit denselben Ersetzungen wie oben.
