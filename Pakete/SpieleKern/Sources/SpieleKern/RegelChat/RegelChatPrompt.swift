// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Grenzen für den Prompt. Das Modell fasst 4096 Token je Sitzung für Anweisungen, Regeltext, Frage und Antwort
/// zusammen. Annahme: im Deutschen etwa 3 Zeichen je Token; 7000 Zeichen sind dann rund 2300 Token und lassen Platz
/// für die Antwort und die Beschreibung von Werkzeugen.
public struct RegelChatGrenzen: Sendable, Equatable {
    public var maxZeichenGesamt: Int
    public var maxAbschnitte: Int
    public var maxZeichenAbschnitte: Int

    public init(maxZeichenGesamt: Int = 7000, maxAbschnitte: Int = 3, maxZeichenAbschnitte: Int = 3200) {
        self.maxZeichenGesamt = maxZeichenGesamt
        self.maxAbschnitte = maxAbschnitte
        self.maxZeichenAbschnitte = maxZeichenAbschnitte
    }

    public static let standard = RegelChatGrenzen()
    /// Zweiter Versuch, wenn der Kontext zu groß war
    public static let knapp = RegelChatGrenzen(maxZeichenGesamt: 4200, maxAbschnitte: 1, maxZeichenAbschnitte: 1800)
}

/// Was an das Modell geht: Anweisungen (Sitzung) und Prompt (Frage), dazu die Abschnitte, aus denen geantwortet wird.
public struct RegelChatEingabe: Sendable, Equatable {
    public let anweisungen: String
    public let prompt: String
    /// Titel der verwendeten Abschnitte (für „aus Abschnitt …“)
    public let quellen: [String]
    public var zeichen: Int { anweisungen.count + prompt.count }
}

public enum RegelChatPrompt {
    /// Das feste Gerüst: nur aus den Regeln antworten, nichts erfinden, höchstens vier Sätze, Du-Form.
    public static func geruest(spielName: String) -> String {
        """
        Du bist die Regelhilfe für „\(spielName)“ in der App „Partie“.
        Du beantwortest nur Fragen zu den Regeln von „\(spielName)“ in dieser App.
        Grundlage sind ausschließlich die EINGESTELLTEN REGELN, die REGELN, die BEGRIFFE und die FAKTEN unten. \
        Andere Varianten aus dem Internet oder aus deinem Wissen gelten hier nicht. Erfinde keine Regeln. \
        Was nicht in den Regeln steht, gibt es in diesem Spiel nicht.

        Rechne nie selbst. Nenne nur Zahlen, die in den Regeln, in den Fakten oder in der Frage stehen. \
        Steht in den FAKTEN ein ERGEBNIS, nenne genau dieses.

        Antworte auf Deutsch, in der Du-Form, freundlich und kurz: höchstens vier Sätze. \
        Schreib Zahlen immer als Ziffern (5, nicht „fünf“). \
        Sprich alle Spielenden an, ohne Geschlecht („wer am Zug ist“, „die nächste Person“).

        Bist du unsicher oder fehlt eine Angabe, sag das offen und frag nach.

        Geht es nicht um die Regeln von „\(spielName)“, sag freundlich, dass du nur dazu Fragen beantwortest.
        """
    }

    /// Baut Anweisungen und Prompt. Passt alles nicht unter `maxZeichenGesamt`, entfallen zuerst die Beispiele,
    /// dann der schwächste Abschnitt (mindestens ein Abschnitt bleibt).
    public static func bauen(frage: String, wissen: any RegelWissen,
                             vorige: (frage: String, antwort: String)? = nil,
                             zug: String? = nil, zusatz: String? = nil,
                             grenzen: RegelChatGrenzen = .standard) -> RegelChatEingabe {
        let gewaehlt = RegelChatAuswahl.waehle(frage: frage, aus: wissen.abschnitte,
                                               maxAnzahl: grenzen.maxAbschnitte, maxZeichen: grenzen.maxZeichenAbschnitte)
        let prompt = promptText(frage: frage, vorige: vorige, zug: zug, zusatz: zusatz,
                                wortgleich: wissen.eigeneAnweisungen != nil)
        var letzte: RegelChatEingabe?
        for anzahl in stride(from: max(gewaehlt.count, 1), through: 1, by: -1) {
            for mitBeispielen in [true, false] {
                let ab = Array(gewaehlt.prefix(anzahl))
                let eingabe = RegelChatEingabe(
                    anweisungen: anweisungen(wissen: wissen, abschnitte: ab, mitBeispielen: mitBeispielen),
                    prompt: prompt, quellen: ab.map(\.titel))
                if eingabe.zeichen <= grenzen.maxZeichenGesamt { return eingabe }
                letzte = eingabe
            }
        }
        return letzte ?? RegelChatEingabe(anweisungen: geruest(spielName: wissen.name), prompt: prompt, quellen: [])
    }

    static func anweisungen(wissen: any RegelWissen, abschnitte: [RegelAbschnitt], mitBeispielen: Bool) -> String {
        if let eigene = wissen.eigeneAnweisungen {
            // Wortgleich: Das Spiel bringt Anweisungen und Überschriften selbst mit
            var teile = [eigene]
            if !wissen.aktiveRegeln.isEmpty { teile.append(wissen.aktiveRegeln) }
            if !abschnitte.isEmpty {
                teile.append("REGELN\n" + abschnitte.map { "## \($0.titel)\n\($0.text)" }.joined(separator: "\n\n"))
            }
            if !wissen.begriffe.isEmpty { teile.append(wissen.begriffe) }
            if mitBeispielen && !wissen.beispiele.isEmpty { teile.append(wissen.beispiele) }
            return teile.joined(separator: "\n\n")
        }
        var teile = [geruest(spielName: wissen.name)]
        if !wissen.zusatzAnweisungen.isEmpty { teile.append(wissen.zusatzAnweisungen) }
        if !wissen.aktiveRegeln.isEmpty { teile.append("EINGESTELLTE REGELN\n" + wissen.aktiveRegeln) }
        if !abschnitte.isEmpty {
            teile.append("REGELN\n" + abschnitte.map { "## \($0.titel)\n\($0.text)" }.joined(separator: "\n\n"))
        }
        if !wissen.begriffe.isEmpty { teile.append("BEGRIFFE\n" + wissen.begriffe) }
        if mitBeispielen && !wissen.beispiele.isEmpty { teile.append("BEISPIELE (so antwortest du)\n" + wissen.beispiele) }
        return teile.joined(separator: "\n\n")
    }

    static func promptText(frage: String, vorige: (frage: String, antwort: String)?, zug: String?, zusatz: String?,
                           wortgleich: Bool = false) -> String {
        var text = frage
        if let vorige {
            text = "Vorige Frage: \(vorige.frage)\nDeine Antwort: \(vorige.antwort)\n\nNeue Frage: \(frage)"
        }
        if let zusatz, !zusatz.isEmpty { text += "\n\n" + (wortgleich ? "" : "FAKTEN\n") + zusatz }
        if let zug, !zug.isEmpty { text += "\n\n" + zug }
        return text
    }
}
