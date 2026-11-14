// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/muehle.md. Nicht von Hand ändern.
enum RegelWissenText_muehle {
    static let quelle = #"""
## Ziel und Brett
Stichwörter: Mühlespiel, Neunermühle, Steine, Punkte, Brett, Quadrate, Spieler, Weiß, Schwarz, Gewinn
Mühle (Neunermühle) spielen zwei Spieler: Weiß (Spieler 1, hell) und Schwarz (Spieler 2, dunkel). Das Brett hat 24 Punkte auf drei ineinanderliegenden Quadraten. Auf jedem Quadrat liegen 8 Punkte: 4 Ecken und 4 Seitenmitten. Die Mitten der drei Quadrate sind durch 4 Linien verbunden. Ecken haben 2 Nachbarn, Seitenmitten des äußeren und inneren Quadrats 3, Seitenmitten des mittleren Quadrats 4. Jeder Spieler hat im klassischen Spiel 9 Steine. Ziel: Bilde Mühlen und nimm dem Gegner Steine weg, bis er weniger als 3 Steine hat oder nicht mehr ziehen kann.

## Ablauf: Setzen und Ziehen
Stichwörter: setzen, ziehen, Phase, Vorrat, Reihenfolge, wer beginnt, Anfang
Das Spiel hat zwei Phasen. Setzphase: Abwechselnd setzt jeder einen Stein auf einen freien Punkt, bis jeder alle 9 Steine gesetzt hat (insgesamt 18 Setzzüge). Gezogen wird noch nicht. Zugphase: Wer keinen Stein mehr im Vorrat hat, zieht pro Zug einen eigenen Stein auf einen freien Nachbarpunkt (entlang einer Linie, nicht diagonal, nicht über andere Steine). Springen nur mit 3 Steinen (siehe unten). Die Spielerleiste zeigt für jeden Spieler Steine auf dem Brett plus Vorrat (am Anfang 9). Wer beginnt, wählst du vor dem Start in der Karte „Wer beginnt“ (Abwechselnd, erster oder zweiter Spieler); Standard ist Spieler 1 (Weiß). Weiß ist immer Spieler 1, auch wenn Spieler 2 beginnt. Bei „Abwechselnd“ beginnt in der Revanche der andere.

## Mühle und Entfernen
Stichwörter: Mühle schließen, Stein wegnehmen, schlagen, nehmen, drei in einer Reihe, Linie
Drei eigene Steine in einer Linie sind eine Mühle. Es gibt 16 solche Linien: 12 Seiten der drei Quadrate und die 4 Verbindungslinien. Schließt du durch Setzen oder Ziehen eine Mühle, musst du sofort einen Stein des Gegners vom Brett nehmen. Du darfst nur Steine nehmen, die nicht selbst in einer Mühle stehen. Stehen alle Steine des Gegners in Mühlen, darfst du einen beliebigen davon nehmen. Mit der Regelart „Auch aus Mühlen schlagen“ darfst du immer jeden Stein nehmen. Danach ist der Gegner am Zug. Öffnest du eine Mühle und schließt sie später wieder, zählt das erneut. Schließt ein Zug zwei Mühlen auf einmal, darfst du trotzdem nur 1 Stein nehmen.

## Springen und Verlieren
Stichwörter: springen, fliegen, verlieren, aufgeben, blockiert, nicht ziehen können, zwei Steine
Wenn du nur noch 3 Steine auf dem Brett hast und keine mehr zu setzen, darfst du in jedem Zug einen beliebigen Stein auf einen beliebigen freien Punkt springen lassen, nicht nur auf Nachbarpunkte. Mit der Regelart „Ohne Springen“ gibt es das nicht: Du ziehst immer nur auf Nachbarpunkte. Du verlierst, wenn du keine Steine mehr zu setzen hast und weniger als 3 auf dem Brett stehen, oder wenn du am Zug bist und keinen Stein bewegen kannst. Solange noch Steine im Vorrat sind, verliert man nicht wegen zu weniger Steine auf dem Brett.

## Remis
Stichwörter: unentschieden, Patt, 60 Züge, Wiederholung, Zählung
Gibt es 60 Züge in der Zugphase hintereinander ohne dass ein Stein entfernt wird, ist die Partie remis (unentschieden). Gezählt wird jeder Zug beider Spieler zusammen, also 30 Züge je Spieler. Setzen zählt nicht mit. Jedes Entfernen eines Steins setzt die Zählung auf 0 zurück. Die App zeigt dann „Remis – 60 Züge ohne Mühle“. Eine Stellungswiederholung zählt in der App nicht als Remis.

## Optionen: Regelarten
Stichwörter: Variante, Regeln wählen, kurz, sechs Steine, ohne Springen, Hausregel, Menü Mehr
Im Menü „Mehr“ (drei Punkte) wählst du „Regeln“, aber nur vor dem ersten Zug. Danach ist die Auswahl gesperrt. Gewählt wird gemerkt und gilt für die nächste Partie. Klassisch (9 Steine): Standard, mit Springen, Schlagen nur aus freien Steinen. Kurz (6 Steine): jeder hat nur 6 Steine, 12 Setzzüge, sonst wie klassisch. Ohne Springen: wie klassisch, aber ohne Springen mit 3 Steinen. Auch aus Mühlen schlagen: wie klassisch, aber nach einer Mühle darf jeder gegnerische Stein genommen werden. Die Regelarten lassen sich nicht kombinieren.

## Computer und Hilfen
Stichwörter: Gegner, KI, Stärke, leicht, schwer, Tipp, Zug zurück, rückgängig, Hilfe
Gegen den Computer wählst du im Menü „Mehr“ die Stärke: Leicht (denkt beim Setzen 1, beim Ziehen 2 Halbzüge voraus, macht in 35 % der Fälle absichtlich einen schwächeren Zug), Mittel (2 und 3 Halbzüge, 10 %), Schwer (4 und 4, kein absichtlicher Fehler). Standard ist Mittel. „Zug zurück“ nimmt deinen letzten Zug zurück, samt den Zügen des Computers danach; ein Mühlenzug und das anschließende Entfernen sind zwei getrennte Schritte. „Tipp“ zeigt einen Vorschlag (nur wenn du am Zug bist). Mit der Karte „Wer beginnt“ kannst du auch den Computer beginnen lassen.

## Beispiele
Stichwörter: Beispiel, Rechnung, Rechenbeispiel
Beispiel klassisch: Beide Spieler haben je 9 Steine, nach 18 Setzzügen sind 18 Steine auf dem Brett und 6 Punkte frei (wenn niemand geschlagen wurde). Beispiel Mühle: Weiß hat Steine auf den drei Punkten einer Seite des äußeren Quadrats und gewinnt damit einen Stein von Schwarz. Beispiel Springen: Schwarz hat 3 Steine auf dem Brett und 0 im Vorrat: Er darf jeden Stein auf jeden freien Punkt setzen. Bei „Ohne Springen“ nicht. Beispiel Verlust: Weiß schlägt einen Stein, Schwarz hat danach 2 Steine auf dem Brett und nichts mehr im Vorrat: Schwarz verliert.

## Begriffe und Umgangssprache
Stichwörter: Zwickmühle, Nine Men's Morris, Vorrat, einfrieren, Zugphase
„Mühle“ heißt hier auch Nine Men's Morris, „Mühlespiel“ oder „Neunermühle“. „Zwickmühle“ nennt man zwei Mühlen, zwischen denen ein Stein hin- und herziehen kann, sodass fast jeder Zug eine Mühle schließt. „Vorrat“ sind die Steine, die noch nicht gesetzt sind. „Schlagen“ ist hier das Wegnehmen eines Steins nach einer Mühle. „Zugphase“ ist die Phase nach dem Setzen. Mit „Einfrieren“ ist gemeint, den Gegner so einzuschließen, dass er nicht mehr ziehen kann.

## Was die App anders macht als die übliche Regel
Stichwörter: Unterschied, Variante, übliche Regel, Wiederholung
Als Standard („Klassisch“) gilt die übliche Regel: 9 Steine, Springen mit 3 Steinen, Steine aus Mühlen nur, wenn es keine anderen gibt. Zusätzlich gibt es Kurz (6 Steine), Ohne Springen und Schlagen aus Mühlen. Die App hat ein Remis nach 60 Zügen ohne Mühle (üblich ist oft eine Wiederholungsregel). Wer beginnt, ist einstellbar.
"""#
}
