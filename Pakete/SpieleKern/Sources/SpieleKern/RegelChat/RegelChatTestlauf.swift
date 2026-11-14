// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Testläufer für den Regel-Chat: liest `testfragen.json` eines Spiels (Format wie 10k: id, frage, regeln, erwartet,
/// muss_enthalten, darf_nicht_enthalten, kategorie; neu und optional: `abschnitt` = Titel des Abschnitts, der zur
/// Frage gewählt werden muss) und prüft (a) ohne Modell, ob der richtige Abschnitt gewählt wird, und
/// (b) mit einem Modell (Gerät oder Attrappe), ob die Antworten stimmen.
/// Abnahme je Spiel: mindestens 95 Prozent bestanden (bei 40 Fragen 38) und 0 falsche Zahlen.

/// Ein JSON-Wert (für das Feld `regeln`, das je Spiel anders aufgebaut ist)
public enum RegelChatJSON: Decodable, Equatable, Sendable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([RegelChatJSON])
    case object([String: RegelChatJSON])
    case null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let i = try? c.decode(Int.self) { self = .int(i) }
        else if let d = try? c.decode(Double.self) { self = .double(d) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([RegelChatJSON].self) { self = .array(a) }
        else { self = .object(try c.decode([String: RegelChatJSON].self)) }
    }

    /// Für `JSONSerialization` (zum Beispiel um `GameRules` aus dem Teil-Objekt zu dekodieren)
    public var any: Any {
        switch self {
        case .bool(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .string(let v): return v
        case .array(let v): return v.map(\.any)
        case .object(let v): return v.mapValues(\.any)
        case .null: return NSNull()
        }
    }
}

public struct RegelChatTestfrage: Decodable, Equatable, Sendable {
    public let id: String
    public let frage: String
    /// Eingestellte Regeln dieser Frage als Teil-Objekt; fehlende Schlüssel = Standard des Spiels
    public let regeln: [String: RegelChatJSON]
    public let erwartet: String
    public let mussEnthalten: [String]
    public let darfNichtEnthalten: [String]
    public let kategorie: String
    /// Titel des Abschnitts, den die Auswahl treffen muss (optional)
    public let abschnitt: String?

    private enum CodingKeys: String, CodingKey {
        case id, frage, regeln, erwartet, kategorie, abschnitt
        case mussEnthalten = "muss_enthalten"
        case darfNichtEnthalten = "darf_nicht_enthalten"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        frage = try c.decode(String.self, forKey: .frage)
        regeln = try c.decodeIfPresent([String: RegelChatJSON].self, forKey: .regeln) ?? [:]
        erwartet = try c.decodeIfPresent(String.self, forKey: .erwartet) ?? ""
        mussEnthalten = try c.decodeIfPresent([String].self, forKey: .mussEnthalten) ?? []
        darfNichtEnthalten = try c.decodeIfPresent([String].self, forKey: .darfNichtEnthalten) ?? []
        kategorie = try c.decodeIfPresent(String.self, forKey: .kategorie) ?? ""
        abschnitt = try c.decodeIfPresent(String.self, forKey: .abschnitt)
    }

    public init(id: String, frage: String, regeln: [String: RegelChatJSON] = [:], erwartet: String = "",
                mussEnthalten: [String] = [], darfNichtEnthalten: [String] = [], kategorie: String = "",
                abschnitt: String? = nil) {
        self.id = id
        self.frage = frage
        self.regeln = regeln
        self.erwartet = erwartet
        self.mussEnthalten = mussEnthalten
        self.darfNichtEnthalten = darfNichtEnthalten
        self.kategorie = kategorie
        self.abschnitt = abschnitt
    }
}

/// Bewertung nach `_hinweis` in `testfragen.json`
public enum RegelChatBewertung {
    /// Kleinschreibung, Tausenderpunkte zwischen Ziffern entfernen (1.000 wird 1000)
    public static func normalisieren(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: #"(?<=\d)\.(?=\d{3})"#, with: "", options: .regularExpression)
    }

    private static func enthaelt(_ text: String, _ muster: String) -> Bool {
        let klein = muster.lowercased()
        if Int(klein) != nil {
            // Ganze Zahl: nicht Teil einer längeren Zahl (250 trifft nicht 1250)
            return text.range(of: #"(?<!\d)"# + klein + #"(?!\d)"#, options: .regularExpression) != nil
        }
        return text.contains(klein)
    }

    /// `a|b` = eine der Alternativen genügt
    public static func besteht(_ antwort: String, muss: [String], darfNicht: [String]) -> Bool {
        let text = normalisieren(antwort)
        let alleDa = muss.allSatisfy { alt in alt.split(separator: "|").contains { enthaelt(text, String($0)) } }
        let nichts = !darfNicht.contains { enthaelt(text, $0) }
        return alleDa && nichts
    }
}

public struct RegelChatErgebnis: Sendable, Equatable {
    public let frage: RegelChatTestfrage
    public let antwort: String
    public let bestanden: Bool
    public let weg: RegelChatWeg?
    public let werkzeuge: [String]
    public let sekunden: Double
    /// Beim Lauf mit Modell: stimmte auch die gewählte Quelle? `nil`, wenn die Frage keinen `abschnitt` verlangt.
    public let quelleRichtig: Bool?
}

public struct RegelChatBericht: Sendable, Equatable {
    public let ergebnisse: [RegelChatErgebnis]
    /// Kategorien, in denen eine falsche Zahl als „falsche Zahl“ zählt
    public let zahlenKategorien: Set<String>

