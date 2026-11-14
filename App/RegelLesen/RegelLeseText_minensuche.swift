// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/minensuche/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_minensuche {
    static let quelle = #"""
## Worum es geht

Unter manchen Feldern liegen Minen. Decke **alle Felder ohne Mine** auf, ohne eine Mine zu treffen. Die Zahlen auf den aufgedeckten Feldern verraten dir, wo die Minen liegen. Du spielst allein, gegen die Uhr.

## Die Zahlen

Eine Zahl sagt, wie viele der **acht Nachbarfelder** (auch schräg) eine Mine haben. Eine 2 heißt: Rund um dieses Feld liegen genau zwei Minen.

Ein leeres Feld hat keine Mine in der Nähe. Es öffnet seine Nachbarn von selbst, oft eine ganze Fläche auf einmal.

## Stufen

@form A
| Stufe | Brett | Minen |
|---|---|---|
|Leicht | 7 × 9 | 8 |
|Mittel | 9 × 14 | 22 |
|Schwer | 11 × 18 | 44 |

Leicht ist immer offen. Mittel öffnet sich nach 3 Siegen ohne Hinweis auf Leicht, Schwer nach 3 Siegen ohne Hinweis auf Mittel. Im Kindermodus und mit „Alle Stufen offen“ ist alles offen.

## Aufdecken und Fahnen

- **Tippen** deckt ein Feld auf.
- **Lang drücken** setzt eine Fahne auf ein Feld, unter dem du eine Mine vermutest. Noch einmal lang drücken nimmt sie weg.
- Der Knopf **„Fahne“** vertauscht beides: Dann setzt Tippen die Fahne, und langes Drücken deckt auf.
- Ein Feld mit Fahne lässt sich nicht aus Versehen aufdecken.
- Wie lange du für die Fahne drücken musst, stellst du vor dem Start ein: 0,2, 0,3 oder 0,5 Sekunden.

Oben steht, wie viele Minen noch übrig sind: alle Minen minus deine Fahnen. Setzt du zu viele Fahnen, wird die Zahl negativ.

## Der erste Zug ist sicher

Die Minen werden erst gelegt, wenn du das erste Feld aufdeckst. Dieses Feld und alle seine Nachbarn sind immer frei. So startest du mit einer offenen Fläche.

## Ohne Raten lösbar

Im Standard baut die App jedes Brett so, dass du es **nur durch Nachdenken** lösen kannst. Du musst nie raten. (Die App probiert dafür sehr viele Anordnungen durch; in ganz seltenen Fällen findet sie keine passende.) Den Schalter „Ohne Raten lösbar“ kannst du vor dem Start ausschalten, dann wird einfach zufällig gemischt. Tagesrätsel und geteilte Bretter sind immer ohne Raten lösbar.

## Zahl antippen

Tippst du auf eine aufgedeckte Zahl und rundherum liegen **genau so viele Fahnen**, wie die Zahl sagt, öffnet die App alle übrigen Nachbarn auf einmal. Das spart Zeit. Aber Vorsicht: Steht eine Fahne falsch, triffst du dabei eine Mine.

*Beispiel:* Eine 2 hat zwei Fahnen neben sich. Ein Tipp auf die 2 öffnet die anderen sechs Nachbarn.

**Alle Minen markiert:** Hast du jede Mine richtig mit einer Fahne markiert und keine falsche Fahne gesetzt, öffnet sich der Rest des Bretts von selbst. Du hast gewonnen.

## Mine getroffen

Triffst du eine Mine, fragt die App: „Mine getroffen. Weiterspielen?“

- **Weiterspielen (+30 s):** Dein letzter Zug wird zurückgenommen, die Mine bekommt eine Fahne, und auf deine Zeit kommen 30 Sekunden. Das geht **einmal** je Partie. Gewinnst du danach, zählt der Sieg, aber nicht als Bestzeit.
- **Aufhören:** Das Brett zeigt alle Minen, die Partie ist verloren. Falsch gesetzte Fahnen bekommen ein X.

Triffst du nach der zweiten Chance noch eine Mine, ist die Partie sofort vorbei.

## Hinweis

Der Knopf **„Hinweis“** deckt ein sicheres Feld für dich auf. Er geht erst nach dem ersten Aufdecken. Jeder Hinweis kostet **10 Sekunden** Strafzeit. Eine Partie mit Hinweis zählt nicht als Bestzeit und nicht fürs Freischalten. Gibt es gerade kein sicheres Feld, passiert nichts, und es kostet auch nichts.

## Zeit und Bestzeit

Die Zeit läuft ab dem ersten Aufdecken, beim Tagesrätsel sofort. Ist die App im Hintergrund, hält sie an. Strafzeiten kommen dazu.

*Beispiel:* Du brauchst 95 Sekunden, nimmst 2 Hinweise und die zweite Chance. Dann stehen 95 + 20 + 30 = 145 Sekunden in der Zeit, und es gibt keine Bestzeit.

Die Statistik zeigt je Stufe: gespielt, gewonnen, Bestzeit und Serie. Ersetzt du eine laufende Partie durch eine neue, zählt sie als verloren.

## Tagesrätsel

Jeden Tag gibt es ein Tagesrätsel der Stufe Mittel, für alle gleich. Das erste Feld ist schon aufgedeckt. Löst du es an Tagen hintereinander, wächst deine Serie. Ein verpasster Tag beendet sie. Das Tagesrätsel hat keine Bestzeit und zählt nicht fürs Freischalten.

## Brett teilen

Du kannst ein Brett als Link teilen. Wer ihn öffnet, bekommt dasselbe Brett. Es zählt wie eine normale Partie.

## Kleine Tipps

- Eine 1 an einer Ecke mit nur einem verdeckten Nachbarn: Dort ist die Mine.
- Hat eine Zahl schon alle ihre Minen mit Fahnen, sind ihre übrigen Nachbarn sicher.
- Fang an den Rändern einer offenen Fläche an. Dort gibt es die meisten Hinweise.
"""#
}
