# Auftrag: Mini-Fragen schreiben (für geteilte Fragefelder)

Ein deutsches Schwedenrätsel auf dem iPhone. Oft teilen sich zwei Fragen ein winziges Kästchen (36 pt). Gemessen mit der App:
**Es passen nur ca. 8 Zeichen** (eine Zeile; bei Fragen nach unten manchmal 9). Für die Wörter deiner Liste schreibst du je
**eine Mini-Frage mit höchstens 8 Zeichen** (Leerzeichen und Punkte zählen mit). Alles selbst, kein Internet, nichts abschreiben.

Eingabe: `Referenz/inhalt/kurz/liste-M<NN>.tsv` (Wort <TAB> Stufe <TAB> bisherige Fragen).
Ausgabe: `Referenz/inhalt/stapel/M<NN>-minifragen.tsv` – erste Zeile `# M<NN> Mini-Fragen – geschrieben von Claude`,
dann je Wort: `Wort <TAB> Stufe <TAB> Mini-Frage` (Wort und Stufe **genau** wie in der Liste). Früh und in Teilen schreiben.

So sehen gute Mini-Fragen aus (wie in Rätselheften): „Tonsilbe“ (RE), „Fürwort“ (ER), „Edelgas“ (AR), „Ausruf“ (OH),
„Gewicht“ (KG? – lieber „Abk.: Kilo“), „Hühnerei“ geht nicht (Stamm EI), „Speise“ (MAHL), „Stadt/Ruhr“, „Fluss/Bay.“.
Kürzel sind ausdrücklich erlaubt: „Abk.:“, „frz.“, „engl.“, „lat.“, „ugs.“, „Hptst.“, Schrägstrich als „in/an“ („Fl./Bay.“).
- **≤ 8 Zeichen**, ein oder zwei kurze Wörter. Prüfe die Länge per Skript.
- Sachlich richtig. Weil die Mini-Frage sehr knapp ist, **darf sie vager sein** als normale Fragen (die volle Frage des Wortes
  steht beim Spielen zusätzlich in der Frageleiste) – sie darf aber nichts Falsches sagen.
- Lösungswort und seine ersten 4 Buchstaben kommen nicht vor (auch nicht über Umlaut).
- Keine lebenden Personen, Vereine, Marken, Herrscherfamilien, keine abwertenden Wörter.
- Gibt es keine vernünftige Mini-Frage, lass das Wort weg.

Zum Schluss im Ordner `Referenz/`: `nice -n 15 python3 inhalt.py pruefen inhalt/stapel/M<NN>-minifragen.tsv` → alle FEHLER beheben.
Keine anderen Dateien ändern, kein git, Hilfsdateien nur mit `scratch-M<NN>` im Namen.

Antwort am Ende kurz: Anzahl geschrieben/weggelassen, Beispiele, schwierige Fälle.
