// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/koenigsweg.md. Nicht von Hand ändern.
enum RegelWissenText_koenigsweg {
    static let quelle = #"""
## Ziel und Überblick
Stichwörter: Spielziel, gewinnen, Steine, Vorrat, draußen, Ur, Rennspiel, wie viele Felder, Spieleranzahl
Königsweg ist ein Rennspiel für 2 Spieler nach dem alten Spiel von Ur. Jeder hat 7 Steine. Sie liegen am Anfang im Vorrat. Du bringst alle 7 Steine über einen Weg von 14 Feldern bis hinaus. Wer als Erster alle 7 Steine draußen hat, gewinnt. Gewürfelt wird mit 4 Münzen. Die App zählt bei jedem Spieler „Vorrat“ (noch nicht gesetzte Steine) und „draußen“ (fertige Steine).

## Münzwurf
Stichwörter: Münzen, würfeln, werfen, Wahrscheinlichkeit, Null, Chance, aussetzen, echte Münzen, eintippen
Du wirfst 4 Münzen. Jede Münze mit Punkt zählt 1 Schritt, also ergibt der Wurf 0, 1, 2, 3 oder 4. Die Chancen sind 0: 1 von 16 (6 %), 1: 4 von 16 (25 %), 2: 6 von 16 (37,5 %), 3: 4 von 16 (25 %), 4: 1 von 16 (6 %). Eine 2 ist am häufigsten. Bei einer 0 („Null – ausgesetzt“) ist der Gegner dran. Bei „Virtuell“ wirft die App („Münzen werfen“), bei „Echt“ wirfst du am Tisch und tippst die Zahl der Münzen mit Punkt (0 bis 4) ein: „Wie viele Münzen zeigen den Punkt?“.

## Ziehen
Stichwörter: ziehen, setzen, Stein, Zugzwang, passen, Ausgang, genau, rauskommen, Neuer Stein, Tipp, kein Zug
Mit dem Wurf ziehst du genau einen Stein um so viele Felder weiter. Ein Stein aus dem Vorrat kommt auf Feld 1 bis 4 (Knopf „Neuer Stein“, Feld = Wurf). Einen Stein auf dem Brett tippst du an. Du musst ziehen, wenn ein Zug möglich ist, passen geht nicht. Gibt es keinen Zug, steht „Kein Zug möglich“ und der Gegner ist dran. Du darfst nicht auf ein Feld, auf dem schon ein eigener Stein steht (Vorrat und draußen sind ausgenommen). Der Weg hat die Felder 1 bis 14, danach kommt das Ausgangsfeld 15 („draußen“). Raus kommst du nur mit genau passender Zahl: Von Feld 13 brauchst du 2, von Feld 14 eine 1. Zu große Würfe sind nicht erlaubt. Der „Tipp“-Knopf zeigt den besten Zug nach Meinung des starken Computers.

## Gemeinsamer Streifen und Schlagen
Stichwörter: schlagen, rauswerfen, geschlagen, Mitte, gemeinsame Felder, sicher, Vorrat zurück
Die Felder 1 bis 4 und 13 bis 14 gehören jedem allein, dort stehen nur die eigenen Steine. Die Felder 5 bis 12 in der Mitte sind gemeinsam. Landest du dort auf einem gegnerischen Stein, wird er geschlagen: Er geht zurück in den Vorrat seines Besitzers, die App meldet „Stein geschlagen!“. Dein Stein bleibt auf dem Feld. Die mittlere Rosette (Feld 8) liegt im gemeinsamen Streifen und ist sicher: Steht dort ein gegnerischer Stein, darfst du nicht auf Feld 8 ziehen, er kann also nicht geschlagen werden.

## Rosetten und Extrazug
Stichwörter: Rosette, Blume, nochmal, Extrazug, Bonus, Feld 4, Feld 8, Feld 14, sicheres Feld
Rosettenfelder sind 4, 8 und 14 (Blume/Funkel-Symbol). Landest du mit einem Zug auf einer Rosette, hast du einen Extrazug: Du wirfst nochmal, die App meldet „Rosette – nochmal!“. Feld 8 in der Mitte ist zusätzlich ein sicheres Feld. Beim Ausgang (Feld 15) gibt es keinen Extrazug, und ein Schlag allein gibt auch keinen. Ein Beispiel: Dein Stein steht auf Feld 2, du wirfst 2: Er geht auf Feld 4 (Rosette), du wirfst sofort nochmal. Beispiel Schlagen: Dein Stein auf Feld 5, Gegner-Stein auf Feld 7, du wirfst 2: Er wird geschlagen, du stehst auf 7 und der Gegner ist dran.

## Sieg und Bedienung
Stichwörter: Ende, Sieger, Ergebnis, Zug zurück, rückgängig, Computer, Stärke, leicht, schwer, Menü, neue Partie
Wer alle 7 Steine auf Feld 15 hat, gewinnt sofort. Das Ergebnis zeigt „7“ für den Sieger und die Zahl der fertigen Steine des Verlierers. Mit „Zug zurück“ nimmst du den letzten Steinzug zurück, solange noch nicht neu geworfen wurde; der Wurf bleibt dann stehen. Einen Münzwurf selbst nimmst du nie zurück. Gegen den Computer geht das praktisch nur nach einer Rosette. Im Menü „Mehr“: „Neue Partie“ und „Spiel beenden“. Der Computer wirft und zieht selbst. Die Stärke wählst du im Neues-Spiel-Blatt: Leicht (zufälliger Zug), Mittel (Standard), Schwer.

## Begriffe und Sonderfälle
Stichwörter: Begriffe, Bedeutung, Vorrat, draußen, geschlagener Stein, Sonderfall, wer beginnt
Vorrat: Steine, die noch nicht auf dem Brett sind (auch geschlagene). Draußen: Steine auf Feld 15. Schlagen: gegnerischen Stein im gemeinsamen Streifen zurückschicken. Rosette: Feld 4, 8 oder 14. Ein geschlagener Stein muss ganz neu beginnen, er kommt mit einem Wurf wieder auf Feld 1 bis 4. Ist dein Zielfeld von einem eigenen Stein besetzt, ist dieser Zug nicht erlaubt, auch wenn er der einzige wäre. Wer beginnt, wählst du vor dem Start in der Karte „Wer beginnt“: „Abwechselnd“ (in der nächsten Partie beginnt der andere), der erste Spieler (gegen den Computer „Ich“) oder der zweite (der Computer). Standard ist der erste Spieler.

## Was die App anders macht als die übliche Regel
Stichwörter: Variante, anders, üblich, Unterschied, Hausregel
Die App spielt das Ur-Spiel mit 7 Steinen, 14 Feldern und 4 Münzen (0 bis 4). Das Schlagen gilt auf den Feldern 5 bis 12 (der gemeinsamen Mitte), die Rosetten sind 4, 8 und 14. Die Mittelrosette schützt, und kein Stein darf auf ein besetztes Feld 8 ziehen. Es gibt keine Varianten: Das Ausgangsfeld verlangt immer die genaue Zahl.
"""#
}
