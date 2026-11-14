// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SwiftUI
import KlarGlas
import Observation

/// Eine Person, die je mitgespielt hat (Konzept 3). Bleibt auf dem Gerät.
public struct Spieler: Identifiable, Codable, Equatable, Hashable, Sendable {
    public enum Art: String, Codable, Sendable {
        case mensch, computer
        /// Unbekannte Werte (z. B. aus einer späteren Fassung) machen die Person nicht unsichtbar: Sie gilt als Mensch.
        public init(from decoder: Decoder) throws {
            self = Art(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .mensch
        }
    }
    public var id: UUID
    public var name: String
    public var avatar: String          // Initiale oder Emoji
    public var farbeIndex: Int         // Index in `Spieler.farbenHex`
    public var art: Art
    public var ich: Bool
    /// Zähler des Fotos (nil = kein Foto). Das Bild liegt als Datei bei `SpielerBilder`; der Zähler erneuert Anzeige und Zwischenspeicher.
    public var bildNr: Int?
    public var angelegt: Date
    public var zuletzt: Date
    /// Game Center: Spieler-Kennung des verknüpften Freundes (nil = nicht verknüpft). Fehlt in alten Daten, dann gilt „nicht verknüpft“.
    public var gameCenterID: String?

    public init(id: UUID = UUID(), name: String, avatar: String? = nil, farbeIndex: Int = 0, art: Art = .mensch, ich: Bool = false,
                bildNr: Int? = nil, angelegt: Date = Date(), zuletzt: Date = Date(), gameCenterID: String? = nil) {
        self.gameCenterID = gameCenterID
        self.bildNr = bildNr
        self.id = id; self.name = name
        self.avatar = avatar ?? String(name.prefix(1)).uppercased()
        self.farbeIndex = farbeIndex; self.art = art; self.ich = ich; self.angelegt = angelegt; self.zuletzt = zuletzt
    }

    /// Spielerfarben (die Familienfarben ohne Graphit).
    public static let farbenHex: [UInt32] = Familienfarbe.spieler.map(\.flaeche)
    /// Spielerfarbe als `Color` (Index läuft im Kreis).
    public static func farbe(_ index: Int) -> Color { Familienfarbe.spieler[((index % farbenHex.count) + farbenHex.count) % farbenHex.count].color }
}

/// Verzeichnis aller Spieler. Eine Quelle für alle Spiele (Konzept 3).
@Observable
@MainActor
public final class SpielerVerzeichnis {
    public private(set) var alle: [Spieler] = []
    /// Wird nach jeder Änderung gerufen (die Hülle spiegelt das Verzeichnis in `SpielerQuelle`).
    public var nachAenderung: (() -> Void)?
    private let ablage: SpielAblageProtokoll

    public init(ablage: SpielAblageProtokoll = DefaultsAblageDaten(schluessel: "partie.spieler")) {
        self.ablage = ablage
        if let d = ablage.lesen(), let l = Verlustfrei.lesen([Spieler].self, aus: d) { alle = l }
    }

    public var ich: Spieler? { alle.first(where: \.ich) }
    public var menschen: [Spieler] { alle.filter { $0.art == .mensch } }
    public var zuletztGespielt: [Spieler] { menschen.sorted { $0.zuletzt > $1.zuletzt } }

    @discardableResult
    public func anlegen(name: String, art: Spieler.Art = .mensch) -> Spieler {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let vorhanden = alle.first(where: { $0.name.caseInsensitiveCompare(n) == .orderedSame && $0.art == art }) { return vorhanden }
        let s = Spieler(name: n, farbeIndex: freieFarbe(), art: art, ich: alle.isEmpty && art == .mensch)
        alle.append(s); sichern(); return s
    }

    /// Erste noch nicht vergebene Farbe (sonst reihum), damit neue Personen unterscheidbar bleiben.
    public func freieFarbe() -> Int {
        let belegt = Set(menschen.map { $0.farbeIndex % Spieler.farbenHex.count })
        return (0..<Spieler.farbenHex.count).first { !belegt.contains($0) } ?? alle.count % Spieler.farbenHex.count
    }

