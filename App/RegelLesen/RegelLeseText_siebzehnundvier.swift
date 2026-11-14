// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/siebzehnundvier/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_siebzehnundvier {
    static let quelle = #"""
## Worum es geht

Du spielst gegen die Bank. Ziel ist, mit deinen Karten **näher an 21** zu kommen als die Bank, ohne über 21 zu geraten. Wer über 21 kommt, hat sich „überkauft“ und verliert sofort.

Gespielt wird um Chips. Jede Hand kostet einen Einsatz. Gewinnst du die Hand, bekommst du den Einsatz dazu, verlierst du, ist er weg.

Das Spiel ist auch als Blackjack bekannt. In der App wird mit 32 Karten gespielt.

## Was du brauchst

- **Spieler:** 1 bis 4, jeder Platz Mensch oder Computer. Jeder spielt für sich gegen die Bank, nicht gegen die anderen.
- **Karten:** 32 Karten, von der 7 bis zum Ass in vier Farben. Vor jeder Hand wird neu gemischt.
- **Chips:** Jeder startet mit 100 Chips. Wählbar sind 50, 100, 200 oder 500.

## Was die Karten zählen

| Karte | Wert |
|---|---|
|7, 8, 9, 10 | ihre Zahl |
|Bube, Dame, König | 10 |
|Ass | 11 oder 1 |

Das Ass zählt 11. Würdest du damit über 21 kommen, zählt es automatisch 1. Das rechnet die App für dich.

## Eine Hand

1. Jeder Spieler und die Bank bekommen **2 Karten**. Von der Bank liegt eine offen, die zweite verdeckt.
2. Die Spieler sind der Reihe nach dran, Platz 1 zuerst. Wer dran ist, wählt:
   - **Karte:** eine Karte mehr ziehen.
   - **Halten:** keine Karte mehr, die Hand ist fertig.
3. Du darfst so oft „Karte“ wählen, wie du willst. Bei 21 oder mehr ist deine Hand automatisch zu Ende.
4. Sind alle Spieler fertig, deckt die Bank ihre zweite Karte auf.
5. Die Bank **zieht, bis sie mindestens 17 hat**. Dann hält sie, auch wenn ein Ass als 11 dabei ist. Sind alle Spieler überkauft, zieht die Bank gar nicht.

## Siebzehn und Vier

Hast du mit den **ersten zwei Karten genau 21**, also ein Ass und eine Karte mit Wert 10, dann hast du „Siebzehn und Vier“. Das ist die beste Hand. Du musst nichts mehr tun und bekommst das 1,5-Fache deines Einsatzes, abgerundet auf ganze Chips. Hat die Bank mit ihren ersten zwei Karten Siebzehn und Vier, deckt sie sofort auf und rechnet ab: Wer selbst Siebzehn und Vier hat, spielt gleichauf, alle anderen verlieren ihren Einsatz, ohne noch zu ziehen.

Eine 21 aus drei oder mehr Karten ist nur eine gewöhnliche 21.

## Verdoppeln

Mit deinen ersten zwei Karten darfst du **verdoppeln**. Dann wird dein Einsatz für diese Hand doppelt so hoch. Du bekommst genau **eine** Karte, danach ist deine Hand fertig.

Verdoppeln geht nur, wenn deine Chips für den doppelten Einsatz reichen, und nicht bei Siebzehn und Vier.

## Wer gewinnt die Hand

Jeder Spieler wird für sich mit der Bank verglichen:

| Lage | Ergebnis |
|---|---|
|Du bist über 21 | verloren, auch wenn die Bank auch über 21 kommt |
|Du hast Siebzehn und Vier, die Bank nicht | gewonnen, 1,5-facher Einsatz |
|Ihr habt beide Siebzehn und Vier | gleichauf, keiner zahlt |
|Die Bank hat Siebzehn und Vier, du nicht | verloren; die Bank deckt sofort auf, du ziehst gar nicht erst |
|Die Bank ist über 21 | gewonnen |
|Du hast mehr als die Bank | gewonnen |
|Gleiche Summe | gleichauf, keiner zahlt |
|Du hast weniger als die Bank | verloren |

