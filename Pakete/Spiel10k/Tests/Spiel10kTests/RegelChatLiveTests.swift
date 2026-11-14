// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k
import SpieleKern
#if canImport(FoundationModels)
import FoundationModels
#endif

// Live-Testfragen mit dem echten Modell. Nur im Paketlauf (Spiel10kTests); das App-Testziel Tests10k
// schließt diese Datei aus (project.yml), weil sie dort nicht übersetzt (Zehnk-Typen nicht gefunden).

nonisolated private let sharedRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Shared")

#if canImport(FoundationModels)
/// Regel-Chat, Teil B: die 20 Testfragen mit dem echten Modell. Nur wenn Apple Intelligence verfügbar ist.
nonisolated func regelChatModelAvailable() -> Bool {
    if #available(iOS 26.0, *) { return SystemLanguageModel.default.isAvailable }
    return false
}

@Suite(.enabled(if: regelChatModelAvailable()), .serialized)
struct RegelChatEvalTests {

    struct Frage: Decodable {
        let id: String
        let frage: String
        let regeln: [String: AnyCodable]
        let muss_enthalten: [String]
        let darf_nicht_enthalten: [String]
        let kategorie: String
    }

    struct AnyCodable: Codable {
        let value: Any
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let b = try? c.decode(Bool.self) { value = b }
            else if let i = try? c.decode(Int.self) { value = i }
            else { value = try c.decode(String.self) }
        }
        func encode(to encoder: Encoder) throws {}
    }

    private static func rules(_ partial: [String: AnyCodable]) throws -> GameRules {
        let dict = partial.mapValues(\.value)
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(GameRules.self, from: data)
    }

    /// Greedy (reproduzierbar) plus drei Durchläufe mit Standard-Sampling; schreibt eine Tabelle.
    @available(iOS 26.0, macOS 26.0, *)
    @Test func testfragen() async throws {
        let data = try Data(contentsOf: sharedRoot.appendingPathComponent("regelchat/testfragen.json"))
        struct File: Decodable { let fragen: [Frage] }
        let fragen = try JSONDecoder().decode(File.self, from: data).fragen
        let runs = Int(ProcessInfo.processInfo.environment["REGELCHAT_RUNS"] ?? "") ?? 0
        var report = "id\tkategorie\tlauf\tok\ttools\tsekunden\tantwort\n"
        var passedPerRun = Array(repeating: 0, count: runs + 1)
        var numberErrors = 0
        var toolMisses = 0
        for f in fragen {
            let r = try Self.rules(f.regeln)
            for run in 0...runs {
                let start = Date()
                let (text, tools): (String, [String])
                do {
                    let a = try await RegelChatMotor.antworten(frage: f.frage, wissen: ZehnkRegelWissen(rules: r),
                                                               modell: ZehnkRegelChat.modell(r), grenzen: ZehnkRegelChat.grenzen,
                                                               deterministisch: run == 0)
                    (text, tools) = (a.text, a.werkzeuge)
                } catch {
                    (text, tools) = ("FEHLER: \(error)", [])
                }
                let secs = Date().timeIntervalSince(start)
                let ok = RegelChatGrading.passes(text, must: f.muss_enthalten, mustNot: f.darf_nicht_enthalten)
                if ok { passedPerRun[run] += 1 }
                let numeric = ["wertung", "grenzfall", "variante"].contains(f.kategorie)
                    && f.muss_enthalten.contains { Int($0.split(separator: "|").first ?? "") != nil }
                if run == 0 && numeric && !ok { numberErrors += 1 }
                if run == 0 && numeric && tools.isEmpty { toolMisses += 1 }
                let clean = text.replacingOccurrences(of: "\n", with: " ")
                report += "\(f.id)\t\(f.kategorie)\t\(run == 0 ? "greedy" : "s\(run)")\t\(ok ? "✓" : "✗")\t\(tools.joined(separator: ","))\t\(String(format: "%.1f", secs))\t\(clean)\n"
            }
        }
        report += "\nBestanden: greedy \(passedPerRun[0])/\(fragen.count)"
        if runs > 0 { report += ", Sampling " + passedPerRun.dropFirst().map { "\($0)/\(fragen.count)" }.joined(separator: ", ") }
        report += "\nFalsche Zahlen (greedy, Punktfragen): \(numberErrors), ohne Tool-Aufruf: \(toolMisses)\n"
        // Simulator: direkt in den Projektordner (build/ ist nicht versioniert); Gerät: temporärer Ordner
        let buildDir = sharedRoot.deletingLastPathComponent().appendingPathComponent("build")
        let dir = FileManager.default.isWritableFile(atPath: buildDir.path) ? buildDir : URL(fileURLWithPath: NSTemporaryDirectory())
        let out = dir.appendingPathComponent("regelchat-report-\(runs == 0 ? "greedy" : "runs\(runs)").tsv")
        try report.write(to: out, atomically: true, encoding: .utf8)
        print("REGELCHAT-REPORT \(out.path)\n\(report)")
        // Kein harter Fehlschlag: Das Ergebnis ist eine Messung (Abnahme siehe Plan §4)
        #expect(passedPerRun[0] >= 0)
    }
}
#endif
