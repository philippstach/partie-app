// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/schwimmen/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_schwimmen {
    static let quelle = #"""
## Worum es geht

Schwimmen (auch „31“ oder „Schnauz“ genannt) ist ein schnelles Kartenspiel für 2 bis 6 Personen. Jede Person hat 3 Karten. In der Mitte liegen 3 offene Karten zum Tauschen. Du versuchst, in **einer Farbe** möglichst nah an **31 Punkte** zu kommen.

Wer am Ende einer Runde die schlechteste Hand hat, verliert ein Leben. Wer kein Leben mehr hat, „schwimmt“. Verliert er dann noch einmal, ist er raus. Wer übrig bleibt, gewinnt.

## Was du brauchst

- **Spieler:** 2 bis 6. Jeder Platz kann ein Mensch oder der Computer sein.
- **Karten:** 32 Karten (Skatblatt): 7, 8, 9, 10, Bube, Dame, König, Ass in Kreuz, Pik, Herz und Karo.
- Jede Person bekommt **3 Karten**, 3 Karten liegen offen in der Mitte (der **Tisch**). Der Rest ist der Stapel.
- Jede Person startet mit **3 Leben** (in den Hausregeln auch 4).

## Wer beginnt

In der ersten Runde beginnt Platz 1. Danach rückt der Beginn jede Runde einen Platz weiter. Wer raus ist, wird übersprungen.

## Was die Karten zählen

| Karte | Punkte |
|---|---|
|Ass | 11 |
|König, Dame, Bube, 10 | je 10 |
|9, 8, 7 | ihre Zahl |

Es zählt nur die **Farbe mit der höchsten Summe**.

*Beispiele:*
- Herz Ass, Herz König, Herz 7: 11 + 10 + 7 = **28**.
- Kreuz 10, Kreuz 9, Herz Ass: Kreuz zählt 19, Herz 11. Es zählt **19**.
- Pik 7, Herz 8, Karo 9: keine gemeinsame Farbe, es zählt die höchste Karte: **9**.
- Drei Karten mit gleichem Wert (zum Beispiel drei Neunen) zählen **30,5**.
- Das Beste ist **31**: Ass und zwei Zehnerkarten in einer Farbe, zum Beispiel Kreuz Ass, Kreuz König, Kreuz Dame.

## Dein Zug

Wenn du dran bist, machst du genau eines:

1. **Eine Karte tauschen:** eine deiner Karten gegen eine Karte vom Tisch.
2. **Alle drei tauschen:** deine drei Karten gegen die drei vom Tisch.
3. **Schieben:** nichts tauschen.
4. **Klopfen:** ansagen, dass du zufrieden bist (siehe unten).

Zum Tauschen tippst du eine Handkarte und eine Tischkarte an. Die App zeigt dir vorher, wie viel deine Hand danach wert wäre. Dann tippst du „Tauschen“.

## Schieben

Schiebst du, tauschst du nichts. Haben alle nacheinander geschoben, kommen 3 neue Karten vom Stapel auf den Tisch.

Mit der Hausregel „Schieben: Höchstens einmal“ darf jede Person pro Runde nur einmal schieben.

## Klopfen

Bist du mit deiner Hand zufrieden, klopfst du. Das geht, solange in dieser Runde noch niemand geklopft hat, auch schon im ersten Zug. Deine Hand bleibt dann, wie sie ist.

Alle anderen sind danach noch **genau einmal** dran (tauschen oder schieben). Dann wird gezählt.

## Feuer (31)

Hat jemand nach einem Tausch **31**, endet die Runde sofort. Das heißt **Feuer**. Auch beim Austeilen kann schon jemand 31 haben.

Bei Feuer verlieren alle anderen je 1 Leben. Wer die 31 hat, verliert nichts.

Mit der Hausregel „31 beendet die Runde sofort“ aus zählt 31 wie jede andere Hand, und die Runde geht weiter.

## Ende der Runde

Nach dem Klopfen (oder bei Feuer) werden alle Hände gezählt:

- Wer die **niedrigste Hand** hat, verliert 1 Leben.
- Haben mehrere dieselbe niedrigste Hand, verlieren alle davon je 1 Leben.
- Haben alle gleich viel, verliert niemand.

*Beispiel:* Hände 28, 17 und 21: Wer 17 hat, verliert ein Leben. Hände 20, 20 und 25: beide mit 20 verlieren je ein Leben.

## Schwimmen und raus

Neben jedem Namen siehst du die Leben (♥). Hast du 0 Leben, **schwimmst** du. Du spielst weiter, aber verlierst du noch einmal, bist du **raus**. Wer als Letzte oder Letzter übrig bleibt, gewinnt.

## Spielart „Punkte (5 Runden)“

Statt mit Leben könnt ihr auch auf Punkte spielen. Dann gibt es genau 5 Runden. In jeder Runde bekommt jede Person die Punkte ihrer Hand gutgeschrieben, auch halbe Punkte. Nach Runde 5 gewinnt die höchste Summe. Bei Gleichstand gewinnt, wer in der Reihenfolge weiter vorn sitzt.

## Hausregeln

Im Blatt „Neues Spiel“ unter „Hausregeln“ (oder in der Partie unter „Mehr“ → „Hausregeln“, nur vor dem ersten Zug):

@form B
| Hausregel | Standard | Was sie macht |
|---|---|---|
|Spielart | Leben | oder „Punkte (5 Runden)“ |
|Leben | 3 | oder 4 (nur bei Spielart Leben) |
|31 beendet die Runde sofort | an | aus: 31 zählt wie jede andere Hand |
|33 mit drei Assen | aus | an: drei Asse zählen 33 und sind das beste Blatt |
|Schieben | Beliebig oft | oder „Höchstens einmal“ je Runde |
|Drei Gleiche | 30,5 Punkte | oder 30 Punkte |

„Standard wiederherstellen“ setzt alles zurück. Änderst du in der Partie etwas, wird neu ausgeteilt.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“ → „Stärke des Computers“:

- **Leicht:** macht oft zufällige Züge.
- **Mittel** (Standard): sucht den besten Tausch und klopft ab 27 Punkten.
- **Schwer:** klopft erst ab 30 Punkten.

## Hilfen in der App

- **Vorschau:** Vor dem Tausch zeigt die App, was deine Hand danach wert ist.
- **Tipp:** zeigt den besten Tausch oder rät zum Klopfen.
- **Sichtschutz:** Spielen mehrere Menschen an einem Gerät, ist die Hand verdeckt, bis die Person am Zug sie aufdeckt.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Entscheide dich früh für eine Farbe und sammle nur diese.
- Ass und Zehnerkarten sind am meisten wert.
- Klopfe nicht zu spät: Mit 27 oder mehr bist du meist sicher.
- Schau, was die anderen vom Tisch nehmen. Dann weißt du, welche Farbe sie sammeln.

## Begriffe

- **Tisch:** die 3 offenen Karten in der Mitte.
- **Schieben:** nichts tauschen.
- **Klopfen:** die letzte Runde ansagen.
- **Feuer:** 31 Punkte, die Runde endet sofort.
- **Schwimmen:** 0 Leben, noch einmal verlieren heißt raus.
"""#
}
