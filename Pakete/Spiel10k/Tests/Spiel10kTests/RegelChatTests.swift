// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k
import SpieleKern
#if canImport(FoundationModels)
import FoundationModels
#endif

nonisolated private let sharedRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Shared")

/// Regel-Chat, Teil A: Tools und Zusammenfassung ohne Modell (Doku/REGELCHAT-PLAN.md §4 A).
struct RegelChatCoreTests {
    private struct Wertung: Decodable {
        struct Score: Decodable {
            let name: String; let dice: [Int]; let fullThrow: Bool; let triples: TripleRule; let expectedScore: Int?
            let diceCount: Int?; let straight6: Straight6?
        }
        let wertung: [Score]
    }

    /// Das Tool nennt dieselbe Zahl wie wertung.json (bzw. „zählt nicht“).
    @Test func wertungToolMatchesSharedCases() throws {
        let data = try Data(contentsOf: sharedRoot.appendingPathComponent("regeltests/wertung.json"))
        let cases = try JSONDecoder().decode(Wertung.self, from: data).wertung
        #expect(!cases.isEmpty)
        for c in cases {
            var r = GameRules()
            r.triples = c.triples
            r.diceCount = c.diceCount ?? 5
            r.straight6 = c.straight6 ?? .five
            guard c.dice.count <= r.diceCount else { continue }
            let full = c.fullThrow && c.dice.count == r.diceCount
            guard full == c.fullThrow else { continue }   // Teilwurf als „voll“ markiert: Tool kann das nicht ausdrücken
            let text = RegelTools.wertung(c.dice, alleGeworfen: c.fullThrow, nachUebernahme: false, rules: r)
            if let expected = c.expectedScore {
                #expect(text == "\(expected) Punkte", "\(c.name): \(text)")
            } else {
                #expect(text.hasPrefix("Zählt"), "\(c.name): \(text)")
            }
        }
    }

