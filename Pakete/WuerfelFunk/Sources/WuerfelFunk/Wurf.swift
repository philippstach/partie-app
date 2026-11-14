// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

// MARK: - Inhalte

/// Ein Wurf, wie er vom Scanner zum Spielgerät geht: die Augen, eine laufende Nummer und (zum Prüfen am Spielgerät) je Würfel ein winziger Bildausschnitt.
/// `lauf` kennzeichnet eine Zählfolge des Scanners. Bleibt sie gleich (Wiederverbinden), zählt das Spielgerät weiter und
/// überliest doppelt geschickte Würfe. Beginnt eine neue Folge, fängt die Nummer wieder bei 1 an.
public struct FunkWurf: Codable, Equatable, Sendable {
    public let folge: Int
    public let augen: [Int]
    public let lauf: String?
    /// Kleine JPEG-Ausschnitte der Würfel, in derselben Reihenfolge wie `augen` (nur wenn der Scanner sie mitschickt; ältere Fassungen lassen sie weg).
    public let bilder: [Data]?
    public init(folge: Int, augen: [Int], lauf: String? = nil, bilder: [Data]? = nil) {
        self.folge = folge; self.augen = augen; self.lauf = lauf
        self.bilder = (bilder?.count == augen.count) ? bilder : nil
    }
    public func mitBildern(_ b: [Data]) -> FunkWurf { FunkWurf(folge: folge, augen: augen, lauf: lauf, bilder: b) }
}

/// Erste Nachricht nach dem Verbinden (und Inhalt der Einladung): Wer bin ich, welche Fassung des Protokolls spreche ich.
/// `kennung` ist eine zufällige, auf dem Gerät gespeicherte Kennung. Sie macht ein Gerät wiedererkennbar, auch wenn zwei Geräte gleich heißen.
public struct FunkHallo: Codable, Equatable, Sendable {
    public enum Rolle: String, Codable, Sendable { case spielgeraet, scanner }
    public let kennung: String
    public let name: String
    public let rolle: Rolle
    public let version: Int
    public init(kennung: String, name: String, rolle: Rolle, version: Int = FunkProtokoll.version) {
        self.kennung = kennung; self.name = name; self.rolle = rolle; self.version = version
    }
}

/// Spielgerät an Scanner: Was gerade gespielt wird und wie viele Würfel erwartet werden. Alles optional, damit auch
/// Seiten ohne Spiel (Einstellungen) eine Lage schicken können.
public struct FunkLage: Codable, Equatable, Sendable {
    public let spiel: String?
    public let amZug: String?
    /// Wie viele Würfel der nächste Wurf haben soll (`nil`: egal).
    public let erwartet: Int?
    /// Wie viele Würfel beiseitegelegt (gehalten) sind und nicht neu gelesen werden.
    public let gehalten: Int
    /// `true`, solange auf dem Spielgerät gerade ein Wurf angenommen werden kann.
    public let bereit: Bool
    public init(spiel: String? = nil, amZug: String? = nil, erwartet: Int? = nil, gehalten: Int = 0, bereit: Bool = true) {
        self.spiel = spiel; self.amZug = amZug; self.erwartet = erwartet; self.gehalten = gehalten; self.bereit = bereit
    }
}

/// Spielgerät an Scanner: Antwort auf einen Wurf.
public struct FunkQuittung: Codable, Equatable, Sendable {
    public enum Grund: String, Codable, Sendable {
        /// Der Wurf ist im Spiel angekommen.
        case angenommen
        /// Derselbe Wurf war schon da (z. B. nach dem Wiederverbinden nochmal geschickt). Für den Scanner gilt er als angekommen.
        case doppelt
        /// Augen ungültig (leer, außerhalb 1…6).
        case ungueltig
        /// Auf dem Spielgerät ist gerade kein Spiel bereit, einen Wurf zu nehmen. Der Wurf wird kurz aufgehoben.
        case keinEmpfaenger
        /// Unbekannter Grund aus einer neueren Fassung.
        case anderer

