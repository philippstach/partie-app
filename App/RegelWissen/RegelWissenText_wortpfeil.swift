// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/wortpfeil.md. Nicht von Hand ändern.
enum RegelWissenText_wortpfeil {
    static let quelle = #"""
## Ziel
Stichwörter: Schwedenrätsel, Pfeilrätsel, Kreuzworträtsel, Spielziel, gelöst, Fragefeld, Pfeil, Aufgabe
Ein Kreuzworträtsel im Pfeilformat (Schwedenrätsel): Es gibt keine Zahlen. Die Fragen stehen in Feldern mitten im Gitter, den Fragefeldern. Der Pfeil im Fragefeld zeigt, wohin das Wort läuft, nach rechts oder nach unten. Das Wort beginnt im Feld direkt hinter dem Pfeil und geht bis zum nächsten Fragefeld oder Leerfeld oder bis zum Rand. Du füllst alle Buchstabenfelder richtig aus. Es gibt keinen Zeitdruck und keine Strafen. Das Rätsel ist gelöst, sobald alle Felder gefüllt und alle richtig sind. Ein Feld gehört meist zu einem waagerechten und einem senkrechten Wort.

## Beispiel
Stichwörter: Oma, Eis, Mini-Rätsel, zeigen, Muster
Im Mini-Rätsel der Regelseite steht links oben im Gitter ein Fragefeld „Großmutter“ mit Pfeil nach rechts. Dahinter stehen die Felder O, M, A, das Wort ist OMA. Ein zweites Fragefeld „Gefrorenes Wasser“ mit Pfeil nach unten ergibt E, I, S, also EIS. Ein Fragefeld kann zwei Fragen haben.

## Eintragen und Cursor
Stichwörter: schreiben, tippen, Feld, Richtung wechseln, waagerecht, senkrecht, nächste Frage, löschen, springen, Frageleiste
Tippe ein Buchstabenfeld oder ein Fragefeld an. Das zugehörige Wort wird markiert, und die ganze Frage steht in der Frageleiste unten, mit „gefüllt/Länge“, etwa 3/7. Tippst du dasselbe Feld nochmal, wechselt die Richtung, wenn dort zwei Wörter kreuzen. Auch Antippen der Frageleiste wechselt die Richtung. Mit den Pfeilen links und rechts der Leiste (oder Wischen darüber) springst du zur vorigen oder nächsten Frage, in Lesereihenfolge: Zeile für Zeile, rechts vor unten. Der Cursor ist klug: Nach einem Buchstaben geht er zum nächsten leeren Feld des Wortes. Ist das Wort voll, springt er zur nächsten Frage mit Lücke. Steht ein Wort schon voll da und du tippst, überschreibst du Buchstabe für Buchstabe. Löschen entfernt den Buchstaben im Feld, oder, wenn es leer ist, im Feld davor.

## Umlaute und Tastatur
Stichwörter: Ä, Ö, Ü, ß, AE, OE, UE, SS, Buchstabe, Tastatur, Sonderzeichen, Hardware-Tastatur
Wie in der Zeitschrift gilt: Ein Feld, ein Buchstabe. Ä wird AE, Ö wird OE, Ü wird UE, ß wird SS. Die Tasten Ä, Ö und Ü tragen daher zwei Felder ein. Das ß gibt es auf der eigenen Tastatur durch langes Drücken auf S, es wird SS. Passt der zweite Buchstabe nicht mehr ins Wort, fällt er weg. Die eigene Tastatur ist QWERTZ. Mit einer Hardware-Tastatur gehen die Pfeiltasten zum nächsten Buchstabenfeld, Tab zur nächsten Frage (mit Shift zur vorigen) und Entf löscht.

## Hilfen und Stern
Stichwörter: Hilfe, Tipp, aufdecken, prüfen, falsch, rot, verraten, Stern, ohne Hilfe, Glühbirne
Aufdecken zeigt den Buchstaben im markierten Feld, langes Drücken (oder „Wort aufdecken“ im Menü) das ganze Wort. Aufgedeckte Felder sind gesperrt. „Wort prüfen“ und „Alles prüfen“ färben falsche Buchstaben rot, ein Hinweis nennt die Zahl der falschen Felder oder „Alles richtig bisher“. Jede dieser Hilfen zählt 1 Hilfe, auch ein Prüfen ohne Fehler. Wer ganz ohne Hilfe löst (0 Hilfen), bekommt einen Stern. Der Zähler (Glühbirne) im Kopf zeigt die Hilfen ab 1, nicht in der Tinte-Gestaltung. Rot markierte Felder verlieren die Markierung, wenn du sie überschreibst. Sind alle Felder gefüllt, aber nicht alles stimmt, erscheint „Noch nicht ganz richtig“.

## Einstellungen, die helfen, ohne zu zählen
Stichwörter: Optionen, Starthilfe, Bleistift, unsicher, Fehler zeigen, Uhr, Pause, Zeit, Frage melden, Frage merken
„Fehler sofort zeigen“ färbt falsche Buchstaben gleich rot. „Richtige Wörter zeigen“ lässt ein richtig gelöstes Wort kurz aufleuchten. „Starthilfe“ trägt den ersten Buchstaben jedes Wortes vorab ein, gesperrt. „Bleistift“ in der Werkzeugzeile markiert Einträge als unsicher. Nichts davon zählt als Hilfe. „Zeit anzeigen“ blendet die Uhr aus oder ein. Pause verdeckt das Gitter und hält die Zeit an. Die Zeit läuft auch nicht, wenn die App im Hintergrund ist. „Frage merken“ (Menü) speichert eine unpassende Frage nur auf dem Gerät.

## Stufen, Themen, Rätsel des Tages
Stichwörter: Schwierigkeit, leicht, mittel, schwer, Größe, Anzahl, Thema, täglich, Tag, neues Rätsel, wiederholen
Es gibt drei Stufen: Leicht (7 × 9, 300 Rätsel), Mittel (9 × 12, 300) und Schwer (11 × 15, 150). Die Karte „Neues Rätsel“ nimmt das nächste ungelöste Rätsel der Stufe. Sind alle gelöst, kannst du von vorn beginnen. Themenrätsel (9 × 12, 8 Themen mit je 30 Rätseln: Tiere, Pflanzen & Natur, Essen & Trinken, Erdkunde, Musik, Sport & Spiel, Mythologie, Geschichte) zählen nicht für den Stufen-Fortschritt. Das Rätsel des Tages ist ein neues Rätsel pro Tag (9 × 12), für alle gleich. Ein schon gelöstes Rätsel noch einmal zu spielen zählt nicht in Statistik und Fortschritt.

## Serie, Archiv und Erinnerung
Stichwörter: Streak, Kalender, nachholen, verpasst, Mitteilung, Wecker, Uhrzeit, Benachrichtigung
Löst du das Tagesrätsel an Tagen hintereinander, wächst die Serie. Ist heute noch offen, zählt sie ab gestern. Im Archiv (Karte „Archiv und Zeiten“, Kalender) kannst du Tage ab dem 01.01.2026 bis heute nachspielen. Nachgeholte Tage zählen nicht zur Serie und zeigen einen hohlen Haken. Zukünftige Tage sind gesperrt. Beginnst du vor Mitternacht, gilt der Starttag. Die Erinnerung (Standard 9:00 Uhr, nur nach Zustimmung) kommt an den nächsten 7 Tagen, heute nicht mehr, wenn das Rätsel gelöst oder die Zeit vorbei ist.

## Erfolge und Lernkurve
Stichwörter: Medaille, Abzeichen, Trophäe, Stufenvorschlag, Empfehlung, Zeitziel, schnell
Es gibt 14 Erfolge. Beispiele: 1, 10 oder 100 gelöste Rätsel, 1 oder 25 ohne Hilfe, ein schweres Rätsel, Serie 7 oder 30 Tage, 30 Tagesrätsel, alle 300 leichten. Zeit-Erfolge: leicht in höchstens 3 Minuten (180 Sekunden), mittel in höchstens 7 Minuten (420), schwer in höchstens 15 Minuten (900). Die Lernkurve schlägt nach einem Stufenrätsel eine Stufe vor: Drei in Folge ohne Hilfe auf derselben Stufe führen zur nächstschwereren, drei in Folge mit je mindestens 3 Hilfen zur leichteren. Sie erscheint höchstens einmal je Stufe und Tag.

## Was die App anders macht als die übliche Regel
Stichwörter: üblich, normal, Unterschied, Besonderheit, Lösungswort, Nummern
Üblich ist ein Rätsel mit nummerierten Wörtern. Hier gibt es Fragefelder mit Pfeil. Es gibt einen Lösungswort-Streifen: Manche Felder tragen Nummern 1 bis n, aus ihnen ergibt sich ein Lösungswort, das du im Streifen siehst. Alle Rätsel und Fragen sind auf Deutsch. Das Tagesrätsel (9 × 12) zählt in der Statistik der Stufe Mittel mit.
"""#
}
