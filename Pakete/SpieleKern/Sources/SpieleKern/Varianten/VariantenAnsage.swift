// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Das Sprachmodell hinter der Ansage. Echt: `AppleVariantenModell` (iOS 26, Apple Intelligence). Im Test und im Simulator: `VariantenModellAttrappe`.
public protocol VariantenModell: Sendable {
    func waehle(anweisung: String, eingabe: String) async throws -> VariantenRohAntwort
}

public enum VariantenFehler: Error, Equatable {
    case nichtVerfuegbar
    case leereEingabe
    /// Das Spiel lässt gerade keine Änderung zu (Mau-Mau nach dem ersten Zug).
    case nichtAenderbar
    case modellFehler
}

/// Zeigt, ob und wie die Ansage angeboten wird. Spiegelt die Stufen des Regel-Chats (KI-1, `RegelChatStatus`); bis KI-1 gemergt ist, hat dieses Gerüst seine eigene kleine Prüfung.
public enum VariantenStatus: Equatable, Sendable {
    /// Bereit: Eingabefeld zeigen.
    case bereit
    /// Modell wird noch geladen: Hinweis zeigen.
    case nichtBereit
    /// Apple Intelligence ist ausgeschaltet: Hinweis zeigen.
    case aus
    /// iOS vor 26, Gerät oder Sprache kann es nicht: nichts zeigen.
    case verborgen
}

/// Ablauf: Eingabetext → Modell wählt Vorlage und Schalter → App prüft gegen das Schema → `VariantenVorschlag` (Bestätigungsliste). Es wird hier nie etwas gesetzt.
public struct VariantenAnsage: Sendable {
    /// Höchstens so viele Optionen und Vorlagen stehen je Anfrage im Prompt (Kontext 4096 Tokens; Plan KI-BAUPLAN F, KI-5).
    public static let hoechstensOptionen = 15
    public static let hoechstensVorlagen = 8

    private let modell: VariantenModell
    public init(modell: VariantenModell) { self.modell = modell }

    public func ansagen(_ text: String, fuer spiel: some SpielVarianten) async throws -> VariantenVorschlag {
        let eingabe = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !eingabe.isEmpty else { throw VariantenFehler.leereEingabe }
        guard spiel.aenderbar else { throw VariantenFehler.nichtAenderbar }
        let schema = spiel.schema
        let aktuell = spiel.lesen()
        let anweisung = Self.anweisung(schema: schema, aktuell: aktuell, eingabe: eingabe)
        let roh: VariantenRohAntwort
        do { roh = try await modell.waehle(anweisung: anweisung, eingabe: eingabe) }
        catch let f as VariantenFehler { throw f }
        catch { throw VariantenFehler.modellFehler }
        return VariantenPruefer.pruefen(roh, schema: schema, aktuell: aktuell)
    }

    // MARK: Prompt

    static func normiert(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
    }

    /// Wenige Kandidaten nach Stichwörtern, wenn das Schema größer ist als die Grenze. Gleiche Punkte: Reihenfolge des Schemas bleibt.
    static func vorauswahl<T>(_ liste: [T], grenze: Int, eingabe: String, text: (T) -> [String]) -> [T] {
        guard liste.count > grenze else { return liste }
        let tokens = normiert(eingabe).split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 2 }
        func punkte(_ x: T) -> Int {
            let t = text(x).map(normiert)
            return tokens.reduce(0) { sum, k in sum + (t.contains { $0.contains(k) } ? 1 : 0) }
        }
        let bewertet = liste.enumerated().map { ($0.offset, $0.element, punkte($0.element)) }
        let beste = bewertet.sorted { $0.2 != $1.2 ? $0.2 > $1.2 : $0.0 < $1.0 }.prefix(grenze)
        return beste.sorted { $0.0 < $1.0 }.map(\.1)
    }

    static func artText(_ o: VariantenOption) -> String {
        switch o.art {
        case .schalter: return "an/aus"
        case let .zahl(von, bis, schritt): return schritt > 1 ? "Zahl \(von) bis \(bis), Schritt \(schritt)" : "Zahl \(von) bis \(bis)"
        case .auswahl(let e): return "eines von: " + e.map(\.id).joined(separator: ", ")
        }
    }

    static func wertText(_ w: VariantenWert) -> String {
        switch w { case .an(let b): return b ? "an" : "aus"; case .zahl(let n): return String(n); case .auswahl(let id): return id }
    }

    /// Anweisung mit Schema: nur diese Optionen und Vorlagen gibt es; das Modell nennt Schlüssel, die App prüft die Werte.
    public static func anweisung(schema: VariantenSchema, aktuell: [String: VariantenWert], eingabe: String) -> String {
        let optionen = vorauswahl(schema.optionen, grenze: hoechstensOptionen, eingabe: eingabe) { [$0.titel, $0.hinweis] + $0.stichworte }
        let vorlagen = vorauswahl(schema.vorlagen, grenze: hoechstensVorlagen, eingabe: eingabe) { [$0.titel, $0.hinweis] + $0.stichworte }
        let optionenText = optionen.map { o in
            "\(o.id)|\(o.titel)|\(artText(o))|jetzt: \(wertText(aktuell[o.id] ?? o.standard))" + (o.hinweis.isEmpty ? "" : "|\(o.hinweis)")
        }.joined(separator: "\n")
        let vorlagenText = vorlagen.isEmpty ? "(keine)" : vorlagen.map { v in
            "\(v.id)|\(v.titel)" + (v.hinweis.isEmpty ? "" : "|\(v.hinweis)")
        }.joined(separator: "\n")
        return """
        Du hilfst, in der App „Partie“ die Regeln des Spiels „\(schema.spielName)“ einzustellen. Die Person sagt, wie sie spielen möchte.
        Du wählst nur aus den VORLAGEN und OPTIONEN unten. Erfinde nichts: Was dort nicht steht, gibt es in diesem Spiel nicht.
        Gib die Vorlage nur an, wenn die Person sie meint (sonst leer). Gib in „aenderungen“ nur Optionen an, die die Person ausdrücklich ändern will.
        Der Wert ist bei Schaltern „an“ oder „aus“, bei Zahlen eine Ziffer innerhalb der Grenzen, bei Auswahl genau eine der genannten ids.
        Alles, was die Person nicht erwähnt, bleibt unverändert und kommt nicht vor.
        VORLAGEN (id|Name|Hinweis):
        \(vorlagenText)
        OPTIONEN (id|Name|Art|aktueller Wert|Hinweis):
        \(optionenText)
        """
    }
}

/// Attrappe für Tests und Simulator: liefert feste Antworten. Ohne Treffer in `antworten` gilt `standard` (leere Antwort).
public struct VariantenModellAttrappe: VariantenModell {
    public let antworten: [String: VariantenRohAntwort]
    public let standard: VariantenRohAntwort
    public let fehler: VariantenFehler?
    public init(antworten: [String: VariantenRohAntwort] = [:], standard: VariantenRohAntwort = VariantenRohAntwort(), fehler: VariantenFehler? = nil) {
        self.antworten = antworten; self.standard = standard; self.fehler = fehler
    }
    public func waehle(anweisung: String, eingabe: String) async throws -> VariantenRohAntwort {
        if let fehler { throw fehler }
        return antworten[eingabe.trimmingCharacters(in: .whitespacesAndNewlines)] ?? standard
    }
}