        public init(from decoder: Decoder) throws {
            self = Grund(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .anderer
        }
    }
    public let folge: Int
    public let lauf: String?
    public let grund: Grund
    public var angekommen: Bool { grund == .angenommen || grund == .doppelt }
    public init(folge: Int, lauf: String?, grund: Grund) { self.folge = folge; self.lauf = lauf; self.grund = grund }
}

/// Scanner an Spielgerät: Was die Kamera gerade sieht (für „liest …“, „3 von 5“).
public struct FunkStand: Codable, Equatable, Sendable {
    public let erkannt: Int
    public let erwartet: Int?
    public let sicher: Bool
    public init(erkannt: Int, erwartet: Int?, sicher: Bool) { self.erkannt = erkannt; self.erwartet = erwartet; self.sicher = sicher }
}

// MARK: - Protokoll

public enum FunkProtokoll {
    /// Fassung 1 war die Einbahnstraße bis Build 21 (nur `wurf`, ohne Umschlag). Fassung 2 bringt Umschlag, Hallo, Lage, Quittung, Stand, Puls.
    public static let version = 2
    /// Abstand der Lebenszeichen.
    public static let pulsAbstand: TimeInterval = 2
    /// So viele verpasste Pulse heißen „unterbrochen“.
    public static let pulsVerpasstGrenze = 3
}

/// Alles, was über die Leitung geht (klein, als JSON). Jede Nachricht steckt in einem Umschlag `{"v":2,"art":"…","inhalt":{…}}`.
/// Unbekannte Arten werden als `.unbekannt` gelesen und überlesen, damit neuere Gegenüber ältere Builds nicht stören.
/// Gelesen wird auch noch das alte Format aus Fassung 1 (`{"wurf":{"_0":{…}}}`).
public enum FunkNachricht: Equatable, Sendable {
    case hallo(FunkHallo)
    case lage(FunkLage)
    case quittung(FunkQuittung)
    case wurf(FunkWurf)
    case stand(FunkStand)
    case puls
    case tschuess
    case unbekannt(art: String)

    public var art: String {
        switch self {
        case .hallo: "hallo"
        case .lage: "lage"
        case .quittung: "quittung"
        case .wurf: "wurf"
        case .stand: "stand"
        case .puls: "puls"
        case .tschuess: "tschuess"
        case .unbekannt(let a): a
        }
    }

    private struct Kopf: Decodable { let v: Int; let art: String }
    private struct Umschlag<Inhalt: Codable>: Codable { let v: Int; let art: String; let inhalt: Inhalt? }
    private struct Leer: Codable {}
    /// Fassung 1: synthetisches Codable eines Enums mit einem unbenannten Wert.
    private struct AltWurf: Decodable { struct Wert: Decodable { let _0: FunkWurf }; let wurf: Wert }

    public func kodiert() -> Data? {
        let e = JSONEncoder()
        let v = FunkProtokoll.version
        switch self {
        case .hallo(let x): return try? e.encode(Umschlag(v: v, art: art, inhalt: x))
        case .lage(let x): return try? e.encode(Umschlag(v: v, art: art, inhalt: x))
        case .quittung(let x): return try? e.encode(Umschlag(v: v, art: art, inhalt: x))
        case .wurf(let x): return try? e.encode(Umschlag(v: v, art: art, inhalt: x))
        case .stand(let x): return try? e.encode(Umschlag(v: v, art: art, inhalt: x))
        case .puls, .tschuess: return try? e.encode(Umschlag<Leer>(v: v, art: art, inhalt: nil))
        case .unbekannt: return nil
        }
    }

