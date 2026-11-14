// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Knappe Zusammenfassung der **aktiven** Regeln für den Regel-Chat (Doku/REGELCHAT-PLAN.md §2).
/// Nennt nur die eingestellte Variante, keine Alternativen – das kleine Modell verwechselt sonst.
nonisolated enum RegelZusammenfassung {
    static func text(_ r: GameRules) -> String {
        let n = r.diceCount
        var lines = ["AKTUELLE REGELN"]
        if r.finalRound {
            lines.append("- Ziel: \(r.goal) Punkte. Wer sie erreicht, lässt die anderen die Runde zu Ende spielen; dann gewinnt, wer vorne liegt.")
        } else {
            lines.append("- Ziel: \(r.goal) Punkte. Wer sie zuerst erreicht, gewinnt sofort.")
        }
        lines.append("- 2 bis 8 Personen spielen reihum an einem Gerät.")
        lines.append("- Würfel: \(n). Nach jedem Wurf mindestens einen Würfel mit Punkten rauslegen, dann aufhören oder weiterwürfeln.")
        lines.append("- Eine 1 = 100, eine 5 = 50. Andere einzelne Würfel zählen nicht.")
        switch r.triples {
        case .all:
            lines.append("- Drei Einsen = 1000, drei Gleiche sonst Augenzahl × 100.")
        case .onesAndFives:
            lines.append("- Drei Einsen = 500, drei Fünfen = 500. Andere Drillinge (z. B. drei Vieren) zählen NICHT.")
        }
        let beispiel = r.triples == .onesAndFives ? "vier Einsen = 600" : "vier Vieren = 400"
        let gleiche = n == 6 ? "Vier bis sechs" : "Vier oder fünf"
        switch r.multiples {
        case .standard:
            lines.append("- \(gleiche) Gleiche: nur der Drilling zählt, weitere Würfel nur, wenn es Einsen oder Fünfen sind (\(beispiel)).")
        case .doubling:
            lines.append("- \(gleiche) Gleiche: der Drilling verdoppelt sich mit jedem weiteren gleichen Würfel (z. B. vier Vieren = 800).")
        case .fixed:
            lines.append("- \(gleiche) Gleiche: feste Werte, vier Gleiche = 1000, fünf = 2000, sechs = 3000.")
        }
        if n == 6 {
            switch r.straight6 {
            case .five:
                lines.append("- Straße 1–5 oder 2–6 = 1000, nur wenn alle 6 Würfel in einem Wurf fallen; der sechste Würfel zählt als 1 oder 5 dazu.")
            case .full:
                lines.append("- Nur die große Straße 1–6 = \(Scoring.bigStraightPoints), nur wenn alle 6 Würfel in einem Wurf fallen.")
            }
            lines.append("- Zwei Drillinge in einem Wurf zählen beide.")
        } else {
            lines.append("- Straße 1–5 oder 2–6 = 1000, nur wenn alle 5 Würfel in einem Wurf fallen.")
        }
        lines.append("- Gewertet wird nur, was in einem Wurf fällt.")
        lines.append("- Niete: Wurf ohne Punkte, alle Punkte des Zugs sind weg.")
        lines.append("- Alle \(n) rausgelegt: mit allen \(n) weiterwürfeln, Punkte bleiben.")
        lines.append(r.inheritAllFive
            ? "- Übernehmen: offene Würfel samt Punkten, auch mit allen \(n). Erster Wurf danach: keine Straße."
            : "- Übernehmen: offene Würfel samt Punkten; hat die Person davor ALLE \(n) Würfel rausgelegt, kann NICHT übernommen werden. Erster Wurf danach: keine Straße.")
        lines.append(r.penalty > 0
            ? "- Strafe: 3 Nieten in Folge = −\(r.penalty), danach zählt die Serie neu. Unter 0 möglich."
            : "- Strafe: keine.")
        lines.append(r.roundLimit > 0 ? "- Runden-Limit: \(r.roundLimit) Runden, danach gewinnt, wer vorne liegt." : "- Runden-Limit: keins.")
        lines.append(r.tiebreak ? "- Gleichstand am Ende: Stechen." : "- Gleichstand am Ende: gemeinsamer Sieg, kein Stechen.")
        lines.append("- Faire Schlussrunde: \(r.finalRound ? "an" : "aus").")
        lines.append(r.entryThreshold > 0
            ? "- Einstieg: Das erste Anschreiben gibt es erst ab \(r.entryThreshold) Punkten in einem Zug."
            : "- Es gibt KEINE Mindestpunktzahl zum Einstieg.")
        lines.append(r.threePairs && n == 6
            ? "- Drei Paare = 1500, nur im Wurf mit allen 6 Würfeln."
            : "- Es gibt KEINE drei Paare.")
        return lines.joined(separator: "\n")
    }
}

