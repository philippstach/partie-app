// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/muehle/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_muehle {
    static let quelle = #"""
## Worum es geht

Mühle ist eines der ältesten Brettspiele der Welt. Schon die alten Römer haben es gespielt. Zwei Personen spielen gegeneinander, jede mit 9 hellen oder dunklen Steinen.

Ihr setzt eure Steine abwechselnd aufs Brett und versucht, drei davon in eine Linie zu bringen. Das ist eine **Mühle**. Für jede Mühle darfst du dem Gegner einen Stein wegnehmen. Wer am Ende zu wenige Steine hat oder sich nicht mehr bewegen kann, verliert.

Es gibt kein Würfelglück und keine verdeckten Karten. Es gewinnt, wer besser vorausdenkt.

## Was du brauchst

- **Spieler:** genau 2. Ihr spielt zu zweit an einem Gerät oder du spielst gegen den Computer.
- **Steine:** jede Seite hat 9 Steine. Spieler 1 hat die hellen, Spieler 2 die dunklen. Bei der Regelart „Kurz“ hat jede Seite nur 6.
- **Brett:** drei ineinander liegende Quadrate mit zusammen 24 Punkten. Jedes Quadrat hat 4 Ecken und 4 Seitenmitten. Die Seitenmitten sind durch Linien mit den anderen Quadraten verbunden. Diagonalen gibt es nicht.

## Wer beginnt

Vor dem Start wählst du in der Karte „Wer beginnt“: der erste Spieler (Standard), der zweite Spieler oder abwechselnd. Bei „Abwechselnd“ beginnt in der Revanche die andere Seite. Gegen den Computer heißen die Plätze „Ich“ und „Computer“.

## Phase 1: Setzen

Ihr setzt abwechselnd je einen Stein auf einen beliebigen freien Punkt. Gezogen wird noch nicht. Das geht so lange, bis jede Seite alle Steine gesetzt hat. Im klassischen Spiel sind das 18 Setzzüge.

Schon beim Setzen kannst du Mühlen bilden.

## Phase 2: Ziehen

Hast du keine Steine mehr zu setzen, ziehst du in jedem Zug einen eigenen Stein auf einen **freien Nachbarpunkt**. Nachbar heißt: direkt entlang einer Linie, ohne Sprung über andere Steine.

## Springen

Hast du nur noch **3 Steine** auf dem Brett (und keine mehr zu setzen), darfst du springen: Jeder deiner Steine darf auf jeden freien Punkt, egal wo. Das gibt dir noch eine Chance.

Bei der Regelart „Ohne Springen“ gibt es das nicht. Dann ziehst du auch mit 3 Steinen nur auf Nachbarpunkte.

## Die Mühle

Drei eigene Steine in einer Linie sind eine Mühle. Es gibt 16 solche Linien: die 12 Seiten der drei Quadrate und die 4 Verbindungslinien zwischen ihnen.

Schließt du eine Mühle (durch Setzen, Ziehen oder Springen), **musst** du sofort einen Stein des Gegners vom Brett nehmen. Erst danach ist der Gegner dran.

**Welche Steine darfst du nehmen?**
- Nur Steine, die nicht in einer Mühle stehen.
- Stehen alle Steine des Gegners in Mühlen, darfst du jeden nehmen.
- Bei der Regelart „Auch aus Mühlen schlagen“ darfst du immer jeden nehmen.

Schließt ein Zug zwei Mühlen auf einmal, darfst du trotzdem nur **einen** Stein nehmen.

Öffnest du eine Mühle (ein Stein zieht heraus) und schließt sie im nächsten Zug wieder, zählt sie erneut. Zwei Mühlen, zwischen denen ein Stein hin- und herpendeln kann, nennt man **Zwickmühle**. Sie ist sehr stark.

## Wer gewinnt