    /// Liest eine Nachricht. `nil` heißt: kaputt (kein JSON, Pflichtfelder fehlen). Unbekannte Arten kommen als `.unbekannt` zurück.
    public static func lies(_ daten: Data) -> FunkNachricht? {
        let d = JSONDecoder()
        guard let kopf = try? d.decode(Kopf.self, from: daten) else {
            if let alt = try? d.decode(AltWurf.self, from: daten) { return .wurf(alt.wurf._0) }
            return nil
        }
        func inhalt<T: Codable>(_ t: T.Type) -> T? { (try? d.decode(Umschlag<T>.self, from: daten))?.inhalt }
        switch kopf.art {
        case "hallo": return inhalt(FunkHallo.self).map { .hallo($0) }
        case "lage": return inhalt(FunkLage.self).map { .lage($0) }
        case "quittung": return inhalt(FunkQuittung.self).map { .quittung($0) }
        case "wurf": return inhalt(FunkWurf.self).map { .wurf($0) }
        case "stand": return inhalt(FunkStand.self).map { .stand($0) }
        case "puls": return .puls
        case "tschuess": return .tschuess
        default: return .unbekannt(art: kopf.art)
        }
    }
}

// MARK: - Scanner: wann ist ein Wurf fertig

/// Entscheidet am Scanner, wann ein Wurf „fertig“ ist: Alle Würfel sicher gelesen und mehrere Auswertungen lang unverändert.
/// Danach wird erst wieder gesendet, wenn sich die Augen ändern oder die Würfel weggenommen wurden (neuer Wurf mit gleichen Augen).
public struct WurfMelder: Sendable {
    public var stabilNoetig = 6
    public var leerNoetig = 8
    /// Kennung dieser Zählfolge (siehe `FunkWurf.lauf`). Neu bei jedem `zuruecksetzen()`.
    public private(set) var lauf = UUID().uuidString
    private var folgeGleich = 0
    private var letzte: [Int] = []
    private var leerFolge = 0
    private var scharf = true
    private var gesendet: [Int]?
    public private(set) var naechsteNummer = 1

    public init() {}

    /// `augen`: aktuell gelesene Würfel, `sicher`: alle sicher erkannt. Liefert den Wurf, wenn er jetzt gesendet werden soll.
    public mutating func beobachte(augen: [Int], sicher: Bool) -> FunkWurf? {
        guard sicher, !augen.isEmpty else {
            leerFolge += 1; folgeGleich = 0; letzte = []
            if leerFolge >= leerNoetig { scharf = true }
            return nil
        }
        leerFolge = 0
        let sortiert = augen.sorted()
        if sortiert != letzte { letzte = sortiert; folgeGleich = 1 } else { folgeGleich += 1 }
        if let g = gesendet, g != sortiert { scharf = true }
        guard scharf, folgeGleich >= stabilNoetig else { return nil }
        scharf = false; gesendet = sortiert
        defer { naechsteNummer += 1 }
        return FunkWurf(folge: naechsteNummer, augen: augen, lauf: lauf)
    }

    /// Von Hand senden („Trotzdem senden“, auch wenn nicht alle Würfel gelesen sind): gibt der aktuellen Anzeige die nächste Nummer.
    /// Der Melder sendet dieselben Augen danach nicht noch einmal von selbst.
    public mutating func erzwinge(augen: [Int]) -> FunkWurf? {
        guard !augen.isEmpty else { return nil }
        scharf = false; gesendet = augen.sorted(); letzte = augen.sorted(); folgeGleich = max(folgeGleich, 1)
        defer { naechsteNummer += 1 }
        return FunkWurf(folge: naechsteNummer, augen: augen, lauf: lauf)
    }

    public mutating func zuruecksetzen() { self = WurfMelder() }
}

// MARK: - Spielgerät: Würfe annehmen

/// Am Spielgerät: ignoriert doppelt oder veraltet angekommene Würfe.
public struct WurfEmpfang: Sendable {
    public enum Ergebnis: Equatable, Sendable { case neu([Int]), doppelt, ungueltig }
    private var letzteFolge = 0
    private var lauf: String?
    public init() {}

    /// Bewertet einen Wurf und merkt sich seine Nummer, wenn er neu ist.
    public mutating func pruefe(_ wurf: FunkWurf) -> Ergebnis {
        guard !wurf.augen.isEmpty, wurf.augen.allSatisfy({ (1...6).contains($0) }) else { return .ungueltig }
        if wurf.lauf != lauf { lauf = wurf.lauf; letzteFolge = 0 }
        guard wurf.folge > letzteFolge else { return .doppelt }
        letzteFolge = wurf.folge
        return .neu(wurf.augen)
    }

