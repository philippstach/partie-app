// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Lern-Aufnahme (Testfunktion, standardmäßig aus): Bei jedem bestätigten Wurf speichert die Kamera-Seite das Standbild, die Rahmen,
// die bestätigten Augen und einige Bilder davor im App-Ordner. Die Bilder bleiben auf dem Gerät, bis der Spieler sie über „Teilen“ wegschickt.
// Reine Logik (Dateiformat, Zuordnung, ZIP) ohne Kamera, damit sie mit `swift test` geprüft werden kann.
// Format: siehe `LernAufnahme.formatText` (liegt auch als LIES-MICH.txt im Paket).

/// Ein Rahmen im Standbild, normiert 0…1, Ursprung oben links.
public struct LernRahmen: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var breite: Double
    public var hoehe: Double
    public init(x: Double, y: Double, breite: Double, hoehe: Double) { self.x = x; self.y = y; self.breite = breite; self.hoehe = hoehe }
}

/// Was beim Ergänzen eines übersehenen Würfels bekannt war: Tippunkt, übliche Würfelgröße der anderen Würfel und der Rahmen des Nah-Finders.
struct LernErgaenzung: Sendable {
    var tipp: CGPoint
    /// Kantenlänge der anderen Würfel als Anteil der kurzen Bildseite (`nil`: kein anderer Würfel im Bild).
    var ueblicheKante: Double?
    var erkannt: CGRect
}

/// Ein bestätigter Würfel im Standbild.
public struct LernWuerfel: Codable, Equatable, Sendable {
    public var id: Int
    /// Bestätigte Augenzahl (nach einer Korrektur der neue Wert).
    public var augen: Int
    /// Rahmen im Standbild, normiert 0…1, Ursprung oben links.
    public var x: Double
    public var y: Double
    public var breite: Double
    public var hoehe: Double
    /// Der Wert stand schon vor der Bestätigung fest (Mehrheit über mehrere Bilder).
    public var sicher: Bool
    /// Hat der Spieler den Wert geändert: was die Erkennung vorher gezeigt hat.
    public var korrigiertVon: Int?
    /// Der Würfel fehlte und wurde per Tipp ergänzt (die Erkennung hatte ihn übersehen).
    public var ergaenzt: Bool
    /// `true` bei ergänzten Würfeln: x, y, breite, hoehe sind aus dem Tippunkt und der üblichen Würfelgröße in diesem Bild geschätzt (Mittelpunkt = Tippunkt),
    /// nicht der Rahmen der Erkennung. Der Rahmen des Nah-Finders steht dann in `erkannterRahmen`.
    public var geschaetzt: Bool
    public var erkannterRahmen: LernRahmen?

    public init(id: Int, augen: Int, x: Double, y: Double, breite: Double, hoehe: Double, sicher: Bool, korrigiertVon: Int? = nil, ergaenzt: Bool = false,
                geschaetzt: Bool = false, erkannterRahmen: LernRahmen? = nil) {
        self.id = id; self.augen = augen; self.x = x; self.y = y; self.breite = breite; self.hoehe = hoehe
        self.sicher = sicher; self.korrigiertVon = korrigiertVon; self.ergaenzt = ergaenzt
        self.geschaetzt = geschaetzt; self.erkannterRahmen = erkannterRahmen
    }
}

/// Ein Fund der Erkennung in einem einzelnen Bild (roh, wie ihn das Modell gemeldet hat).
public struct LernFund: Codable, Equatable, Sendable {
    public var augen: Int
    public var x: Double
    public var y: Double
    public var breite: Double
    public var hoehe: Double
    public var sicherheit: Double
    /// Bei den Bildern davor: die bestätigte Augenzahl des Würfels, zu dem dieser Fund gehört. `nil`: keinem bestätigten Würfel zuzuordnen.
    public var richtig: Int?

    public init(augen: Int, x: Double, y: Double, breite: Double, hoehe: Double, sicherheit: Double, richtig: Int? = nil) {
        self.augen = augen; self.x = x; self.y = y; self.breite = breite; self.hoehe = hoehe; self.sicherheit = sicherheit; self.richtig = richtig
    }
}

