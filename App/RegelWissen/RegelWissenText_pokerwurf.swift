// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/pokerwurf.md. Nicht von Hand ändern.
enum RegelWissenText_pokerwurf {
    static let quelle = #"""
## Ziel und Überblick
Stichwörter: Spielziel, gewinnen, Runden, Spieleranzahl, Reihenfolge, wer fängt an, Punkte pro Runde, Maximum
Pokerwurf wird mit 5 Würfeln gespielt, es gibt 5 Runden. Es spielen 2 bis 4 Personen, jeder Platz ist ein Mensch oder der Computer. In jeder Runde würfelt jeder einmal reihum und versucht, die beste Pokerhand zu bekommen. Wer in einer Runde die beste Hand hat, bekommt 1 Punkt. Nach 5 Runden gewinnt, wer die meisten Punkte hat. Mehr als 5 Punkte sind nicht möglich. Gewürfelt wird in der Reihenfolge der Spielerliste. Wer beginnt, wählst du vor dem Start: „Reihum“ (Standard, jede neue Partie beginnt die nächste Person) oder eine feste Person. Innerhalb der Partie beginnt jede Runde die nächste Person.

## Ablauf eines Zuges
Stichwörter: Würfeln, festhalten, behalten, liegen lassen, aufhören, dreimal, Wurf, stehen lassen, Zug beenden
Du würfelst bis zu 3 Mal. Beim ersten Wurf werden alle 5 Würfel geworfen. Nach dem 1. und 2. Wurf tippst du die Würfel an, die du behalten willst. Gehaltene Würfel sind markiert und werden beim nächsten Wurf nicht mitgeworfen. Nochmal antippen gibt den Würfel wieder frei. Der Knopf „Würfeln (2 übrig)“ zählt die übrigen Würfe herunter. Mit „Behalten“ beendest du den Zug, das geht nach jedem Wurf, also schon nach dem 1. Wurf. Nach dem 3. Wurf gibt es nur noch „Behalten“. Vor dem 1. Wurf und nach dem 3. Wurf kannst du keine Würfel halten. Ein Zug braucht mindestens 1 Wurf. Wenn der letzte Spieler „Behalten“ drückt, wird die Runde gewertet.

## Die Hände
Stichwörter: Hände, Rangfolge, Straße, Poker, Paar, Drilling, Full House, Vierling, Fünfling, Kniffel, was schlägt was, stärker
Von schwach nach stark: Nichts, Ein Paar, Zwei Paare, Drilling, Kleine Straße, Große Straße, Full House, Vierling, Fünfling. Nichts: keine gleichen Würfel und keine Straße. Ein Paar: 2 gleiche. Zwei Paare: 2 und 2 gleiche. Drilling: 3 gleiche. Kleine Straße: genau 1-2-3-4-5. Große Straße: genau 2-3-4-5-6. Full House: 3 gleiche und 2 gleiche. Vierling: 4 gleiche. Fünfling: 5 gleiche. Die Straßen brauchen alle 5 Würfel, nur diese zwei Folgen zählen (3-4-5-6 plus eine Zahl ist keine Straße). Die App-Reihenfolge ist: Full House schlägt beide Straßen, beide Straßen schlagen den Drilling. Fünfling ist die stärkste Hand.

## Gleiche Hand: wer gewinnt
Stichwörter: gleiche Hand, höher, Gleichstand, Rest-Würfel, Kicker, vergleichen, besser, wer hat mehr
Haben zwei Spieler dieselbe Handart, zählen die Würfel der Reihe nach, die wichtigsten zuerst. Bei Paar, Drilling, Vierling und Full House zählt erst der Wert der Gruppe (bei Full House zuerst der Drilling), dann die Rest-Würfel von hoch nach tief. Bei Zwei Paaren zählt erst das höhere Paar, dann das niedrigere, dann der einzelne Würfel. Bei Nichts zählen alle 5 Würfel von der höchsten Zahl abwärts. Bei Fünfling zählt die höhere Zahl. Beispiele: 4-4-4-1-1 schlägt 3-3-3-5-5 (Drilling 4 gegen 3). 6-6-2-3-4 verliert gegen 6-6-5-1-2 (Rest-Würfel 5 gegen 4). 5-5-2-2-6 verliert gegen 5-5-3-3-1 (zweites Paar 3 gegen 2). 6-5-4-3-1 schlägt 6-5-4-2-1. Beide Straßen derselben Art sind gleich gut.

## Wertung der Runde und Gleichstand
Stichwörter: Punkt, Rundensieger, Unentschieden, teilen, Wertung, Sieger der Runde, Ergebnis
Nachdem alle ihren Zug beendet haben, vergleicht die App die 4 oder weniger Hände. Die beste Hand bekommt 1 Punkt. Sind mehrere Hände exakt gleich gut (zum Beispiel zwei große Straßen), bekommen alle Besten je 1 Punkt, die App meldet „Unentschieden in dieser Runde“. Sonst steht „… gewinnt die Runde“. Dann „Nächste Runde“, nach der 5. Runde „Ergebnis“. Gleiche Punkte am Ende bedeuten gleiche Plätze. Ein Beispiel mit 3 Spielern: A hat Drilling, B Full House, C Paar: B bekommt 1 Punkt.

## Würfel, Computer und Bedienung
Stichwörter: echte Würfel, eintippen, Computer, Stärke, leicht, schwer, rückgängig, zurück, Schütteln, Menü
Im Neues-Spiel-Blatt: „Virtuell“ (die App würfelt, auch Schütteln geht) oder „Echt“ (du würfelst echt und tippst nur die Augen der Würfel ein, die du neu geworfen hast; sind alle gehalten, kommt keine Eingabe). Der Computer würfelt immer selbst. Die Stärke des Computers wählst du im Menü „Mehr“ (nur wenn ein Computer mitspielt): Leicht, Mittel (Standard), Schwer. Der Computer hält Paare, Drillinge, fertige Straßen oder Full House, und sucht Vierer-Folgen für eine Straße. Mit „Zug zurück“ nimmst du deine letzte Halte-Auswahl oder dein „Behalten“ zurück, nie aber einen Wurf.

## Was die App anders macht als die übliche Regel
Stichwörter: Hausregel, Joker, Einsatz, anders, üblich, Unterschied, Ansage
Pokerwurf wird anderswo oft mit Ansagen, Einsätzen oder Wertung nach Gesamtpunkten gespielt. Hier gewinnt die beste Hand der Runde genau 1 Punkt. Nur die zwei festen Straßen 1-5 und 2-6 zählen. Der Fünfling ist eine eigene Hand. Es gibt keine Joker, keine Einsätze, keine Ansage der Hand. Alle Spieler würfeln gleich oft (3 Würfe) und die Hände sind offen. Die Handart wird nach jedem Wurf angezeigt.
"""#
}
