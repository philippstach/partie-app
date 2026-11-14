// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/yacht.md. Nicht von Hand ändern.
enum RegelWissenText_yacht {
    static let quelle = #"""
## Ziel und Ablauf
Stichwörter: Spielablauf, Zug, würfeln, Würfe, halten, behalten, streichen, Runde, Spielende, wer gewinnt, Solo, Rekord
Yacht ist ein Würfelspiel für 1 bis 4 Personen mit 5 Würfeln. Du füllst eine Wertungstabelle. Jedes Feld darfst du nur einmal benutzen. Wer am Ende die meisten Punkte hat, gewinnt. Allein spielst du auf Punkte und gegen deinen Rekord.

Ein Zug besteht aus bis zu 3 Würfen. Der erste Wurf nimmt alle 5 Würfel. Danach tippst du die Würfel an, die du behalten willst. Nur die anderen werden neu geworfen. Das darfst du nach dem ersten und nach dem zweiten Wurf tun. Gehaltene Würfel bleiben für den nächsten Wurf gehalten, bis du sie wieder antippst (Einstellung „Gehaltene Würfel bleiben liegen“, Standard an). Nach dem letzten Wurf, oder früher, wenn du zufrieden bist, wählst du ein freies Feld. Passt nichts, streichst du ein freies Feld: Es bekommt 0 Punkte und ist verbraucht. Die App fragt vor dem Streichen noch einmal nach. Danach ist die nächste Person dran. Die Partie endet, wenn alle ihre Felder gefüllt haben: nach 13 Runden (Klassisch), 15 (Yatzy) oder 11 (Original-Yacht).

## Felder Klassisch
Stichwörter: Klassisch, Kniffel, Punkte, Full House, Straße, Pasch, Chance, Einser, Zweier, Dreier, Vierer, Fünfer, Sechser, Wertung, wie viel
Klassisch hat 13 Felder. Oben: Einser bis Sechser. Du zählst alle Würfel mit dieser Augenzahl zusammen. Drei Vierer ergeben im Vierer-Feld 12.
Unten: Dreierpasch (mindestens 3 gleiche, Summe aller 5 Würfel), Viererpasch (mindestens 4 gleiche, Summe aller 5 Würfel), Full House (3 gleiche und 2 gleiche, 25 Punkte), Kleine Straße (4 aufeinanderfolgende Zahlen, 30 Punkte), Große Straße (5 aufeinanderfolgende, 40 Punkte), Yacht (5 gleiche, 50 Punkte) und Chance (Summe aller Würfel, immer erlaubt).
Das Feld „Yacht“ heißt im Code „kniffel“. Es ist dasselbe Feld.
Fünf gleiche Würfel sind kein Full House: Ohne Joker bringt das Full-House-Feld dafür 0. Dagegen zählen 5 gleiche als Dreierpasch und als Viererpasch.

## Felder Yatzy
Stichwörter: Yatzy, skandinavisch, Paar, zwei Paare, 15 Felder, Punkte, Straße
Yatzy hat 15 Felder: Einser bis Sechser, Ein Paar, Zwei Paare, Dreierpasch, Viererpasch, Kleine Straße, Große Straße, Full House, Chance und Yatzy (fünf gleiche, 50 Punkte).
Ein Paar: zwei gleiche, es zählen nur diese zwei Würfel, bei mehreren Paaren das höchste. Zwei Paare: zwei verschiedene Paare, Summe der vier Würfel. Dreierpasch: Summe nur der drei gleichen. Viererpasch: Summe nur der vier gleichen. Full House: Summe aller 5 Würfel. Kleine Straße ist nur 1-2-3-4-5 und bringt 15. Große Straße ist nur 2-3-4-5-6 und bringt 20. Chance ist die Summe aller Würfel.
Vier gleiche zählen nicht als „Zwei Paare“. Fünf gleiche bringen im Feld Ein Paar, Dreierpasch und Viererpasch Punkte, aber 0 bei Zwei Paare und Full House.

## Felder Original-Yacht
Stichwörter: Original, Original-Yacht, 11 Felder, ohne Chance, Punkte, Straße
Original-Yacht hat nur 11 Felder: Einser bis Sechser, Full House, Viererpasch, Kleine Straße, Große Straße und Yacht. Es gibt weder Chance noch Dreierpasch noch Bonus.
Full House bringt die Summe aller 5 Würfel. Viererpasch bringt vier mal die Augenzahl der vier gleichen Würfel, der fünfte Würfel zählt nicht. Kleine Straße ist 1-2-3-4-5 und Große Straße ist 2-3-4-5-6, beide bringen 30 Punkte. Yacht (fünf gleiche) bringt 50 Punkte.
Es gibt in dieser Wertung weder Joker noch Yacht-Bonus.

## Oberer Block und Bonus
Stichwörter: Bonus, 63, 35, 50, oben, oberer Block, Summe, Gesamtpunkte, ausrechnen
Der obere Block sind Einser bis Sechser. Erreichst du dort die Schwelle, bekommst du einen Bonus. Klassisch: ab 63 Punkten gibt es 35 Bonus. Yatzy: ab 63 Punkten gibt es 50 Bonus. Original-Yacht: kein Bonus.
63 Punkte schaffst du zum Beispiel mit je drei Würfeln jeder Augenzahl: 3 + 6 + 9 + 12 + 15 + 18 = 63. Der Bonus wird erst bei der Summe addiert.
Rechenbeispiel Klassisch: oben 64, dazu 35 Bonus, unten 100. Das sind 199 Punkte.
Die Schwelle und der Bonus lassen sich nicht einzeln einstellen. Sie folgen der gewählten Wertung.

## Joker (nur Klassisch, Zusatzregel)
Stichwörter: Joker, zweites Yacht, zweiter Kniffel, Zwang, Zusatzregel, Variante
Der Joker ist aus, solange du ihn oder den Yacht-Bonus nicht vor dem ersten Wurf einschaltest. Mit dem Yacht-Bonus ist der Joker automatisch an und lässt sich nicht ausschalten. Er gilt nur bei Klassisch.
Er greift, wenn du ein Yacht würfelst und dein Yacht-Feld schon belegt ist. Auch ein gestrichenes Yacht-Feld mit 0 zählt als belegt. Dann gilt: Ist das obere Feld dieser Augenzahl frei, musst du es nehmen. Sonst nimmst du ein freies unteres Feld. Full House zählt dann 25, Kleine Straße 30 und Große Straße 40, auch wenn die Würfel das nicht hergeben. Sind alle unteren Felder belegt, darfst du ein freies oberes Feld nehmen.
Ist das Yacht-Feld noch frei, gibt es keinen Joker. Dann darfst du jedes freie Feld wählen.
Beispiel: Dein Yacht-Feld zeigt 50. Du würfelst 4-4-4-4-4. Ist das Vierer-Feld frei, musst du es nehmen: 20 Punkte. Ist es belegt, kannst du zum Beispiel Große Straße mit 40 Punkten wählen.

## Yacht-Bonus (nur Klassisch, Zusatzregel)
Stichwörter: Bonus, 100 Punkte, weiteres Yacht, Zusatzregel, Variante
Mit dem Yacht-Bonus bekommst du 100 Punkte für jedes weitere Yacht, das du nach einem Yacht mit 50 Punkten per Joker einträgst. Hast du im Yacht-Feld 0 stehen, gibt es keinen Bonus. Das Feld mit dem Bonus erscheint als eigene Zeile „Yacht-Bonus“ im Block.
Wichtig: Der Bonus wirkt nur zusammen mit dem Joker. Schaltest du den Yacht-Bonus ein, schaltet die App den Joker automatisch mit ein; der Joker-Schalter ist dann gesperrt.
Beispiel mit Joker und Bonus: Yacht-Feld 50, du würfelst 6-6-6-6-6 und trägst im Sechser-Feld ein. Das Feld bekommt 30 Punkte, dazu kommen 100 Bonus.

## Regeln einstellen und Bedienung
Stichwörter: einstellen, Optionen, Menü, Wertung wechseln, echte Würfel, eintippen, Tipp, rückgängig, korrigieren, Bedienung
Die Wertung und die Zusatzregeln stellst du vor dem ersten Wurf ein: im Menü (drei Punkte) „Wertung und Regeln ändern“, dort „Wertung“ mit Klassisch, Yatzy oder Original-Yacht, bei Klassisch zusätzlich „Joker“ und „Yacht-Bonus (100 Punkte)“. Mit „Übernehmen“ gilt die Wahl, sie wird für die nächste Partie gemerkt. Sobald der erste Wurf gefallen ist, lässt sich die Wertung nicht mehr ändern.
Beim Start wählst du außerdem „Echte Würfel“: Du würfelst am Tisch und tippst nach jedem Wurf die Augen ein. Mit „Wurf korrigieren“ kannst du dich vertippen. Echte Würfel gehen nicht mit Computergegnern.
Der Knopf „Tipp“ zeigt, welche Würfel du halten oder welches Feld du nehmen solltest. Im Menü findest du „Regeln“ und „Spielverlauf“. Mit „Letzten Eintrag zurücknehmen“ machst du das Eintragen rückgängig, solange nicht der nächste Wurf folgt.

## Computer, Tageswürfel, Ende
Stichwörter: Computer, Stufe, leicht, schwer, Tageswürfel, Serie, Rekord, Gleichstand, Platz, Gegner
Der Computer hat drei Stufen. Leicht hält meist gleiche Würfel und macht Fehler. Mittel spielt jeden Schritt zur Hälfte klug, zur Hälfte wie leicht. Schwer spielt immer mit dem besten Rat.
Tageswürfel: Die Würfel kommen für jeden Tag aus einer festen Folge, für alle gleich. Du spielst allein mit App-Würfeln. Die Partie zählt für die Serie, nicht als Rekord.
Ende: Es gewinnt die höchste Gesamtsumme. Gleich viele Punkte teilen sich den Platz. Allein gibt es keinen Sieg, nur Punkte. Der Rekord wird je Wertung gespeichert. Die erste Partie einer Wertung zählt noch nicht als „Neuer Rekord“.

## Beispiele mit Rechnung
Stichwörter: Beispiel, rechnen, ausrechnen, wie viele Punkte
Klassisch: 3-3-3-5-5. Full House 25, Dreierpasch 19 (9 + 10), Chance 19, Dreier-Feld 9, Fünfer-Feld 10, Viererpasch 0.
Klassisch: 2-3-4-5-6. Große Straße 40, Kleine Straße 30, Chance 20. Beim Wurf 1-2-3-4-6 gibt es Kleine Straße 30 und Große Straße 0.
Klassisch: 4-4-4-4-2. Viererpasch 18 und Dreierpasch 18. Dieselben Würfel in Yatzy: Viererpasch 16, Dreierpasch 12 (3 mal 4). In Original-Yacht: Viererpasch 16.
Yatzy: 6-6-3-3-3. Ein Paar 12, Zwei Paare 18 (6+6+3+3), Dreierpasch 9, Full House 21, Chance 21.
Yatzy: 5-5-5-5-5. Yatzy 50, Ein Paar 10, Dreierpasch 15, Viererpasch 20, Chance 25, Zwei Paare 0, Full House 0.
Original-Yacht: 6-6-6-2-2. Full House 22. Wurf 3-3-3-3-6: Viererpasch 12.

## Begriffe
Stichwörter: Begriff, Pasch, Kniffel, was heißt, streichen, halten
Pasch: mehrere gleiche Würfel. „Kniffel“ ist der übliche Name für Yacht (fünf gleiche); in der App heißt das Feld „Yacht“, bei Yatzy „Yatzy“. „Streichen“ heißt, ein Feld mit 0 Punkten zu belegen. „Halten“ heißt, Würfel beim nächsten Wurf liegen zu lassen. „Joker“ ist die Ausnahme beim zweiten Yacht. „Chance“ nimmt immer die Summe.

## Was die App anders macht als die übliche Regel
Stichwörter: anders, Abweichung, üblich, Unterschied, Hausregel, Kniffel-Regel
Das Feld heißt „Yacht“, nicht „Kniffel“. Im Klassisch-Block ist der Yacht-Bonus 100 Punkte und schaltet den Joker automatisch mit ein. Der Joker-Zwang entspricht der Kniffel-Regel: Das obere Feld zuerst. Yatzy hat die skandinavische Zählung mit Bonus 50 und Straßen 15 und 20. Die Original-Yacht der App hat 11 Felder ohne Chance und Dreierpasch, mit Straßen zu je 30 und Full House mit Summe. Der Viererpasch zählt in Yatzy und Original-Yacht nur die vier gleichen Würfel. Vier gleiche zählen in Yatzy nicht als zwei Paare. Das gilt, was die App rechnet.
"""#
}