    /// Wie `pruefe`, liefert aber nur die Augen eines neuen Wurfs.
    public mutating func nimm(_ wurf: FunkWurf) -> [Int]? {
        if case .neu(let a) = pruefe(wurf) { return a }
        return nil
    }

    /// Nach einer neuen Verbindung ohne Lauf-Kennung (Fassung 1) beginnt der Scanner wieder bei 1.
    /// Mit Lauf-Kennung zählt das Spielgerät über das Wiederverbinden hinweg weiter.
    public mutating func neueVerbindung() { if lauf == nil { letzteFolge = 0 } }
}

// MARK: - Scanner: Würfe bis zur Quittung aufheben

/// Am Scanner: Würfe, die noch nicht quittiert sind. Nach dem Wiederverbinden werden sie nochmal geschickt;
/// das Spielgerät erkennt doppelte an der Nummer.
public struct WurfAusgang: Sendable {
    public var hoechstens = 5
    public private(set) var offen: [FunkWurf] = []
    public private(set) var zuletztQuittiert: FunkQuittung?
    public init() {}

    public mutating func gesendet(_ w: FunkWurf) {
        offen.removeAll { $0.lauf == w.lauf && $0.folge == w.folge }
        offen.append(w)
        if offen.count > hoechstens { offen.removeFirst(offen.count - hoechstens) }
    }

    /// Nimmt eine Quittung entgegen. Angekommene Würfe (auch ältere derselben Folge) fallen aus der Liste,
    /// abgelehnte ungültige ebenfalls (nochmal schicken hilft nicht). `keinEmpfaenger` bleibt offen.
    public mutating func quittiert(_ q: FunkQuittung) {
        zuletztQuittiert = q
        switch q.grund {
        case .angenommen, .doppelt: offen.removeAll { $0.lauf == q.lauf && $0.folge <= q.folge }
        case .ungueltig, .anderer: offen.removeAll { $0.lauf == q.lauf && $0.folge == q.folge }
        case .keinEmpfaenger: break
        }
    }

    public mutating func leeren() { offen = []; zuletztQuittiert = nil }
}

// MARK: - Lebenszeichen

/// Merkt sich, wann zuletzt etwas vom Gegenüber kam. Drei verpasste Pulse heißen „unterbrochen“.
public struct PulsWaechter: Sendable {
    public var abstand: TimeInterval
    public var grenze: Int
    public private(set) var zuletzt: Date?
    public init(abstand: TimeInterval = FunkProtokoll.pulsAbstand, grenze: Int = FunkProtokoll.pulsVerpasstGrenze) {
        self.abstand = abstand; self.grenze = grenze
    }
    /// Jede Nachricht vom Gegenüber zählt als Lebenszeichen, nicht nur `puls`.
    public mutating func lebenszeichen(_ jetzt: Date = Date()) { zuletzt = jetzt }
    public mutating func zuruecksetzen() { zuletzt = nil }
    public func istStumm(_ jetzt: Date = Date()) -> Bool {
        guard let z = zuletzt else { return false }
        return jetzt.timeIntervalSince(z) > abstand * Double(grenze)
    }
}

// MARK: - Wiederverbinden

/// Abstände für neue Versuche nach einem Abbruch: 1, 2, 4, 8, 8, … Sekunden, höchstens `dauer` Sekunden lang.
public struct WiederverbindePlan: Sendable {
    public var stufen: [TimeInterval] = [1, 2, 4, 8]
    public var dauer: TimeInterval = 120
    public private(set) var versuch = 0
    public private(set) var gewartet: TimeInterval = 0
    public init() {}
    public init(stufen: [TimeInterval], dauer: TimeInterval) { self.stufen = stufen; self.dauer = dauer }

    /// Wartezeit bis zum nächsten Versuch, `nil` wenn aufgegeben wird.
    public mutating func naechsteWartezeit() -> TimeInterval? {
        guard let letzte = stufen.last else { return nil }
        let w = versuch < stufen.count ? stufen[versuch] : letzte
        guard gewartet + w <= dauer else { return nil }
        versuch += 1; gewartet += w
        return w
    }