Du gewinnst, wenn
- der Gegner nur noch **2 Steine** auf dem Brett hat und keine mehr zu setzen. Solange er noch Steine zu setzen hat, verliert er deswegen nicht.
- oder der Gegner am Zug ist und **keinen Stein bewegen kann**, weil alle eingeschlossen sind.

## Unentschieden (Remis)

Werden 60 Züge lang keine Steine entfernt, endet die Partie unentschieden. Gezählt werden die Züge beider Seiten zusammen, also 30 je Seite. Setzen zählt nicht mit, nur Ziehen und Springen. Jedes Mal, wenn ein Stein entfernt wird, beginnt die Zählung von vorn. Die App meldet dann „Remis – 60 Züge ohne Mühle“.

Wenn sich dieselbe Stellung wiederholt, ist das in der App noch kein Remis.

## Regelarten

Unter „Mehr“ → „Regeln“ wählst du eine von vier Regelarten. Sie lassen sich nicht kombinieren.

| Regelart | Was sich ändert |
|---|---|
|Klassisch (9 Steine) | Standard: 9 Steine, Springen mit 3 Steinen, aus Mühlen nur nehmen, wenn es nicht anders geht |
|Kurz (6 Steine) | Jede Seite hat nur 6 Steine (12 Setzzüge). Sonst wie Klassisch. |
|Ohne Springen | Kein Springen mit 3 Steinen. Sonst wie Klassisch. |
|Auch aus Mühlen schlagen | Nach einer Mühle darfst du jeden Stein des Gegners nehmen. Sonst wie Klassisch. |

Die Regelart lässt sich nur vor dem ersten Zug ändern. Die App merkt sie sich für die nächsten Partien.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“ → „Stärke des Computers“:

- **Leicht:** denkt nur kurz voraus und macht öfter mit Absicht einen schwächeren Zug (etwa jeden dritten).
- **Mittel** (Standard): denkt weiter voraus, patzt selten (etwa jeden zehnten Zug).
- **Schwer:** denkt am weitesten voraus und macht keine Fehler mit Absicht.

## So bedienst du das Spiel

- **Setzen:** Tippe einen freien Punkt an.
- **Ziehen:** Tippe zuerst deinen Stein an. Er wird markiert, und die möglichen Ziele bekommen einen Ring. Dann tippe das Ziel an.
- **Nehmen:** Nach einer Mühle bekommen die Steine des Gegners, die du nehmen darfst, einen roten Ring. Tippe einen davon an.
- **Hinweiszeile:** Unter dem Brett steht, was gerade zu tun ist, zum Beispiel „Anna setzt (5 übrig)“ oder „Mühle! Nimm einen Stein des Gegners.“
- **Oben** siehst du bei jeder Seite, wie viele Steine sie noch hat (auf dem Brett und zum Setzen).
- **Tipp:** zeigt mit einem gelben Ring einen guten Zug.
- **Zug zurück:** nimmt deinen letzten Schritt zurück, gegen den Computer auch seinen Zug danach. Mühle schließen und Stein nehmen sind zwei Schritte.
- **Pause:** Verlässt du die Partie, kannst du später an derselben Stelle weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Besetze beim Setzen gern die Seitenmitten des mittleren Quadrats. Sie haben die meisten Nachbarn (4).
- Achte auf den Gegner: Hat er zwei Steine in einer Linie und der dritte Punkt ist frei, stell dich dazwischen.
- Bau dir eine Zwickmühle. Dann kannst du fast jeden Zug einen Stein nehmen.
- Lass deine Steine nicht einschließen. Wer sich nicht bewegen kann, verliert.

## Begriffe

- **Mühle:** drei eigene Steine in einer Linie.
- **Zwickmühle:** zwei Mühlen, zwischen denen ein Stein hin- und herziehen kann.
- **Setzen / Ziehen / Springen:** die drei Arten, einen Stein zu bewegen.
- **Vorrat:** Steine, die du noch nicht gesetzt hast.
- **Nehmen (Schlagen):** einen Stein des Gegners vom Brett entfernen.
- **Remis:** unentschieden.
"""#
}
