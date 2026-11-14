#!/bin/zsh
# Paket-Tests ohne Simulator über „Mac Catalyst“ (UIKit-Code läuft so auf dem Mac).
# Aufruf: Werkzeug/catalyst-tests.sh Spiel10k|SpielSudoku|SpielViererreihe|SpielMinensuche
# Kein Eintrag nötig für Daten: PARTIE_PARTIEN zeigt auf App/Ressourcen/Daten (JSON-Inhalte, die sonst im App-Bundle liegen).
set -e
wurzel=${0:A:h:h}
p=$1
schema=$p; [ "$p" = Spiel10k ] && schema=Spiel10k-Package
cd "$wurzel/Pakete/$p"
TEST_RUNNER_PARTIE_PARTIEN="$wurzel/App/Ressourcen/Daten" xcodebuild test -scheme $schema \
  -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath ${TMPDIR:-/tmp}/partie-bau-$p-cat 2>&1 \
  | grep -E "✘|Fatal error|error:.*swift|TEST |Test run with"
rm -rf ${TMPDIR:-/tmp}/partie-bau-$p-cat
