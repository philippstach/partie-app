// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/schwimmen.md. Nicht von Hand ändern.
enum RegelWissenText_schwimmen {
    static let quelle = #"""
## Ziel
Stichwörter: gewinnen, Leben, schwimmt, raus, Spieler, verlieren
Sammle in einer Farbe Karten, die zusammen möglichst nah an 31 Punkte kommen. In der Spielart „Leben“ (Standard) verliert in jeder Runde die Person mit der niedrigsten Hand ein Leben. Du startest mit 3 Leben (einstellbar auf 4). Wer 0 Leben hat, „schwimmt“. Verliert er dann noch einmal, ist er raus. Wer als Letzter übrig bleibt, gewinnt. Es spielen 2 bis 6 Personen, auch mit Computer. Die Spielart „Punkte (5 Runden)“ ist ein anderes Ziel (siehe Punktemodus).

## Austeilen und Zug
Stichwörter: anfangen, Karten, Tisch, tauschen, was darf ich, Ablauf
Gespielt wird mit 32 Karten (7 bis Ass in vier Farben). Jede Person bekommt 3 Karten auf die Hand, 3 Karten liegen offen in der Mitte (Tisch), der Rest ist der Stapel. Die erste Runde beginnt der erste Platz, danach rückt der Beginn jede Runde einen Platz weiter. Wer dran ist, macht genau eine Sache: eine Karte tauschen (eine Handkarte gegen eine Tischkarte), alle drei tauschen (deine drei Handkarten gegen die drei Tischkarten), schieben (nichts tauschen) oder klopfen. Die App zeigt vor dem Tausch eine Vorschau mit dem neuen Wert. Du tippst eine Hand- und eine Tischkarte an und dann „Tauschen“.

## Punkte zählen
Stichwörter: Wert, Ass, Bild, Farbe, wie viel, Summe, 31, Drei Gleiche
Es zählt nur die Farbe mit der höchsten Summe. Ass = 11, König, Dame und Bube je 10, 10 = 10, 7, 8 und 9 ihre Zahl. Beispiele: Herz-Ass, Herz-König, Herz-7 = 11 + 10 + 7 = 28. Kreuz-10, Kreuz-9, Herz-Ass: Kreuz 19, Herz 11, also zählt 19. Pik-7, Herz-8, Karo-9 haben keine gemeinsame Farbe: es zählt die höchste Einzelkarte, hier 9. Drei Karten gleichen Werts (zum Beispiel drei Neunen) zählen 30,5 (oder 30, wenn so eingestellt). Das höchste Blatt aus einer Farbe ist 31: Ass plus zwei Karten mit 10, zum Beispiel Kreuz-Ass, Kreuz-König, Kreuz-Dame.

## Schieben und Klopfen
Stichwörter: passen, aussetzen, Klopfrunde, letzte Runde, Tischkarten neu
Schieben: Du tauschst nichts. Haben alle, die noch im Spiel sind, nacheinander geschoben, werden die 3 Tischkarten durch 3 neue vom Stapel ersetzt (wenn noch mindestens 3 im Stapel sind). Mit der Einstellung „Höchstens einmal“ darf jede Person pro Runde nur 1-mal schieben. Dann musst du tauschen oder klopfen. Klopfen: Das geht nur, wenn in dieser Runde noch niemand geklopft hat, auch gleich im ersten Zug. Deine Hand bleibt, wie sie ist. Jede andere Person hat noch genau einen Zug (tauschen oder schieben, nicht klopfen), danach wird ausgewertet. Wer geklopft hat, spielt in dieser Runde nicht mehr.

## Feuer
Stichwörter: 31, 33, Sofortende, Runde sofort, drei Asse
Mit „31 beendet die Runde sofort“ (Standard) endet die Runde sofort, wenn jemand nach einem Tausch 31 hat. Wer schiebt oder klopft, löst kein Feuer aus. Das nennt man Feuer. Das passiert auch beim Austeilen, wenn schon jemand 31 hat (bei mehreren gilt der Erste in der Platzreihenfolge). In der Spielart Leben verlieren dann alle anderen je 1 Leben, wer 31 hat, verliert nichts. Im Punktemodus werden die Hände sofort gebucht. Ist die Einstellung aus, zählt 31 wie jede andere Hand und die Runde geht normal weiter. Mit „33 mit drei Assen“ sind drei Asse 33 und damit das beste Blatt; bei Feuer sofort beenden sie die Runde auch.

## Wertung der Runde (Leben)
Stichwörter: Leben verlieren, niedrigste Hand, Gleichstand, schwimmen
Nach der Klopfrunde (oder nach Feuer) werden alle Hände gezählt. Wer den niedrigsten Wert hat, verliert 1 Leben. Haben mehrere den gleichen niedrigsten Wert, verlieren alle diese je 1 Leben. Haben alle gleich viele Punkte, verliert niemand. Beispiel: Hände 28, 17 und 21: Wer 17 hat, verliert 1 Leben. Beispiel: 20, 20, 25: beide mit 20 verlieren je 1 Leben. Die Anzeige zeigt ♥ mit der Zahl der Leben, bei 0 „schwimmt“, bei einer weiteren Niederlage „raus“. Wer als Letzter übrig bleibt, gewinnt.

## Punktemodus
Stichwörter: Punkte, fünf Runden, Summe, Sieger, ohne Leben
In der Spielart „Punkte (5 Runden)“ gibt es keine Leben. Alle spielen genau 5 Runden. In jeder Runde bekommt jede Person die Punkte ihrer Hand gutgeschrieben (Σ), auch halbe Punkte. Beispiel: Hände mit 28, 30,5 und 17 Punkten schreiben diesen drei Personen in dieser Runde genau diese Punkte gut. Nach Runde 5 gewinnt die höchste Summe. Bei Gleichstand gewinnt, wer in der Reihenfolge am Tisch weiter vorn sitzt. Mit Feuer endet eine Runde sofort. Die Zahl der Runden lässt sich nicht ändern.

## Bedienung und Hausregeln
Stichwörter: einstellen, Optionen, Tipp, Menü, Knopf
Die Hausregeln stehen im Blatt „Neues Spiel“ (Karte „Hausregeln“), in der Partie unter „Mehr“ → „Hausregeln“. In der Partie lassen sie sich nur vor dem ersten Zug der ersten Runde ändern, dann wird neu ausgeteilt. Bei mehreren Menschen verdeckt ein Sichtschutz die Hand. Der Knopf „Tipp“ (Glühbirne) zeigt den besten Tausch oder rät zum Klopfen. Begriffe: Feuer = 31 mit sofortigem Rundenende. Schwimmen = 0 Leben. Tisch = die 3 offenen Karten. Hand = deine 3 Karten.

## Was die App anders macht als die übliche Regel
Stichwörter: abweichen, anders, üblich, Unterschied
Bei 31 (und mit der Einstellung bei drei Assen 33) endet die Runde sofort. Das lässt sich abschalten. Bei Gleichstand am unteren Ende verlieren alle Beteiligten ein Leben, haben alle gleich viel, verliert niemand. Schieben ist standardmäßig unbegrenzt oft erlaubt. Drei Gleiche zählen 30,5 (oder 30). Wer 0 Leben hat und noch einmal verliert, ist raus, es gibt kein weiteres Leben. Die Spielart „Punkte (5 Runden)“ mit genau 5 Runden und die Wahl von 3 oder 4 Leben sind Einstellungen der App. Beim Gleichstand in den Punkten gewinnt der frühere Platz.
"""#
}
