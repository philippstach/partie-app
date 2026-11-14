# Auftrag: Stapel schreiben (für Claude-Schreibaufträge)

Du schreibst Inhalte für ein deutsches Kreuzworträtsel (Schwedenrätsel) in einer App. Die Rechte sollen bei uns liegen:
**Schreib alles selbst**, übernimm nichts aus Rätselheften, Rätsel-Webseiten, Wiktionary o. Ä., recherchiere nicht im Internet.

Datei: `Referenz/inhalt/stapel/<NNN>-<thema>.tsv` (Name steht im Auftrag), mindestens ca. 220 Wörter zum Thema aus `inhalt/THEMEN.md` – mehr ist gut, gute Wörter nie nur wegen der Zahl streichen.
Bevor du anfängst: Lies `Referenz/inhalt/woerter.tsv` (schon vorhandener Bestand) und alle Dateien in `inhalt/stapel/`
und nimm **keine Wörter, die dort schon stehen**.

Format: UTF-8, eine Zeile je Wort, TAB-getrennt: `Wort <TAB> Stufe <TAB> Frage|Frage|Frage`.
Erste Zeile Kommentar: `# <NNN> <Thema> – geschrieben von Claude`.

Wörter:
- Grundform, normale Schreibweise mit Umlauten (Verben klein im Infinitiv). Ein Wort, ohne Leerzeichen/Bindestrich,
  2–14 Buchstaben nach Umwandlung Ä→AE, Ö→OE, Ü→UE, ß→SS.
- Stufe 1 = kennt jedes 12-jährige Kind · 2 = Allgemeinwissen · 3 = selten oder typisches Rätselwort.
- Keine Längenquote (der Bestand hat genug kurze Wörter). Nimm alle guten Wörter zum Thema, kurz wie lang; nie mit
  Wörtern auffüllen, die selbst Rätselfreunde nicht kennen.
- Nicht: Marken/Firmen, lebende oder kürzlich verstorbene Personen, Schimpfwörter, Wertendes, Zeitabhängiges.

Fragen:
- 1–3 je Wort, je höchstens 30 Zeichen (besser ≤ 20), Rätselheft-Ton: knapp, ohne Artikel am Anfang.
- Lösungswort und seine ersten 4 Buchstaben kommen in der Frage nicht vor – auch nicht versteckt in einem längeren Wort.
- Sachlich und grammatisch richtig, dauerhaft gültig.
- Mit der Buchstabenzahl eindeutig genug: Passt ein naheliegenderes Wort gleicher Länge, die Frage schärfen
  („Kernobst“ passt auf APFEL und BIRNE → „Kernobst, oft als Schnaps“). Keine gegenseitigen Verweise (A=„B“, B=„A“).
- Mehrere Fragen eines Wortes zeigen verschiedene Blickwinkel.

Zum Schluss im Ordner `Referenz/`: `python3 inhalt.py pruefen inhalt/stapel/<datei>` – alle FEHLER beheben. Hinweise zu
korrekten seltenen oder zusammengesetzten Wörtern dürfen bleiben. Keine anderen Dateien ändern, kein git.
Hilfsdateien nur mit deiner Stapelnummer im Namen (z. B. `scratch-<NNN>-…`), andere Aufträge laufen parallel.
Bei ENOSPC (Platte voll) ein paar Minuten warten, dann erneut versuchen.

Antwort am Ende kurz: Zahl der Wörter, Verteilung nach Stufe und Länge, Wörter, bei denen du unsicher bist.