    public var laeuft: Bool { versuch > 0 }
    public mutating func zuruecksetzen() { versuch = 0; gewartet = 0 }
}

// MARK: - Bekannte Geräte

/// Ein Gerät, mit dem schon einmal gekoppelt wurde. Es verbindet sich danach ohne Rückfrage.
public struct BekanntesGeraet: Codable, Equatable, Identifiable, Sendable {
    public let kennung: String
    public var name: String
    public var zuletzt: Date
    public var id: String { kennung }
    public init(kennung: String, name: String, zuletzt: Date = Date()) { self.kennung = kennung; self.name = name; self.zuletzt = zuletzt }
}

/// Liste der bekannten Geräte, gespeichert in den UserDefaults (nur Kennung, Name, Datum).
public struct BekannteGeraete: Sendable {
    public static let schluessel = "wuerfelFunk.bekannteGeraete"
    public var hoechstens = 20
    public private(set) var liste: [BekanntesGeraet] = []

    public init(liste: [BekanntesGeraet] = []) { self.liste = liste }

    public func kennt(_ kennung: String?) -> Bool {
        guard let kennung, !kennung.isEmpty else { return false }
        return liste.contains { $0.kennung == kennung }
    }

    /// Merkt sich ein Gerät oder frischt Name und Datum auf. Die neuesten stehen vorne.
    public mutating func merke(kennung: String, name: String, jetzt: Date = Date()) {
        guard !kennung.isEmpty else { return }
        liste.removeAll { $0.kennung == kennung }
        liste.insert(BekanntesGeraet(kennung: kennung, name: name, zuletzt: jetzt), at: 0)
        if liste.count > hoechstens { liste.removeLast(liste.count - hoechstens) }
    }

    public mutating func vergiss(_ kennung: String) { liste.removeAll { $0.kennung == kennung } }
    public mutating func vergissAlle() { liste = [] }

    public static func laden(_ d: UserDefaults = .standard) -> BekannteGeraete {
        guard let daten = d.data(forKey: schluessel), let l = try? JSONDecoder().decode([BekanntesGeraet].self, from: daten) else { return BekannteGeraete() }
        return BekannteGeraete(liste: l)
    }

    public func sichern(_ d: UserDefaults = .standard) {
        if let daten = try? JSONEncoder().encode(liste) { d.set(daten, forKey: Self.schluessel) }
    }
}

/// Eigene, zufällige und gespeicherte Kennung dieses Geräts (keine Geräte-ID von Apple, nichts Persönliches).
public enum EigeneKennung {
    public static let schluessel = "wuerfelFunk.eigeneKennung"
    public static func lesen(_ d: UserDefaults = .standard) -> String {
        if let k = d.string(forKey: schluessel), !k.isEmpty { return k }
        let k = UUID().uuidString
        d.set(k, forKey: schluessel)
        return k
    }
}

// MARK: - Zustände

/// Zustand der Verbindung, wie ihn beide Geräte anzeigen.
public enum FunkZustand: Equatable, Sendable {
    /// Funk ist aus (noch nicht gestartet oder beendet).
    case aus
    /// Scanner sucht Spielgeräte, Spielgerät ist sichtbar und wartet.
    case sucht
    /// Scanner hat eingeladen, das Spielgerät muss noch zusagen.
    case wartetAufZusage(name: String)
    /// Verbunden und es kommen Lebenszeichen.
    case verbunden(name: String)
    /// Verbindung abgerissen, es wird neu verbunden (`versuch` ab 1).
    case unterbrochen(name: String, versuch: Int)
    /// Aufgegeben oder abgelehnt. Funk läuft weiter, es wird wieder gesucht.
    case getrennt(name: String?, grund: Trenngrund)

    public enum Trenngrund: Equatable, Sendable { case vonHand, abgelehnt, keineAntwort, aufgegeben, vomGegenueber }

    public var istVerbunden: Bool { if case .verbunden = self { return true }; return false }
    public var istUnterbrochen: Bool { if case .unterbrochen = self { return true }; return false }
    public var gegenueber: String? {
        switch self {
        case .wartetAufZusage(let n), .verbunden(let n), .unterbrochen(let n, _): return n
        case .getrennt(let n, _): return n
        case .aus, .sucht: return nil
        }
    }
}
