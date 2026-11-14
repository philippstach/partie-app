// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/irrgang.md. Nicht von Hand ändern.
enum RegelWissenText_irrgang {
    static let quelle = #"""
## Ziel
Stichwörter: Labyrinth, Irrgarten, Spielziel, Start, Ausgang, Ecke, Größe, Stufe, Punktelauf, gewinnen, verlieren
Du startest in der Ecke links oben, der Ausgang liegt rechts unten. Du sammelst auf dem Weg Funken und bekommst Punkte für jede geschaffte Stufe. Es gibt keinen Sieg und keine Niederlage, es ist ein Punktelauf: Du gehst von Stufe zu Stufe, bis du den Lauf selbst beendest. Mit jeder Stufe wird das Labyrinth größer. Stufe 1 ist 6 Felder breit und 8 hoch (6 × 8), Stufe 2 ist 7 × 9, Stufe 3 ist 8 × 10, und so weiter bis Stufe 14 mit 19 × 21. Höhere Stufen bleiben bei 19 × 21. In der App heißt das Spiel „Labyrinth“.

## Ablauf und Laufen
Stichwörter: wischen, Wisch, steuern, laufen, Läufer, Figur, Wand, Abzweigung, abbiegen, weiter, nächste Stufe
Wische in eine Richtung (hoch, runter, links, rechts). Dein Läufer geht dann geradeaus und hält an, wenn er vor einer Wand steht, an einer Abzweigung ankommt, einen Funken einsammelt oder den Ausgang erreicht. Er biegt nie von allein ab. Ein Wisch gegen eine Wand bewegt nichts. Die Wische gelten auf der ganzen Fläche. Erreichst du den Ausgang, bekommst du die Punkte der Stufe, und mit „Weiter zu Stufe N“ geht es zur nächsten. Vorher kannst du nicht weiterlaufen. Das Labyrinth hat keine Schleifen, jedes Feld ist auf genau einem Weg erreichbar.

## Funken
Stichwörter: Sterne, einsammeln, Bonus, Sackgasse, Schatz, sammeln, Anzeige
Funken liegen in Sackgassen, nie am Start und nie am Ausgang. Jeder Funke bringt 50 Punkte. Auf Stufe 1 liegen bis zu 4 Funken, dann je Stufe einer mehr (Stufe 5: 8), ab Stufe 7 sind es bis zu 10. Die Zahl ist 3 + Stufe, höchstens 10, und kann kleiner sein, wenn das Labyrinth nicht genug Sackgassen hat. Oben zeigt die Leiste, wie viele du schon hast und wie viele es gibt, zum Beispiel 2/6. Nimmst du einen Zug zurück, liegt ein eben eingesammelter Funke wieder da.

## Punkte einer Stufe
Stichwörter: Wertung, Punktzahl, berechnen, Bonus, Schritte, kürzester Weg, Effizienz, Beispiel, Grundwert
Beim Erreichen des Ausgangs zählt: 100 × Stufe, plus 50 je Funke, plus ein Wegbonus. Der Bonus ist bis zu 100 × Stufe groß. Er sinkt, je mehr Schritte du über den kürzesten Weg vom Start zum Ausgang hinausgehst. Er ist 0, wenn du doppelt so viele Schritte mehr gebraucht hast, wie der kürzeste Weg lang ist. Beispiel Stufe 3: Kürzester Weg 20, du brauchst 30 Schritte, 2 Funken. Der Anteil ist 1 − 10/40 = 0,75. Punkte: 300 + 100 + 225 = 625. Beispiel Stufe 1, kürzester Weg 14, 14 Schritte, kein Funke: 100 + 0 + 100 = 200. Jedes Feld, das du läufst, zählt als 1 Schritt.

## Tipp und Zug zurück
Stichwörter: Hilfe, Hinweis, Richtung, Rückgängig, zurücknehmen, undo, Punktabzug, kostet
Der Tipp zeigt die Richtung des ersten Schritts auf dem kürzesten Weg zum Ausgang, ohne den Weg zu verraten. Jeder Tipp kostet 25 Punkte von deinem Punktestand, der Stand sinkt aber nie unter 0. Es gibt keine Obergrenze für Tipps. „Zug zurück“ nimmt den letzten Wisch zurück, auch mehrere nacheinander. Die Schrittzahl geht dabei nicht zurück: Der Umweg zählt für den Bonus weiter. Beide Knöpfe sind nur sichtbar, solange du den Ausgang noch nicht erreicht hast.

## Dunkel ab Stufe 4
Stichwörter: Nebel, Sicht, Laterne, Licht, sehen, dunkel, Sichtweite, Fackel
Ab Stufe 4 ist es dunkel. Du siehst nur die Felder um dich herum, wie ein Quadrat mit der Laterne in der Mitte: Auf den Stufen 4 bis 6 reicht die Sicht 5 Felder in jede Richtung, auf 7 bis 9 sind es 4, auf 10 bis 12 sind es 3, ab Stufe 13 sind es 2 Felder (weniger wird es nie). Felder, die du schon besucht hast, bleiben blass sichtbar. Ausgang und Funken siehst du nur im Licht oder auf besuchten Feldern.

## Lauf beenden, Tageslauf, Wertung
Stichwörter: aufhören, abbrechen, täglich, Tag, Serie, Bestleistung, Rekord, neue Partie, fortsetzen
„Lauf beenden“ im Menü ist kein Sieg. Es zählen deine Punkte und die geschafften Stufen, beides steht im Ende. Die Bestpunktzahl (Menü „Beste Punktzahl“) wird gemerkt, bei „Neue Bestleistung!“ im Ende. „Neue Partie“ beginnt wieder bei Stufe 1. Der Tageslauf gibt jedem am selben Tag dieselben Labyrinthe, Stufe für Stufe. Hast du darin mindestens 1 Stufe geschafft, zählt der Tag für die Serie auf der Karte „Tageslauf heute“. Die Partie wird gespeichert und lässt sich fortsetzen.

## Was die App anders macht als die übliche Regel
Stichwörter: üblich, normal, Unterschied, Besonderheit, Zeitlimit, Gleiten
In einem üblichen Irrgarten läufst du Feld für Feld und es gibt Sackgassen ohne Belohnung. Hier gleitest du bis zur nächsten Abzweigung, sammelst Funken in den Sackgassen und bekommst Punkte nach Weglänge. Es gibt kein Zeitlimit und keine Niederlage. Das Labyrinth hat keine Schleifen. Auf den Stufen 4 bis 6 ist die Sicht so groß (11 Felder breit), dass du auf den kleineren Labyrinthen fast alles siehst. Das Dunkel wirkt erst später richtig.
"""#
}
