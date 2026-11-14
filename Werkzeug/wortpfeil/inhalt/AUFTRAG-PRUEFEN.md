# Auftrag: Stapel prüfen (für Claude-Prüfaufträge, unabhängig vom Schreiber)

Du prüfst Fragen eines deutschen Kreuzworträtsels (Schwedenrätsel) für eine App – wie ein Redakteur einer
Rätselzeitschrift, kritisch, Zeile für Zeile. Eigenes Wissen, kein Internet.

Lies `Referenz/inhalt/stapel/<datei>` (Wort <TAB> Stufe <TAB> Fragen mit `|`). Verben dürfen klein sein.

Prüfe je Wort:
1. Schreibweise, Grundform; passend (keine Marken, Schimpfwörter, Anstößiges, lebenden Personen)?
2. Jede Frage sachlich richtig (Fachangaben genau prüfen), grammatisch korrekt, dauerhaft gültig?
3. Mit Buchstabenzahl eindeutig genug? Passt ein naheliegenderes Wort gleicher Länge → Problem. Gegenseitige Verweise sind schwach.
4. Knapp (≤ 30, besser ≤ 20 Zeichen), Rätselheft-Ton, kein Artikel am Anfang?
5. Steckt das Lösungswort in der Frage – auch versteckt in einem längeren Wort (ab 4 Buchstaben: schon die ersten 4)? Verboten.
6. Stufe passend? 1 = 12-jähriges Kind · 2 = Allgemeinwissen · 3 = selten/typisches Rätselwort.

Ergebnis nach `Referenz/inhalt/pruefung/<gleicher Dateiname>`, **eine Zeile für jedes Wort**, erste Zeile
`# Prüfung <NNN> – unabhängiger Prüfdurchgang`, TAB-getrennt:
`Wort <TAB> Urteil <TAB> neue Fragen <TAB> Grund <TAB> neue Stufe`
- `ok`: Spalten 3+4 leer · `aendern`: Spalte 3 = KOMPLETTER neuer Fragensatz (1–3 mit `|`), Spalte 4 = Grund ·
  `streichen`: Spalte 4 = Grund (nur wenn nicht zu retten oder unpassend) · Spalte 5 nur bei falscher Stufe (1–3).

Dann: Stapeldatei mit deinen Änderungen als Testdatei in den Scratchpad-Ordner aus dem Auftrag schreiben und im Ordner
`Referenz/` `python3 inhalt.py pruefen <testdatei>` → 0 FEHLER. Stapeldatei nicht ändern, kein git.
Bei ENOSPC ein paar Minuten warten, dann erneut.

Antwort am Ende kurz: Anzahl ok/geändert/gestrichen, häufigste Probleme, Note 1–6.