    public var gesamt: Int { ergebnisse.count }
    public var bestanden: Int { ergebnisse.filter(\.bestanden).count }
    /// Durchgefallene Rechenfragen (verlangen eine Zahl als Antwort)
    public var zahlenfehler: Int {
        ergebnisse.filter { e in
            !e.bestanden && zahlenKategorien.contains(e.frage.kategorie)
                && e.frage.mussEnthalten.contains { Int($0.split(separator: "|").first.map(String.init) ?? "") != nil }
        }.count
    }
    /// Abnahmeregel: mindestens 95 Prozent bestanden (aufgerundet, bei 40 Fragen 38) und 0 falsche Zahlen
    public var abnahmeErreicht: Bool {
        gesamt > 0 && bestanden >= RegelChatTestlauf.mindestBestanden(gesamt: gesamt) && zahlenfehler == 0
    }

    /// Tabelle zum Ablegen (tab-getrennt, wie bei 10k)
    public var tabelle: String {
        var text = "id\tkategorie\tok\tweg\twerkzeuge\tsekunden\tantwort\n"
        for e in ergebnisse {
            let sauber = e.antwort.replacingOccurrences(of: "\n", with: " ")
            text += "\(e.frage.id)\t\(e.frage.kategorie)\t\(e.bestanden ? "✓" : "✗")\t\(e.weg?.rawValue ?? "-")\t"
                + "\(e.werkzeuge.joined(separator: ","))\t\(String(format: "%.1f", e.sekunden))\t\(sauber)\n"
        }
        text += "\nBestanden: \(bestanden)/\(gesamt), falsche Zahlen: \(zahlenfehler), "
            + "Abnahme: \(abnahmeErreicht ? "erreicht" : "nicht erreicht")\n"
        return text
    }
}

/// Ergebnis der Abschnittsprüfung ohne Modell
public struct RegelChatAbschnittsPruefung: Sendable, Equatable {
    public let id: String
    public let erwartet: String
    public let gewaehlt: [String]
    public var ok: Bool { gewaehlt.contains(erwartet) }
}

public enum RegelChatTestlauf {
    /// Abnahme: 95 Prozent, aufgerundet (40 Fragen: 38, 30 Fragen: 29)
    public static func mindestBestanden(gesamt: Int) -> Int {
        Int((Double(gesamt) * 0.95).rounded(.up))
    }

    /// Kategorien, in denen die Antwort eine berechnete Zahl nennen muss (wie bei 10k)
    public static let standardZahlenKategorien: Set<String> = ["wertung", "wertung/zug", "zug", "grenzfall", "variante", "variant", "rechnen", "zahl"]

    private struct Datei: Decodable { let fragen: [RegelChatTestfrage] }

    public static func laden(data: Data) throws -> [RegelChatTestfrage] {
        try JSONDecoder().decode(Datei.self, from: data).fragen
    }

    public static func laden(url: URL) throws -> [RegelChatTestfrage] {
        try laden(data: Data(contentsOf: url))
    }

    /// (a) Ohne Modell: Kommt zu jeder Frage mit `abschnitt` der richtige Abschnitt in die Auswahl?
    public static func abschnittsPruefung(fragen: [RegelChatTestfrage],
                                          wissen: (RegelChatTestfrage) -> any RegelWissen,
                                          grenzen: RegelChatGrenzen = .standard) -> [RegelChatAbschnittsPruefung] {
        fragen.compactMap { f in
            guard let erwartet = f.abschnitt else { return nil }
            let gewaehlt = RegelChatAuswahl.waehle(frage: f.frage, aus: wissen(f).abschnitte,
                                                   maxAnzahl: grenzen.maxAbschnitte, maxZeichen: grenzen.maxZeichenAbschnitte)
            return RegelChatAbschnittsPruefung(id: f.id, erwartet: erwartet, gewaehlt: gewaehlt.map(\.titel))
        }
    }

    /// (b) Mit Modell: jede Frage einmal (greedy, damit es sich wiederholen lässt), Antworten bewerten.
    public static func lauf(fragen: [RegelChatTestfrage],
                            wissen: (RegelChatTestfrage) -> any RegelWissen,
                            modell: any RegelChatSprachmodell,
                            grenzen: RegelChatGrenzen = .standard,
                            deterministisch: Bool = true,
                            zahlenKategorien: Set<String> = standardZahlenKategorien) async -> RegelChatBericht {
        var ergebnisse: [RegelChatErgebnis] = []
        for f in fragen {
            let start = Date()
            var text: String
            var weg: RegelChatWeg?
            var werkzeuge: [String] = []
            var quellen: [String] = []
            do {
                let a = try await RegelChatMotor.antworten(frage: f.frage, wissen: wissen(f), modell: modell,
                                                           grenzen: grenzen, deterministisch: deterministisch)
                text = a.text
                weg = a.weg
                werkzeuge = a.werkzeuge
                quellen = a.quellen
            } catch {
                text = "FEHLER: \(error)"
            }
            let ok = RegelChatBewertung.besteht(text, muss: f.mussEnthalten, darfNicht: f.darfNichtEnthalten)
            let quelleRichtig = f.abschnitt.map { quellen.contains($0) }
            ergebnisse.append(RegelChatErgebnis(frage: f, antwort: text, bestanden: ok, weg: weg, werkzeuge: werkzeuge,
                                                sekunden: Date().timeIntervalSince(start), quelleRichtig: quelleRichtig))
        }
        return RegelChatBericht(ergebnisse: ergebnisse, zahlenKategorien: zahlenKategorien)
    }
}
