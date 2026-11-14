// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/yacht/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_yacht {
    static let quelle = #"""
## Worum es geht

Yacht ist ein Würfelspiel mit fünf Würfeln, in Deutschland vor allem als **Kniffel** bekannt. In jedem Zug würfelst du bis zu dreimal und trägst das Ergebnis in ein Feld deiner Wertungstabelle ein. Jedes Feld kannst du nur einmal füllen. Sind alle Felder voll, gewinnt, wer die meisten Punkte hat.

Allein spielst du gegen deinen eigenen Rekord.

## Was du brauchst

- **Spieler:** 1 bis 4, jeder Platz Mensch oder Computer.
- **Würfel:** fünf. Die App würfelt, oder ihr würfelt mit echten Würfeln und tippt die Augen ein.
- **Wertung:** Klassisch (Standard), Yatzy oder Original-Yacht. Sie bestimmt, welche Felder es gibt und was sie zählen.

## Ein Zug

1. Tippe **„Würfeln“**. Beim ersten Wurf rollen alle fünf Würfel.
2. Tippe die Würfel an, die du **halten** willst. Sie werden angehoben. Nochmal antippen gibt sie frei.
3. Tippe **„Nochmal würfeln“**. Nur die nicht gehaltenen Würfel rollen neu. Gehaltene Würfel bleiben für den nächsten Wurf gehalten, bis du sie wieder antippst. (Einstellung „Gehaltene Würfel bleiben liegen“, Standard an.)
4. Nach höchstens **drei Würfen** wählst du ein freies Feld und trägst ein. Das darfst du auch schon nach dem ersten oder zweiten Wurf.

Unter jedem freien Feld siehst du, wie viele Punkte es dir jetzt bringen würde. Tippe das Feld an und bestätige mit „eintragen“.

**Streichen:** Passt nichts, trägst du in ein Feld 0 Punkte ein. Es ist dann verbraucht. Die App fragt vorher nach.

## Wertung Klassisch (wie Kniffel)

**Oberer Block**

| Feld | Punkte |
|---|---|
|Einser bis Sechser | Summe aller Würfel mit dieser Zahl. Drei Vierer sind 12. |
|Bonus | 35, wenn der obere Block mindestens 63 Punkte hat |

**Unterer Block**

@form C
| Feld | Was du brauchst | Punkte |
|---|---|---|
|Dreierpasch | mindestens 3 gleiche | Summe aller 5 Würfel |
|Viererpasch | mindestens 4 gleiche | Summe aller 5 Würfel |
|Full House | 3 gleiche und 2 gleiche | 25 |
|Kleine Straße | 4 Zahlen hintereinander (1-2-3-4, 2-3-4-5 oder 3-4-5-6) | 30 |
|Große Straße | 5 Zahlen hintereinander (1-2-3-4-5 oder 2-3-4-5-6) | 40 |
|Yacht | 5 gleiche | 50 |
|Chance | alles | Summe aller 5 Würfel |

13 Felder, also 13 Runden.

## Wertung Yatzy (skandinavisch)

@form C
| Feld | Was du brauchst | Punkte |
|---|---|---|
|Einser bis Sechser | wie Klassisch | Summe dieser Zahl |
|Bonus | oberer Block mindestens 63 | 50 |
|Ein Paar | 2 gleiche | Summe des höchsten Paares |
|Zwei Paare | zwei verschiedene Paare | Summe der 4 Würfel |
|Dreierpasch | 3 gleiche | Summe dieser 3 Würfel |
|Viererpasch | 4 gleiche | Summe dieser 4 Würfel |
|Full House | 3 gleiche und 2 gleiche | Summe aller 5 |
|Kleine Straße | genau 1-2-3-4-5 | 15 |
|Große Straße | genau 2-3-4-5-6 | 20 |
|Yatzy | 5 gleiche | 50 |
|Chance | alles | Summe aller 5 |

15 Felder, also 15 Runden. Vier gleiche Würfel sind keine zwei Paare.

## Wertung Original-Yacht

Die ursprüngliche Form mit weniger Feldern:

@form C
| Feld | Was du brauchst | Punkte |
|---|---|---|
|Einser bis Sechser | wie Klassisch | Summe dieser Zahl |
|Full House | 3 gleiche und 2 gleiche | Summe aller 5 |
|Viererpasch | 4 gleiche | Summe dieser 4 Würfel |
|Kleine Straße | genau 1-2-3-4-5 | 30 |
|Große Straße | genau 2-3-4-5-6 | 30 |
|Yacht | 5 gleiche | 50 |

