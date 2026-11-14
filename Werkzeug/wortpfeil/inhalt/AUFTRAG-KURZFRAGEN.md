# Auftrag: Kurzfragen schreiben (für Claude-Schreibaufträge)

Ein deutsches Schwedenrätsel auf dem iPhone: Die Frage steht **im Kästchen** des Gitters. Oft teilen sich zwei Fragen ein
Kästchen – dann ist nur Platz für ca. 2 kurze Zeilen à 8–9 Buchstaben. Für die Wörter in deiner Liste gibt es bisher nur Fragen,
die dafür zu lang sind. Du schreibst je Wort **eine neue, kurze Frage**. Alles selbst, kein Internet, nichts abschreiben.

Eingabe: `Referenz/inhalt/kurz/liste-<NN>.tsv` (Wort <TAB> Stufe <TAB> bisherige Fragen).
Ausgabe: `Referenz/inhalt/stapel/K<NN>-kurzfragen.tsv` – erste Zeile `# K<NN> Kurzfragen – geschrieben von Claude`,
dann je Wort eine Zeile: `Wort <TAB> Stufe <TAB> Kurzfrage` (Wort und Stufe **genau** wie in der Liste übernehmen).
Schreib die Datei früh und in Teilen (Abbrüche kommen vor).

Regeln für die Kurzfrage:
- **höchstens 16 Zeichen** insgesamt, **kein einzelnes Wort länger als 9 Buchstaben** (Umlaute zählen als 1).
- Rätselheft-Ton, knapp, ohne Artikel am Anfang: „Fluss in Bayern“, „Wüstentier“, „Ital.: Liebe“, „Abk.: Kilometer“.
  Übliche Kürzel sind erlaubt: „ugs.“, „Abk.“, „franz.“, „engl.“, „lat.“, „griech.“, „ehem.“, „Hptst.“ (Hauptstadt).
- Muss **sachlich richtig** und mit der Buchstabenzahl **eindeutig genug** sein. Lieber ein anderer Blickwinkel als die bisherigen Fragen.
- Lösungswort und seine ersten 4 Buchstaben kommen nicht vor (auch nicht versteckt, auch nicht über Umlaut).
- Gibt es keine gute Kurzfrage (zu speziell), lass das Wort **weg** – lieber weglassen als eine schlechte Frage.

Zum Schluss im Ordner `Referenz/`: `python3 inhalt.py pruefen inhalt/stapel/K<NN>-kurzfragen.tsv` → alle FEHLER beheben.
Prüfe außerdem selbst per Skript: jede Frage ≤ 16 Zeichen, kein Wort > 9 Buchstaben. Keine anderen Dateien ändern, kein git.
Hilfsdateien nur mit `scratch-K<NN>` im Namen. Mit `nice -n 15` rechnen, falls du Skripte laufen lässt.

Antwort am Ende kurz: wie viele Wörter mit Kurzfrage, wie viele weggelassen, Beispiele für schwierige Fälle.