    @Test func toolsForTypicalQuestions() {
        let r = GameRules()
        #expect(RegelTools.wertung([1, 1, 5], alleGeworfen: false, nachUebernahme: false, rules: r) == "250 Punkte")
        #expect(RegelTools.besteAuswahl([4, 4, 4, 4, 2], alleGeworfen: true, nachUebernahme: false, rules: r)
                == "Beste Auswahl 4, 4, 4 = 400 Punkte, Rest 4, 2.")
        #expect(RegelTools.wertung([1, 2, 3, 4, 5], alleGeworfen: true, nachUebernahme: true, rules: r).contains("150"))
        #expect(RegelTools.besteAuswahl([2, 3, 4, 6, 6], alleGeworfen: true, nachUebernahme: false, rules: r).hasPrefix("Niete"))
        #expect(RegelTools.zug([[1], [2, 3, 4, 5]], uebernommenePunkte: 0, erstesWurfNachUebernahme: false, rules: r)
                .contains("zählt so nicht"))
        #expect(RegelTools.zug([[1], [5]], uebernommenePunkte: 0, erstesWurfNachUebernahme: false, rules: r) == "Zug: 100 + 50 = 150 Punkte")
        #expect(RegelTools.zug([[5, 5]], uebernommenePunkte: 300, erstesWurfNachUebernahme: true, rules: r) == "Zug: 300 + 100 = 400 Punkte")
        // Alle rausgelegt → wieder voller Wurf, Straße zählt
        #expect(RegelTools.zug([[1, 1, 1, 5, 5], [1, 2, 3, 4, 5]], uebernommenePunkte: 0, erstesWurfNachUebernahme: false, rules: r)
                == "Zug: 1100 + 1000 = 2100 Punkte")
        #expect(RegelTools.wertung([1, 1, 1, 1, 1, 1], alleGeworfen: true, nachUebernahme: false, rules: r).hasPrefix("Zu viele"))
        #expect(RegelTools.nachschlagen("Strafe", rules: r).contains("3 Nieten"))
        #expect(RegelTools.nachschlagen("Schlussrunde", rules: r).contains("aus"))
        for thema in RegelTools.themen {
            #expect(!RegelTools.nachschlagen(thema, rules: r).hasPrefix("Dazu gibt es"), "\(thema)")
        }
    }

    /// Zusammenfassung nennt nur die aktive Variante.
    @Test func summaryCoversVariants() {
        let std = RegelZusammenfassung.text(GameRules())
        #expect(std.contains("Ziel: 10000"))
        #expect(std.contains("Drei Einsen = 1000"))
        #expect(std.contains("−500"))
        #expect(std.contains("KEINE drei Paare"))
        #expect(!std.contains("500, drei Fünfen"))

        var r = GameRules()
        r.triples = .onesAndFives
        r.penalty = 0
        r.inheritAllFive = false
        r.roundLimit = 8
        r.tiebreak = false
        r.finalRound = true
        let v = RegelZusammenfassung.text(r)
        #expect(v.contains("Drei Einsen = 500"))
        #expect(!v.contains("vier Vieren = 400"))
        #expect(!v.contains("Drei Einsen = 1000"))
        #expect(v.contains("Strafe: keine"))
        #expect(v.contains("kann NICHT übernommen werden"))
        #expect(v.contains("8 Runden"))
        #expect(v.contains("kein Stechen"))
        #expect(v.contains("Schlussrunde: an"))
        #expect(RegelTools.nachschlagen("Ziel", rules: r).contains("nicht sofort"))
        #expect(RegelTools.nachschlagen("Ziel", rules: GameRules()).contains("gewinnt sofort"))

        var six = GameRules()
        six.diceCount = 6
        #expect(RegelZusammenfassung.text(six).contains("sechste Würfel"))
        six.straight6 = .full
        #expect(RegelZusammenfassung.text(six).contains("1–6 = \(Scoring.bigStraightPoints)"))
    }

    @Test func gradingFollowsHints() {
        #expect(RegelChatGrading.passes("Das sind 1.000 Punkte.", must: ["1000"], mustNot: ["500"]))
        #expect(!RegelChatGrading.passes("Das sind 1.250 Punkte.", must: ["250"], mustNot: []))
        #expect(RegelChatGrading.passes("Nein, das zählt nicht.", must: ["nein|nicht"], mustNot: ["ja,"]))
        #expect(!RegelChatGrading.passes("Ja, 400 Punkte", must: ["400"], mustNot: ["ja,"]))
    }
}

