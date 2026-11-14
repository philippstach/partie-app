// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/schiebepuzzle.md. Nicht von Hand ändern.
enum RegelWissenText_schiebepuzzle {
    static let quelle = #"""
## Ziel
Stichwörter: 15er-Puzzle, Spielziel, Aufgabe, Reihenfolge, gewinnen, lösbar, Start, neues Brett
Das Brett hat n × n Felder, davon n² − 1 nummerierte Kacheln und eine Lücke. Standard ist 4 × 4 mit 15 Kacheln. Du schiebst die Kacheln, bis die Zahlen von 1 an der Reihe nach stehen: erste Zeile 1, 2, 3, 4, danach die nächsten, und die Lücke liegt unten rechts. Weniger Züge sind besser. Das Spiel ist für einen Spieler. Jedes Brett ist lösbar, denn es wird gemischt, indem die App aus der Lösung heraus zufällige gültige Schiebezüge ausführt. Größere Bretter werden länger gemischt. Das Brett startet nie schon gelöst.

## Ablauf und Zug
Stichwörter: antippen, tippen, verschieben, Kachel, Plättchen, Stein, Feld, Reihe, Spalte, Zug, diagonal, bewegen
Tippe eine Kachel an, die in derselben Zeile oder derselben Spalte wie die Lücke liegt. Sie rückt in die Lücke, und alle Kacheln zwischen ihr und der Lücke rücken mit. Das zählt als 1 Zug, egal wie viele Kacheln sich bewegen. Beispiel 3 × 3: Steht 1 2 3 / 4 5 6 / 7 8 und die Lücke unten rechts, und du tippst die 3 an, dann rutschen 3 und 6 nach unten. Danach steht 1 2 Lücke / 4 5 3 / 7 8 6, das ist 1 Zug. Kacheln, die schräg zur Lücke liegen, bewegen sich nicht, auch die Lücke selbst reagiert nicht. Tippst du eine Kachel an, die nicht schiebbar ist, passiert nichts und es zählt kein Zug.

## Größe, Tagesrätsel und Neu mischen
Stichwörter: Brettgröße, 3x3, 4x4, 5x5, 6x6, Menü, drei Punkte, mischen, täglich, Tag, fortsetzen, speichern, beenden
Die Größe wählst du auf der Spielseite vor dem Start (Aussehen Tinte) oder im Spiel im Menü „Mehr“ (drei Punkte): 3 × 3 (8 Kacheln), 4 × 4 (15), 5 × 5 (24) oder 6 × 6 (35). Beim Wechsel wird sofort neu gemischt. „Neu mischen“ gibt ein frisches Zufallsbrett in der gleichen Größe. „Tagesrätsel“ mischt so, dass alle Spieler am selben Kalendertag in derselben Größe dasselbe Brett bekommen. Das Tagesrätsel bleibt an, bis du „Neu mischen“ wählst. Mit „Spiel beenden“ verlässt du die Partie. Die Partie wird gespeichert (Brett, Zeit, Tipps, Tagesrätsel) und lässt sich fortsetzen.

## Tipp und Rückgängig
Stichwörter: Hilfe, Hinweis, Zug zurück, zurücknehmen, undo, rückgängig, gelber Rahmen, nächster Zug
Der Tipp-Knopf unter dem Brett zeigt mit einem gelben Rahmen die Kachel, die du als Nächstes anfassen sollst. Auf 3 × 3 und meist auch auf 4 × 4 liegt sie auf einem kürzesten Weg zur Lösung. Bei sehr schwierigen Brettern nimmt die App einen Zug, der die Kacheln insgesamt näher an ihre Zielplätze bringt. Der Tipp kostet keine Züge, aber mit Tipp wird keine Bestleistung gewertet. Es gibt keine Obergrenze für Tipps. „Rückgängig“ im Menü nimmt Züge zurück, auch mehrere nacheinander. Der Zugzähler geht dabei mit zurück.

## Wertung und Bestleistung
Stichwörter: Punkte, Rekord, Bestzeit, Zeit, Sekunden, Hintergrund, beste Zugzahl, Ende, wie gut
Gewertet werden die Züge, nicht die Zeit. Nach dem Lösen zeigt das Ende „N Züge in S Sekunden“. Die Zeit läuft nur, solange die App offen ist, die Zeit im Hintergrund zählt nicht. Die „Beste Zugzahl“ (Menü) merkt sich die geringste Zugzahl je Größe, aber nur aus Partien ohne Tipp. Ist die Zahl neu, steht „Neue Bestleistung!“ dabei. Das Tagesrätsel hat eine eigene Bestleistung für den Tag. Es gibt keine Siege, keine Punkte und keinen Computer.

## Begriffe und Beispiele
Stichwörter: Lücke, Kachel, leer, Beispiel, Bedeutung, 15-Puzzle
„Lücke“ ist das leere Feld, „Kachel“ ein nummeriertes Plättchen. Das Spiel heißt auch 15-Puzzle, wenn es 4 × 4 ist. Beispiel 4 × 4: Steht in der letzten Zeile 13 14 15 und die Lücke, und du tippst die 13 an, dann steht dort Lücke 13 14 15, das ist 1 Zug. Auf 6 × 6 liegen 35 Kacheln, die Lücke wandert beim Schieben quer durchs Brett.

## Was die App anders macht als die übliche Regel
Stichwörter: üblich, normal, Unterschied, Besonderheit, Regel anders, mehrere Kacheln
Üblich wird nur die Kachel neben der Lücke bewegt. In der App darfst du eine ganze Reihe oder Spalte in einem Zug schieben, das zählt als 1 Zug. Die Größen 2 × 2, 7 × 7 oder 8 × 8 gibt es im Menü nicht. Es gibt keine Zeitwertung.
"""#
}
