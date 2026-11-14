// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Ein Spiel, dessen Optionen sich per Ansage einstellen lassen. Der Adapter bildet die Optionen des Spiels
/// (zum Beispiel `NRegeln` bei Mau-Mau) auf das Schema ab. Er liegt im Spielpaket, nicht hier.
public protocol SpielVarianten {
    var schema: VariantenSchema { get }
    /// Aktuelle Werte aller Optionen (Schlüssel = `VariantenOption.id`). Fehlende Schlüssel gelten als Standardwert.
    func lesen() -> [String: VariantenWert]
    /// Setzt nur die übergebenen, schon geprüften Werte; alles andere bleibt. Wird erst nach der Bestätigung aufgerufen.
    func anwenden(_ werte: [String: VariantenWert])
    /// `false`, wenn gerade nichts mehr geändert werden darf (Mau-Mau: nach dem ersten Zug). Dann zeigt die Oberfläche die Eingabe ausgegraut.
    var aenderbar: Bool { get }
}

public extension SpielVarianten {
    var aenderbar: Bool { true }
}

/// Eine Zeile der Bestätigungsliste „Das stelle ich ein: …“.
public struct VariantenAenderung: Equatable, Sendable, Identifiable {
    public var id: String { optionID }
    public let optionID: String
    public let titel: String
    public let alt: VariantenWert
    public let neu: VariantenWert
}

public enum VariantenVerwerfGrund: Equatable, Sendable {
    case unbekannteVorlage
    case unbekannteOption
    case ungueltigerWert
}

/// Etwas, das das Modell genannt hat und die App nicht übernimmt (für die Anzeige „nicht verstanden“ und für Tests).
public struct VariantenVerworfen: Equatable, Sendable {
    public let name: String
    public let grund: VariantenVerwerfGrund
}

/// Ergebnis der Ansage nach der Prüfung. Noch nichts gesetzt: Die Oberfläche zeigt `aenderungen`, die Person bestätigt (Übernehmen) oder verwirft.
public struct VariantenVorschlag: Equatable, Sendable {
    public let spielID: String
    /// Gewählte Vorlage (nur wenn sie im Schema steht).
    public let vorlageID: String?
    /// Echte Änderungen gegenüber dem heutigen Stand, in der Reihenfolge des Schemas.
    public let aenderungen: [VariantenAenderung]
    public let verworfen: [VariantenVerworfen]
    /// Wie viele genannte Werte schon so eingestellt waren (nicht in der Liste).
    public let schonSo: Int

    public var istLeer: Bool { aenderungen.isEmpty }

    /// Die Werte, die nach der Bestätigung gesetzt werden; `ausgenommen` = Zeilen, die die Person abgewählt hat.
    public func werte(ausgenommen: Set<String> = []) -> [String: VariantenWert] {
        var r: [String: VariantenWert] = [:]
        for a in aenderungen where !ausgenommen.contains(a.optionID) { r[a.optionID] = a.neu }
        return r
    }

    /// Setzt die bestätigten Änderungen. Rückgabe: wie viele gesetzt wurden. Nichts passiert, wenn das Spiel gerade nicht änderbar ist.
    @discardableResult
    public func uebernehmen(in spiel: some SpielVarianten, ausgenommen: Set<String> = []) -> Int {
        guard spiel.aenderbar, spiel.schema.spielID == spielID else { return 0 }
        let w = werte(ausgenommen: ausgenommen)
        guard !w.isEmpty else { return 0 }
        spiel.anwenden(w)
        return w.count
    }
}

/// Rohantwort des Modells, noch ungeprüft: eine Vorlage und Paare (Option, Wert als Text).
public struct VariantenRohAntwort: Equatable, Sendable {
    public struct Eintrag: Equatable, Sendable {
        public let option: String
        public let wert: String
        public init(option: String, wert: String) { self.option = option; self.wert = wert }
    }
    public let vorlage: String?
    public let aenderungen: [Eintrag]
    public init(vorlage: String? = nil, aenderungen: [Eintrag] = []) { self.vorlage = vorlage; self.aenderungen = aenderungen }
}

/// Prüft die Rohantwort gegen das Schema: unbekannte Schlüssel und Werte außerhalb der Grenzen fallen weg.
public enum VariantenPruefer {
    public static func pruefen(_ roh: VariantenRohAntwort, schema: VariantenSchema, aktuell: [String: VariantenWert]) -> VariantenVorschlag {
        var gewuenscht: [String: VariantenWert] = [:]
        var verworfen: [VariantenVerworfen] = []

        // 1. Vorlage (leere Angabe oder „keine“ = keine Vorlage)
        var vorlageID: String?
        if let v = roh.vorlage?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty, v.lowercased() != "keine" {
            if let vorlage = schema.vorlage(v) ?? schema.vorlagen.first(where: { $0.titel.lowercased() == v.lowercased() }) {
                vorlageID = vorlage.id
                for (k, w) in vorlage.werte {
                    if let o = schema.option(k), schema.istGueltig(w, fuer: o) { gewuenscht[k] = w }
                }
            } else {
                verworfen.append(VariantenVerworfen(name: v, grund: .unbekannteVorlage))
            }
        }

        // 2. Einzelne Schalter: überschreiben die Vorlage; bei doppelter Nennung gilt die letzte.
        for e in roh.aenderungen {
            guard let o = schema.option(e.option.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                verworfen.append(VariantenVerworfen(name: e.option, grund: .unbekannteOption)); continue
            }
            guard let w = schema.wert(aus: e.wert, fuer: o) else {
                verworfen.append(VariantenVerworfen(name: e.option, grund: .ungueltigerWert)); continue
            }
            gewuenscht[o.id] = w
        }

        // 3. Nur echte Änderungen, in Schema-Reihenfolge
        var liste: [VariantenAenderung] = []
        var schonSo = 0
        for o in schema.optionen {
            guard let neu = gewuenscht[o.id] else { continue }
            let alt = aktuell[o.id] ?? o.standard
            if alt == neu { schonSo += 1 } else { liste.append(VariantenAenderung(optionID: o.id, titel: o.titel, alt: alt, neu: neu)) }
        }
        return VariantenVorschlag(spielID: schema.spielID, vorlageID: vorlageID, aenderungen: liste, verworfen: verworfen, schonSo: schonSo)
    }
}
