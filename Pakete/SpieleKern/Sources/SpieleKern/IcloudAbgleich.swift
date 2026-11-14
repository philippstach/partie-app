// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// E7: Abgleich der Daten (Personen, Fotos, Partien) zwischen mehreren Geräten derselben Apple-ID über iCloud (CloudKit, privat).
///
/// Prinzip: Jedes Gerät lädt seine eigene Sicherung (`Sicherung`, dasselbe Format wie die Sicherungsdatei) in einen eigenen Datensatz
/// und übernimmt die Sicherungen der anderen Geräte mit `SpielerVerzeichnis.uebernehmen`. Das ist rein hinzufügend und wiederholbar:
/// Nichts wird überschrieben, nichts doppelt angelegt, es gibt keine Konflikte, weil jedes Gerät nur seinen eigenen Datensatz schreibt.
/// Grenze (bewusst, siehe Doku/E7-ICLOUD.md): Löschungen werden nicht auf andere Geräte übertragen.
public protocol AbgleichSpeicher: Sendable {
    /// `false`, wenn kein iCloud-Konto angemeldet oder iCloud eingeschränkt ist.
    func kontoVerfuegbar() async -> Bool
    /// Legt die Sicherung dieses Geräts ab (ersetzt die frühere).
    func hochladen(geraet: String, daten: Data) async throws
    /// Sicherungen aller anderen Geräte.
    func laden(ausser geraet: String) async throws -> [Data]
    /// C-002: Entfernt die Sicherung dieses Geräts (bei „Alle Daten löschen“). Standard: nichts tun.
    func loeschen(geraet: String) async throws
}

public extension AbgleichSpeicher {
    func loeschen(geraet: String) async throws {}
}

public enum AbgleichStatus: Equatable, Sendable {
    case aus
    case laeuft
    case fertig(Date, Uebernahme)
    case keinKonto
    case fehler
}

@MainActor
public final class AbgleichDienst {
    public private(set) var status: AbgleichStatus = .aus
    public var nachAenderung: (() -> Void)?
    private let speicher: AbgleichSpeicher
    private let geraet: String
    private let defaults: UserDefaults
    private var laeuft = false

    public static let schalterSchluessel = "partie.icloud.an"
    public static let zuletztSchluessel = "partie.icloud.zuletzt"
    private static let geraetSchluessel = "partie.icloud.geraet"
    private static let hashSchluessel = "partie.icloud.hash"

    public init(speicher: AbgleichSpeicher, defaults: UserDefaults = .standard) {
        self.speicher = speicher; self.defaults = defaults
        if let g = defaults.string(forKey: Self.geraetSchluessel) { geraet = g }
        else { geraet = UUID().uuidString; defaults.set(geraet, forKey: Self.geraetSchluessel) }
        if aktiv, let t = defaults.object(forKey: Self.zuletztSchluessel) as? Date { status = .fertig(t, Uebernahme()) }
    }

    public var aktiv: Bool {
        get { defaults.bool(forKey: Self.schalterSchluessel) }
        set { defaults.set(newValue, forKey: Self.schalterSchluessel); if !newValue { status = .aus; nachAenderung?() } }
    }

    /// C-002: Schaltet den Abgleich aus und löscht die Sicherung dieses Geräts aus iCloud (andere Geräte bleiben unberührt).
    /// Die Kennung wird vorab gelesen, damit das Löschen der Einstellungen sie nicht vorher entfernt.
    public func zuruecksetzen() {
        let war = aktiv, kennung = geraet, ablage = speicher
        aktiv = false
        guard war else { return }
        Task { try? await ablage.loeschen(geraet: kennung) }
    }

    /// Gleicht ab: eigene Sicherung hochladen (nur wenn sie sich geändert hat), fremde übernehmen. Gleichzeitige Aufrufe werden ignoriert.
    @discardableResult
    public func abgleichen(spieler: SpielerVerzeichnis, statistik: StatistikDienst, foto: (UUID) -> Data?, jetzt: Date = Date()) async -> AbgleichStatus {
        guard aktiv, !laeuft else { return status }
        laeuft = true; status = .laeuft; nachAenderung?()
        defer { laeuft = false; nachAenderung?() }
        guard await speicher.kontoVerfuegbar() else { status = .keinKonto; return status }
        do {
            // 1. Übernehmen (zuerst, damit die eigene Sicherung danach alles enthält)
            var gesamt = Uebernahme()
            for d in try await speicher.laden(ausser: geraet) {
                guard let s = try? Datensicherung.lesen(d) else { continue }   // kaputte oder zu neue Datensätze überspringen
                let u = spieler.uebernehmen(s, statistik: statistik)
                gesamt.spieler += u.spieler; gesamt.fotos += u.fotos; gesamt.partien += u.partien
            }
            // 2. Hochladen, wenn sich seit dem letzten Mal etwas geändert hat
            let daten = try Datensicherung.erstellen(spieler: spieler.alle, partien: statistik.ereignisse, foto: foto, am: Date(timeIntervalSince1970: 0))
            let pruefsumme = Self.pruefsumme(daten)
            if defaults.string(forKey: Self.hashSchluessel) != pruefsumme {
                try await speicher.hochladen(geraet: geraet, daten: try Datensicherung.erstellen(spieler: spieler.alle, partien: statistik.ereignisse, foto: foto, am: jetzt))
                defaults.set(pruefsumme, forKey: Self.hashSchluessel)
            }
            defaults.set(jetzt, forKey: Self.zuletztSchluessel)
            status = .fertig(jetzt, gesamt)
        } catch {
            status = .fehler
        }
        return status
    }

    /// Einfache, stabile Prüfsumme (FNV-1a), reicht für „hat sich etwas geändert“.
    static func pruefsumme(_ d: Data) -> String {
        var h: UInt64 = 0xcbf29ce484222325
        for b in d { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return String(h, radix: 16)
    }
}
