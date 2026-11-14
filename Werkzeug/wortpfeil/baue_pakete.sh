#!/bin/bash
# Erzeugt alle fünf Rätselpakete neu (dauert etwa eine Stunde, „schwer“ am längsten) und wählt danach die Fragen.
# Aufruf im Ordner Werkzeug/wortpfeil:  ./baue_pakete.sh
set -e
cd "$(dirname "$0")"
python3 bestand.py
python3 inhalt.py pruefen inhalt/woerter.tsv | tail -1
mkdir -p /tmp/wortpfeil-log
for p in leicht mittel schwer taeglich; do
  nice -n 10 python3 paket.py --woerter inhalt/woerter.tsv --nur $p > /tmp/wortpfeil-log/$p.log 2>&1 &
done
nice -n 10 python3 paket.py --woerter inhalt/woerter.tsv --themen > /tmp/wortpfeil-log/themen.log 2>&1 &
wait
tail -qn 1 /tmp/wortpfeil-log/*.log
nice -n 10 python3 nachbearbeitung.py
nice -n 10 python3 eindeutig.py
python3 pruefe_pakete.py
