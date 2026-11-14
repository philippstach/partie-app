// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/galgenmaennchen.md. Nicht von Hand ändern.
enum RegelWissenText_galgenmaennchen {
    static let quelle = #"""
## Ziel und Ablauf
Stichwörter: Hangman, Galgenraten, Buchstaben raten, Wort, Ballons, Fehler, Striche, verlieren, gewinnen
Ein Wort ist gesucht, du siehst nur Striche (_) für die Buchstaben. Leerzeichen und Bindestriche in mehrteiligen Wörtern stehen von Anfang an offen. Du tippst auf der Tastatur einen Buchstaben. Kommt er im Wort vor, werden alle Stellen aufgedeckt. Kommt er nicht vor, platzt ein Ballon. Du hast 8 Ballons. Sind alle 8 geplatzt, ist die Runde verloren, und das Wort wird gezeigt. Sind alle Buchstaben aufgedeckt, hast du gewonnen. Ein schon getippter Buchstabe kostet nichts. Am iPad mit Tastatur tippst du die Buchstaben direkt.

## Lösen und Hinweise
Stichwörter: ganzes Wort raten, Tipp, Hilfe, Vokal, Kinder, Kinderleicht, Strafe
Mit „Lösen“ rätst du das ganze Wort. Es ist richtig, wenn es genau stimmt (Groß- und Kleinschreibung egal, ß zählt als ss). Ein richtiges Lösen gewinnt sofort. Ein falsches Lösen kostet 2 Ballons. Denselben falschen Versuch noch einmal zu wählen kostet nichts („Das hast du schon versucht“). „Hinweis“ deckt einen Buchstaben auf, nach Wahl: „Beliebiger Buchstabe“, „Erster Buchstabe“ oder „Ein Vokal“. Du hast 2 Hinweise je Runde (4 bei „Kinderleicht“). Ein Hinweis kostet keinen Ballon, geht aber nur, wenn noch mindestens 2 verschiedene Buchstaben verdeckt sind. Hinweise zählen bei Party-Punkten und beim Überleben-Bonus.

## Spielarten allein
Stichwörter: Einzelspiel, allein, Tagesrätsel, Wort des Tages, Thema, Kategorie, Sprache, eigene Wortliste, Stufe, schwer
Freies Spiel: Du wählst Wörter auf (Deutsch, English, Español, Français), ein Thema (oder Alle) und die Stufe Leicht, Mittel oder Schwer (Standard Mittel). „Kinderleicht“ nimmt nur leichte Wörter und gibt 4 Hinweise. Wort des Tages: Ein Wort pro Tag, für alle gleich. Es kommt aus den Stufen Leicht und Mittel. Du hast einen Versuch pro Tag und Sprache; danach heißt es „Morgen gibt es ein neues Wort“. Siegestage hintereinander zählen als Serie, das Ergebnis lässt sich teilen. Eigene Wörter: Du legst eine eigene Wortliste an (zum Beispiel für Familie oder Schule), mit freiem Hinweis. Die App zieht daraus ein Wort. Ein Wort braucht 3 bis 20 Buchstaben und darf nur Buchstaben, Leerzeichen und Bindestrich enthalten.

## Überleben
Stichwörter: Leben, Serie, Survival, immer schwerer, Bonus
Du startest mit 3 Leben. Jedes Wort ist eine normale Runde mit 8 Ballons. Verlierst du ein Wort, verlierst du ein Leben. Löst du ein Wort mit höchstens 1 Fehler und ohne Hinweis, bekommst du ein Leben zurück, aber nie mehr als 5. Die Stufe steigt: Die ersten 3 Wörter sind leicht, die nächsten 4 mittel, danach nur noch schwer. Gezählt werden gelöste Wörter. Sind alle Leben weg, endet Überleben. Es gibt kein Thema zu wählen.

## Party mit 2 bis 4 Personen
Stichwörter: mehrere Spieler, Wortgeber, Rater, Runden, reihum, zu zweit
Mit 2 bis 4 Spielern spielt ihr Party: reihum rät einer. Standard: Wörter selbst ausdenken. In Runde 1 rät Spieler 1, in Runde 2 Spieler 2 und so weiter. Das Wort denkt sich jeweils der nächste Spieler nach dem Rater aus (bei 2 Spielern der andere). Das Gerät wird übergeben, der Rater schaut nicht hin. Das Wort hat 3 bis 20 Buchstaben, dazu ein Hinweis (höchstens 30 Zeichen). Alternativ zieht die App die Wörter, mit Thema und Stufe. Runden je Spieler: 1 bis 5, Standard 2. Bei 3 Spielern und 2 Runden sind es 6 Runden.

## Party-Punkte
Stichwörter: Punkte, Wertung, Rangliste, Platz, Sieger, Rechnung
Der Rater bekommt, wenn er gewinnt: 2 + übrige Ballons − benutzte Hinweise, mindestens 1 Punkt. Verliert er, bekommt er 0. Bei eigenen Wörtern bekommt der Wortgeber 3 Punkte, wenn der Rater verliert. Beispiel: Rater löst mit 2 Fehlern und 1 Hinweis: 2 + (8 − 2) − 1 = 7. Ohne Fehler und ohne Hinweis: 2 + 8 = 10. Ein falsches Lösen zählt 2 Fehler. Nach der letzten Runde gewinnt, wer die meisten Punkte hat. Bei Gleichstand gibt es denselben Platz (1, 1, 3).

## Beispiele
Stichwörter: Beispiel, Rechnung
Beispiel Ballons: Wort KATZE, du tippst E (Treffer, 1 Stelle), X (Fehler, noch 7 Ballons), dann lösen mit „Hund“ (falsch): 2 weitere Ballons, noch 5. Beispiel Hinweis: Sind bei KATZE nur noch Z und E verdeckt: Ein Hinweis geht noch. Fehlt nur noch das Z, gibt es keinen Hinweis mehr. Beispiel Überleben: 3 Leben, du verlierst ein Wort (2 Leben), löst das nächste mit 1 Fehler ohne Hinweis (3 Leben), das übernächste mit 3 Fehlern (3 Leben bleiben).

## Begriffe und Umgangssprache
Stichwörter: Rater, Wortgeber, Treffer, Umlaut, ß
„Hangman“ oder „Galgenraten“ heißt dasselbe Spiel; in der App platzen Ballons statt eines Galgens. „Rater“ ist, wer rät, „Wortgeber“ wer sich das Wort ausdenkt. „Treffer“ ist ein Buchstabe im Wort, „Fehler“ ein Buchstabe, der nicht vorkommt. „Lösen“ heißt das ganze Wort raten. „Wort des Tages“ ist das tägliche Rätsel. Umlaute Ä, Ö, Ü sind eigene Buchstaben (eigene Tasten), ß wird zu ss.

## Was die App anders macht als die übliche Regel
Stichwörter: Galgen, Strichmännchen, Unterschied, Variante
Statt Galgen und Strichmännchen platzen 8 Ballons. Die App gibt Hinweise (2, bei Kinderleicht 4), die keinen Ballon kosten. Lösen kostet bei Fehler 2 Ballons. Neu sind Wort des Tages, Überleben, eigene Wortlisten und Party mit Punkten (2 bis 4 Spieler). Es gibt vier Wortsprachen unabhängig von der App-Sprache. Wörter wiederholen sich nicht, solange es frische gibt (die letzten 200 pro Sprache werden vermieden).
"""#
}
