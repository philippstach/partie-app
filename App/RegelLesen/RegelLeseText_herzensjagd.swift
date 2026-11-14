// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/herzensjagd/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_herzensjagd {
    static let quelle = #"""
## Worum es geht

Herzensjagd ist ein Stichspiel für genau vier Personen. Anders als bei den meisten Kartenspielen willst du hier **keine** Punkte bekommen: Jedes Herz zählt einen Minuspunkt, die Pik-Dame sogar 13. Wer am Ende die wenigsten Punkte hat, gewinnt.

Die Kunst ist, gefährliche Karten rechtzeitig loszuwerden, ohne selbst die Stiche mit Herzen zu bekommen. Und wer mutig ist, versucht den **Mondschuss**: alle Punkte auf einmal holen.

## Was du brauchst

- **Spieler:** genau 4. Jeder Platz kann ein Mensch oder der Computer sein.
- **Karten:** 52 Karten in vier Farben (Kreuz ♣, Karo ♦, Pik ♠, Herz ♥), jeweils 2 bis Ass. Das Ass ist die höchste Karte, die 2 die niedrigste. Es gibt keinen Trumpf.
- Jede Person bekommt **13 Karten**.

## Karten weitergeben

Vor jeder Runde gibst du **3 Karten** an eine andere Person weiter. Die Richtung wechselt:

1. Runde: nach links
2. Runde: nach rechts
3. Runde: nach gegenüber
4. Runde: keine Weitergabe

Dann geht es wieder von vorn los. Tippe 3 Karten an und dann „Weitergeben“. Getauscht wird erst, wenn alle gewählt haben.

Im Blatt „Neues Spiel“ kannst du das Weitergeben unter „Drei Karten weitergeben“ abschalten.

## So läuft ein Stich

- Die Runde beginnt mit der **Kreuz 2**. Wer sie hat, spielt sie aus.
- Reihum legt jede Person eine Karte.
- **Bedienen ist Pflicht:** Du musst eine Karte der ausgespielten Farbe legen, wenn du eine hast.
- Hast du die Farbe nicht, wirfst du eine beliebige Karte ab. Im ersten Stich aber möglichst keine Herzen und nicht die Pik-Dame (außer du hast nichts anderes).
- Den Stich gewinnt die **höchste Karte der ausgespielten Farbe**. Abgeworfene Karten anderer Farben gewinnen nie.
- Wer den Stich gewinnt, bekommt alle Karten darin und spielt den nächsten aus.

Gespielt werden 13 Stiche, bis alle Karten weg sind.

## Wann darf man Herz ausspielen?

Ausspielen heißt: den Stich mit der ersten Karte beginnen. Herz darfst du erst ausspielen, wenn die Herzen **offen** sind. Das sind sie, sobald ein Herz gespielt wurde (auch als Abwurf) oder ein Stich mit der Pik-Dame vorbei ist. Hast du nur noch Herzen, darfst du sie immer ausspielen.

## Punkte

Am Ende der Runde zählt jede Person die Karten in ihren Stichen:

| Karte | Punkte |
|---|---|
|jedes Herz | 1 |
|Pik-Dame | 13 |
|alle anderen | 0 |

In jeder Runde sind es zusammen 26 Punkte.

## Mondschuss

Holt eine Person in einer Runde **alle 26 Punkte**, also alle Herzen und die Pik-Dame, bekommt sie 0 Punkte, und alle drei anderen bekommen je 26.

## Spielende

Die Punkte werden über die Runden zusammengezählt. Sobald jemand die Grenze erreicht, ist das Spiel vorbei. Die Grenze wählst du im Blatt „Neues Spiel“ unter „Spielende bei“: 50 (Standard), 75 oder 100 Punkte.

Es gewinnt, wer dann die **wenigsten** Punkte hat. Bei gleichen Punkten teilt ihr euch den Platz.

## Gegen den Computer

Die Stärke wählst du unter „Mehr“ → „Stärke des Computers“:

- **Leicht:** spielt oft eine zufällige erlaubte Karte (fast jede zweite).
- **Mittel** (Standard): spielt meist überlegt, ab und zu zufällig.
- **Schwer:** spielt immer überlegt.

Beim Weitergeben gibt der Computer immer seine gefährlichsten Karten ab (Pik-Dame, Pik-König, Pik-Ass, hohe Herzen), egal auf welcher Stufe.

## Hilfen in der App

- Erlaubte Karten sind hell, die anderen abgedunkelt. Tippe eine helle Karte an, um sie zu spielen.
- **Tipp:** umrahmt die Karte gelb, die der stärkste Computer jetzt spielen würde.
- **Punktestand:** oben stehen der Gesamtstand und die Punkte dieser Runde.
- **Übergabe:** Spielen mehrere Menschen an einem Gerät, kommt vor jedem Zug eine Seite zum Weitergeben, damit die Hand geheim bleibt.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps für den Anfang

- Gib beim Weitergeben die Pik-Dame, Pik-König und Pik-Ass ab, wenn du wenige Pik hast. Mit ihnen fängst du sonst leicht die Dame.
- Werde eine Farbe ganz los. Dann kannst du bei dieser Farbe Herzen und die Pik-Dame abwerfen.
- Spiel niedrige Karten aus, wenn du keine Stiche willst.
- Ein Mondschuss ist riskant: Fehlt dir am Ende ein einziges Herz, hast du 25 Punkte.

## Begriffe

- **Stich:** die vier Karten einer Runde reihum.
- **Ausspielen:** die erste Karte eines Stichs legen.
- **Bedienen:** eine Karte der ausgespielten Farbe legen.
- **Abwerfen:** eine Karte einer anderen Farbe legen, weil du die ausgespielte nicht hast.
- **Mondschuss:** alle 26 Punkte einer Runde holen.
"""#
}