    /// Legt eine Person mit allen Angaben an (Name, Avatar-Zeichen, Farbe, Foto) oder ändert die mit `id` vorhandene.
    /// `nil`, wenn der Name leer oder schon an eine andere Person vergeben ist. `avatar` leer = Initiale. `bild`: `.behalten`, `.entfernen` oder `.neu(Daten)`.
    public enum BildAenderung: Sendable { case behalten, entfernen, neu(Data) }
    @discardableResult
    public func speichern(id: UUID? = nil, name: String, avatar: String, farbeIndex: Int, bild: BildAenderung = .behalten, ich: Bool? = nil) -> Spieler? {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, !nameVergeben(n, ausser: id) else { return nil }
        let av = avatar.trimmingCharacters(in: .whitespaces).isEmpty ? String(n.prefix(1)).uppercased() : avatar
        var s: Spieler
        if let id, let i = alle.firstIndex(where: { $0.id == id }) { s = alle[i]; s.name = n; s.avatar = av; s.farbeIndex = farbeIndex }
        else { s = Spieler(name: n, avatar: av, farbeIndex: farbeIndex, ich: ich ?? alle.isEmpty) }
        if ich == true { for i in alle.indices where alle[i].id != s.id { alle[i].ich = false }; s.ich = true }
        switch bild {
        case .behalten: break
        case .entfernen: SpielerBilder.loeschen(s.id); s.bildNr = nil
        case .neu(let d): if SpielerBilder.sichern(d, fuer: s.id) { s.bildNr = (s.bildNr ?? 0) + 1 }
        }
        if let i = alle.firstIndex(where: { $0.id == s.id }) { alle[i] = s } else { alle.append(s) }
        sichern(); return s
    }

    /// Ist der Name schon an eine andere Person vergeben?
    public func nameVergeben(_ name: String, ausser id: UUID? = nil) -> Bool {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return menschen.contains { $0.id != id && $0.name.caseInsensitiveCompare(n) == .orderedSame }
    }

    /// Benennt eine Person um. Ein selbst gewähltes Zeichen bleibt, die Initiale zieht mit. `false`, wenn der Name leer oder vergeben ist.
    @discardableResult
    public func umbenennen(_ id: UUID, zu name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let i = alle.firstIndex(where: { $0.id == id }), !n.isEmpty, !nameVergeben(n, ausser: id) else { return false }
        let warInitiale = alle[i].avatar == String(alle[i].name.prefix(1)).uppercased()
        alle[i].name = n
        if warInitiale { alle[i].avatar = String(n.prefix(1)).uppercased() }
        sichern(); return true
    }

    public func loeschen(_ id: UUID) {
        SpielerBilder.loeschen(id)
        alle.removeAll { $0.id == id }
        if !alle.contains(where: \.ich), let i = alle.firstIndex(where: { $0.art == .mensch }) { alle[i].ich = true }
        sichern()
    }

    /// Ordnet die Namen einer gemeldeten Partie den Personen zu: leerer Name = „Ich“, sonst Treffer unter den Menschen
    /// (ohne Beachtung von Groß-/Kleinschreibung und Leerzeichen am Rand). Computergegner bleiben ohne Person,
    /// Gefunden werden nur Menschen.
    public func zuordnen(_ ergebnis: PartieErgebnis, computerNamen: Set<String> = []) -> PartieErgebnis {
        var e = ergebnis
        for i in e.teilnehmer.indices {
            let n = e.teilnehmer[i].name.trimmingCharacters(in: .whitespacesAndNewlines)
            if n.isEmpty {
                e.teilnehmer[i].spielerID = ich?.id; e.teilnehmer[i].name = ich?.name ?? ""
            } else if computerNamen.contains(n.lowercased()) {
                continue   // C-012: Computer mit Menschennamen (z. B. „Anna“) bekommt nie das Ergebnis der gleichnamigen Person
            } else if let s = menschen.first(where: { $0.name.caseInsensitiveCompare(n) == .orderedSame }) {
                e.teilnehmer[i].spielerID = s.id; e.teilnehmer[i].name = s.name
            }
        }
        return e
    }

