// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/siebzehnundvier.md. Nicht von Hand ändern.
enum RegelWissenText_siebzehnundvier {
    static let quelle = #"""
## Ziel und Karten
Stichwörter: Blackjack, 21, Kartenwerte, Ass, Bank, Spielerzahl, 32 Karten, Ziel
Du spielst gegen die Bank. Ziel: Du kommst mit deinen Karten näher an 21 als die Bank, ohne darüber zu kommen. Gespielt wird mit 32 Karten: 7, 8, 9, 10, Bube, Dame, König und Ass in vier Farben. Vor jeder Hand wird neu gemischt. Die Karten zählen: 7, 8, 9, 10 ihren Wert, Bube, Dame und König je 10, das Ass 11 oder 1. Die App wählt beim Ass automatisch den besten Wert: Wärst du mit 11 über 21, zählt es 1. Du darfst mit 1 bis 4 Personen spielen, auch mit Computer als Mitspieler. Jeder spielt für sich gegen die Bank.

## Ablauf einer Hand
Stichwörter: ziehen, Karte, halten, stehen bleiben, Bank zieht, 17, Siebzehn und Vier, Blackjack, verdeckt, Reihenfolge
Jeder Spieler und die Bank bekommen 2 Karten. Von der Bank liegt eine Karte offen, die zweite ist verdeckt. Die Spieler sind der Reihe nach dran. Du wählst „Karte“ (noch eine ziehen) oder „Halten“. Erreichst du 21 oder mehr, ist deine Hand automatisch zu Ende. Wer mit den ersten zwei Karten 21 hat, also Ass plus Zehnwert (10, Bube, Dame, König), hat „Siebzehn und Vier“ (Blackjack) und muss nicht mehr ziehen. Danach deckt die Bank auf und zieht Karten, bis sie mindestens 17 hat. Ein Ass zählt dabei 11 (Ass + 6 = 17, die Bank hält). Haben alle Spieler mehr als 21, zieht die Bank gar nicht. Hat die Bank mit ihren ersten zwei Karten Siebzehn und Vier, deckt sie sofort auf und rechnet ab: Wer selbst Siebzehn und Vier hat, spielt gleichauf, alle anderen verlieren ihren Einsatz, ohne noch zu ziehen.

## Gewinn, Verlust, Chips
Stichwörter: gewinnen, verlieren, Einsatz, auszahlen, 1,5, gleichauf, unentschieden, überkaufen, pleite, Chips
Vor jeder Hand setzt jeder den Einsatz. Du gewinnst den Einsatz, wenn die Bank über 21 kommt oder du bei höchstens 21 mehr hast als die Bank. Bei gleicher Summe ist es „gleichauf“, nichts passiert. Wer über 21 liegt, verliert immer, auch wenn die Bank ebenfalls überkauft. Siebzehn und Vier zahlt das 1,5-Fache des Einsatzes, abgerundet auf ganze Chips: bei Einsatz 10 sind das 15, bei 25 sind es 37, bei 50 sind es 75, bei 100 sind es 150. Hat die Bank selbst Siebzehn und Vier und du auch, ist es gleichauf. Alle anderen Hände verlieren; die Bank deckt dann sofort auf, und niemand zieht mehr. Die Bank hat unendlich viele Chips.

## Verdoppeln
Stichwörter: verdoppeln, Double, doppelter Einsatz, splitten, Versicherung, eine Karte
Mit genau deinen ersten zwei Karten darfst du „Verdoppeln“. Der Einsatz wird doppelt, du bekommst genau eine Karte, dann ist deine Hand zu Ende. Das geht nicht bei Siebzehn und Vier. Es geht nur, wenn deine Chips für den doppelten Einsatz reichen. Mit 100 Chips und Einsatz 50 darfst du verdoppeln, mit 100 Chips und Einsatz 100 nicht. Gewinnst du, bekommst du den doppelten Einsatz, verlierst du, zahlst du ihn. Beispiel: Einsatz 25, verdoppelt, gewonnen: +50, verloren: −50. Splitten (Paare teilen) und Versicherung gibt es nicht.

## Start-Chips, Einsatz und Spielende
Stichwörter: Start-Chips, Einsatz einstellen, 50, 100, 200, 500, Option, ausscheiden, Spielende, abschließen, Punkte allein
Optionen: Start-Chips 50, 100 (Standard), 200 oder 500. Einsatz je Hand 10 (Standard), 25, 50 oder 100. Du stellst beides im Blatt „Neues Spiel“ ein. Im Spiel änderst du den Einsatz im Menü „Mehr“ vor dem ersten Zug und zwischen den Händen. Die Start-Chips nur vor der ersten Entscheidung. Ist der Einsatz höher als die Start-Chips, gilt der höchste, der passt (bei 50 Chips und Einsatz 100 gilt 50). Wer weniger Chips hat als der Einsatz, spielt nicht mehr mit und scheidet aus (nicht erst bei 0 Chips; wird der Einsatz gesenkt, kann er wieder mitspielen). Zu mehreren endet das Spiel, wenn weniger als 2 Spieler mithalten können oder wenn du im Menü „Spiel abschließen“ wählst. Es gewinnt, wer die meisten Chips hat. Allein zählt der Chip-Stand als Punkte. Du hast verloren, wenn du den Einsatz nicht mehr zahlen kannst.

## Begriffe und Beispiele
Stichwörter: Beispiel, rechnen, überkauft, Ass zählt 1, Begriffe
„Karte“ heißt ziehen, „halten“ heißt stehen bleiben, „überkaufen“ heißt über 21 kommen. Beispiel 1: K + 5 + 9 = 24, überkauft, verloren. Beispiel 2: Ass + 6 = 17, dann eine 9: 11 + 6 + 9 = 26, das Ass zählt 1, es sind 16. Beispiel 3: Du hast 18, die Bank 17: Du gewinnst. Bank 24: Du gewinnst mit jeder Hand bis 21. Beispiel 4: Ass + König, Einsatz 25: Siebzehn und Vier, du bekommst 37 Chips dazu. Beispiel 5: Die Bank hat Ass + Zehnwert, du K + 7: Die Bank deckt sofort auf, du verlierst den Einsatz, ohne zu ziehen.

## Bedienung und Tipp
Stichwörter: Bedienung, Knopf, Tipp, Grundstrategie, Computer, nächste Hand
Die Knöpfe heißen „Tipp“, „Halten“, „Verdoppeln“ (nur wenn erlaubt) und „Karte“. Nach der Hand folgt „Nächste Hand“ oder „Ergebnis“. Der Tipp folgt einer einfachen Grundstrategie: Ab 17 halten. Zwischen 12 und 16 eine Karte, wenn die offene Bankkarte mindestens 7 zählt (Ass 11, Bilder 10), sonst halten. Computer-Mitspieler spielen genauso.

## Was die App anders macht
Stichwörter: anders, Abweichung, übliche Regel, weiche 17, abgerundet, Unterschied
Es gibt 32 statt 52 Karten und es wird jede Hand neu gemischt. Es gibt kein Teilen und keine Versicherung. Die Bank hält schon bei 17 mit Ass (weiche 17). Hat die Bank Siebzehn und Vier, deckt sie sofort auf, bevor jemand zieht. Siebzehn und Vier (Blackjack) gilt nur mit zwei Karten. Die 1,5-fache Auszahlung wird abgerundet. Wer weniger Chips hat als den Einsatz, scheidet aus.
"""#
}
