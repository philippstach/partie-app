// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/herzensjagd.md. Nicht von Hand ändern.
enum RegelWissenText_herzensjagd {
    static let quelle = #"""
## Ziel und Karten
Stichwörter: Herzen, Pik-Dame, Punkte, Strafpunkte, Spielerzahl, vier Spieler, Trumpf, Karten, Ziel
Herzensjagd spielst du zu viert, auch allein gegen 3 Computer. Es gibt 52 Karten, jeder bekommt 13. Das Ass ist die höchste Karte, die 2 die niedrigste. Es gibt keinen Trumpf. Gesammelt werden Minuspunkte: Jedes Herz zählt 1 Punkt, die Pik-Dame 13 Punkte, alles andere 0. In einer Runde sind das zusammen 26 Punkte. Ziel: möglichst wenige Punkte haben. Du willst also keine Herzen und nicht die Pik-Dame in deinen Stichen. Das Spiel besteht aus mehreren Runden. Wer am Ende die wenigsten Punkte hat, gewinnt.

## Ablauf einer Runde
Stichwörter: Stich, Kreuz-Zwei, bedienen, Farbe zugeben, abwerfen, 13 Stiche, ausspielen, anspielen, wer gewinnt den Stich
Gespielt werden 13 Stiche. Die Runde beginnt mit der Kreuz-Zwei: Wer sie hat, spielt sie aus. In einem Stich legt jeder reihum eine Karte. Du musst die ausgespielte Farbe bedienen. Hast du sie nicht, wirfst du eine beliebige Karte ab. Den Stich gewinnt die höchste Karte der ausgespielten Farbe (Abwürfe in anderen Farben gewinnen nie). Der Gewinner nimmt die Karten, bekommt ihre Punkte und spielt als Nächster aus. Nach dem 13. Stich ist die Runde zu Ende. Die Punkte der Runde werden auf den Gesamtstand addiert.

## Regeln fürs Ausspielen
Stichwörter: erster Stich, Herzen anspielen, Herzen gesperrt, Herzen offen, nur Herzen, erlaubt, Punktkarten
Im ersten Stich darfst du, wenn du kein Kreuz hast, möglichst keine Punktkarten abwerfen: Herzen und die Pik-Dame sind dann nicht erlaubt, solange du andere Karten hast. Nur wenn du nur Punktkarten hast, darfst du sie abwerfen. Herzen darfst du nicht ausspielen (anspielen), bis Herzen „offen“ sind. Das passiert, sobald ein Herz gespielt wurde oder ein Stich mit der Pik-Dame abgeschlossen ist. Hast du nur Herzen auf der Hand, darfst du sie trotzdem ausspielen. Wenn du eine Farbe nicht hast, darfst du Herzen auch vor dem Öffnen abwerfen (außer im ersten Stich).

## Mondschuss und Spielende
Stichwörter: Mondschuss, Shoot the Moon, alle 26, Spielende, Ziel, 50, 75, 100, Gleichstand, Sieger
Holt ein Spieler in einer Runde alle 26 Punkte, ist das ein Mondschuss. Dann bekommt er 0 Punkte und jeder der anderen drei 26. Das Spielende hängt von der Option „Spielende bei“ ab: 50 (Standard), 75 oder 100 Punkte. Sobald nach einer Runde mindestens ein Spieler diese Punktzahl oder mehr hat, endet das Spiel. Wer dann die wenigsten Punkte hat, gewinnt. Bei Gleichstand teilen sich die Spieler den Platz. Beispiel: Ziel 50, Stand 30, 40, 10, 20. Spieler 3 gelingt der Mondschuss: Neuer Stand 56, 66, 10, 46. Das Spiel ist zu Ende, Spieler 3 gewinnt mit 10.

## Karten weitergeben
Stichwörter: weitergeben, schieben, tauschen, links, rechts, gegenüber, Richtung, Runde 4, Option
Die Option „Drei Karten weitergeben“ ist in der App standardmäßig eingeschaltet. Vor jeder Runde wählt jeder Spieler 3 Karten aus und gibt sie weiter: in Runde 1 nach links (zum nächsten Spieler in der Reihenfolge), in Runde 2 nach rechts, in Runde 3 nach gegenüber, in Runde 4 gar nicht. Ab Runde 5 beginnt es wieder mit links. Die Spieler wählen nacheinander und bestätigen mit „Weitergeben“. Erst wenn alle bestätigt haben, wird getauscht. Danach beginnt der Spieler, der jetzt die Kreuz-Zwei hat. Computer geben Pik-Dame, Pik-König und Pik-Ass weiter, dann hohe Herzen, dann hohe Karten. Ist die Option aus, wird nie weitergegeben.

## Begriffe und Beispiele
Stichwörter: Beispiel, rechnen, Begriffe, Stich Beispiel, Punkte ausrechnen
Stich: die 4 Karten, die einmal reihum gespielt werden. Bedienen: die ausgespielte Farbe zugeben. Abwerfen: eine andere Farbe legen. Beispiel Stich: Spieler 1 spielt Karo 7, Spieler 2 Karo 10, Spieler 3 hat kein Karo und wirft Herz 4, Spieler 4 spielt Karo Dame. Karo Dame ist die höchste Karo-Karte: Spieler 4 gewinnt den Stich, bekommt 1 Punkt und spielt aus. Beispiel Stich mit Pik-Dame: Herz 4, Herz 9 und Pik-Dame in einem Stich sind 1 + 1 + 13 = 15 Punkte. Beispiel Runde: Anna hat die Pik-Dame und 4 Herzen (17), Ben 9 Herzen (9), Cem und Dora 0. Zusammen sind es 26.

## Bedienung in der App
Stichwörter: Bedienung, tippen, Knopf, Tipp, Computer, Stärke, Übergabe, Weitergeben
Gespielt werden kann nur eine erlaubte Karte, die anderen sind abgedunkelt. Tippe die Karte an, um sie zu spielen. Zu Beginn jeder Weitergabe tippst du 3 Karten an und dann „Weitergeben“. Die Anzeige oben zeigt den Gesamtstand und den Rundenstand („+ …“). Der „Tipp“ zeigt die Karte, die der stärkste Computer spielen würde. Im Menü „Mehr“ stellst du die Stärke der Computer ein. Spielen mehrere Menschen an einem Gerät, erscheint vor jedem Zug eine Übergabeseite, damit die Hand geheim bleibt.

## Was die App anders macht
Stichwörter: anders, Abweichung, übliche Regel, Pik-Dame öffnet, Unterschied
Herzen werden auch geöffnet, wenn nur die Pik-Dame gefallen ist. Im ersten Stich sind bei fehlendem Kreuz Herzen und die Pik-Dame nicht erlaubt, solange andere Karten da sind. Die Weitergabe-Reihenfolge ist fest (links, rechts, gegenüber, keine). Beim Mondschuss bekommt der Schütze 0 und jeder andere 26 Punkte. Das Spielende ist an eine Zielpunktzahl gebunden (50, 75 oder 100), nicht an eine feste Rundenzahl. Es gibt immer genau 4 Spieler.
"""#
}
