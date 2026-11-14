// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Sprachmodell-Attrappe für Tests und den Simulator (dort gibt es meist kein Apple-Intelligence-Modell).
/// Liefert feste Antworten: die erste Regel, deren Stichwort im Prompt vorkommt, sonst `standard`.
public final class RegelChatAttrappe: RegelChatSprachmodell, @unchecked Sendable {
    public struct Antwort: Sendable, Equatable {
        public let stichwort: String
        public let text: String
        public init(stichwort: String, text: String) {
            self.stichwort = stichwort
            self.text = text
        }
    }

    public struct Anfrage: Sendable, Equatable {
        public let anweisungen: String
        public let prompt: String
    }

    private let sperre = NSLock()
    private var _anfragen: [Anfrage] = []
    private var _fehlerFolge: [RegelChatFehler]

    public let antworten: [Antwort]
    public let standard: String

    /// - Parameter fehlerFolge: Fehler, die die ersten Aufrufe werfen (einer je Aufruf), danach antwortet sie normal.
    public init(antworten: [Antwort] = [], standard: String = "Keine Ahnung.", fehlerFolge: [RegelChatFehler] = []) {
        self.antworten = antworten
        self.standard = standard
        self._fehlerFolge = fehlerFolge
    }

    /// Alle bisherigen Aufrufe (für Prüfungen wie „Prompt unter der Grenze“)
    public var anfragen: [Anfrage] {
        sperre.lock()
        defer { sperre.unlock() }
        return _anfragen
    }

    public func antworte(anweisungen: String, prompt: String, deterministisch: Bool) async throws -> RegelChatModellAntwort {
        sperre.lock()
        _anfragen.append(Anfrage(anweisungen: anweisungen, prompt: prompt))
        let fehler = _fehlerFolge.isEmpty ? nil : _fehlerFolge.removeFirst()
        sperre.unlock()
        if let fehler { throw fehler }
        let klein = prompt.lowercased()
        if let treffer = antworten.first(where: { klein.contains($0.stichwort.lowercased()) }) {
            return RegelChatModellAntwort(text: treffer.text, werkzeuge: ["attrappe"])
        }
        return RegelChatModellAntwort(text: standard, werkzeuge: ["attrappe"])
    }
}