**Rechenbeispiel Siebzehn und Vier:** Einsatz 10 bringt 15 Chips, Einsatz 25 bringt 37 (abgerundet), Einsatz 50 bringt 75, Einsatz 100 bringt 150.

Die Bank hat unbegrenzt Chips. Teilen (Splitten), Versicherung und Aufgeben gibt es in der App nicht.

## Einsatz und Chips

Der Einsatz je Hand ist 10 Chips. Wählbar sind 10, 25, 50 oder 100.

- Vor dem Start wählst du Chips und Einsatz in der Karte „Neues Spiel“.
- Im Spiel änderst du den Einsatz unter „Mehr“ → „Einsatz je Hand“, vor dem ersten Zug oder zwischen zwei Händen.
- Die Start-Chips lassen sich unter „Mehr“ nur vor der ersten Entscheidung ändern. Dann wird neu ausgeteilt.
- Die App merkt sich beides für das nächste Spiel.

**Ausscheiden:** Wer weniger Chips hat, als ein Einsatz kostet, spielt keine Hand mehr mit. Wird der Einsatz gesenkt, kann er wieder einsteigen.

## Wie das Spiel endet

- **Zu mehreren:** Das Spiel endet, wenn weniger als zwei Spieler den Einsatz zahlen können. Wer die meisten Chips hat, ist Erster. Gleich viele Chips teilen sich den Platz.
- **Allein:** Das Spiel endet, wenn deine Chips nicht mehr für einen Einsatz reichen. Dein Chip-Stand zählt dann wie ein Punktestand.
- **Jederzeit:** Unter „Mehr“ → „Spiel abschließen“ beendest du das Spiel und siehst das Ergebnis. Das geht ab der ersten Entscheidung.

## Gegen den Computer

Der Computer spielt immer gleich, es gibt keine Stufen. Er nimmt bei 11 oder weniger immer eine Karte und hält ab 17. Dazwischen nimmt er eine Karte, wenn die offene Karte der Bank 7 oder mehr zeigt.

## So bedienst du das Spiel

- **Karte / Halten / Verdoppeln:** die Knöpfe unten. „Verdoppeln“ erscheint nur, wenn es erlaubt ist.
- **Tipp:** Die Glühbirne sagt dir, was die übliche Strategie jetzt rät, zum Beispiel „Halten – 18 ist stark genug“.
- Bei jedem Spieler stehen Chips, Einsatz und die Summe der Karten. Über 21 wird die Summe rot.
- Nach der Hand steht bei jedem „gewinnt“, „verliert“, „gleichauf“ oder „Siebzehn und Vier!“. Mit „Nächste Hand“ geht es weiter.
- **Pause:** Verlässt du das Spiel, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

Einen Zug zurücknehmen kannst du nicht.

## Kleine Tipps

- Bei 11 oder weniger kann nichts passieren: Nimm eine Karte.
- Ab 17 lieber halten.
- Zeigt die Bank eine niedrige Karte (7 oder 8), überkauft sie sich öfter. Dann reicht dir weniger.
- Verdoppeln lohnt sich, wenn du mit zwei Karten gut liegst und die Bank schwach aussieht.

## Begriffe

- **Bank:** der Gegner aller Spieler. Sie folgt festen Regeln.
- **Überkauft:** mehr als 21.
- **Siebzehn und Vier:** 21 mit den ersten zwei Karten (Ass und ein Zehner).
- **Halten:** keine Karte mehr nehmen.
- **Verdoppeln:** Einsatz verdoppeln, genau eine Karte.
- **Einsatz:** Chips, um die es in einer Hand geht.
"""#
}