/// Die Rechen-Tools des Regel-Chats als reine Funktionen (ohne Modell testbar).
/// Die Zahlen kommen immer aus `Scoring`, nie aus dem Sprachmodell.
nonisolated enum RegelTools {
    static let themen = ["Ziel", "Ablauf", "Punkte", "Pro Wurf", "Niete", "Alle punkten", "Übernehmen",
                         "Strafe", "Runden-Limit", "Schlussrunde", "Stechen", "Vier Gleiche"]

    private static func list(_ dice: [Int]) -> String { dice.map(String.init).joined(separator: ", ") }

    /// Voller Wurf = alle Würfel geworfen, nicht der erste Wurf nach einer Übernahme
    private static func full(_ dice: [Int], alleGeworfen: Bool, nachUebernahme: Bool, rules: GameRules) -> Bool {
        alleGeworfen && !nachUebernahme && dice.count == rules.diceCount
    }

    private static func valid(_ dice: [Int], rules: GameRules) -> String? {
        if dice.isEmpty { return "Keine Würfel angegeben." }
        if dice.count > rules.diceCount { return "Zu viele Würfel: in diesem Spiel gibt es \(rules.diceCount)." }
        if !dice.allSatisfy((1...6).contains) { return "Augen müssen zwischen 1 und 6 liegen." }
        return nil
    }

    /// `wertung_berechnen`: Punkte für rausgelegte Würfel aus einem Wurf
    static func wertung(_ dice: [Int], alleGeworfen: Bool, nachUebernahme: Bool, rules: GameRules) -> String {
        if let e = valid(dice, rules: rules) { return e }
        let isFull = full(dice, alleGeworfen: alleGeworfen, nachUebernahme: nachUebernahme, rules: rules)
        if let p = Scoring.score(dice, fullThrow: isFull, rules: rules.scoring) {
            return "\(p) Punkte"
        }
        let best = Scoring.bestSelection(dice, fullThrow: isFull, rules: rules.scoring)
        let rest = dice.indices.filter { !best.indices.contains($0) }.map { dice[$0] }
        if best.points == 0 { return "Zählt nicht: \(list(dice)) bringen keine Punkte (Niete)." }
        return "Zählt so nicht: \(list(rest)) bringen allein keine Punkte. Gültig wären \(list(best.indices.map { dice[$0] })) = \(best.points) Punkte."
    }

    /// Aufschlüsselung der besten Auswahl, z. B. „Drilling Einsen 1000 + 3 einzelne Einsen je 100“ – damit das
    /// Modell die Zahl nicht selbst herleitet (1.0.1 (8)).
    static func aufschluesselung(_ dice: [Int], full: Bool, rules: GameRules) -> String? {
        let best = Scoring.bestSelection(dice, fullThrow: full, rules: rules.scoring)
        guard best.points > 0 else { return nil }
        let chosen = best.indices.map { dice[$0] }
        if full, chosen.count >= 5, Scoring.isStraight(Array(chosen.sorted().prefix(5))) || Scoring.isStraight(Array(chosen.sorted().suffix(5))) {
            if Scoring.score(chosen, fullThrow: false, rules: rules.scoring) != best.points { return "Straße" + (chosen.count > 5 ? " plus einzelner Würfel" : "") }
        }
        let namen = [1: "Einsen", 2: "Zweien", 3: "Dreien", 4: "Vieren", 5: "Fünfen", 6: "Sechsen"]
        var teile: [String] = []
        for face in 1...6 {
            var c = chosen.filter { $0 == face }.count
            guard c > 0 else { continue }
            while c >= 3, let p = Scoring.score([face, face, face], fullThrow: false, rules: rules.scoring) {
                // Zwei Drillinge nur bei verschiedenen Augen (sechs Einsen = Drilling + 3 Einzelne)
                teile.append("Drilling \(namen[face]!) \(p)")
                c -= 3
                break
            }
            if c > 0 {
                let single = face == 1 ? 100 : 50
                teile.append(c == 1 ? "eine \(face == 1 ? "Eins" : "Fünf") \(single)" : "\(c) einzelne \(namen[face]!) je \(single)")
            }
        }
        return teile.isEmpty ? nil : teile.joined(separator: " + ")
    }

    /// `beste_auswahl`: beste Auswahl aus einem Wurf oder Niete
    static func besteAuswahl(_ dice: [Int], alleGeworfen: Bool, nachUebernahme: Bool, rules: GameRules) -> String {
        if let e = valid(dice, rules: rules) { return e }
        let isFull = full(dice, alleGeworfen: alleGeworfen, nachUebernahme: nachUebernahme, rules: rules)
        let best = Scoring.bestSelection(dice, fullThrow: isFull, rules: rules.scoring)
        guard best.points > 0 else { return "Niete: In \(list(dice)) zählt nichts. Alle Punkte des Zugs sind weg." }
        let chosen = best.indices.sorted().map { dice[$0] }
        let rest = dice.indices.filter { !best.indices.contains($0) }.map { dice[$0] }
        return "Beste Auswahl \(list(chosen)) = \(best.points) Punkte" + (rest.isEmpty ? ", alle Würfel punkten." : ", Rest \(list(rest)).")
    }

    /// `zug_berechnen`: Summe eines Zugs über mehrere Würfe (je Wurf die rausgelegten Würfel)
    static func zug(_ wuerfe: [[Int]], uebernommenePunkte: Int, erstesWurfNachUebernahme: Bool, rules: GameRules) -> String {
        guard !wuerfe.isEmpty else { return "Keine Würfe angegeben." }
        let n = rules.diceCount
        // Nach einer Übernahme ist unbekannt, wie viele Würfel offen waren – der erste Wurf ist nie „voll“
        var open = n
        var parts: [Int] = uebernommenePunkte > 0 ? [uebernommenePunkte] : []
        for (k, dice) in wuerfe.enumerated() {
            if let e = valid(dice, rules: rules) { return "Wurf \(k + 1): \(e)" }
            if dice.count > open { return "Wurf \(k + 1): Es waren nur \(open) Würfel offen." }
            let isFull = open == n && !(k == 0 && erstesWurfNachUebernahme)
            guard let p = Scoring.score(dice, fullThrow: isFull, rules: rules.scoring) else {
                return "Wurf \(k + 1) (\(list(dice))) zählt so nicht – darin bringt nicht jeder Würfel Punkte."
            }
            parts.append(p)
            open -= dice.count
            if open == 0 { open = n }   // alle rausgelegt → mit allen weiter
        }
        let total = parts.reduce(0, +)
        return parts.count == 1 ? "Zug: \(total) Punkte" : "Zug: \(parts.map(String.init).joined(separator: " + ")) = \(total) Punkte"
    }

    /// `regel_nachschlagen`: Wortlaut zu einem Thema
    static func nachschlagen(_ thema: String, rules: GameRules) -> String {
        let key: String
        switch thema {
        case "Alle punkten": key = "Alle"
        case "Schlussrunde": key = "Faire Schlussrunde"
        case "Vier Gleiche": key = rules.diceCount == 6 ? "Vier bis sechs" : "Vier oder fünf"
        case "Stechen": key = rules.tiebreak ? "Stechen" : "Gleichstand"
        default: key = thema
        }
        if thema == "Schlussrunde" && !rules.finalRound {
            return "Faire Schlussrunde: in diesem Spiel aus. Wer das Ziel erreicht, gewinnt sofort."
        }
        if thema == "Runden-Limit" && rules.roundLimit > 0 {
            return "Runden-Limit: \(rules.roundLimit) Runden. Danach gewinnt, wer die meisten Punkte hat."
        }
        return RulesText.section(key, for: rules) ?? "Dazu gibt es in diesem Spiel keine Regel."
    }
}