/// Eines der Bilder vor dem Standbild.
public struct LernVorBild: Codable, Equatable, Sendable {
    public var datei: String
    /// So viele Sekunden vor dem letzten Bild der Kamera.
    public var sekundenVorher: Double
    public var funde: [LernFund]
}

/// Die Beschreibung eines Wurfs (`wurf.json`).
public struct LernWurf: Codable, Equatable, Sendable {
    public var version: Int
    public var id: String
    /// ISO 8601, UTC.
    public var zeit: String
    public var standbild: String
    public var breite: Int
    public var hoehe: Int
    /// Wie viele Würfel das Spiel erwartet hat (`nil`: unbekannt, zum Beispiel beim Ausprobieren in den Einstellungen).
    public var erwartet: Int?
    /// `true`: Der Spieler hat etwas geändert, ergänzt oder entfernt. Diese Fälle sind für das Training am wertvollsten.
    public var korrigiert: Bool
    public var wuerfel: [LernWuerfel]
    /// Entfernte Funde („Kein Würfel“): Gegenbeispiele.
    public var falscheFunde: [LernFund]
    public var vorher: [LernVorBild]
    public var geraet: String?
    /// Worauf sich die Rahmen beziehen: immer das volle Kamerabild, wie es im Standbild liegt. Die App schneidet nichts aus; der Zoom
    /// (feste Stufe oder Automatik) wirkt schon in der Kamera. Die Pixel liegen so, wie die Kamera sie liefert (Hochformat), ohne EXIF-Drehung.
    public var bildBezug: String
    /// Zoomfaktor der Kamera zum Zeitpunkt der Bestätigung (roher `videoZoomFactor`; bei virtuellen Kameras ist die Zahl je nach Gerät anders skaliert, die Stufe steht in `zoomStufe`).
    public var zoomFaktor: Double?
    /// Name der Zoomstufe („0,5×“, „1×“, „3×“).
    public var zoomStufe: String?
    /// Die Zoom-Automatik war an.
    public var zoomAutomatik: Bool?

    public static let volleKamerabild = "volles Kamerabild, kein Ausschnitt, ohne EXIF-Drehung"

    public init(version: Int = 2, id: String, zeit: String, standbild: String = "standbild.jpg", breite: Int, hoehe: Int, erwartet: Int?, korrigiert: Bool,
                wuerfel: [LernWuerfel], falscheFunde: [LernFund], vorher: [LernVorBild] = [], geraet: String? = nil,
                zoomFaktor: Double? = nil, zoomStufe: String? = nil, zoomAutomatik: Bool? = nil) {
        self.bildBezug = Self.volleKamerabild
        self.zoomFaktor = zoomFaktor; self.zoomStufe = zoomStufe; self.zoomAutomatik = zoomAutomatik
        self.version = version; self.id = id; self.zeit = zeit; self.standbild = standbild; self.breite = breite; self.hoehe = hoehe
        self.erwartet = erwartet; self.korrigiert = korrigiert; self.wuerfel = wuerfel; self.falscheFunde = falscheFunde
        self.vorher = vorher; self.geraet = geraet
    }
}

/// Ein Bild aus dem Ring der letzten Bilder (schon als JPEG, damit der Speicher klein bleibt).
public struct LernRingBild: Sendable {
    public let jpeg: Data
    public let funde: [GesehenerWuerfel]
    public let zeit: Date
    public let seitenverhaeltnis: Double
}

/// Die letzten Bilder der Kamera, höchstens `kapazitaet`. Wird auf dem Kamera-Thread gefüllt und vom Hauptthread gelesen.
public final class LernRing: @unchecked Sendable {
    private let schloss = NSLock()
    private var bilder: [LernRingBild] = []
    public let kapazitaet: Int
    public init(kapazitaet: Int = 15) { self.kapazitaet = max(1, kapazitaet) }