    /// Übernimmt eine Sicherung, ohne etwas zu überschreiben oder zu verlieren (mehrfaches Übernehmen ändert nichts):
    /// - Person mit gleicher ID: bleibt, wie sie ist (hatte sie kein Foto, die Sicherung aber eins, kommt das Foto dazu).
    /// - Person mit gleichem Namen unter anderer ID: gilt als dieselbe Person, ihre Partien werden auf die vorhandene umgelegt.
    /// - Sonst: neue Person (nie als „Ich“, solange es schon eine gibt).
    /// - Alle Partien mit unbekannter ID kommen dazu, auch die ohne Personenzuordnung.
    @discardableResult
    public func uebernehmen(_ sicherung: Sicherung, statistik: StatistikDienst) -> Uebernahme {
        var u = Uebernahme()
        var ids: [UUID: UUID] = [:]
        for p in sicherung.spieler {
            let foto = sicherung.fotos[p.id.uuidString]
            if let i = alle.firstIndex(where: { $0.id == p.id }) ?? alle.firstIndex(where: { $0.art == p.art && $0.name.caseInsensitiveCompare(p.name) == .orderedSame }) {
                ids[p.id] = alle[i].id
                if alle[i].bildNr == nil, let foto, SpielerBilder.ablegen(foto, fuer: alle[i].id) { alle[i].bildNr = p.bildNr ?? 1; u.fotos += 1 }
            } else {
                var neu = p; neu.ich = p.ich && !alle.contains(where: \.ich)
                if let foto, SpielerBilder.ablegen(foto, fuer: neu.id) { u.fotos += 1 } else { neu.bildNr = nil }
                alle.append(neu); ids[p.id] = neu.id; u.spieler += 1
            }
        }
        if ich == nil, let i = alle.firstIndex(where: { $0.art == .mensch }) { alle[i].ich = true }
        u.partien = statistik.uebernehmen(sicherung.partien, ids: ids)
        if u.spieler > 0 || u.fotos > 0 { sichern() }
        return u
    }

    // MARK: Game Center (nur lokale Verknüpfung, es wird nichts übertragen)

    /// Die Person, die mit diesem Game-Center-Freund verknüpft ist.
    public func mitGameCenter(_ gcID: String) -> Spieler? { alle.first { $0.gameCenterID == gcID } }

    /// Menschen, die noch mit keinem Game-Center-Freund verknüpft sind („Ich“ nicht).
    public var ohneGameCenter: [Spieler] { menschen.filter { $0.gameCenterID == nil && !$0.ich } }

    /// Verknüpft eine vorhandene Person mit einem Game-Center-Freund. Ein Freund gehört immer nur zu einer Person.
    @discardableResult
    public func verknuepfen(_ id: UUID, gameCenterID gc: String) -> Bool {
        guard !gc.isEmpty, let i = alle.firstIndex(where: { $0.id == id && $0.art == .mensch }) else { return false }
        for j in alle.indices where j != i && alle[j].gameCenterID == gc { alle[j].gameCenterID = nil }
        alle[i].gameCenterID = gc
        sichern(); return true
    }

    /// Hebt die Verknüpfung auf. Die Person und ihre Partien bleiben.
    public func verknuepfungLoesen(_ id: UUID) {
        guard let i = alle.firstIndex(where: { $0.id == id }), alle[i].gameCenterID != nil else { return }
        alle[i].gameCenterID = nil
        sichern()
    }

