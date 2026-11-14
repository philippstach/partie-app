// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(FoundationModels)
import FoundationModels

/// Das echte Modell: Apples Sprachmodell auf dem Gerät (FoundationModels, iOS 26). Nur über
/// `#available(iOS 26)` anlegen. Rechen-Werkzeuge (`Tool`) bringt das Spiel mit (10k: Wertung, Zug …).
@available(iOS 26.0, macOS 26.0, *)
public struct AppleSprachmodell: RegelChatSprachmodell, @unchecked Sendable {
    private let werkzeuge: [any Tool]
    /// Wörter, die den Inhaltsfilter auslösen können, und ihr neutraleres Ersatzwort (nur für den zweiten Versuch)
    private let weichmacher: [String: String]

    public init(werkzeuge: [any Tool] = [], weichmacher: [String: String] = [:]) {
        self.werkzeuge = werkzeuge
        self.weichmacher = weichmacher
    }

    public func vorwaermen(anweisungen: String) {
        LanguageModelSession(tools: werkzeuge, instructions: anweisungen).prewarm()
    }

    public func antworte(anweisungen: String, prompt: String, deterministisch: Bool) async throws -> RegelChatModellAntwort {
        let optionen = deterministisch ? GenerationOptions(sampling: .greedy) : GenerationOptions(temperature: 0.2)
        do {
            let sitzung = LanguageModelSession(tools: werkzeuge, instructions: anweisungen)
            return try await lauf(sitzung, prompt: prompt, optionen: optionen)
        } catch let fehler as LanguageModelSession.GenerationError {
            switch fehler {
            case .exceededContextWindowSize: throw RegelChatFehler.kontextZuGross
            case .unsupportedLanguageOrLocale: throw RegelChatFehler.spracheNichtUnterstuetzt
            default: break
            }
            // Harmlose Spielbegriffe lösen den Inhaltsfilter manchmal aus: einmal mit gelockerten Regeln
            // für Textumformungen und neutralerem Wort versuchen (wie im 10k-Chat).
            let gelockert = SystemLanguageModel(guardrails: .permissiveContentTransformations)
            let zweite = LanguageModelSession(model: gelockert, tools: werkzeuge, instructions: anweisungen)
            var weich = prompt
            for (wort, ersatz) in weichmacher { weich = weich.replacingOccurrences(of: wort, with: ersatz) }
            do {
                return try await lauf(zweite, prompt: weich, optionen: optionen)
            } catch let nochmal as LanguageModelSession.GenerationError {
                if case .exceededContextWindowSize = nochmal { throw RegelChatFehler.kontextZuGross }
                if case .guardrailViolation = nochmal { throw RegelChatFehler.inhaltsfilter }
                throw RegelChatFehler.sonstiger
            }
        }
    }

    private func lauf(_ sitzung: LanguageModelSession, prompt: String, optionen: GenerationOptions) async throws -> RegelChatModellAntwort {
        let antwort = try await sitzung.respond(to: prompt, options: optionen)
        var namen: [String] = []
        for eintrag in sitzung.transcript {
            if case .toolCalls(let aufrufe) = eintrag {
                namen += aufrufe.map(\.toolName)
            }
        }
        return RegelChatModellAntwort(text: antwort.content, werkzeuge: namen)
    }
}
#endif
