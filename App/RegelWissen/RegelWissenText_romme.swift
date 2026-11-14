// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/romme.md. Nicht von Hand ändern.
enum RegelWissenText_romme {
    static let quelle = #"""
## Ziel und Karten
Stichwörter: Spielerzahl, Karten, Blatt, Joker, geben, austeilen, Ziel, gewinnen, Runde zu Ende, leer werden
Rommé spielst du zu zweit bis zu viert. Es gibt 110 Karten: zwei Blätter mit je 52 Karten und 6 Joker (★). Jeder bekommt 13 Karten. Eine Karte liegt offen auf der Ablage, der Rest ist der Stapel. Ziel: Du wirst als Erster alle Handkarten los, indem du Sätze und Folgen auslegst. Die Runde endet sofort, wenn deine Hand leer ist. Das geht durch Abwerfen der letzten Karte, aber auch schon durch Auslegen oder Anlegen der letzten Karten. Alle anderen bekommen Strafpunkte: die Augen ihrer Resthand. Der Gewinner der Runde bekommt 0.

## Ablauf eines Zugs
Stichwörter: Zug, dran, ziehen, Stapel, Ablage, nehmen, abwerfen, wegwerfen, wer fängt an, Startspieler, mischen
Du bist reihum dran. Zuerst ziehst du eine Karte: vom Stapel oder die oberste Ablagekarte. Es ist immer nur die oberste Karte, und du darfst sie ohne Bedingung nehmen. Erst nach dem Ziehen darfst du auslegen, anlegen oder einen Joker tauschen. Nichts davon ist Pflicht. Zum Schluss wirfst du genau eine Karte auf die Ablage ab, dann ist der Nächste dran. Ist der Stapel leer, werden die Ablagekarten unter der obersten gemischt und bilden den neuen Stapel. In Runde 1 beginnt der erste Spieler. In jeder weiteren Runde einer Mehrrunden-Partie rückt der Anfang einen Platz weiter.

## Sätze und Folgen
Stichwörter: Satz, Folge, Reihe, Sequenz, Drilling, Vierling, Joker, Ass, Lücke, K-A-2, Länge, Farbe
Ein Satz sind 3 oder 4 Karten gleichen Werts in verschiedenen Farben, zum Beispiel K♠ K♥ K♦. Ein Satz hat höchstens 2 Joker. Eine Folge sind mindestens 3 Karten einer Farbe in aufsteigender Reihe ohne doppelte Werte, zum Beispiel 5♥ 6♥ 7♥. Das Ass liegt unten (A-2-3) oder oben (D-K-A), aber nicht „um die Ecke“: K-A-2 ist keine Folge. Eine Folge hat höchstens 14 Karten (A bis K und wieder A). Joker ersetzen jede Karte, füllen Lücken oder verlängern eine Folge an einem Ende. In einer Folge dürfen beliebig viele Joker stehen, aber mindestens eine Karte muss echt sein.

## Augen und erste Auslage
Stichwörter: Augen, Punkte, 40, erste Auslage, rauskommen, einmelden, Ass 11, Wert, Joker zählt
Augen einer Auslage: Die Karten 2 bis 10 zählen ihren Wert, Bube, Dame und König 10. Das Ass zählt im Satz 11, in einer Folge unten (A-2-3) 1 und oben (D-K-A) 11. Ein Joker zählt so viel wie die Karte, die er ersetzt: im Satz den Wert des Satzes, in der Folge den Wert seiner Stelle. Deine erste Auslage einer Runde muss zusammen mindestens 40 Augen haben. Du darfst dafür mehrere Sätze und Folgen gleichzeitig auslegen, ihre Augen werden addiert. Alle gewählten Karten müssen vollständig in gültige Auslagen passen. Danach darfst du in jedem Zug weitere Auslagen ohne Mindestwert legen. Die App zeigt beim Wählen „Gewählte Auslage: … von 40 Augen“. Beispiel: K♠ K♥ K♦ sind 30 Augen, das reicht allein nicht. 10♣ B♣ D♣ K♣ sind genau 40, das reicht.

## Anlegen und Joker tauschen
Stichwörter: anlegen, ansetzen, Joker tauschen, Jokertausch, Joker nehmen, Auslage, Tisch, Mitspieler
Anlegen und Jokertausch sind erst nach deiner eigenen ersten Auslage und nach dem Ziehen erlaubt. Anlegen: Du legst eine Handkarte an eine beliebige ausliegende Auslage, auch an die eines Mitspielers, wenn die Auslage danach gültig bleibt. Ein Satz mit 4 Karten ist voll. Auch ein Joker lässt sich anlegen. Jokertausch: Hast du die echte Karte, die ein Joker auf dem Tisch vertritt, legst du sie dorthin und nimmst den Joker auf die Hand. Die Auslage muss danach gültig bleiben. Der Zug geht weiter: Du darfst den Joker auslegen, anlegen, abwerfen oder behalten. Kann deine Karte anlegen und tauschen, fragt die App „Joker nehmen“ oder „Karte anlegen“.

## Strafpunkte, Runden und Optionen
Stichwörter: Strafpunkte, Minuspunkte, Resthand, Runden, 3 Runden, 5 Runden, Gleichstand, Gesamtwertung, Option
Strafpunkte einer Resthand: Joker 20, Ass 11, Bube, Dame, König je 10, sonst der Kartenwert. Beispiel: K♠, 5♥, A♦ und ein Joker sind 10 + 5 + 11 + 20 = 46. Option „Runden“ (nur vor dem Start): Bei „Eine Runde“ (Standard) gewinnt, wer zuerst keine Karten mehr hat. Der Gewinner bekommt 0, die anderen „−Strafpunkte“. Bei „3 Runden“ oder „5 Runden“ wird genau 3 oder 5 Runden gespielt, und die Strafpunkte aller Runden werden addiert. Wer nach der letzten Runde die wenigsten hat, gewinnt. Gleichstand: Die App zeigt „Gleichstand“. In der Rangfolge steht vorn, wer die letzte Runde gewonnen hat, sonst der frühere Sitzplatz.

## Beispiele mit Rechnung
Stichwörter: Beispiel, rechnen, Rechnung, wie viele Punkte, Augen ausrechnen
Folge A♥ 2♥ 3♥: 1 + 2 + 3 = 6 Augen (das Ass liegt unten und zählt 1). Folge D♥ K♥ A♥: 10 + 10 + 11 = 31 Augen (Ass oben zählt 11). Folge 5♥ 6♥ und Joker: Der Joker verlängert nach oben und zählt als 7, zusammen 5 + 6 + 7 = 18. Folge 8♥ 9♥ B♥ mit Joker auf der 10: 8 + 9 + 10 + 10 = 37. Satz K♠ K♥ und Joker: 3 × 10 = 30. Mehrrunden-Partie mit 3 Runden: Anna hat nach Runde 1 den Stand 0, Ben 23. In Runde 2 gewinnt Ben, Anna hat noch 14 Augen auf der Hand. Neuer Stand: Anna 14, Ben 23.

## Bedienung in der App
Stichwörter: Bedienung, tippen, Knopf, Sortieren, Tipp, Computer, Stärke, Stufe, leicht, schwer
Tippe Karten an, sie heben sich. Der Zug beginnt mit „Vom Stapel ziehen“ oder „Ablage nehmen“. „Auslegen“ geht erst ab 3 gewählten Karten. Zum Anlegen wählst du genau eine Karte und tippst dann die Auslage auf dem Tisch an. „Abwerfen“ braucht genau eine gewählte Karte. „Sortieren“ ordnet deine Hand „Wie gezogen“, „Nach Farbe“ oder „Nach Wert“ (Joker immer hinten, nur Anzeige). „Tipp“ schlägt vor, was ein starker Computer jetzt täte. Im Menü stellst du die Stärke des Computers ein (Leicht, Mittel, Schwer; Standard Schwer). Leicht nimmt nie die Ablagekarte und wirft zufällig ab, Schwer spielt am klügsten.

## Was die App anders macht
Stichwörter: anders, Abweichung, Hausregel, üblich, Unterschied, Schlussabwurf, Joker sofort, Ass, rückgängig
Nach einem Jokertausch musst du den Joker nicht sofort verwenden. Die Runde endet auch, wenn du mit dem Auslegen oder Anlegen die letzte Karte loswirst, ein Schlussabwurf ist nicht nötig. Von der Ablage kannst du nur die oberste Karte nehmen und musst sie nicht verwenden. Es gibt kein „Zug zurück“: Ein Abwurf lässt sich nicht zurücknehmen. Auf der Hand zählt das Ass am Ende immer 11 Strafpunkte, der Joker 20.
"""#
}
