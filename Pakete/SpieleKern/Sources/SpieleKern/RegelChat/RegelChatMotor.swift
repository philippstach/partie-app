// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Fehler, die der Regel-Chat unterscheidet (unabhängig von Apple-Typen).
public enum RegelChatFehler: Error, Equatable, Sendable {
    /// Anweisungen, Regeltext und Frage waren zu lang für das Modell
    case kontextZuGross
    /// Der Inhaltsfilter des Modells hat die Frage oder Antwort blockiert
    case inhaltsfilter
    /// Das Modell kann die Sprache nicht
    case spracheNichtUnterstuetzt
    case sonstiger

    /// Freundlicher Text für den Chat (Hinweis auf die normalen Regeln)
    public static func freundlich(_ fehler: Error) -> String {
        switch fehler as? RegelChatFehler {
        case .some(.kontextZuGross):
            return "Die Frage war zu lang. Stell sie bitte kürzer – oder schau unter „Regeln“ nach."
        case .some(.inhaltsfilter):
            return "Darauf kann ich nicht antworten. Schau gern unter „Regeln“ nach."
        case .some(.spracheNichtUnterstuetzt):
            return "Ich verstehe nur Deutsch. Schau sonst unter „Regeln“ nach."
        default:
            return "Das hat gerade nicht geklappt. Versuch es noch einmal oder schau unter „Regeln“ nach."
        }
    }
}

/// Antwort des Sprachmodells samt Namen der aufgerufenen Werkzeuge (für Test und Prüfung)
public struct RegelChatModellAntwort: Sendable, Equatable {
    public let text: String
    public let werkzeuge: [String]
    public init(text: String, werkzeuge: [String] = []) {
        self.text = text
        self.werkzeuge = werkzeuge
    }
}

/// Das Sprachmodell hinter dem Chat. Echte Umsetzung: `AppleSprachmodell` (iOS 26, FoundationModels).
/// Für Tests und den Simulator: `RegelChatAttrappe`. Neue Sitzung je Frage (Kontextfenster 4096 Token).
public protocol RegelChatSprachmodell: Sendable {
    func antworte(anweisungen: String, prompt: String, deterministisch: Bool) async throws -> RegelChatModellAntwort
    /// Modell vorwärmen (damit die erste Antwort schneller kommt); kann leer bleiben
    func vorwaermen(anweisungen: String)
}

public extension RegelChatSprachmodell {
    func vorwaermen(anweisungen: String) {}
}

/// Wie die Antwort zustande kam
public enum RegelChatWeg: String, Sendable, Equatable {
    /// Swift allein, ohne Modell
    case direkt
    /// Das Modell hat formuliert
    case modell
    /// Das Modell nannte eine Zahl, die nicht in den Regeln steht: Regeltext statt Antwort
    case waechter
    /// Das Modell scheiterte (Filter, Kontext): Regeltext statt Antwort
    case regeltext
}

public struct RegelChatAntwort: Sendable, Equatable {
    public let text: String
    /// Titel der Abschnitte, aus denen geantwortet wurde (leer bei Direktantwort)
    public let quellen: [String]
    public let werkzeuge: [String]
    public let weg: RegelChatWeg
}