    public func merke(_ bild: LernRingBild) {
        schloss.withLock {
            bilder.append(bild)
            if bilder.count > kapazitaet { bilder.removeFirst(bilder.count - kapazitaet) }
        }
    }
    /// Alle Bilder, das älteste zuerst.
    public func alle() -> [LernRingBild] { schloss.withLock { bilder } }
    public func leeren() { schloss.withLock { bilder = [] } }
}

public enum LernAufnahme {
    /// Schlüssel des Schalters in den Einstellungen (`UserDefaults`/`@AppStorage`).
    public static let schalterKey = "wuerfelLernAufnahme"
    /// Jedes so vielte Kamerabild (Auswertung) kommt in den Ring: bei 10 Auswertungen je Sekunde ein Bild alle 0,3 s, 15 Bilder = rund 4,5 s.
    public static let ringAbstand = 3

    /// Nur in der Beta (TestFlight) und in Debug-Bauten: Philipp 14.11. Im App-Store-Bau gibt es weder Schalter noch Aufnahme.
    public static var istBeta: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    public static var schalterAn: Bool { istBeta && UserDefaults.standard.bool(forKey: schalterKey) }

    /// Ordner, in dem die Würfe liegen (App-Ordner, nicht in der Sicherung).
    public static var ordner: URL {
        let basis = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return basis.appendingPathComponent("LernAufnahmen", isDirectory: true)
    }

    // MARK: Zuordnung

    /// Rahmen eines ergänzten Würfels aus Tippunkt und üblicher Würfelgröße: Quadrat um den Tippunkt, an den Bildrand geschoben.
    /// `kante` = Anteil der kurzen Bildseite (wie `ueblicheKante`); ohne sie gilt die Größe des Rahmens aus dem Nah-Finder.
    static func geschaetzterRahmen(_ e: LernErgaenzung, breite: Int, hoehe: Int) -> LernRahmen {
        let b = Double(max(breite, 1)), h = Double(max(hoehe, 1))
        let kantePixel = e.ueblicheKante.map { $0 * min(b, h) } ?? max(Double(e.erkannt.width) * b, Double(e.erkannt.height) * h)
        let rb = min(kantePixel / b, 1), rh = min(kantePixel / h, 1)
        let x = min(max(Double(e.tipp.x) - rb / 2, 0), 1 - rb), y = min(max(Double(e.tipp.y) - rh / 2, 0), 1 - rh)
        return LernRahmen(x: x, y: y, breite: rb, hoehe: rh)
    }

    /// Ordnet die rohen Funde eines Bildes den bestätigten Würfeln zu (nächster Mittelpunkt, höchstens gut einen halben Würfel entfernt).
    /// `seitenverhaeltnis` = Breite geteilt durch Höhe des Bildes, damit Abstände in beiden Richtungen gleich zählen.
    public static func funde(_ gesehen: [GesehenerWuerfel], bestaetigt: [LernWuerfel], seitenverhaeltnis k: Double) -> [LernFund] {
        var frei = Array(bestaetigt.indices)
        return gesehen.map { g in
            var fund = LernFund(augen: g.augen, x: Double(g.rahmen.minX), y: Double(g.rahmen.minY),
                                breite: Double(g.rahmen.width), hoehe: Double(g.rahmen.height), sicherheit: g.sicherheit)
            let gx = Double(g.rahmen.midX) * k, gy = Double(g.rahmen.midY)
            let kante = max(Double(g.rahmen.width) * k, Double(g.rahmen.height))
            var beste: (Int, Double)?
            for i in frei {
                let w = bestaetigt[i]
                let d = hypot((w.x + w.breite / 2) * k - gx, (w.y + w.hoehe / 2) - gy)
                if d < 0.6 * kante, d < (beste?.1 ?? .infinity) { beste = (i, d) }
            }
            if let (i, _) = beste { fund.richtig = bestaetigt[i].augen; frei.removeAll { $0 == i } }
            return fund
        }
    }

    // MARK: Speichern

