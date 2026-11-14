// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/sudoku.md. Nicht von Hand ändern.
enum RegelWissenText_sudoku {
    static let quelle = #"""
## Ziel und Spielarten
Stichwörter: Sudoku-Regeln, Gitter, 9x9, 6x6, Diagonale, Kinderversion, Zahlenrätsel, Feld, Kästchen
Du füllst alle leeren Felder mit Zahlen. In jeder Zeile, jeder Spalte und jedem Kästchen darf jede Zahl nur einmal stehen. Klassisch ist 9×9 mit den Zahlen 1 bis 9 und 3×3-Kästchen. Kinder-Sudoku ist 6×6 mit den Zahlen 1 bis 6, die Kästchen sind 3 Felder breit und 2 Felder hoch. X-Sudoku ist 9×9 wie klassisch, aber auch die beiden langen Diagonalen enthalten jede Zahl von 1 bis 9 genau einmal. Jedes Rätsel hat genau eine Lösung. Die fest gedruckten Zahlen (Vorgaben) kannst du nicht ändern. Du gewinnst, wenn das ganze Gitter der Lösung entspricht. Verlieren gibt es nicht.

## Ablauf und Bedienung
Stichwörter: Zahl eintragen, antippen, Stift, Bleistift, Kandidaten, löschen, rückgängig, Zeit, Notizen
Tippe ein Feld an, dann unten die Zahl. Tippst du dieselbe Zahl noch einmal, verschwindet sie wieder. „Löschen“ leert das Feld, „Rückgängig“ nimmt Züge zurück, im Menü „Mehr“ gibt es „Wiederholen“. Im Notizmodus (Stift) trägst du kleine Merkzahlen ein, nur in leeren Feldern. „Notizen füllen“ im Menü trägt in alle leeren Felder alle noch möglichen Zahlen ein. Setzt du eine Zahl und „Notizen automatisch streichen“ ist an (Standard), verschwindet sie aus den Notizen aller Nachbarn in Zeile, Spalte, Kästchen (und Diagonale). Oben steht die Zeit (sie ruht im Hintergrund), dazu Chips für Fehler, Fortschritt in Prozent und Tipps.

## Fehler und Fehlerlimit
Stichwörter: falsch, Fehlversuch, drei Fehler, verlieren, Game over, Zähler, rot, zurück
Ein Fehler ist jede Zahl, die nicht der Lösung entspricht. Das gilt auch, wenn sie keine Regel verletzt. Jede falsche Zahl erhöht den Fehlerzähler um 1; Löschen und neu Eintragen derselben falschen Zahl zählt erneut. Rot markiert die App bei „Fehler sofort zeigen“ (Standard an) alle doppelten und alle falschen Zahlen, sonst nur doppelte. Beim dritten Fehler erscheint das Blatt „Drei Fehler“. „Zurücksetzen“ geht zum letzten Stand ohne falsche Zahl zurück und setzt den Zähler auf 0. „Weiterspielen“ behält alles; der Zähler läuft weiter (zum Beispiel 4 / 3) und das Blatt kommt nicht wieder. Im Lernweg zählen keine Fehler.

## Tipp
Stichwörter: Hilfe, Hinweis, Glühbirne, nächster Schritt, verraten, Lösung zeigen
„Tipp“ zeigt den nächsten Schritt. Gibt es eine falsche Zahl, zeigt der Tipp zuerst sie („Falsche Zahl“). Sonst erklärt er den nächsten Trick. Klassisch nennt er die Technik, zum Beispiel „Einzige Möglichkeit“ (im Feld passt nur eine Zahl) oder „Einzige Stelle“ (eine Zahl passt in der Zeile, Spalte oder dem Kästchen nur an eine Stelle). In Kinder- und X-Sudoku gibt es nur diese zwei Arten, die Diagonale zählt als Einheit; reicht das nicht mehr, heißt der Tipp „Knifflig“ und zeigt das Feld mit den wenigsten Möglichkeiten. „Eintragen“ setzt die richtige Zahl ins Feld, „Nur zeigen“ schließt das Blatt. „Eintragen“ streicht auch die Notizen der Nachbarn. Ein eingetragener Tipp zählt als Tipp, nicht als Fehler, und kostet keine Zeit. Mit Tipp zählt der Sieg nicht für Freischaltung und Bestzeit.

## Stufen und Techniken
Stichwörter: Schwierigkeit, leicht, mittel, schwer, Experte, Vorgaben, Givens, Tricks, wie viele Zahlen vorgegeben
Klassisch richtet sich die Stufe nach den nötigen Tricks. Leicht: nur einzelne Zahlen (Einzige Möglichkeit, Einzige Stelle), mindestens 36 bis 40 Vorgaben. Mittel: dazu Zeigendes Paar, Beanspruchte Linie, Nacktes Paar, Verstecktes Paar. Schwer: dazu Nacktes und Verstecktes Tripel und X-Wing. Experte: braucht mindestens eine Technik wie Schwertfisch, XY-Flügel oder Färben, ist aber ohne Raten lösbar. Kinder (6×6) und X-Sudoku kennen nur Leicht, Mittel, Schwer. Dort richtet sich die Stufe nach der Zahl der Vorgaben: Kinder 22, 18, 14; X-Sudoku 40, 33, 27. So weit entfernt die App Vorgaben; sonst bleiben mehr stehen. Beispiel: Klassisch Leicht hat 81 minus 36 = höchstens 45 leere Felder.

## Neues Rätsel, Tagesrätsel, Lernweg, Eigenes Rätsel
Stichwörter: täglich, Serie, Tagesrätsel, Übungen, Training, Zeitung, abtippen, Link, teilen, neues Spiel
Auf der Startseite wählst du Tagesrätsel, Neues Rätsel (Spielart und Stufe), Lernweg oder Eigenes Rätsel. Das Tagesrätsel ist klassisch, Stufe Mittel, für alle am selben Tag gleich. Gelöste Tage bilden eine Serie; ein einzelner verpasster Tag ist ein Ruhetag und bricht sie nicht, zwei verpasste Tage in Folge beenden sie. Der Lernweg hat 12 Techniken mit je 6 Übungen (Stufe 1: 2 Techniken, Stufe 2: 4, Stufe 3: 3, Stufe 4: 3). „Eigenes Rätsel“: Du wählst die Spielart, tippst die Zahlen ab, „Prüfen“ sagt, ob es genau eine Lösung gibt, doppelte Zahlen, keine Lösung oder mehr als eine Lösung; nur mit genau einer Lösung kannst du „Spielen“. „Rätsel per Link teilen“ schickt ein Rätsel, das der andere genauso bekommt.

## Stufen freischalten und Bestzeit
Stichwörter: gesperrt, Schloss, freischalten, Rekord, schnellste Zeit, Siege, Kindermodus
Stufen sind gesperrt: Mittel öffnet sich nach 3 Siegen ohne Tipp auf Leicht, Schwer nach 3 auf Mittel, Experte nach 3 auf Schwer. Die Siege zählen je Stufe, egal in welcher Spielart du sie holst. Tagesrätsel, Übungen und eigene Rätsel zählen dafür nicht. Im Kindermodus und mit dem Schalter „Alle Stufen offen“ ist nichts gesperrt. Die Bestzeit wird je Spielart und Stufe gespeichert, nur ohne Tipp, nicht für Tagesrätsel, Übungen, eigene Rätsel. Die Statistik je Stufe zählt nur klassisches 9×9.

## Begriffe und Beispiele
Stichwörter: Begriffe, Block, Box, Naked Single, Beispiel, Umgangssprache
Kästchen heißt auch Box oder Block. Vorgaben, Hinweise oder Givens sind die fest gedruckten Zahlen. Notizen heißen auch Kandidaten oder Bleistiftmarken. „Einzige Möglichkeit“ heißt auch Naked Single, „Einzige Stelle“ Hidden Single. Beispiel Fehler: Du setzt nacheinander drei falsche Zahlen. Der Chip zeigt 3 / 3 und das Blatt „Drei Fehler“ erscheint. Wählst du „Weiterspielen“ und machst noch einen Fehler, zeigt der Chip 4 / 3. Beispiel: 9×9 sind 81 Felder, bei 40 Vorgaben bleiben 41 leer; 6×6 sind 36 Felder, bei 22 Vorgaben bleiben 14 leer. Beispiel Stufe: Wer 3 Mal Leicht ohne Tipp gewinnt, kann Mittel wählen. Gewinnst du mit einem Tipp, zählt dieser Sieg nicht mit.

## Was die App anders macht als die übliche Regel
Stichwörter: Unterschied, Besonderheit, anders als normal, Hausregel
Die App zählt Fehler nach der Lösung, nicht nur nach Regelverstößen: Eine Zahl, die nirgends doppelt steht, aber nicht zur Lösung passt, ist trotzdem ein Fehler. Auch nach drei Fehlern geht das Spiel weiter; es gibt kein Verlieren. Notizen kann die App automatisch füllen und streichen. Der Tipp erklärt Techniken mit Namen und kann ein Feld eintragen. Das Tagesrätsel hat eine Serie mit einem erlaubten Ruhetag. Stufen sind gesperrt, bis du 3 Mal ohne Tipp gewonnen hast. Die Zeit läuft nur, solange die App offen ist.
"""#
}