/// Bewertung nach `_hinweis` in Shared/regelchat/testfragen.json
nonisolated enum RegelChatGrading {
    static func normalize(_ s: String) -> String {
        var t = s.lowercased()
        // Tausenderpunkte zwischen Ziffern entfernen
        t = t.replacingOccurrences(of: #"(?<=\d)\.(?=\d{3})"#, with: "", options: .regularExpression)
        return t
    }

    private static func contains(_ text: String, _ token: String) -> Bool {
        let tok = token.lowercased()
        if Int(tok) != nil {
            // Ganze Zahl: nicht Teil einer längeren Zahl
            return text.range(of: #"(?<!\d)"# + tok + #"(?!\d)"#, options: .regularExpression) != nil
        }
        return text.contains(tok)
    }

    static func passes(_ answer: String, must: [String], mustNot: [String]) -> Bool {
        let t = normalize(answer)
        let allMust = must.allSatisfy { alt in alt.split(separator: "|").contains { contains(t, String($0)) } }
        let noForbidden = !mustNot.contains { contains(t, $0) }
        return allMust && noForbidden
    }
}


/// Vorab-Rechnung aus der Frage (ohne Modell)
struct RegelChatKontextTests {
    @Test func readsDiceFromQuestions() {
        #expect(RegelChatKontext.diceLists(in: "Ich habe 1, 1 und 5 rausgelegt.") == [[1, 1, 5]])
        #expect(RegelChatKontext.diceLists(in: "Ich habe 4-4-4-4-2 geworfen.") == [[4, 4, 4, 4, 2]])
        // 1.2: Satzende-Punkt nach dem letzten Würfel (vorher fiel die letzte 6 weg)
        #expect(RegelChatKontext.diceLists(in: "Mein Wurf: 2, 3, 4, 6, 6. Was kann ich rauslegen?") == [[2, 3, 4, 6, 6]])
        #expect(RegelChatKontext.diceLists(in: "Ziel sind 10.000 Punkte, ich habe 1 und 5.") == [[1, 5]])
        #expect(RegelChatKontext.diceLists(in: "Was bringen drei Einsen?") == [[1, 1, 1]])
        #expect(RegelChatKontext.diceLists(in: "Habe ich sofort gewonnen, wenn ich 10.000 Punkte erreiche?").isEmpty)
        #expect(RegelChatKontext.diceLists(in: "Wir spielen 10 Runden.").isEmpty)
    }

    @Test func precomputesTheRightNumbers() {
        let r = GameRules()
        func z(_ q: String, _ rules: GameRules = GameRules()) -> String { RegelChatKontext.zusatz(for: q, rules: rules) ?? "" }
        #expect(z("Ich habe 1, 1 und 5 rausgelegt. Wie viele Punkte sind das?").contains("250 Punkte"))
        #expect(z("Ich habe vier Einsen geworfen. Wie viel ist das?").contains("1100 Punkte"))
        #expect(z("Ich habe 4-4-4-4-2 geworfen.").contains("= 400 Punkte"))
        let g02 = z("Ich habe erst eine 1 rausgelegt und dann mit den restlichen vier Würfeln 2-3-4-5 geworfen. Habe ich jetzt eine Straße?")
        #expect(g02.contains("= 50 Punkte") && g02.contains("Keine Straße"))
        #expect(g02.contains("Zusammen: 150 Punkte"))
        #expect(RegelChatKontext.mehrereWuerfe(in: "Was bringen drei Einsen?", rules: r) == nil)
        let g03 = z("Ich habe mit allen 5 Würfeln übernommen und direkt 1-2-3-4-5 geworfen. Zählt die Straße?")
        #expect(g03.contains("= 150 Punkte") && g03.contains("Übernahme"))
        var six = r
        six.diceCount = 6
        #expect(z("Wie viel ist 1-2-3-4-5-5?", six).contains("1050"))
        #expect(z("Ich habe mit 6 Würfeln 2-2-2-4-4-4 geworfen.", six).contains("600"))
        #expect(z("Was passiert, wenn nach der letzten Runde zwei gleich viele Punkte haben?").contains("Stechen"))
        var noAll = GameRules()
        noAll.inheritAllFive = false
        #expect(z("Mein Vorgänger hat alle Würfel rausgelegt und aufgehört. Kann ich übernehmen?", noAll).contains("NEIN"))
        #expect(z("Mein Vorgänger hat alle Würfel rausgelegt und aufgehört. Kann ich übernehmen?").contains("JA"))
    }
}

/// 1.0.1 (8): Begriffe, Beispiele und erweiterte Erkennung
struct RegelChatWissenTests {
    @Test func examplesFollowRules() {
        let std = RegelChatWissen.beispiele(GameRules())
        #expect(std.contains("A: 200 Punkte"))          // 1, 5, 5
        #expect(std.contains("300 Punkte für drei Dreien"))   // 3-3-3-3-6
        #expect(std.contains("Rauslegen: 150 Punkte"))  // Straße nach Übernahme
        var of = GameRules()
        of.triples = .onesAndFives
        #expect(RegelChatWissen.beispiele(of).contains("Niete"))   // vier Vieren zählen dort nicht
    }

    @Test func promptFitsTheContextWindow() {
        // grobe Schätzung: ~4 Zeichen je Token; Anleitung soll unter ~2.000 Token bleiben
        var six = GameRules()
        six.diceCount = 6
        for r in [GameRules(), six] {
            let e = RegelChatPrompt.bauen(frage: "", wissen: ZehnkRegelWissen(rules: r), grenzen: ZehnkRegelChat.grenzen)
            #expect(e.anweisungen.count < 8_000)
            #expect(e.anweisungen.hasPrefix("Du bist die Regelhilfe der App „10k"))
            #expect(e.anweisungen.contains("AKTUELLE REGELN"))
            #expect(e.anweisungen.contains("BEGRIFFE"))
            #expect(e.anweisungen.contains("BEISPIELE (so antwortest du)"))
        }
    }

    @Test func fallbackAndExplicitFacts() {
        var noPenalty = GameRules()
        noPenalty.penalty = 0
        #expect(RegelChatKontext.regelAntwort(for: "Gibt es bei uns eine Strafe nach drei Nieten?", rules: noPenalty)?.contains("keine Strafe") == true)
        #expect((RegelChatKontext.zusatz(for: "Zählt die Straße 2-3-4-5-6 auch?", rules: GameRules()) ?? "").contains("JA, das ist eine Straße"))
        #expect((RegelChatKontext.zusatz(for: "Zählen zwei Fünfer und zwei Zweier zusammen was?", rules: GameRules()) ?? "").contains("Nicht gezählt: 2, 2"))
        #expect((RegelChatKontext.zusatz(for: "Darf ich nach einem Wurf gar nichts rauslegen und einfach nochmal würfeln?", rules: GameRules()) ?? "").contains("NEIN"))
    }

    @Test func breakdown() {
        var six = GameRules()
        six.diceCount = 6
        #expect(RegelTools.aufschluesselung([1, 1, 1, 1, 1, 1], full: true, rules: six) == "Drilling Einsen 1000 + 3 einzelne Einsen je 100")
        #expect(RegelTools.aufschluesselung([2, 2, 2, 4, 4, 4], full: true, rules: six) == "Drilling Zweien 200 + Drilling Vieren 400")
        #expect(RegelTools.aufschluesselung([5, 5, 2, 2], full: false, rules: GameRules()) == "2 einzelne Fünfen je 50")
        #expect(RegelTools.aufschluesselung([1, 2, 3, 4, 5], full: true, rules: GameRules()) == "Straße")
        #expect((RegelChatKontext.zusatz(for: "Ich habe sechs Einsen geworfen.", rules: six) ?? "").contains("Drilling Einsen 1000 + 3 einzelne Einsen je 100"))
        #expect((RegelChatKontext.zusatz(for: "Zählen zwei Fünfer und zwei Zweier zusammen was?", rules: GameRules()) ?? "").contains("= 100 Punkte"))
    }

    /// Im Spiel: aktueller Wurf mit Swift-Rechnung
    @Test func turnContext() {
        var t = DiceTurn(count: 5)
        #expect(RegelChatKontext.zugText(t, rules: GameRules())?.contains("Noch nicht gewürfelt") == true)
        t.dice = [1, 3, 5, 2, 6]
        t.hasRolled = true
        t.fullThrow = true
        let text = RegelChatKontext.zugText(t, rules: GameRules()) ?? ""
        #expect(text.contains("1-3-5-2-6"))
        #expect(text.contains("= 150 Punkte"))
        t.locked = [true, false, false, false, false]
        t.banked = 100
        t.fullThrow = false
        t.dice = [1, 2, 3, 4, 5]
        let partial = RegelChatKontext.zugText(t, rules: GameRules()) ?? ""
        #expect(partial.contains("Gesichert in diesem Zug: 100"))
        #expect(partial.contains("2-3-4-5"))
        #expect(partial.contains("= 50 Punkte"))      // keine Straße mit 4 Würfeln
    }

    @Test func readsWordsAndSpaces() {
        #expect(RegelChatKontext.diceLists(in: "Zwei Fünfen und eine Eins, was ist das wert?") == [[5, 5, 1]])
        #expect(RegelChatKontext.diceLists(in: "Ich habe sechs Einsen geworfen.") == [[1, 1, 1, 1, 1, 1]])
        #expect(RegelChatKontext.diceLists(in: "Wurf 1 1 5 3 2") == [[1, 1, 5, 3, 2]])
        #expect(RegelChatKontext.diceLists(in: "Bis wie viele Punkte spielen wir?").isEmpty)
        var six = GameRules()
        six.diceCount = 6
        #expect((RegelChatKontext.zusatz(for: "Ich habe sechs Einsen geworfen. Wie viel ist das?", rules: six) ?? "").contains("1300"))
        #expect((RegelChatKontext.zusatz(for: "Ich hab erst 5-5 rausgelegt und dann mit den restlichen drei Würfeln 1-1-1 geworfen.", rules: GameRules()) ?? "").contains("Zusammen: 1100"))
        #expect((RegelChatKontext.zusatz(for: "Gibt es Punkte für drei Paare, zum Beispiel 2-2-4-4-6-6?", rules: six) ?? "").contains("Niete"))
        #expect((RegelChatKontext.zusatz(for: "Ich hab einen Zonk geworfen.", rules: GameRules()) ?? "").contains("Niete"))
    }
}

/// 1.2: Rechenfragen ohne Modell – jede direkt beantwortete Testfrage muss die Bewertung bestehen.
struct RegelChatDirektTests {
    private struct Frage: Decodable {
        let id: String
        let frage: String
        let regeln: [String: Wert]
        let muss_enthalten: [String]
        let darf_nicht_enthalten: [String]
    }

    private enum Wert: Decodable {
        case b(Bool), i(Int), s(String)
        init(from d: Decoder) throws {
            let c = try d.singleValueContainer()
            if let v = try? c.decode(Bool.self) { self = .b(v) }
            else if let v = try? c.decode(Int.self) { self = .i(v) }
            else { self = .s(try c.decode(String.self)) }
        }
        var any: Any { switch self { case .b(let v): v; case .i(let v): v; case .s(let v): v } }
    }

    private func fragen() throws -> [Frage] {
        struct File: Decodable { let fragen: [Frage] }
        let url = sharedRoot.appendingPathComponent("regelchat/testfragen.json")
        return try JSONDecoder().decode(File.self, from: Data(contentsOf: url)).fragen
    }

    private func regeln(_ f: Frage) throws -> GameRules {
        let data = try JSONSerialization.data(withJSONObject: f.regeln.mapValues(\.any))
        return try JSONDecoder().decode(GameRules.self, from: data)
    }

    @Test func directAnswersPass() throws {
        var direkt: [String] = []
        for f in try fragen() {
            guard let a = RegelChatDirekt.antwort(for: f.frage, rules: try regeln(f)) else { continue }
            direkt.append(f.id)
            #expect(RegelChatGrading.passes(a, must: f.muss_enthalten, mustNot: f.darf_nicht_enthalten), "\(f.id): \(a)")
        }
        // Alle Rechenfragen mit Würfeln bzw. Übernahme-Summe laufen ohne Modell
        for id in ["w01", "w02", "w03", "w04", "w05", "w06", "w07", "w08", "w09", "g01", "g02", "g03", "g04",
                   "g05", "g06", "g07", "g08", "v01", "v03", "v04", "v05", "v10", "v11", "a04",
                   // Build 11: feste Regel-Fakten
                   "a01", "a02", "a03", "a05", "a06", "a09", "a10", "v08"] {
            #expect(direkt.contains(id), "\(id) nicht direkt beantwortet")
        }
    }

    @Test func numberGuard() {
        let r = GameRules()
        #expect(RegelChatDirekt.zahlen(in: "Das sind 1.000 Punkte, −500 bei Strafe") == [1000, 500])
        #expect(RegelChatDirekt.zahlenOK("Drei Einsen bringen 1000 Punkte.", question: "Was bringen drei Einsen?", rules: r))
        // Erfundene Zahl (kommt in keiner Regel vor) wird erkannt. Grenze: Eine gültige Regelzahl an falscher
        // Stelle (z. B. 200) erkennt der Wächter nicht – darum beantwortet Swift Würfelfragen allein.
        let erfunden = RegelChatDirekt.zahlenOK("Zwei Fünfer ergeben 1250 Punkte.", question: "Was ist eine Niete?", rules: r)
        #expect(erfunden == false)
        #expect(RegelChatDirekt.zahlenOK("3 Nieten in Folge kosten 500.", question: "Was ist die Strafe?", rules: r))
        var ohne = GameRules()
        ohne.penalty = 0
        #expect(!RegelChatDirekt.zahlenOK("Die Strafe ist 700 Punkte.", question: "Gibt es eine Strafe?", rules: ohne))
    }
}

/// KI-2: Der Umzug auf das Gerüst ändert nichts am Verhalten ohne Modell.
struct ZehnkRegelWissenTests {
    @Test func promptIstWortgleichAufgebaut() {
        let r = GameRules()
        let w = ZehnkRegelWissen(rules: r)
        let e = RegelChatPrompt.bauen(frage: "Was bringen drei Einsen?", wissen: w, grenzen: ZehnkRegelChat.grenzen)
        let erwartet = [ZehnkRegelWissen.anweisungen, RegelZusammenfassung.text(r), RegelChatWissen.begriffe, RegelChatWissen.beispiele(r)]
            .joined(separator: "\n\n")
        #expect(e.anweisungen == erwartet)
        #expect(e.quellen.isEmpty)
        // Fakten kommen ohne zusätzliche Überschrift hinter die Frage, wie vorher
        let zusatz = RegelChatKontext.zusatz(for: "Zählen 1, 5 und 5?", rules: r) ?? ""
        let p = RegelChatPrompt.bauen(frage: "Zählen 1, 5 und 5?", wissen: w, zusatz: zusatz, grenzen: ZehnkRegelChat.grenzen).prompt
        #expect(p == "Zählen 1, 5 und 5?\n\n" + zusatz)
    }

    @Test func direktAntwortenUndWaechterQuellen() async throws {
        let w = ZehnkRegelWissen(rules: GameRules())
        let modell = RegelChatAttrappe(standard: "darf nicht aufgerufen werden")
        let a = try await RegelChatMotor.antworten(frage: "Was bringen 1, 1 und 5?", wissen: w, modell: modell,
                                                   grenzen: ZehnkRegelChat.grenzen)
        #expect(a.weg == .direkt)
        #expect(a.text.contains("250"))
        #expect(modell.anfragen.isEmpty)
        // Zahl aus den Regelabschnitten (nicht im Prompt) bleibt erlaubt, eine erfundene nicht
        let ok = try await RegelChatMotor.antworten(frage: "Erkläre die faire Schlussrunde", wissen: w,
                                                    modell: RegelChatAttrappe(standard: "Die Schlussrunde zählt bis 500 Punkte."), grenzen: ZehnkRegelChat.grenzen)
        #expect(ok.weg == .modell)
        let falsch = try await RegelChatMotor.antworten(frage: "Erkläre die faire Schlussrunde", wissen: w,
                                                        modell: RegelChatAttrappe(standard: "Die Schlussrunde zählt bis 777 Punkte."), grenzen: ZehnkRegelChat.grenzen)
        #expect(falsch.weg == .waechter)
        #expect(!falsch.text.contains("777"))
    }

    @Test func statusShim() {
        RegelChatUmgebung.statusVorgabe = .hidden
        defer { RegelChatUmgebung.statusVorgabe = nil }
        #expect(!RegelChatStatus.sichtbar(experimente: true))
        RegelChatUmgebung.statusVorgabe = .notEnabled
        #expect(RegelChatStatus.sichtbar(experimente: false))
    }
}
