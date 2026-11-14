# Wortpfeil: Wortbestand und Rätselpakete

Hier liegen der Wortbestand des Kreuzworträtsels (Spiel `SpielWortpfeil`) und die Werkzeuge, die daraus die
Rätselpakete in `Pakete/SpielWortpfeil/Shared/raetsel/` erzeugen. Alles läuft nur auf dem Mac, nichts davon ist Teil der App.

## Ziel des Bestands (Stand 11/2026)

Rund 10.000 bekannte, allgemein verständliche, familientaugliche deutsche Wörter mit 2 bis 8 Buchstaben
(längere Wörter sind im Bestand, werden vom Erzeuger aber nicht benutzt). Keine obskuren Abkürzungen,
Nebenflüsse, chemischen Zeichen oder Fachwörter. Stufe 1 = kennt ein 12-jähriges Kind, 2 = Allgemeinwissen,
3 = anspruchsvoller (nur im Paket „schwer“ und als Notnagel).

## Dateien

| Datei | Inhalt |
|---|---|
| `inhalt/woerter.tsv` | Der fertige Bestand: Wort, Stufe, Fragen (mit `|` getrennt). Wird erzeugt, nicht von Hand ändern. |
| `inhalt/alt/woerter-alt.tsv` | Alter Bestand von Oktober 2026 (8.069 Wörter) |
| `inhalt/auswahl/stufe3-behalten.txt` | Stufe-3-Wörter, die bleiben. Alle anderen Stufe-3-Wörter fallen weg. |
| `inhalt/auswahl/streichen.txt` | Weitere gestrichene Wörter |
| `inhalt/korrektur/*.tsv` | Ersetzt Stufe und alle Fragen eines vorhandenen Wortes |
| `inhalt/neu/*.txt` | Neue Wörter und zusätzliche Fragen: `Wort;Stufe;Frage|Frage` |
| `inhalt/stapel/` | Alte Themenstapel; legen fest, welche Wörter zu welchem Themenpaket gehören (`themen.py`) |

## Ablauf

```bash
cd Werkzeug/wortpfeil
python3 bestand.py                         # baut inhalt/woerter.tsv
python3 inhalt.py pruefen inhalt/woerter.tsv   # 0 FEHLER nötig (Lösung in der Frage, Überlänge …)
./baue_pakete.sh                           # alle fünf Pakete neu erzeugen, Fragen wählen, prüfen
```

`bestand.py` lässt Fragen automatisch weg, die den Wortstamm der Lösung enthalten oder länger als 30 Zeichen sind.
Neue Wörter vorher mit `python3 kandidaten.py < liste.txt` gegen den Bestand abgleichen.

## Regeln für Fragen

- Rätselheft-Ton, kein Artikel am Anfang, höchstens 30 Zeichen, sachlich richtig und dauerhaft gültig.
- Lösung und ihre ersten vier Buchstaben kommen in der Frage nicht vor.
- Mit der Buchstabenzahl eindeutig genug; immer die gängige Bedeutung des Wortes.
- Je Wort möglichst eine ausführliche Frage (Frageleiste) und eine kurze fürs Kästchen (höchstens 8 Zeichen
  passt immer, auch im geteilten Feld).
- Keine Marken, keine lebenden Personen, nichts Anstößiges.
