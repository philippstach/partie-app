// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/farbflut.md. Nicht von Hand ändern.
enum RegelWissenText_farbflut {
    static let quelle = #"""
## Ziel
Stichwörter: Farbfüller, Flood-It, Spielziel, gewinnen, einfarbig, Feld färben, Start, Flut
Das Feld besteht aus bunten Quadraten. Die Flut beginnt oben links: Das ist das Startfeld samt allen angrenzenden Feldern gleicher Farbe. Dein Ziel ist, das ganze Feld in eine einzige Farbe zu färben, bevor deine Züge aufgebraucht sind. In der App heißt das Spiel „Farbfüller“. Es gibt keinen Gegner. Die Zeit spielt keine Rolle, nur die Zahl der Züge. Das Feld startet nie schon einfarbig. Jedes Feld ist lösbar, denn die App berechnet vorab einen Lösungsweg und gibt dir mehr Züge, als der braucht.

## Ablauf und Zug
Stichwörter: Farbe wählen, Knopf, antippen, Runde, übrig, verloren, Niederlage, Zug, Farbknopf, schlucken
Ein Zug ist das Antippen eines der runden Farbknöpfe unter dem Feld. Die ganze Flut nimmt diese Farbe an und schluckt dabei alle Felder in dieser Farbe, die an die Flut grenzen. Die Farbe, die die Flut gerade hat, ist abgeschaltet, sie zu wählen wäre kein Zug. Oben steht „N Züge übrig“. Beispiel: Steht in der Ecke ein roter Block und daneben blau, wählst du blau, dann wird der rote Block blau und die blauen Nachbarfelder gehören zur Flut. Hat die Flut das ganze Feld, steht „Geschafft!“. Bei 0 Zügen übrig ohne ganze Farbe ist die Partie verloren. Wird das Feld mit dem letzten Zug voll, hast du gewonnen. „Neu beginnen“ im Menü „Mehr“ legt ein neues Brett, im Tagesrätsel dasselbe Tagesbrett. Hast du schon Züge gemacht und die Partie läuft noch, fragt die App vorher „Aktuelle Partie abbrechen?“.

## Stufen und Züge-Limit
Stichwörter: Schwierigkeit, leicht, normal, schwer, Größe, Farben, Reserve, Limit, Zugzahl, Feldgröße
Du wählst vor dem Start die Schwierigkeit: Leicht ist 8 × 8 (64 Felder) mit 4 Farben, Normal 12 × 12 (144 Felder) mit 6 Farben, Schwer 14 × 14 (196 Felder) mit 6 Farben. Das Limit ist die Zugzahl einer einfachen Lösung der App (jedes Mal die Farbe wählen, die gerade die meisten Felder dazubringt) plus Reserve: 6 Züge bei Leicht, 5 bei Normal, 2 bei Schwer. Braucht die einfache Lösung 20 Züge, ist das Limit 26, 25 oder 22. Ein geschickter Spieler kommt oft mit weniger aus. Die Farben (Rot, Blau, Grün, Orange, Violett, Türkis; Leicht nutzt die ersten 4) haben zusätzlich Formzeichen: Kreis, Quadrat, Dreieck, Raute, Stern, Sechseck.

## Schwierigkeitsleiter
Stichwörter: freischalten, gesperrt, Schloss, Schwierigkeit, Siege, Kindermodus, alle Stufen offen
Die Stufen schalten sich nacheinander frei. Leicht ist immer offen. Normal öffnet sich nach 3 Siegen ohne Tipp auf Leicht, Schwer nach 3 Siegen ohne Tipp auf Normal. Gesperrte Stufen zeigen ein Schloss. Im Kindermodus und mit dem Schalter „Alle Stufen offen“ in den Einstellungen sind alle offen. Siege im Tagesrätsel und Siege mit Tipp zählen für die Leiter nicht.

## Zurück und Tipp
Stichwörter: Hilfe, Hinweis, zurücknehmen, rückgängig, undo, Ring, beste Farbe
„Zurück“ nimmt den letzten Zug zurück, mehrfach nacheinander, und stellt auch die übrigen Züge wieder her. Nach Ende der Partie, gelöst oder verloren, geht es nicht mehr. „Tipp“ markiert die Farbe mit einem Ring, die die meisten Felder zur Flut dazubringt. Bei Gleichstand nimmt er die Farbe mit der kleineren Nummer in der Reihe Rot, Blau, Grün, Orange, Violett, Türkis. Der Tipp kostet keine Punkte und keine Züge, kann aber kürzere Lösungen verpassen. Wer einen Tipp benutzt, bekommt für die Partie keine Bestleistung und keinen Leiter-Sieg.

## Wertung
Stichwörter: Punkte, Rekord, Bestleistung, Ergebnis, Ende, wie viele Punkte, verloren
Geschafft: 100 Punkte plus 10 je übrigem Zug. Beispiel: Limit 25, nach 21 Zügen geschafft, 4 übrig, ergibt 140 Punkte. Mit dem letzten Zug geschafft ergibt 100. Verloren ist 0 Punkte, mit der Meldung „Keine Züge mehr“, und zählt nicht als Sieg. Das Ende zeigt „In X von Y Zügen geschafft“. Die Bestleistung ist die geringste Zugzahl je Stufe, nur ohne Tipp, bei neuer Bestleistung steht das dabei. Das Tagesrätsel hat eine eigene Bestleistung pro Tag.

## Tagesrätsel
Stichwörter: täglich, Tag, Serie, Mitternacht, für alle gleich, Karte
Das Tagesrätsel ist für alle am selben Tag gleich: 12 × 12, 6 Farben, Reserve 5. Die gewählte Stufe gilt dafür nicht. Du startest es über die Karte „Tagesrätsel heute“ der Startseite oder, außer in der Tinte-Gestaltung, über den Schalter im Neues-Spiel-Blatt. Löst du es, zählt der Tag für die Serie (in Tagen in Folge), auch mit Tipp. Wer kurz vor Mitternacht beginnt, bekommt das Ergebnis dem Starttag gutgeschrieben.

## Was die App anders macht als die übliche Regel
Stichwörter: üblich, normal, Unterschied, Besonderheit, Formen, Limit
Üblich ist ein festes Zuglimit je Feldgröße. Hier hat jedes Brett sein eigenes Limit: die Zugzahl der einfachen Lösung der App plus Reserve (6, 5 oder 2). Deshalb kann das Limit bei zwei Brettern gleicher Größe verschieden sein. Die aktuelle Farbe lässt sich nicht noch einmal wählen. Neben den Farben gibt es Formzeichen. Punkte, Leiter, Bestleistung und Tagesrätsel sind Eigenheiten der App.
"""#
}