    /// JPEG eines Bildes (Qualität 0,85).
    public static func jpeg(von bild: CGImage, qualitaet: Double = 0.85) -> Data? {
        let daten = NSMutableData()
        guard let ziel = CGImageDestinationCreateWithData(daten, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(ziel, bild, [kCGImageDestinationLossyCompressionQuality: qualitaet] as CFDictionary)
        guard CGImageDestinationFinalize(ziel) else { return nil }
        return daten as Data
    }

    /// Kennung für einen neuen Wurf: Zeit und vier zufällige Zeichen, mit „-k“ am Ende bei korrigierten Würfen (zum schnellen Sortieren).
    public static func neueKennung(zeit: Date = Date(), korrigiert: Bool) -> (id: String, ordnerName: String, iso: String) {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyyMMdd-HHmmss"
        let zufall = String(format: "%04x", UInt16.random(in: 0...UInt16.max))
        let id = "\(f.string(from: zeit))-\(zufall)"
        let iso = ISO8601DateFormatter().string(from: zeit)
        return (id, korrigiert ? id + "-k" : id, iso)
    }

    /// Schreibt einen Wurf: `standbild.jpg`, `vorher-01.jpg` … (das älteste zuerst) und `wurf.json`. Gibt den Ordner des Wurfs zurück.
    /// Erst in einen verborgenen Zwischenordner, dann umbenannt: ein Abbruch hinterlässt keinen halben Wurf.
    @discardableResult
    public static func speichere(wurf: LernWurf, ordnerName: String, standbild: Data, vorher: [LernRingBild], in wurzel: URL = ordner) throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: wurzel, withIntermediateDirectories: true)
        var wurzelKopie = wurzel
        var werte = URLResourceValues(); werte.isExcludedFromBackup = true
        try? wurzelKopie.setResourceValues(werte)