/// Ablauf einer Frage: Direktantwort → Prompt aus passenden Abschnitten → Modell → Zahlen-Wächter,
/// mit Rückfall auf den Regeltext. Ohne Apple-Typen, daher mit der Attrappe testbar.
public enum RegelChatMotor {
    public static func antworten(frage: String, wissen: any RegelWissen,
                                 vorige: (frage: String, antwort: String)? = nil,
                                 zug: String? = nil,
                                 modell: any RegelChatSprachmodell,
                                 grenzen: RegelChatGrenzen = .standard,
                                 deterministisch: Bool = false) async throws -> RegelChatAntwort {
        // Rechenfragen und feste Fakten beantwortet Swift allein
        if let direkt = wissen.direktAntwort(auf: frage) {
            return RegelChatAntwort(text: direkt, quellen: [], werkzeuge: ["swift"], weg: .direkt)
        }
        let fakten = wissen.zusatz(zu: frage)
        var eingabe = RegelChatPrompt.bauen(frage: frage, wissen: wissen, vorige: vorige, zug: zug,
                                            zusatz: fakten, grenzen: grenzen)
        let antwort: RegelChatModellAntwort
        do {
            antwort = try await modell.antworte(anweisungen: eingabe.anweisungen, prompt: eingabe.prompt,
                                                deterministisch: deterministisch)
        } catch is CancellationError {
            throw CancellationError()
        } catch let fehler as RegelChatFehler where fehler == .kontextZuGross {
            // Einmal mit weniger Regeltext wiederholen
            eingabe = RegelChatPrompt.bauen(frage: frage, wissen: wissen, vorige: nil, zug: zug,
                                            zusatz: fakten, grenzen: .knapp)
            do {
                antwort = try await modell.antworte(anweisungen: eingabe.anweisungen, prompt: eingabe.prompt,
                                                    deterministisch: deterministisch)
            } catch {
                if error is CancellationError { throw error }
                return try regeltextOderFehler(frage: frage, wissen: wissen, fehler: error)
            }
        } catch let fehler as RegelChatFehler where fehler == .spracheNichtUnterstuetzt {
            throw fehler
        } catch {
            return try regeltextOderFehler(frage: frage, wissen: wissen, fehler: error)
        }

        // Zahlen-Wächter: nur Zahlen aus Frage, Regeln, Fakten, Beispielen und früherer Antwort
        var quellen = [frage, wissen.aktiveRegeln, wissen.begriffe, wissen.beispiele]
        quellen += wissen.abschnitte.map { "\($0.titel) \($0.text)" }
        if let fakten { quellen.append(fakten) }
        quellen += wissen.waechterQuellen
        if let zug { quellen.append(zug) }
        if let vorige { quellen.append("\(vorige.frage) \(vorige.antwort)") }
        guard RegelChatZahlen.ok(antwort: antwort.text, quellen: quellen) else {
            let ersatz = regeltext(frage: frage, wissen: wissen)
            return RegelChatAntwort(text: ersatz?.text ?? Self.keineSichereAntwort, quellen: ersatz?.quellen ?? [],
                                    werkzeuge: antwort.werkzeuge + ["wächter"], weg: .waechter)
        }
        return RegelChatAntwort(text: antwort.text, quellen: eingabe.quellen, werkzeuge: antwort.werkzeuge, weg: .modell)
    }

    static let keineSichereAntwort = "Dazu kann ich keine sichere Antwort geben. Schau bitte unter „Regeln“ nach."

    /// Der passende Regeltext ohne Modell (höchstens zwei Abschnitte, je gekürzt); `nil`, wenn nichts passt.
    static func regeltext(frage: String, wissen: any RegelWissen) -> (text: String, quellen: [String])? {
        if let eigene = wissen.ersatzAntwort(auf: frage) { return (eigene, []) }
        let treffer = RegelChatAuswahl.waehle(frage: frage, aus: wissen.abschnitte, maxAnzahl: 2,
                                              maxZeichen: 800, ersatzErster: false)
        guard !treffer.isEmpty else { return nil }
        let text = "Laut den Regeln: " + treffer.map { RegelChatAuswahl.kuerzen($0.text, auf: 400) }.joined(separator: " ")
        return (text, treffer.map(\.titel))
    }

    private static func regeltextOderFehler(frage: String, wissen: any RegelWissen, fehler: Error) throws -> RegelChatAntwort {
        guard let ersatz = regeltext(frage: frage, wissen: wissen) else { throw fehler }
        return RegelChatAntwort(text: ersatz.text, quellen: ersatz.quellen, werkzeuge: [], weg: .regeltext)
    }
}
