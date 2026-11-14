#!/bin/bash
# Baut messen/fragefeld_messen.swift zusammen mit der Satzlogik der App (ClueMeasure.swift, ohne die Paket-Importe)
# und liest/schreibt über stdin/stdout:  messen/fragefeld_messen.sh < ein.tsv > aus.tsv
set -e
HIER="$(cd "$(dirname "$0")" && pwd)"
BAU="${TMPDIR:-/tmp}/wortpfeil-messen"
BIN="$BAU/fragefeld_messen"
QUELLE="$HIER/../../../Pakete/SpielWortpfeil/Sources/SpielWortpfeil/Model/ClueMeasure.swift"
if [ ! -x "$BIN" ] || [ "$HIER/fragefeld_messen.swift" -nt "$BIN" ] || [ "$QUELLE" -nt "$BIN" ]; then
  mkdir -p "$BAU"
  grep -v -E '^import (KlarGlas|SpieleKern)$' "$QUELLE" > "$BAU/ClueMeasure.swift"
  nice -n 10 swiftc -O -parse-as-library "$HIER/fragefeld_messen.swift" "$BAU/ClueMeasure.swift" -o "$BIN"
fi
exec nice -n 10 "$BIN"
