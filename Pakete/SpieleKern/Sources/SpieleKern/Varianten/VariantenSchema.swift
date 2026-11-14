// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

// KI-5 (13.11.2026): Varianten-Gerüst. Ein Spiel beschreibt hier seine Optionen und benannten Vorlagen.
// Das Sprachmodell wählt nur Vorlage und Schalter; Werte setzt und prüft immer die App (nie freie Zahlen).
// Keine Oberfläche, keine Zeichenketten für Spieler in dieser Datei.

/// Wert einer Option: Schalter, Zahl oder eine Auswahl unter festen Einträgen.
public enum VariantenWert: Equatable, Hashable, Sendable, Codable {
    case an(Bool)
    case zahl(Int)
    case auswahl(String)
}

/// Ein Eintrag einer Auswahl-Option (zum Beispiel „Mit der 8“ → id `acht`).
public struct VariantenAuswahlEintrag: Equatable, Sendable {
    public let id: String
    public let titel: String
    public init(id: String, titel: String) { self.id = id; self.titel = titel }
}

/// Art einer Option mit ihren Grenzen.
public enum VariantenArt: Equatable, Sendable {
    case schalter
    /// Ganze Zahl von … bis …, in Schritten (Standard 1; Werte müssen auf dem Raster von `von` liegen).
    case zahl(von: Int, bis: Int, schritt: Int = 1)
    case auswahl([VariantenAuswahlEintrag])
}

public struct VariantenOption: Equatable, Sendable, Identifiable {
    /// Stabiler Schlüssel (ohne Leerzeichen), den das Modell nennt, zum Beispiel `sieben_ziehen`.
    public let id: String
    /// Name, wie ihn das Spiel im Blatt zeigt.
    public let titel: String
    /// Kurze Erklärung für das Modell (ein Satz): was die Option im Spiel bewirkt.
    public let hinweis: String
    public let art: VariantenArt
    public let standard: VariantenWert
    /// Umgangssprache, damit „Mau sagen“ oder „Strafkarte“ die Option findet (nur für die Vorauswahl).
    public let stichworte: [String]
    public init(id: String, titel: String, hinweis: String = "", art: VariantenArt, standard: VariantenWert, stichworte: [String] = []) {
        self.id = id; self.titel = titel; self.hinweis = hinweis; self.art = art; self.standard = standard; self.stichworte = stichworte
    }
}

/// Benannte Schnellwahl („Wild“): setzt einige Optionen auf feste Werte. Nicht genannte Optionen bleiben, wie sie sind.
public struct VariantenVorlage: Equatable, Sendable, Identifiable {
    public let id: String
    public let titel: String
    public let hinweis: String
    public let werte: [String: VariantenWert]
    public let stichworte: [String]
    public init(id: String, titel: String, hinweis: String = "", werte: [String: VariantenWert], stichworte: [String] = []) {
        self.id = id; self.titel = titel; self.hinweis = hinweis; self.werte = werte; self.stichworte = stichworte
    }
}

public struct VariantenSchema: Equatable, Sendable {
    public let spielID: String
    public let spielName: String
    public let optionen: [VariantenOption]
    public let vorlagen: [VariantenVorlage]
    public init(spielID: String, spielName: String, optionen: [VariantenOption], vorlagen: [VariantenVorlage] = []) {
        self.spielID = spielID; self.spielName = spielName; self.optionen = optionen; self.vorlagen = vorlagen
    }

    public func option(_ id: String) -> VariantenOption? { optionen.first { $0.id == id } }
    public func vorlage(_ id: String) -> VariantenVorlage? { vorlagen.first { $0.id == id } }

    /// Ist der Wert für diese Option zulässig (richtige Art, innerhalb der Grenzen, auf dem Raster, in der Auswahl)?
    public func istGueltig(_ wert: VariantenWert, fuer option: VariantenOption) -> Bool {
        switch (option.art, wert) {
        case (.schalter, .an): return true
        case let (.zahl(von, bis, schritt), .zahl(n)):
            return n >= von && n <= bis && (schritt <= 1 || (n - von) % schritt == 0)
        case let (.auswahl(eintraege), .auswahl(id)):
            return eintraege.contains { $0.id == id }
        default: return false
        }
    }

    /// Wandelt die Zeichenkette des Modells („an“, „7“, „acht“) in einen Wert dieser Option. `nil`, wenn nicht lesbar oder nicht zulässig.
    public func wert(aus text: String, fuer option: VariantenOption) -> VariantenWert? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let kandidat: VariantenWert?
        switch option.art {
        case .schalter:
            switch t {
            case "an", "ein", "ja", "true", "1": kandidat = .an(true)
            case "aus", "nein", "false", "0": kandidat = .an(false)
            default: kandidat = nil
            }
        case .zahl:
            kandidat = Int(t).map { .zahl($0) }
        case .auswahl(let eintraege):
            if let e = eintraege.first(where: { $0.id.lowercased() == t }) { kandidat = .auswahl(e.id) }
            else if let e = eintraege.first(where: { $0.titel.lowercased() == t }) { kandidat = .auswahl(e.id) }
            else { kandidat = nil }
        }
        guard let k = kandidat, istGueltig(k, fuer: option) else { return nil }
        return k
    }

    /// Schema in sich stimmig? (eindeutige ids, Standardwerte zulässig, Vorlagen nennen nur bekannte Optionen mit zulässigen Werten.) Für Tests der Adapter.
    public func fehler() -> [String] {
        var f: [String] = []
        if Set(optionen.map(\.id)).count != optionen.count { f.append("Doppelte Options-id") }
        if Set(vorlagen.map(\.id)).count != vorlagen.count { f.append("Doppelte Vorlagen-id") }
        for o in optionen where !istGueltig(o.standard, fuer: o) { f.append("Standardwert ungültig: \(o.id)") }
        for v in vorlagen {
            for (k, w) in v.werte {
                guard let o = option(k) else { f.append("Vorlage \(v.id): unbekannte Option \(k)"); continue }
                if !istGueltig(w, fuer: o) { f.append("Vorlage \(v.id): Wert ungültig für \(k)") }
            }
        }
        return f
    }
}
