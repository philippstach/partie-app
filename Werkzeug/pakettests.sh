#!/bin/zsh
# swift test (Mac, ohne Simulator) für jedes Paket mit Tests; Ergebnis in ${TMPDIR:-/tmp}/partie/pakettests.txt
: > ${TMPDIR:-/tmp}/partie/pakettests.txt
for p in Pakete/*/; do
  [ -d "$p/Tests" ] || continue
  r=$(cd $p && swift test --scratch-path ${TMPDIR:-/tmp}/partie/pt 2>&1 | grep -E "Executed [0-9]+ tests|error:|Test run with|Suite .* (passed|failed)|✘" | tail -2 | tr '\n' ' ')
  echo "$(basename $p): ${r:-keine Ausgabe}" >> ${TMPDIR:-/tmp}/partie/pakettests.txt
done
echo FERTIG >> ${TMPDIR:-/tmp}/partie/pakettests.txt