    /// Legt für einen Game-Center-Freund eine neue Person an (ist der Name schon vergeben, wird eine Zahl angehängt) und verknüpft sie.
    @discardableResult
    public func freundAnlegen(name: String, gameCenterID gc: String) -> Spieler? {
        if let vorhanden = mitGameCenter(gc) { return vorhanden }
        var n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { n = "Freund" }
        var kandidat = n, zaehler = 2
        while nameVergeben(kandidat) { kandidat = "\(n) \(zaehler)"; zaehler += 1 }
        guard let s = speichern(name: kandidat, avatar: "", farbeIndex: freieFarbe(), ich: false) else { return nil }
        verknuepfen(s.id, gameCenterID: gc)
        return mitGameCenter(gc)
    }

    public func alsIchMarkieren(_ id: UUID) {
        for i in alle.indices { alle[i].ich = alle[i].id == id }
        sichern()
    }

    public func gespielt(_ ids: [UUID], am datum: Date = Date()) {
        for i in alle.indices where ids.contains(alle[i].id) { alle[i].zuletzt = datum }
        sichern()
    }

    private func sichern() { Verlustfrei.schreiben(alle, in: ablage); nachAenderung?() }
}

/// Liest eine Liste so, dass ein einzelner defekter Eintrag nicht alle anderen mitreißt (sonst wäre beim nächsten Speichern alles weg).
/// Nicht lesbar als Liste: `nil`, die Ablage bleibt unberührt, bis sich wirklich etwas ändert.
enum Verlustfrei {
    private struct Eintrag<T: Decodable>: Decodable {
        let wert: T?
        init(from decoder: Decoder) throws { wert = try? T(from: decoder) }
    }
    /// Schreibt nur, wenn das Kodieren geklappt hat. Ein gescheitertes Kodieren (z. B. NaN in einer Zahl) darf nie `nil` schreiben,
    /// denn das löscht den Schlüssel und damit alle bisherigen Daten. Gibt zurück, ob geschrieben wurde.
    @discardableResult
    static func schreiben<T: Encodable>(_ wert: T, in ablage: SpielAblageProtokoll) -> Bool {
        guard let d = try? JSONEncoder().encode(wert) else { return false }
        return (try? ablage.schreiben(d)) != nil
    }
    static func lesen<T: Decodable>(_: [T].Type, aus daten: Data) -> [T]? {
        (try? JSONDecoder().decode([Eintrag<T>].self, from: daten))?.compactMap(\.wert)
    }
}

public protocol SpielAblageProtokoll: AnyObject {
    func lesen() -> Data?
    func schreiben(_ daten: Data?) throws
}

public final class DefaultsAblageDaten: SpielAblageProtokoll {
    let schluessel: String; let defaults: UserDefaults
    public init(schluessel: String, defaults: UserDefaults = .standard) { self.schluessel = schluessel; self.defaults = defaults }
    public func lesen() -> Data? { defaults.data(forKey: schluessel) }
    public func schreiben(_ daten: Data?) throws { defaults.set(daten, forKey: schluessel) }
}

public final class SpeicherAblage: SpielAblageProtokoll {
    public var daten: Data?
    public init(daten: Data? = nil) { self.daten = daten }
    public func lesen() -> Data? { daten }
    public func schreiben(_ daten: Data?) throws { self.daten = daten }
}

public extension Spieler {
    /// Eigenes Zeichen der Person (Emoji); `nil`, wenn nur die Initiale hinterlegt ist. Die eine Regel dafür: Vorher stand dieselbe
    /// Prüfung an sieben Stellen (Rahmen, Hülle, Yacht, 10k).
    var zeichen: String? { avatar.count > 1 || avatar.unicodeScalars.contains { $0.value > 0x2000 } ? avatar : nil }

    /// Was ein Abzeichen für eine Person zeigt: ihr Zeichen, sonst den Anfangsbuchstaben des Namens (wie die Spielerliste im Blatt
    /// „Neues Spiel“). So sieht eine Person im Blatt und im Spiel gleich aus (M-005).
    static func abzeichen(name: String, zeichen: String?) -> String {
        zeichen ?? String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }
}