        let zwischen = wurzel.appendingPathComponent(".neu-" + ordnerName, isDirectory: true)
        try? fm.removeItem(at: zwischen)
        try fm.createDirectory(at: zwischen, withIntermediateDirectories: true)
        do {
            try standbild.write(to: zwischen.appendingPathComponent(wurf.standbild))
            var beschrieben = wurf
            let ende = vorher.last?.zeit ?? Date()
            beschrieben.vorher = []
            for (i, b) in vorher.enumerated() {
                let name = String(format: "vorher-%02d.jpg", i + 1)
                try b.jpeg.write(to: zwischen.appendingPathComponent(name))
                beschrieben.vorher.append(LernVorBild(datei: name, sekundenVorher: (ende.timeIntervalSince(b.zeit) * 10).rounded() / 10,
                                                      funde: funde(b.funde, bestaetigt: wurf.wuerfel, seitenverhaeltnis: b.seitenverhaeltnis)))
            }
            let kodierer = JSONEncoder()
            kodierer.outputFormatting = [.prettyPrinted, .sortedKeys]
            try kodierer.encode(beschrieben).write(to: zwischen.appendingPathComponent("wurf.json"))
        } catch {
            try? fm.removeItem(at: zwischen)
            throw error
        }
        let ziel = wurzel.appendingPathComponent(ordnerName, isDirectory: true)
        try? fm.removeItem(at: ziel)
        try fm.moveItem(at: zwischen, to: ziel)
        return ziel
    }

    /// Anzahl der gespeicherten Würfe.
    public static func anzahl(in wurzel: URL = ordner) -> Int { wuerfe(in: wurzel).count }

    /// Anzahl der gespeicherten Würfe, bei denen etwas korrigiert wurde.
    public static func anzahlKorrigiert(in wurzel: URL = ordner) -> Int { wuerfe(in: wurzel).filter { $0.lastPathComponent.hasSuffix("-k") }.count }

    /// Die Wurf-Ordner, nach Name (= Zeit) sortiert. Verborgene Zwischenordner zählen nicht.
    static func wuerfe(in wurzel: URL) -> [URL] {
        let inhalt = (try? FileManager.default.contentsOfDirectory(at: wurzel, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        return inhalt.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Löscht alle gespeicherten Würfe (nur auf ausdrücklichen Wunsch des Spielers in den Einstellungen).
    public static func loescheAlle(in wurzel: URL = ordner) {
        try? FileManager.default.removeItem(at: wurzel)
    }

    // MARK: Teilen

    /// Packt alle Würfe in eine ZIP-Datei (ohne Verkleinern: JPEG lässt sich kaum weiter verkleinern) und gibt ihren Ort zurück.
    /// Jede Datei wird einzeln gelesen, der Speicher bleibt klein. Dazu kommt `LIES-MICH.txt` mit der Beschreibung des Formats.
    public static func packe(in wurzel: URL = ordner, nach ziel: URL? = nil) throws -> URL {
        let datei = ziel ?? FileManager.default.temporaryDirectory.appendingPathComponent("Wuerfelaufnahmen-" + neueKennung(korrigiert: false).id + ".zip")
        var eintraege: [(name: String, quelle: URL)] = []
        for w in wuerfe(in: wurzel) {
            let namen = ((try? FileManager.default.contentsOfDirectory(atPath: w.path)) ?? []).filter { !$0.hasPrefix(".") }.sorted()
            for n in namen { eintraege.append((w.lastPathComponent + "/" + n, w.appendingPathComponent(n))) }
        }
        try ZipSchreiber.schreibe(nach: datei, text: [("LIES-MICH.txt", formatText)], dateien: eintraege)
        return datei
    }

    public static let formatText = """
    Lern-Aufnahme der Partie-Test-App (Format Version 2)

    Jeder Unterordner ist ein bestätigter Wurf. Der Name ist Zeit (UTC) und vier zufällige Zeichen; endet er auf „-k“, hat der Spieler etwas korrigiert, ergänzt oder entfernt. Diese Fälle sind für das Training am wertvollsten.

    standbild.jpg   das Bild, das der Spieler bestätigt hat (Hochformat, in der Regel 1080 × 1920)
    vorher-01.jpg … Bilder aus den Sekunden davor, das älteste zuerst (Abstand etwa 0,3 s)
    wurf.json       Beschriftung

    Alle Rahmen sind normiert auf 0…1, Ursprung oben links: x, y = linke obere Ecke, breite, hoehe = Größe, jeweils als Anteil der Bildbreite bzw. -höhe. Der Rahmen im Standbild ist der Rahmen der Erkennung, nicht von Hand nachgezogen.

    wuerfel[]       bestätigte Würfel im Standbild: augen (bestätigter Wert), sicher, korrigiertVon (vorheriger Wert der Erkennung, nur wenn geändert), ergaenzt (die Erkennung hatte den Würfel übersehen)
    falscheFunde[]  Funde, die der Spieler als „Kein Würfel“ entfernt hat (Gegenbeispiele)
    vorher[]        je Bild davor: datei, sekundenVorher, funde[] mit den rohen Funden der Erkennung (augen, Rahmen, sicherheit) und richtig = bestätigte Augenzahl, wenn der Fund zu einem bestätigten Würfel passt (nächster Mittelpunkt); ohne richtig ist der Fund nicht zuzuordnen (Würfel noch in Bewegung oder Fehlfund)
    geschaetzt      bei ergänzten Würfeln true: x, y, breite, hoehe sind aus dem Tippunkt (= Mittelpunkt) und der üblichen Würfelgröße der anderen Würfel in diesem Bild geschätzt, nicht der Rahmen der Erkennung; der Rahmen des Nah-Finders steht dann in erkannterRahmen
    bildBezug       alle Rahmen beziehen sich auf das volle Kamerabild genau so, wie es in standbild.jpg liegt. Die App schneidet nichts aus; der Zoom (Stufe oder Automatik) wirkt schon in der Kamera (zoomFaktor, zoomStufe, zoomAutomatik). Pixel wie von der Kamera geliefert (Hochformat), keine EXIF-Drehung.
    erwartet        wie viele Würfel das Spiel erwartet hat (leer: unbekannt)

    Hinweis: Die Rahmen der Bilder davor sind nur Funde der Erkennung, keine von Hand geprüften Beschriftungen. Würfel, die sich zwischen den Bildern bewegt haben, sind nicht beschriftet.
    """
}

// MARK: - ZIP

/// Schreibt eine ZIP-Datei ohne Kompression („stored“), Datei für Datei. Genügt für JPEG und kleine Textdateien.
enum ZipSchreiber {
    struct Fehler: Error { let grund: String }

    enum Crc32 {
        static let tabelle: [UInt32] = (0..<256).map { n -> UInt32 in
            var c = UInt32(n)
            for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
            return c
        }
        static func summe(_ daten: Data) -> UInt32 {
            var c: UInt32 = 0xFFFF_FFFF
            for b in daten { c = tabelle[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
            return c ^ 0xFFFF_FFFF
        }
    }

    private struct Zentral { let name: Data; let crc: UInt32; let groesse: UInt32; let versatz: UInt32 }

    static func schreibe(nach ziel: URL, text: [(String, String)], dateien: [(name: String, quelle: URL)]) throws {
        let fm = FileManager.default
        try? fm.removeItem(at: ziel)
        guard fm.createFile(atPath: ziel.path, contents: nil) else { throw Fehler(grund: "Datei nicht anlegbar") }
        let h = try FileHandle(forWritingTo: ziel)
        defer { try? h.close() }
        var zentral: [Zentral] = []
        var versatz: UInt64 = 0

        func eintrag(_ name: String, _ daten: Data) throws {
            guard daten.count < Int(UInt32.max), versatz < UInt64(UInt32.max) - UInt64(daten.count) - 1000 else { throw Fehler(grund: "ZIP zu groß") }
            guard zentral.count < 65_000 else { throw Fehler(grund: "zu viele Dateien") }
            let n = Data(name.utf8)
            let crc = Crc32.summe(daten)
            var kopf = Data()
            kopf.u32(0x0403_4b50); kopf.u16(20); kopf.u16(0x0800); kopf.u16(0); kopf.u16(0); kopf.u16(33)
            kopf.u32(crc); kopf.u32(UInt32(daten.count)); kopf.u32(UInt32(daten.count))
            kopf.u16(UInt16(n.count)); kopf.u16(0); kopf.append(n)
            try h.write(contentsOf: kopf)
            try h.write(contentsOf: daten)
            zentral.append(Zentral(name: n, crc: crc, groesse: UInt32(daten.count), versatz: UInt32(versatz)))
            versatz += UInt64(kopf.count + daten.count)
        }

        for (n, t) in text { try eintrag(n, Data(t.utf8)) }
        for d in dateien { try eintrag(d.name, try Data(contentsOf: d.quelle)) }

        var verzeichnis = Data()
        for z in zentral {
            verzeichnis.u32(0x0201_4b50); verzeichnis.u16(20); verzeichnis.u16(20); verzeichnis.u16(0x0800); verzeichnis.u16(0)
            verzeichnis.u16(0); verzeichnis.u16(33)
            verzeichnis.u32(z.crc); verzeichnis.u32(z.groesse); verzeichnis.u32(z.groesse)
            verzeichnis.u16(UInt16(z.name.count)); verzeichnis.u16(0); verzeichnis.u16(0); verzeichnis.u16(0); verzeichnis.u16(0)
            verzeichnis.u32(0); verzeichnis.u32(z.versatz); verzeichnis.append(z.name)
        }
        var ende = Data()
        ende.u32(0x0605_4b50); ende.u16(0); ende.u16(0); ende.u16(UInt16(zentral.count)); ende.u16(UInt16(zentral.count))
        ende.u32(UInt32(verzeichnis.count)); ende.u32(UInt32(versatz)); ende.u16(0)
        try h.write(contentsOf: verzeichnis)
        try h.write(contentsOf: ende)
    }
}

private extension Data {
    mutating func u16(_ v: UInt16) { append(UInt8(v & 0xFF)); append(UInt8(v >> 8)) }
    mutating func u32(_ v: UInt32) { u16(UInt16(v & 0xFFFF)); u16(UInt16(v >> 16)) }
}
