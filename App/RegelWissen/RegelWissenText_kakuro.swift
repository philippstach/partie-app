// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/kakuro.md. Nicht von Hand ändern.
enum RegelWissenText_kakuro {
    static let quelle = #"""
## Ziel und Aufbau
Stichwörter: Kakuro-Regeln, Summenrätsel, Zahlenkreuzworträtsel, Hinweisfeld, Summe, Lauf, dunkles Feld, weiße Felder
Kakuro ist ein Zahlen-Kreuzworträtsel. Du trägst in die weißen Felder Ziffern von 1 bis 9 ein. Die dunklen Felder sind Hinweisfelder. Die Zahl oben rechts in einem dunklen Feld ist die Summe aller weißen Felder rechts davon bis zum nächsten dunklen Feld. Die Zahl unten links ist die Summe der weißen Felder darunter. Eine solche Reihe heißt Lauf. In jedem Lauf darf keine Ziffer doppelt vorkommen. Du gewinnst, wenn jeder Lauf voll ist, keine Ziffer doppelt hat und die Summe stimmt. Die erste Zeile und die erste Spalte des Gitters sind immer Hinweisfelder; ein 5 × 5-Gitter hat also höchstens 4 × 4 weiße Felder. Jedes Rätsel hat genau eine Lösung.

## Bedienung
Stichwörter: Ziffer eintragen, antippen, löschen, rückgängig, Zeit, möglich, Kandidaten, Zug zurück
Tippe ein weißes Feld an, dann unten die Ziffer 1 bis 9. Eine Ziffer ersetzt die vorige. Dieselbe Ziffer noch einmal tippen löscht nicht; dafür gibt es die Löschtaste. „Zug zurück“ nimmt den letzten Eintrag zurück (auch im Menü „Mehr“ als „Rückgängig“). Unter dem Ziffernblock steht „Möglich: …“ für das gewählte Feld. Die App rechnet aus, welche Ziffern nach den Summen und den schon stehenden Ziffern beider Läufe noch passen. Passt keine mehr, steht dort, dass du die anderen Felder prüfen sollst. Die Zeit läuft ab Spielbeginn und ruht, wenn die App im Hintergrund ist.

## Rot, Prüfen und Tipp
Stichwörter: rot, falsch, Fehler, kontrollieren, Hilfe, Hinweis, verraten, doppelt, Summe zu groß
Rot werden Ziffern, wenn in einem Lauf eine Ziffer doppelt steht oder die Summe der eingetragenen Ziffern größer ist als die Hinweiszahl. Eine zu kleine Summe wird nicht rot, solange der Lauf nicht fertig ist. „Prüfen“ vergleicht mit der Lösung und markiert falsche Felder rot; es meldet „Bisher alles richtig.“ oder „Falsche Felder: N“. Eine Ziffer kann also alle Regeln einhalten und trotzdem falsch sein. „Tipp“ trägt in das gewählte Feld die richtige Ziffer ein, sonst in ein zufälliges leeres oder falsches Feld, und zählt als Tipp. Es gibt keine Strafzeit und kein Fehlerlimit. Mit Tipp zählt der Sieg nicht für die Freischaltung und nicht als Bestzeit.

## Feste Ziffern (Vorgaben)
Stichwörter: vorgegeben, schon eingetragen, nicht änderbar, gesperrt, Givens, Starthilfe
Damit ein Rätsel genau eine Lösung hat, stehen in manchen weißen Feldern schon Ziffern, die die App vorgibt. Diese Vorgaben lassen sich nicht ändern oder löschen. Wie viele es sind, hängt vom Rätsel ab; die App versucht, möglichst wenige vorzugeben. Du erkennst sie nicht an einer eigenen Farbe: Sie stehen einfach von Anfang an im Feld. Tippst du ein solches Feld an und dann eine Ziffer, passiert nichts. Sie zählen in den Summen wie jede andere Ziffer mit. „Prüfen“ markiert sie nie als falsch, und der „Tipp“ greift sie nie an.

## Größen, Tagesrätsel, Freischalten
Stichwörter: Größe, 5x5, 6x6, 7x7, Schwierigkeit, gesperrt, Schloss, täglich, Tagesaufgabe, neue Partie, Menü
Es gibt drei Größen: 5 × 5, 6 × 6 und 7 × 7 (jeweils mit der Hinweiszeile und -spalte). Du wählst sie auf der Spielseite vor dem Start (dort auch „Tagesrätsel“ oder „Neues Rätsel“) oder im Spiel im Menü „Mehr“ unter „Größe“; die Wahl im Menü startet sofort ein neues Rätsel. Ohne Siege beginnt das Spiel mit 5 × 5. 6 × 6 öffnet sich nach 3 Siegen ohne Tipp auf 5 × 5, 7 × 7 nach 3 Siegen ohne Tipp auf 6 × 6. Im Kindermodus oder mit „Alle Stufen offen“ ist nichts gesperrt. Gesperrte Größen zeigen ein Schloss. Das „Tagesrätsel“ im Menü gibt in der gewählten Größe ein Rätsel, das für alle am selben Tag gleich ist. Tagesrätsel zählen nicht für die Freischaltung. Es gibt für Kakuro keine Tagesserie. „Neue Partie“, „Tagesrätsel“ und ein Größenwechsel im Menü ersetzen das Rätsel. Hast du schon etwas eingetragen oder einen Tipp genutzt, fragt die App vorher „Aktuelle Partie abbrechen?“.

## Bestzeit und Beispiele
Stichwörter: Rekord, schnellste Zeit, Beispiel, Summe 7, Kombinationen, welche Ziffern
Die Bestzeit wird je Größe gespeichert, nur bei Siegen ohne Tipp. Das Tagesrätsel hat eine eigene Bestzeit je Tag. Im Menü steht „Bestzeit: N s“. Beispiel Lauf: Ein Hinweis 7 über zwei Feldern lässt 1 + 6, 2 + 5 oder 3 + 4 zu. Ein Hinweis 8 über zwei Feldern lässt 1 + 7, 2 + 6 oder 3 + 5 zu; 4 + 4 ist verboten, weil die Ziffer doppelt wäre, und wird rot. Ein Hinweis 3 über zwei Feldern geht nur mit 1 und 2. Ein Hinweis 16 über zwei Feldern geht nur mit 7 + 9. Ein Hinweis 6 über drei Feldern geht nur mit 1, 2 und 3 in beliebiger Reihenfolge.

## Was die App anders macht als die übliche Regel
Stichwörter: Unterschied, Besonderheit, anders als normal, Begriffe, Umgangssprache
Üblich sind Kakuros ohne vorgegebene Ziffern. Diese App gibt bei Bedarf einzelne Ziffern vor und macht so jedes Rätsel eindeutig. Es gibt Kandidatenanzeige („Möglich: …“), Tipp und Prüfen, aber keine Notizen im Feld und keine Fehlergrenze. Die Gitter sind zufällig erzeugt, quadratisch und in drei Größen. Die Größen werden freigeschaltet, wie bei Sudoku und Minensuche, durch Siege ohne Tipp. Ein Tagesrätsel gibt es, aber ohne Serie und ohne Karte auf der Startseite. Begriffe: Lauf = Summenreihe, Hinweisfeld = Summenfeld, Block = dunkles Feld. Die Hinweiszahl oben rechts gilt waagrecht, unten links senkrecht.
"""#
}
