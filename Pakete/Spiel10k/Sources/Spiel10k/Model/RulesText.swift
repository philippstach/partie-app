// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Regeltext (Abschnitt → Text) für „Regeln“ und den Regel-Chat – eine Quelle für beide.
/// `active == nil`: allgemeine Regeln mit Varianten.
nonisolated enum RulesText {
    static func sections(for active: GameRules?) -> [(String, String)] {
        let triples = active?.triples
        let n = active?.diceCount ?? 5
        var points = String(localized: "Eine 1 = 100 · Eine 5 = 50\n")
        switch triples {
        case .all?:
            points += String(localized: "Drei Einsen = 1.000\nDrei gleiche = Augenzahl × 100 (z. B. drei Vieren = 400)")
        case .onesAndFives?:
            points += String(localized: "Drei Einsen = 500 · Drei Fünfen = 500\nAndere Drillinge zählen in diesem Spiel nicht.")
        case nil:
            points += String(localized: "Drei Einsen = 1.000\nDrei gleiche = Augenzahl × 100 (z. B. drei Vieren = 400)\nVariante „Nur Einsen und Fünfen“: nur drei Einsen und drei Fünfen zählen als Drilling, je 500.")
        }
        switch (active?.diceCount, active?.straight6) {
        case (6?, .full?):
            points += String(localized: "\nGroße Straße 1–6 = \(fmt(Scoring.bigStraightPoints)) (nur mit allen 6 in einem Wurf)")
        case (6?, _):
            points += String(localized: "\n5er-Straße 1–5 oder 2–6 = 1.000; ein sechster Würfel zählt als 1 oder 5 dazu (1-2-3-4-5-5 = 1.050)")
        default:
            points += String(localized: "\nStraße 1–5 oder 2–6 = 1.000")
            if active == nil {
                points += String(localized: "\nMit 6 Würfeln (Variante): 5er-Straße = 1.000 plus sechster Würfel, oder große Straße 1–6 = \(fmt(Scoring.bigStraightPoints)), je nach Einstellung.")
            }
        }

        var list: [(String, String)] = [
            // Mit fairer Schlussrunde gewinnt man nicht sofort (1.0.1: war hier falsch)
            ("Ziel", active?.finalRound == true
                ? String(localized: "Wer zuerst die Zielpunkte (\(fmt(active!.goal))) erreicht, gewinnt nicht sofort: Die anderen spielen die Runde noch zu Ende, dann gewinnt, wer vorne liegt.")
                : String(localized: "Wer zuerst die Zielpunkte (\(active.map { fmt($0.goal) } ?? String(localized: "Standard 10.000"))) erreicht, gewinnt sofort – außer im Stechen, dort zählt nur der Zug im Stechen.")),
            ("Ablauf", String(localized: "Du würfelst mit \(n) Würfeln. Nach jedem Wurf musst du mindestens einen Würfel mit Punkten rauslegen. Dann aufhören und die Punkte gutschreiben – oder mit den übrigen Würfeln weiterwürfeln.")),
            ("Punkte", points),
            (String(localized: "Pro Wurf"), String(localized: "Gewertet wird nur, was in einem Wurf fällt. Drillinge und Straßen können nicht über mehrere Würfe zusammengesetzt werden. Eine Straße zählt nur, wenn alle \(n) Würfel gleichzeitig geworfen wurden.")),
            ("Niete", String(localized: "Bringt ein Wurf keinen einzigen Punkt, ist der Zug vorbei und alle Punkte dieses Zugs sind verloren.")),
            (String(localized: "Alle \(n) punkten"), String(localized: "Hast du alle \(n) Würfel rausgelegt, darfst du mit allen \(n) weiterwürfeln – die Punkte bleiben.")),
        ]
        var inherit = String(localized: "Hört jemand auf und lässt Würfel offen, darf die nächste Person diese Würfel samt Punkten übernehmen und weiterwürfeln.")
        if active?.inheritAllFive ?? true {
            inherit += String(localized: " Sind alle \(n) rausgelegt, übernimmst du mit allen \(n) Würfeln.")
        } else {
            inherit += String(localized: " Sind alle \(n) rausgelegt, gibt es in diesem Spiel nichts zu übernehmen.")
        }
        inherit += String(localized: " Beim ersten Wurf nach einer Übernahme zählt keine Straße. Bei einer Niete ist alles weg.")
        list.append((String(localized: "Übernehmen"), inherit))
        if let penalty = active?.penalty, penalty == 0 {
            list.append(("Strafe", String(localized: "In diesem Spiel gibt es keine Strafe für Nieten in Folge.")))
        } else {
            list.append(("Strafe", active.map { String(localized: "Wer 3 Nieten in Folge hat (3 Züge ohne Punkte), bekommt \(fmt($0.penalty)) Strafpunkte abgezogen. Danach zählt die Serie neu. Der Punktestand kann dadurch auch unter 0 fallen.") } ?? String(localized: "Wer 3 Nieten in Folge hat (3 Züge ohne Punkte), bekommt die Strafpunkte abgezogen. Danach zählt die Serie neu. Der Punktestand kann dadurch auch unter 0 fallen.")))
        }
        if let r = active, r.entryThreshold > 0 {
            list.append(("Einstieg", String(localized: "Wer noch nicht angeschrieben hat, darf erst aufhören, wenn der Zug mindestens \(fmt(r.entryThreshold)) Punkte bringt. Bis dahin weiterwürfeln – oder eine Niete in Kauf nehmen.")))
        }
        if let r = active, r.multiples != .standard {
            list.append(("Mehrfache", r.multiples == .doubling
                ? String(localized: "Vier, fünf oder sechs gleiche Würfel: Der Drilling verdoppelt sich mit jedem weiteren Würfel. Beispiel: vier Vieren = 800, fünf Vieren = 1.600.")
                : String(localized: "Vier gleiche Würfel zählen 1.000, fünf gleiche 2.000, sechs gleiche 3.000.")))
        }
        if let r = active, r.threePairs, r.diceCount == 6 {
            list.append((String(localized: "Drei Paare"), String(localized: "Drei verschiedene Paare in einem Wurf mit allen 6 Würfeln = \(fmt(Scoring.threePairsPoints)).")))
        }
        list.append(("Runden-Limit", String(localized: "Ist ein Limit eingestellt, gewinnt nach der letzten Runde, wer die meisten Punkte hat.")))
        if active?.finalRound ?? false {
            list.append((String(localized: "Faire Schlussrunde"), String(localized: "Erreicht jemand das Ziel, spielen die anderen die Runde noch zu Ende. Danach gewinnt, wer vorne liegt; bei Gleichstand gibt es ein Stechen.")))
        } else if active == nil {
            list.append((String(localized: "Faire Schlussrunde (Variante)"), String(localized: "Wahlweise gewinnt nicht sofort, wer das Ziel erreicht: Die anderen spielen die Runde noch zu Ende, dann gewinnt, wer vorne liegt.")))
        }
        if active?.tiebreak ?? true {
            list.append(("Stechen", String(localized: "Liegen nach der letzten Runde mehrere vorne gleichauf, gibt es ein Stechen: Nur sie haben je einen Zug, in der normalen Reihenfolge. Wer dabei die meisten Punkte macht, gewinnt – bei erneutem Gleichstand folgt die nächste Stechrunde. Das Erreichen der Zielpunkte beendet das Stechen nicht vorzeitig – es zählen nur die Punkte des Stechzugs. Im Stechen gibt es keine Strafe, und übernommen werden kann nur innerhalb der Stechrunde.")))
        } else {
            list.append(("Gleichstand", String(localized: "Liegen nach der letzten Runde mehrere vorne gleichauf, gewinnen sie gemeinsam (kein Stechen).")))
        }
        let ones = active?.triples == .onesAndFives
            ? String(localized: "vier Einsen sind 500 + 100 = 600, fünf Einsen 700.")
            : String(localized: "bei vier Vieren zählen nur drei (400), vier Einsen sind 1.000 + 100 = 1.100.")
        // 1.0.1: „Drilling plus einzelne Würfel“ war missverständlich – vier Vieren sind nur 400
        if active?.multiples ?? .standard == .standard {
            list.append((n == 6 ? String(localized: "Vier bis sechs Gleiche") : String(localized: "Vier oder fünf Gleiche"), String(localized: "Es zählt der Drilling; weitere Würfel zählen nur, wenn es Einsen oder Fünfen sind – \(ones)") + (n == 6 ? String(localized: " Zwei Drillinge in einem Wurf zählen beide, z. B. 2-2-2-4-4-4 = 600.") : "")))
        }
        return list
    }

    /// „1.000“ wie in der Oberfläche
    static func fmt(_ value: Int) -> String {
        value.formatted(.number.locale(Locale(identifier: "de_DE")))
    }

    /// Abschnitt zu einem Thema (für das Tool `regel_nachschlagen`); unscharf über den Anfang des Titels.
    static func section(_ topic: String, for rules: GameRules) -> String? {
        let t = topic.lowercased()
        let tl = NSLocalizedString(topic, comment: "Regelthema").lowercased()
        return sections(for: rules).first { $0.0.lowercased().hasPrefix(t) || t.hasPrefix($0.0.lowercased()) || $0.0.lowercased().hasPrefix(tl) || tl.hasPrefix($0.0.lowercased()) }
            .map { "\($0.0): \($0.1)" }
    }
}