11 Felder, also 11 Runden. Keine Chance, kein Dreierpasch, kein Bonus.

## Was überall gilt

- **Fünf gleiche** sind kein Full House. Sie zählen aber als Dreierpasch und Viererpasch.
- Der **Bonus** kommt erst in der Endsumme dazu. 63 schaffst du zum Beispiel mit je drei Würfeln jeder Zahl: 3 + 6 + 9 + 12 + 15 + 18 = 63.

## Joker und Yacht-Bonus (nur Klassisch)

Diese zwei Zusatzregeln schaltest du vor dem ersten Wurf ein. Im Standard sind sie aus.

**Joker:** Du würfelst ein Yacht, aber das Yacht-Feld ist schon belegt (mit 50 oder mit 0). Dann gilt:
1. Ist das obere Feld dieser Zahl frei, **musst** du es nehmen. Fünf Sechser kommen also in die Sechser.
2. Sonst darfst du ein freies Feld im unteren Block nehmen. Full House zählt dann 25, kleine Straße 30, große Straße 40.
3. Ist unten alles voll, nimmst du ein freies oberes Feld.

**Yacht-Bonus:** Steht im Yacht-Feld 50, bringt jedes weitere Yacht, das du mit dem Joker einträgst, **100 Punkte** extra. Schaltest du den Yacht-Bonus ein, ist der Joker automatisch mit an.

*Beispiel:* Yacht-Feld 50, du würfelst 6-6-6-6-6 und trägst in die Sechser ein: 30 Punkte und 100 Bonus.

## Wertung einstellen

Unter „Mehr“ → „Wertung und Regeln ändern“ wählst du vor dem ersten Wurf Klassisch, Yatzy oder Original-Yacht und bei Klassisch Joker und Yacht-Bonus. Mit „Übernehmen“ gilt die Wahl, auch für die nächsten Partien.

## Wer gewinnt

Sind alle Felder bei allen voll, zählt die App zusammen: oberer Block, Bonus, unterer Block und Yacht-Bonus. Die höchste Summe gewinnt. Gleiche Summen teilen sich den Platz.

**Allein** zählt dein Ergebnis gegen deinen **Rekord**, getrennt je Wertung. Die allererste Partie einer Wertung setzt den Rekord erst.

*Beispiel:* Oben 64 Punkte, dazu 35 Bonus, unten 100 Punkte: zusammen 199.

## Tageswürfel

Jeden Tag gibt es die Tageswürfel: eine feste Würfelfolge, für alle gleich. Du spielst allein mit den App-Würfeln. Wer gleich hält, bekommt dieselben Würfe. Tageswürfel zählen für deine Serie, aber nicht als Rekord.

## Gegen den Computer

Die Stärke stellst du unter „Mehr“ ein, sie gilt sofort:
- **Leicht:** spielt einfach.
- **Mittel** (Standard): entscheidet etwa jedes zweite Mal klug.
- **Schwer:** rechnet immer aus, welche Würfel er am besten hält.

## Mit echten Würfeln

Wähle beim Start „Echte Würfel“. Du würfelst am Tisch und tippst nach jedem Wurf die Augen ein, so wie sie liegen. Du kannst sie auch mit der Kamera erfassen lassen oder ansagen („drei, fünf, eins …“). „Wurf korrigieren“ hilft, wenn du dich vertippt hast. Echte Würfel gehen nur ohne Computer.

## So bedienst du das Spiel

- **Tipp:** zeigt dir, welche Würfel du halten sollst oder welches Feld jetzt am besten ist.
- **Letzten Eintrag zurücknehmen:** der Pfeil oben, solange noch nicht weitergewürfelt wurde.
- **Spielverlauf:** unter „Mehr“, zeigt die Punkte Runde für Runde.
- **Pause:** Verlässt du die Partie, kannst du später weiterspielen.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps

- Arbeite früh auf den Bonus hin: Drei gleiche von jeder Zahl reichen genau.
- Die Chance ist dein Notfeld. Heb sie dir für einen schlechten Wurf auf.
- Musst du streichen, streich lieber Einser oder ein Feld, das du selten schaffst, etwa die große Straße.

## Begriffe

- **Halten:** Würfel beim nächsten Wurf liegen lassen.
- **Pasch:** mehrere gleiche Würfel.
- **Straße:** Zahlen hintereinander.
- **Full House:** drei gleiche und zwei gleiche.
- **Yacht (Kniffel, Yatzy):** fünf gleiche.
- **Streichen:** ein Feld mit 0 Punkten belegen.
"""#
}
