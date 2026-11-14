// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation

/// Zustand eines Regel-Chats (Nachrichten, „arbeitet“) für die spätere Oberfläche (KI-3). Ohne Apple-Typen:
/// das Modell kommt von außen (`AppleSprachmodell` oder `RegelChatAttrappe`).
@MainActor
@Observable
public final class RegelChatSitzung {
    public struct Nachricht: Identifiable, Equatable, Sendable {
        public let id = UUID()
        public let vonSpieler: Bool
        public let text: String
        /// Titel der Abschnitte, aus denen die Antwort stammt („aus Abschnitt …“)
        public let quellen: [String]
        public let istFehler: Bool

        public init(vonSpieler: Bool, text: String, quellen: [String] = [], istFehler: Bool = false) {
            self.vonSpieler = vonSpieler
            self.text = text
            self.quellen = quellen
            self.istFehler = istFehler
        }
    }

    public private(set) var nachrichten: [Nachricht] = []
    public private(set) var beschaeftigt = false
    public let wissen: any RegelWissen
    /// Aktueller Zug oder Stand im Spiel (nur Kontext), sonst `nil`
    public var zug: String?
    private let modell: any RegelChatSprachmodell
    private let grenzen: RegelChatGrenzen

    public init(wissen: any RegelWissen, modell: any RegelChatSprachmodell, zug: String? = nil,
                grenzen: RegelChatGrenzen = .standard) {
        self.wissen = wissen
        self.modell = modell
        self.zug = zug
        self.grenzen = grenzen
    }

    public func vorwaermen() {
        let eingabe = RegelChatPrompt.bauen(frage: "", wissen: wissen, grenzen: grenzen)
        modell.vorwaermen(anweisungen: eingabe.anweisungen)
    }

    public func frage(_ text: String) async {
        let frage = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !frage.isEmpty, !beschaeftigt else { return }
        // Rückfrage: nur wenn die letzte Nachricht eine echte Antwort war
        var vorige: (frage: String, antwort: String)?
        if let antwort = nachrichten.last, !antwort.vonSpieler, !antwort.istFehler,
           let davor = nachrichten.dropLast().last(where: \.vonSpieler) {
            vorige = (davor.text, antwort.text)
        }
        nachrichten.append(Nachricht(vonSpieler: true, text: frage))
        beschaeftigt = true
        defer { beschaeftigt = false }
        do {
            let ergebnis = try await RegelChatMotor.antworten(frage: frage, wissen: wissen, vorige: vorige, zug: zug,
                                                              modell: modell, grenzen: grenzen)
            nachrichten.append(Nachricht(vonSpieler: false, text: ergebnis.text, quellen: ergebnis.quellen))
        } catch {
            nachrichten.append(Nachricht(vonSpieler: false, text: RegelChatFehler.freundlich(error), istFehler: true))
        }
    }
}
