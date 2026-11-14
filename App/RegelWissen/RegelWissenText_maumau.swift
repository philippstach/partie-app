// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/maumau.md. Nicht von Hand ändern.
enum RegelWissenText_maumau {
    static let quelle = #"""
## Ziel und Spieler
Stichwörter: gewinnen, Kartenzahl, wie viele Spieler, Blatt, Skat
Du willst als Erste oder Erster alle Karten loswerden. Gespielt wird mit dem Skatblatt: Kreuz, Pik, Herz und Karo mit 7, 8, 9, 10, Bube, Dame, König und Ass, zusammen 32 Karten. Es spielen 2 bis 6 Personen, auch mit Computer. Ab 5 Personen nimmt die App zwei Blätter (64 Karten). Wer zuerst keine Karten mehr hat, gewinnt die Runde sofort. Im Standard ist das schon die ganze Partie. Wer lieber mehrere Runden mit Punkten spielt, schaltet „Mehrere Runden mit Punkten“ ein (siehe Abschnitt Mehrere Runden).

## Ablauf und Ziehen
Stichwörter: anfangen, austeilen, ablegen, Karte nehmen, nachziehen, Stapel leer, passt nicht
Jede Person bekommt 5 Karten (einstellbar 5 bis 7). Eine Karte liegt offen auf der Ablage, der Rest ist der Stapel. Die Startkarte ist nie ein Bube, nie eine 7 oder 8 und nie die Aussetzen-Karte; bei „9 wechselt die Richtung“ auch keine 9. Wer dran ist, legt eine Karte gleicher Farbe oder gleichen Werts wie die oberste Ablagekarte. Es geht im Uhrzeigersinn. Kannst du nicht legen, ziehst du genau 1 Karte, und dein Zug ist vorbei. Ziehen darfst du auch dann, wenn du legen könntest. Ist der Stapel leer, wird die Ablage ohne die oberste Karte gemischt und wird der neue Stapel. Beispiel: Oben liegt Herz 9. Du darfst jede Herz-Karte, jede 9 und (fast) jeden Buben legen.

## 7, 8 und Bube
Stichwörter: Siebener, Achter, Jungs, Wunschfarbe, aussetzen, Strafkarten, Farbwunsch
7 (Standard): Der Nächste muss 2 Karten ziehen. Hat er selbst eine 7, legt er sie, dann muss der Übernächste 4 ziehen, danach 6 und so weiter. Solange gezogen werden muss, darf nur eine 7 gelegt werden, auch kein Bube. Wer keine 7 hat, zieht alle Karten auf einmal (Knopf „4 Karten ziehen“) und ist danach nicht mehr dran. 8 (Standard): Der Nächste setzt aus. Er kann mit einer weiteren 8 weitergeben, dann setzt der Übernächste aus. Sonst tippt er „Aussetzen“. Bei 2 Personen ist nach dem Aussetzen wieder die Person dran, die die 8 gelegt hat. Bube: Er passt auf fast jede Karte. Wer ihn legt, wünscht sich eine Farbe. Danach zählt nur diese Farbe, der Wert zählt nicht, oder ein weiterer Bube (falls erlaubt). Auf eine offene 7- oder 8-Pflicht darf kein Bube.

## Hausregeln
Stichwörter: Mau sagen, vergessen, Strafe, neun, Richtung, sofort legen, Schalter
„Mau“ sagen: Wer die vorletzte Karte legt (danach hat er 1 Karte), muss vorher „Mau sagen“ antippen. Der Knopf erscheint, wenn du genau 2 Karten hast und eine legen kannst. Sonst zieht er sofort 1 Strafkarte. Der Computer sagt immer „Mau“. „9 wechselt die Richtung“: Eine 9 dreht die Richtung, nur ab 3 Personen. „Gezogene Karte gleich legen“: Passt die eine gezogene Karte, darfst du sie legen oder „Weitergeben“ tippen. Das gilt nicht, wenn du wegen einer 7 ziehen musstest. „Bube darf die letzte Karte sein“ aus: Dann kannst du mit einem Buben nicht gewinnen. „Bube auf Bube“ aus: Kein Bube auf einen Buben. Mit „Aussetzen mit dem Ass“ setzt das Ass aus statt der 8, die 8 ist dann normal. Ohne „7 lässt ziehen“ ist die 7 normal.

## Vorlagen (Schnellwahl)
Stichwörter: Wild, Streng, Schlicht, Voreinstellung, Schnellwahl
Standard: 5 Karten, 7 zieht, 8 setzt aus. Ass setzt aus: wie Standard, aber das Ass setzt aus. Sieben Karten auf die Hand. Schlicht: ohne 7-Ziehen und ohne Aussetzen. Streng: Bube nie als letzte Karte und nicht auf Bube. Wild: 9 dreht die Richtung, „Mau“ ist Pflicht, gezogene Karte gleich legen. Eine Vorlage setzt alle Schalter neu, nur die Runden-Einstellung bleibt. Danach kannst du jeden Schalter einzeln ändern. Die Vorlage „Standard“ stellt also die Grundregeln wieder her. Merkt sich das Spiel deine Wahl? Ja, die Regeln bleiben für die nächsten Partien gespeichert.

## Mehrere Runden und Wertung
Stichwörter: Punkte, zählen, Augen, Ziel erreichen, verlieren, Runden
Mit „Mehrere Runden mit Punkten“ bekommt die Gewinnerin oder der Gewinner einer Runde 0 Punkte. Alle anderen bekommen die Augen ihrer Restkarten: Bube 20, Ass 11, Dame 10, König 10, 7, 8, 9 und 10 je ihre Zahl. Beispiel: Rest Bube, Ass und 9 = 20 + 11 + 9 = 40 Punkte. Die Punkte werden über die Runden addiert. Sobald jemand die Zielsumme erreicht (50, 100 oder 150, Standard 100), endet die Partie. Wer die wenigsten Punkte hat, gewinnt. Wer die Zielsumme zuerst erreicht, verliert also meistens. Beispiel: Ziel 100, du hast 85 und bekommst 20, dann hast du 105 und die Partie ist zu Ende. Ohne Mehrrunden zählt keine Punktzahl, nur wer zuerst leer ist.

## Bedienung in der App
Stichwörter: Knopf, Tipp, antippen, Menü, ändern, einstellen, iPad
Vor dem Start stehen die Hausregeln im Blatt „Neues Spiel“ in der Karte „Hausregeln“. In der laufenden Partie öffnest du sie über „Mehr“ → „Hausregeln“. Sie lassen sich nur vor dem ersten Zug ändern, dann wird neu ausgeteilt. Du tippst eine Karte an, um sie zu legen; spielbare Karten sind hell, die anderen gedimmt. Beim Buben wählst du die Farbe in einer Leiste. „Tipp“ zeigt die beste Karte. Bei mehreren Menschen ist ein Sichtschutz davor. Auf dem iPad im Querformat gibt es zusätzlich eine Seitenspalte mit dem Verlauf und den Regeln dieser Partie.

## Begriffe
Stichwörter: was heißt, Bedeutung, Fachwort, Ablage
Ablage: die offene Karte oben, auf die gelegt wird. Stapel: die verdeckten Karten zum Ziehen. Aussetzen: eine Runde nicht spielen. Wunschfarbe: die Farbe, die ein Bube bestimmt. „Mau“: der Ruf bei der vorletzten Karte. Augen: die Punkte der Karten am Rundenende. Strafkarte: die Karte, die du ziehen musst, wenn du „Mau“ vergessen hast. Ziehpflicht: das Ziehen von 2, 4, 6 … Karten nach einer 7. Hausregel: ein Schalter im Blatt „Hausregeln“, der die Grundregeln ändert. Runde: ein Durchgang, bis jemand keine Karten mehr hat.

## Was die App anders macht als die übliche Regel
Stichwörter: abweichen, anders, üblich, Hausregel, Unterschied
Im Standard darf ein Bube die letzte Karte sein und auf einen Buben gelegt werden, das verbieten viele Familien. Gezogen wird genau 1 Karte (nicht bis eine passt). Eine 7 kann nur mit einer 7 gekontert werden, ein Bube hilft dabei nicht. Eine 8 kann weitergegeben werden. Nach dem Wunsch zählt nur die Farbe. Der Ruf „Mau-Mau“ bei der letzten Karte entfällt, „Mau“ gibt es nur als Hausregel bei der vorletzten Karte. Die Regeln der Partie sind nach dem ersten Zug fest.

## Gewinner und Rangfolge
Stichwörter: Platz, Zweiter, Ergebnis, wer verliert, Ende, Platzierung
Wer die letzte Karte ablegt, gewinnt sofort, auch mit einer 7 oder 8 als letzter Karte. Ohne „Mehrere Runden mit Punkten“ ist die Partie dann vorbei. Die Plätze danach richten sich nach den Karten auf der Hand: Wer weniger Karten hat, steht weiter vorn. Im Ergebnis steht bei jeder Person die Zahl ihrer Restkarten. Mit mehreren Runden steht dort der Punktestand, und vorn steht, wer die wenigsten Punkte hat. Haben am Ende zwei oder mehr gleich wenige Punkte, nennt die App keinen Sieger (unentschieden). Wer beginnt, wählst du vor dem Start: „Reihum“ (Standard, jede neue Partie beginnt die nächste Person) oder eine feste Person. Mit mehreren Runden beginnt jede neue Runde die nächste Person.

## Gegen den Computer
Stichwörter: Computer, Stärke, Stufe, leicht, schwer, KI, Gegner, Bot
Plätze können mit dem Computer besetzt werden. Seine Stärke stellst du in der Partie über „Mehr“ ein: Leicht, Mittel oder Schwer (Standard Schwer). Leicht legt in 7 von 10 Zügen eine zufällige passende Karte, Mittel in 1 von 4 Zügen, Schwer nie. Der Computer legt immer, wenn er eine passende Karte hat, und zieht nur, wenn nichts passt. Er sagt immer „Mau“, auch auf Leicht. Bei einem guten Zug wünscht er sich die Farbe, von der er die meisten Karten hat; bei einem Zufallszug eine zufällige Farbe. Der Knopf „Tipp“ zeigt dir die Karte, die der Computer auf Schwer an deiner Stelle legen würde.

## Tipps für den Anfang
Stichwörter: Taktik, Strategie, Trick, wie gewinne ich, besser spielen, Anfänger
Hebe einen Buben für den Notfall auf, er passt fast immer. Wünsch dir die Farbe, von der du die meisten Karten hast. Hat die nächste Person nur noch 1 oder 2 Karten, ist eine 7 oder 8 besonders wertvoll, denn sie bremst sie. Bei mehreren Runden zählen Bube (20) und Ass (11) viele Punkte, werde sie lieber früh los. Diese Tipps sind keine Regeln, nur Hinweise.
"""#
}