/// Vorab-Rechnung für den Regel-Chat (1.0.1, vorläufig): Das kleine Modell ruft Tools kaum zuverlässig auf.
/// Deshalb liest Swift Würfel aus der Frage, rechnet mit `Scoring` und legt das Ergebnis samt passender
/// Regelabschnitte verbindlich in den Prompt. Das Modell formuliert nur noch.
nonisolated enum RegelChatKontext {
    private static let zahlwoerter = ["ein": 1, "eine": 1, "zwei": 2, "drei": 3, "vier": 4, "fünf": 5, "sechs": 6]
    private static let augenwoerter = ["einsen": 1, "zweien": 2, "zweier": 2, "dreien": 3, "dreier": 3, "vieren": 4, "vierer": 4,
                                       "fünfen": 5, "fünfer": 5, "sechsen": 6, "sechser": 6]
    /// „eine Eins“, „eine Fünf“ (Einzahl)
    private static let einzelwoerter = ["eins": 1, "einser": 1, "fünf": 5, "fünfer": 5]

    /// Würfellisten in der Frage: „1, 1 und 5“, „4-4-4-4-2“, „1-2-3-4-5-5“, „vier Einsen“
    static func diceLists(in question: String) -> [[Int]] {
        var result: [[Int]] = []
        let q = question.lowercased()
        // Ziffernfolgen mit Trennern (mindestens zwei Würfel)
        // Punkt nur als Tausendertrenner ausschließen („10.000“), nicht als Satzende („…, 6, 6.“) – 1.2
        let pattern = #"(?<!\d)(?<!\d\.)[1-6](?:(?:\s*(?:,|-|–|und|\+)\s*|\s+)[1-6])+(?!\d)(?!\.\d)"#
        if let re = try? NSRegularExpression(pattern: pattern) {
            for m in re.matches(in: q, range: NSRange(q.startIndex..., in: q)) {
                guard let r = Range(m.range, in: q) else { continue }
                let digits = q[r].compactMap { Int(String($0)) }.filter { (1...6).contains($0) }
                if digits.count >= 2 { result.append(digits) }
            }
        }
        // „drei Einsen“, „vier Vieren“, „eine Eins“; mehrere Gruppen („zwei Fünfen und eine Eins“) zusammen
        let words = q.components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        var groups: [[Int]] = []
        for (i, w) in words.enumerated() where i + 1 < words.count {
            if let n = zahlwoerter[w], let face = augenwoerter[words[i + 1]] ?? (n == 1 ? einzelwoerter[words[i + 1]] : nil) {
                groups.append(Array(repeating: face, count: n))
            }
        }
        if groups.count == 1, groups[0].count >= 2 { result.append(groups[0]) }
        // „drei Einsen und was drei Vieren“: eigene Drillinge = getrennte Fragen (1.2);
        // „zwei Fünfen und eine Eins“: ein Wurf
        if groups.count > 1 {
            if groups.allSatisfy({ $0.count >= 3 }) { result += groups } else { result.append(groups.flatMap { $0 }) }
        }
        return result
    }

    /// Passende Regelabschnitte nach Stichwörtern
    static func themen(in question: String) -> [String] {
        let q = question.lowercased()
        var t: [String] = []
        if q.contains("übernehm") || q.contains("übernomm") || q.contains("vorgänger") || q.contains("liegen") { t.append("Übernehmen") }
        if q.contains("niete") || q.contains("zonk") || q.contains("farkle") { t.append("Niete") }
        if q.contains("stehen lass") || q.contains("stehenlass") || q.contains("liegen lass") { t.append("Übernehmen") }
        if q.contains("hot dice") || q.contains("alle würfel punkten") { t.append("Alle punkten") }
        if q.contains("mindest") || q.contains("einstieg") || q.contains("rauskommen") || q.contains("rauslegen")
            || q.contains("nichts rauslegen") || q.contains("aufhören") { t.append("Ablauf") }
        if q.contains("unter null") || q.contains("unter 0") || q.contains("negativ") || q.contains("minus") { t.append("Strafe") }
        if q.contains("dreimal") || q.contains("strafe") || q.contains("in folge") || q.contains("hintereinander") { t.append("Strafe") }
        if q.contains("gleich viel") || q.contains("gleichstand") || q.contains("unentschieden") || q.contains("stechen") { t.append("Stechen") }
        if q.contains("runde") { t.append("Runden-Limit") }
        if q.contains("gewonnen") || q.contains("gewinn") || q.contains("ziel") { t.append("Ziel"); t.append("Schlussrunde") }
        if q.contains("alle") && q.contains("punkt") { t.append("Alle punkten") }
        if q.contains("straße") { t.append("Pro Wurf") }
        if q.contains("vier") || q.contains("fünf gleiche") { t.append("Vier Gleiche") }
        var seen = Set<String>()
        return t.filter { seen.insert($0).inserted }
    }

    /// „Erst eine 1 rausgelegt, dann mit den restlichen vier 2-3-4-5“: Würfe getrennt werten und addieren.
    static func mehrereWuerfe(in question: String, rules: GameRules) -> String? {
        let q = question.lowercased()
        guard let erst = q.range(of: "erst"), let dann = q.range(of: "dann", range: erst.upperBound..<q.endIndex) else { return nil }
        let first = String(q[erst.upperBound..<dann.lowerBound])
        let second = String(q[dann.upperBound...])
        var firstDice = diceLists(in: first).first ?? []
        if firstDice.isEmpty,
           let re = try? NSRegularExpression(pattern: #"\b(?:eine|ein|die|der)\s+([1-6])\b"#),
           let m = re.firstMatch(in: first, range: NSRange(first.startIndex..., in: first)),
           let r = Range(m.range(at: 1), in: first), let v = Int(first[r]) {
            firstDice = [v]
        }
        guard !firstDice.isEmpty, let secondThrow = diceLists(in: second).first else { return nil }
        let open = rules.diceCount - firstDice.count
        guard secondThrow.count <= open else { return nil }
        guard let p1 = Scoring.score(firstDice, fullThrow: false, rules: rules.scoring) else { return nil }
        // Zweiter Wurf mit den übrigen Würfeln: nie „voll“, also keine Straße
        let best = Scoring.bestSelection(secondThrow, fullThrow: false, rules: rules.scoring)
        let w1 = "Wurf 1: \(firstDice.map(String.init).joined(separator: "-")) = \(p1) Punkte"
        guard best.points > 0 else {
            return "- \(w1). Wurf 2 mit \(open) Würfeln (\(secondThrow.map(String.init).joined(separator: "-"))): Niete, alle Punkte des Zugs sind weg."
        }
        let chosen = best.indices.sorted().map { String(secondThrow[$0]) }.joined(separator: "-")
        let straight = Scoring.isStraight(secondThrow + firstDice) || q.contains("straße")
            ? " NEIN, keine Straße, weil nur \(open) Würfel geworfen wurden." : ""
        return "- \(w1). Wurf 2 mit den restlichen \(open) Würfeln (\(secondThrow.map(String.init).joined(separator: "-"))): beste Auswahl \(chosen) = \(best.points) Punkte.\(straight) Zusammen: \(p1 + best.points) Punkte."
    }

    /// Zusatz für den Prompt; `nil`, wenn nichts zu rechnen oder nachzuschlagen ist.
    static func zusatz(for question: String, rules: GameRules) -> String? {
        let q = question.lowercased()
        let nachUebernahme = q.contains("übernomm") || q.contains("übernehm")
        let teilwurf = q.contains("restlich") || q.contains("übrig") || q.contains("rest ")
        var lines: [String] = []
        for dice in diceLists(in: question) where dice.count <= rules.diceCount {
            let alle = dice.count == rules.diceCount && !teilwurf
            let gueltig = Scoring.score(dice, fullThrow: false, rules: rules.scoring) != nil
            var text = dice.count == rules.diceCount || teilwurf || nachUebernahme || !gueltig
                ? RegelTools.besteAuswahl(dice, alleGeworfen: alle, nachUebernahme: nachUebernahme, rules: rules)
                : RegelTools.wertung(dice, alleGeworfen: false, nachUebernahme: false, rules: rules)
            if let teile = RegelTools.aufschluesselung(dice, full: alle && !nachUebernahme, rules: rules), teile.contains("+") || teile.hasPrefix("Straße") {
                text += " Aufschlüsselung: \(teile)."
            }
            let best = Scoring.bestSelection(dice, fullThrow: alle && !nachUebernahme, rules: rules.scoring)
            let rest = dice.indices.filter { !best.indices.contains($0) }.map { dice[$0] }
            if best.points > 0, !rest.isEmpty {
                text += " Nicht gezählt: \(rest.map(String.init).joined(separator: ", ")) (bringen keine Punkte)."
            }
            if alle && !nachUebernahme && (RegelTools.aufschluesselung(dice, full: true, rules: rules) ?? "").hasPrefix("Straße") {
                text = "JA, das ist eine Straße (alle \(rules.diceCount) Würfel in einem Wurf): \(best.points) Punkte."
            }
            var hinweis = ""
            if (Scoring.isStraight(dice) || q.contains("straße")) && !(alle && !nachUebernahme && Scoring.isStraight(dice)) {
                hinweis = nachUebernahme
                    ? " (Keine Straße: erster Wurf nach einer Übernahme.)"
                    : " (Keine Straße: nicht alle \(rules.diceCount) Würfel in einem Wurf.)"
            }
            let annahme = alle && !nachUebernahme ? " (alle \(rules.diceCount) Würfel in einem Wurf)" : ""
            let ergebnis = Scoring.bestSelection(dice, fullThrow: alle && !nachUebernahme, rules: rules.scoring).points
            let kopf = ergebnis > 0 ? "ERGEBNIS \(ergebnis) Punkte. " : "ERGEBNIS: Niete, 0 Punkte. "
            lines.append("- Würfel \(dice.map(String.init).joined(separator: "-"))\(annahme): \(kopf)\(text)\(hinweis)")
        }
        if let zug = mehrereWuerfe(in: question, rules: rules) { lines.append(zug) }
        let themen = themen(in: question)
        // Ja/Nein-Fakten, die das Modell sonst gern aus dem Training „weiß“
        if themen.contains("Übernehmen") && q.contains("alle") {
            lines.append(rules.inheritAllFive
                ? "- Hat die Person davor alle \(rules.diceCount) Würfel rausgelegt: JA, du darfst mit allen \(rules.diceCount) Würfeln übernehmen."
                : "- Hat die Person davor alle \(rules.diceCount) Würfel rausgelegt: NEIN, dann kannst du nicht übernehmen.")
        }
        if q.contains("nichts rauslegen") || q.contains("gar nichts") || q.contains("keinen würfel rauslegen") {
            lines.append("- NEIN: Nach jedem Wurf musst du mindestens einen Würfel mit Punkten rauslegen. Bringt kein Würfel Punkte, ist es eine Niete.")
        }
        if q.contains("paar") {
            lines.append("- Paare zählen in Zehntausend nicht, auch drei Paare nicht. Nur Einsen, Fünfen, Drillinge und Straßen bringen Punkte.")
        }
        if q.contains("mitspiel") || q.contains("leute") || q.contains("personen") || q.contains("wie viele spieler") {
            lines.append("- In der App spielen 2 bis 8 Personen an einem Gerät (iPhone oder iPad).")
        }
        if q.contains("mindest") || q.contains("einstieg") || q.contains("rauskommen") {
            lines.append("- Eine Mindestpunktzahl zum Einstieg oder zum Aufhören gibt es NICHT. Aufhören darfst du nach jedem Wurf mit Punkten.")
        }
        if q.contains("zonk") || q.contains("farkle") {
            lines.append("- Zonk und Farkle sind andere Wörter für eine Niete: Wurf ohne Punkte, alle Punkte des Zugs sind weg.")
        }
        if q.contains("unter null") || q.contains("unter 0") || q.contains("negativ") {
            lines.append("- Der Punktestand kann durch die Strafe unter 0 fallen. Es wird ganz normal weitergespielt, niemand scheidet aus.")
        }
        if themen.contains("Alle punkten") {
            lines.append("- Punkten alle \(rules.diceCount) Würfel: mit allen \(rules.diceCount) weiterwürfeln, die Punkte bleiben.")
        }
        guard !lines.isEmpty || !themen.isEmpty else { return nil }
        var out: [String] = []
        if !lines.isEmpty {
            out.append("FAKTEN DER APP (verbindlich): Nenne genau diese Punktzahl und, falls angegeben, die Aufschlüsselung. Rechne nicht selbst.")
            out += lines
        }
        if !themen.isEmpty {
            out.append("PASSENDE REGELN:")
            out += themen.map { "- " + RegelTools.nachschlagen($0, rules: rules) }
        }
        return out.joined(separator: "\n")
    }
}

/// Begriffe und vorgerechnete Beispiele für den Regel-Chat (1.0.1 (8)). Die Zahlen rechnet Swift mit den
/// aktiven Regeln aus – so passen die Beispiele auch zu „Nur Einsen und Fünfen“ oder 6 Würfeln.
nonisolated enum RegelChatWissen {
    static let begriffe = """
    BEGRIFFE
    - Zonk, Farkle = Niete (Wurf ohne Punkte).
    - Rauslegen = Würfel mit Punkten zur Seite legen. Mindestens einer pro Wurf.
    - Aufhören, sichern, schreiben = Punkte des Zugs gutschreiben.
    - Stehen lassen, liegen lassen, Vorgänger = Übernehmen durch die nächste Person.
    - Hot Dice = alle Würfel punkten, mit allen weiter.
    - Drilling = drei Gleiche in einem Wurf. Paare zählen nicht.
    """

    static func beispiele(_ r: GameRules) -> String {
        let n = r.diceCount
        func best(_ d: [Int], full: Bool = false, nach: Bool = false) -> Int {
            Scoring.bestSelection(d, fullThrow: full && !nach && d.count == n, rules: r.scoring).points
        }
        let straight = Array(1...5) + (n == 6 ? [3] : [])
        var lines = ["BEISPIELE (so antwortest du)"]
        lines.append("F: Was bringen 1, 5 und 5? A: \(best([1, 5, 5])) Punkte.")
        let dreien = best([3, 3, 3, 3, 6])
        lines.append("F: Ich habe 3-3-3-3-6 geworfen. A: \(dreien == 0 ? "Nichts – das ist eine Niete." : (r.multiples == .standard ? "\(dreien) Punkte für drei Dreien; die vierte 3 und die 6 zählen nicht." : "\(dreien) Punkte für die vier Dreien; die 6 zählt nicht."))")
        lines.append("F: Was zählt eine Straße 1-2-3-4-5? A: \(best(Array(1...5) + (n == 6 ? [6] : []), full: true) >= 1000 ? "1000" : "\(best(Array(1...5), full: true))") Punkte – wenn alle \(n) Würfel in einem Wurf fallen.")
        lines.append("F: Was ist eine Niete? A: Ein Wurf, der keine Punkte bringt. Alle Punkte des Zugs sind weg.")
        lines.append("F: Was heißt stehen lassen? A: Wer aufhört, lässt Würfel liegen; die nächste Person darf sie samt Punkten übernehmen.")
        lines.append("F: Ich habe übernommen und direkt \(straight.map(String.init).joined(separator: "-")) geworfen. Straße? A: Nein, im ersten Wurf nach einer Übernahme zählt keine Straße. Rauslegen: \(best(straight, full: true, nach: true)) Punkte.")
        lines.append(r.threePairs && n == 6
            ? "F: Zählen drei Paare? A: Ja, drei Paare = 1500, aber nur im Wurf mit allen 6 Würfeln."
            : "F: Zählen drei Paare? A: Nein, Paare zählen in dieser Partie nicht.")
        lines.append("F: Ich habe einen Zonk. A: Das ist eine Niete: Die Punkte dieses Zugs sind weg, die nächste Person ist dran.")
        lines.append("F: Ich übernehme 300 und mache 200 dazu. A: Du bekommst 500 Punkte.")
        lines.append(r.entryThreshold > 0
            ? "F: Gibt es eine Mindestpunktzahl? A: Ja, das erste Anschreiben erst ab \(r.entryThreshold) Punkten in einem Zug."
            : "F: Gibt es eine Mindestpunktzahl? A: Nein, aufhören darfst du nach jedem Wurf mit Punkten.")
        return lines.joined(separator: "\n")
    }
}

nonisolated extension RegelChatKontext {
    /// Der aktuelle Zug für Fragen wie „Was zählt mein Wurf?“ – die Zahl rechnet Swift (1.0.1 (8)).
    static func zugText(_ turn: DiceTurn, rules: GameRules) -> String? {
        var lines = ["AKTUELLER ZUG (nur nutzen, wenn die Frage sich darauf bezieht):"]
        if turn.inheritedFrom != nil {
            lines.append("- \(turn.inheritedPoints) Punkte übernommen.")
        }
        lines.append("- Gesichert in diesem Zug: \(turn.banked) Punkte.")
        let free = turn.dice.indices.filter { !turn.locked[$0] }
        if turn.hasRolled, !free.isEmpty, free.allSatisfy({ (1...6).contains(turn.dice[$0]) }) {
            let values = free.map { turn.dice[$0] }
            let full = turn.fullThrow
            lines.append("- Letzter Wurf (\(values.count) Würfel\(full ? ", alle geworfen" : "")): \(values.map(String.init).joined(separator: "-")). "
                + RegelTools.besteAuswahl(values, alleGeworfen: full, nachUebernahme: false, rules: rules))
        } else if !turn.hasRolled {
            lines.append("- Noch nicht gewürfelt, \(turn.openCount) Würfel offen.")
        }
        return lines.count > 1 ? lines.joined(separator: "\n") : nil
    }
}

nonisolated extension RegelChatKontext {
    /// Antwort ohne Modell aus dem Regeltext – Rückfall, wenn der Inhaltsfilter des Modells blockiert.
    static func regelAntwort(for question: String, rules: GameRules) -> String? {
        let t = themen(in: question)
        guard !t.isEmpty else { return nil }
        let texte = t.prefix(2).map { RegelTools.nachschlagen($0, rules: rules) }
        return "Laut euren Regeln: " + texte.joined(separator: " ")
    }
}

/// Regel-Chat 1.2: Rechenfragen komplett aus Swift (Zahl, Aufschlüsselung, ein Satz aus einer Vorlage),
/// ohne Sprachmodell; dazu ein Zahlen-Wächter für die Antworten des Modells. Damit sind falsche Zahlen
/// per Konstruktion ausgeschlossen (Doku/BACKLOG.md, Version 1.2, Punkt R).
nonisolated enum RegelChatDirekt {
    private static func liste(_ d: [Int]) -> String { d.map(String.init).joined(separator: "-") }
    private static func aufzaehlung(_ d: [Int]) -> String { d.map(String.init).joined(separator: ", ") }

    /// Antwort ohne Modell, wenn die Frage Würfel oder eine Übernahme-Summe enthält; sonst `nil`.
    static func antwort(for question: String, rules: GameRules) -> String? {
        let q = question.lowercased()
        if let summe = uebernahmeSumme(q) { return summe }
        let nach = q.contains("übernomm") || q.contains("übernehm")
        let teilwurf = q.contains("restlich") || q.contains("übrig") || q.contains("rest ")
        let fragtStrasse = q.contains("straße")
        if let mehrere = RegelChatKontext.mehrereWuerfe(in: question, rules: rules) {
            // „- Wurf 1: … Zusammen: X Punkte.“ → Satz
            var text = mehrere.hasPrefix("- ") ? String(mehrere.dropFirst(2)) : mehrere
            text = text.replacingOccurrences(of: " NEIN, keine Straße", with: " Keine Straße")
            return fragtStrasse ? "Nein. " + text : text
        }
        let listen = RegelChatKontext.diceLists(in: question).filter { $0.count <= rules.diceCount }
        guard !listen.isEmpty else { return themenAntwort(q, rules: rules) }
        let saetze = listen.map { satz($0, rules: rules, nach: nach, teilwurf: teilwurf, fragtStrasse: fragtStrasse, fragtPaare: q.contains("paar")) }
        return saetze.joined(separator: " ")
    }

    private static func satz(_ d: [Int], rules: GameRules, nach: Bool, teilwurf: Bool, fragtStrasse: Bool, fragtPaare: Bool) -> String {
        let n = rules.diceCount
        let alle = d.count == n && !teilwurf
        let voll = alle && !nach
        let best = Scoring.bestSelection(d, fullThrow: voll, rules: rules.scoring)
        let chosen = best.indices.sorted().map { d[$0] }
        let rest = d.indices.filter { !best.indices.contains($0) }.map { d[$0] }
        let istStrasse = (RegelTools.aufschluesselung(d, full: true, rules: rules) ?? "").hasPrefix("Straße")

        if best.points == 0 {
            if fragtPaare { return "Nein, Paare zählen in Zehntausend nicht – \(liste(d)) bringt keine Punkte, das ist eine Niete." }
            if d.count == 3, Set(d).count == 1, rules.triples == .onesAndFives {
                return "Nein, \(liste(d)) zählt bei euren Regeln nicht: Nur drei Einsen und drei Fünfen bilden einen Drilling."
            }
            return alle
                ? "\(liste(d)) ist eine Niete: Kein Würfel bringt Punkte, alle Punkte dieses Zugs sind weg."
                : "\(liste(d)) bringt keine Punkte."
        }
        if fragtStrasse || istStrasse {
            if istStrasse && voll {
                return "Ja, \(liste(d)) ist eine Straße: \(best.points) Punkte – wenn alle \(n) Würfel in einem Wurf fallen."
            }
            if istStrasse || fragtStrasse {
                let grund = nach && alle
                    ? "im ersten Wurf nach einer Übernahme zählt keine Straße"
                    : "eine Straße zählt nur, wenn alle \(n) Würfel in einem Wurf fallen"
                return "Nein, \(grund). Rauslegen kannst du \(aufzaehlung(chosen)) = \(best.points) Punkte."
            }
        }
        var text = "\(liste(d)): \(best.points) Punkte"
        if let teile = RegelTools.aufschluesselung(d, full: voll, rules: rules), teile.contains("+") || teile.contains("einzelne") {
            text += " (\(teile))"
        }
        if !rest.isEmpty {
            text += ". Nicht gezählt: \(aufzaehlung(rest)) – die bringen keine Punkte"
        }
        return text + "."
    }

    /// Feste Regel-Fakten aus den aktiven Regeln (1.2/Build 11): Kernfragen, bei denen das kleine Modell
    /// gern ausschmückt oder Farkle-Wissen einstreut. Nur wenn die Frage eindeutig ein Thema trifft.
    static func themenAntwort(_ q: String, rules r: GameRules) -> String? {
        let n = r.diceCount
        if q.contains("mindest") || q.contains("einstieg") || q.contains("rauskommen") {
            return "Nein, eine Mindestpunktzahl gibt es in Zehntausend nicht – weder zum Einstieg noch zum Aufhören. Aufhören darfst du nach jedem Wurf mit Punkten."
        }
        if q.contains("nichts rauslegen") || q.contains("gar nichts") || q.contains("keinen würfel rauslegen") {
            return "Nein. Nach jedem Wurf musst du mindestens einen Würfel mit Punkten rauslegen. Bringt kein Würfel Punkte, ist es eine Niete."
        }
        if q.contains("unter null") || q.contains("unter 0") || q.contains("negativ") {
            return r.penalty > 0
                ? "Das geht: Durch die Strafe kann der Punktestand unter 0 fallen. Es wird ganz normal weitergespielt, niemand scheidet aus."
                : "Bei euch gibt es keine Strafe – der Punktestand kann also nicht unter 0 fallen."
        }
        if q.contains("strafe") || q.contains("dreimal") || q.contains("nieten in folge") || q.contains("hintereinander") {
            return r.penalty > 0
                ? "Wer 3 Nieten in Folge hat, bekommt \(r.penalty) Punkte abgezogen. Danach zählt die Serie wieder von vorn."
                : "Nein, bei euch gibt es keine Strafe für Nieten in Folge."
        }
        if q.contains("alle") && (q.contains("punkten") || q.contains("hot dice")) && !q.contains("übernehm") {
            return "Punkten alle \(n) Würfel, darfst du mit allen \(n) weiterwürfeln – die Punkte dieses Zugs bleiben dir."
        }
        if (q.contains("niete") || q.contains("zonk") || q.contains("farkle"))
            && (q.contains("was ist") || q.contains("was heißt") || q.contains("was bedeutet") || q.contains("geworfen")) {
            return "Eine Niete (auch Zonk) ist ein Wurf, der keine Punkte bringt. Alle Punkte dieses Zugs sind weg, und die nächste Person ist dran."
        }
        return nil
    }

    /// „300 übernommen und 200 dazu“ → „300 + 200 = 500 Punkte“
    private static func uebernahmeSumme(_ q: String) -> String? {
        guard q.contains("übernehm") || q.contains("übernomm") else { return nil }
        let punkte = zahlen(in: q).filter { $0 >= 50 && $0 % 50 == 0 }
        guard punkte.count == 2, q.contains("dazu") || q.contains("noch") || q.contains("plus") else { return nil }
        let summe = punkte[0] + punkte[1]
        return "Du bekommst \(punkte[0]) + \(punkte[1]) = \(summe) Punkte: Die übernommenen Punkte zählen einmal, deine kommen dazu."
    }

    // MARK: - Zahlen-Wächter

    /// Ganze Zahlen in einem Text (1.000 → 1000, −500 → 500)
    static func zahlen(in text: String) -> [Int] {
        let t = text.replacingOccurrences(of: #"(?<=\d)\.(?=\d{3})"#, with: "", options: .regularExpression)
        guard let re = try? NSRegularExpression(pattern: #"\d+"#) else { return [] }
        return re.matches(in: t, range: NSRange(t.startIndex..., in: t)).compactMap { m in
            Range(m.range, in: t).flatMap { Int(t[$0]) }
        }
    }

    /// Zahlen, die eine Antwort nennen darf: aus Frage, Swift-Fakten, Regeltext und Beispielen dieser Regeln, plus 0–12
    static func erlaubteZahlen(question: String, rules: GameRules, zug: String? = nil) -> Set<Int> {
        var quellen = [question, RegelZusammenfassung.text(rules), RegelChatWissen.beispiele(rules)]
        quellen += RulesText.sections(for: rules).map { "\($0.0) \($0.1)" }
        if let z = RegelChatKontext.zusatz(for: question, rules: rules) { quellen.append(z) }
        if let zug { quellen.append(zug) }
        return Set(quellen.flatMap { zahlen(in: $0) }).union(0...12)
    }

    /// Nennt die Antwort nur erlaubte Zahlen?
    static func zahlenOK(_ antwort: String, question: String, rules: GameRules, zug: String? = nil) -> Bool {
        let erlaubt = erlaubteZahlen(question: question, rules: rules, zug: zug)
        return zahlen(in: antwort).allSatisfy(erlaubt.contains)
    }

    /// Ersatz, wenn das Modell eine Zahl erfindet: der passende Regeltext, sonst ein ehrlicher Hinweis
    static func ersatz(for question: String, rules: GameRules) -> String {
        RegelChatKontext.regelAntwort(for: question, rules: rules)
            ?? "Dazu kann ich keine sichere Antwort geben. Schau bitte unter „Regeln“ nach."
    }
}

