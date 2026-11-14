// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import Foundation

/// Ein Würfel auf der Anzeige: mit fester Nummer über viele Bilder hinweg.
public struct AngezeigterWuerfel: Equatable, Identifiable, Sendable {
    public let id: Int
    public let rahmen: CGRect
    public let augen: Int
    /// `true`: Der Wert hat über mehrere Auswertungen die klare Mehrheit (oder wurde von Hand gesetzt).
    public let sicher: Bool
}

/// Verfolgt Würfel über viele Bilder: Jeder Würfel behält seine Nummer und seinen Wert, auch wenn sich die Kamera bewegt,
/// der Abstand sich ändert (Herauszoomen) oder die Erkennung ihn in einzelnen Bildern übersieht.
///
/// So geht es:
/// 1. Vorhersage: Alle Spuren wandern mit der zuletzt gemessenen gemeinsamen Bewegung weiter (die Hand bewegt sich meist gleichmäßig).
/// 2. Kamerabewegung: Aus allen Würfeln gemeinsam wird geschätzt, wie sich das Bild verschoben, vergrößert und gedreht hat.
///    Diese Bewegung gilt für alle Spuren – auch für Würfel, die gerade nicht erkannt wurden.
/// 3. Zuordnung: Jede Erkennung gehört zur nächstgelegenen Spur ähnlicher Größe.
/// 4. Mehrheit: Jede Auswertung ist eine Stimme für eine Augenzahl. Alte Stimmen verblassen, Stimmen aus bewegten (unscharfen)
///    Bildern zählen weniger. Der Wert mit klarer Mehrheit wird fest; einzelne Fehlwerte ändern ihn nicht.
///
/// Reine Logik, ohne Kamera testbar.
public struct WuerfelVerfolger: Sendable {
    /// Breite geteilt durch Höhe des Bildes (die Rahmen sind 0…1 normiert, Abstände werden damit entzerrt).
    public var seitenverhaeltnis: Double
    /// Stimmgewicht, ab dem ein Wert fest wird (eine ruhige Auswertung zählt 1).
    public var festAb: Double
    /// Mindestanteil des führenden Werts an allen Stimmen.
    public var anteil: Double
    /// Faktor, mit dem alte Stimmen je Auswertung verblassen.
    public var vergessen: Double
    /// So viele Auswertungen in Folge mit demselben anderen Wert ersetzen einen festen Wert sofort (Würfel wurde gedreht).
    public var wechsel: Int
    /// Ab so vielen Funden wird ein neuer Würfel angezeigt (unterdrückt einzelne Fehlfunde).
    public var sichtbarAb: Int
    /// So viele Auswertungen darf ein fester Würfel fehlen, bevor er verschwindet.
    public var geduld: Int
    /// Dasselbe für noch unsichere Würfel.
    public var geduldNeu: Int
    /// Wie weit (in Würfelkanten) eine Erkennung nach Ausgleich der Kamerabewegung von ihrer Spur entfernt sein darf.
    public var reichweite: Double

    /// Bewegung der Würfel im Bild bei der letzten Auswertung, in Würfelkanten (Median). `nil`: kein Würfel wiedergefunden.
    public private(set) var bewegung: Double?

    private var spuren: [Spur] = []
    private var naechsteId = 1
    /// Gemeinsame Bewegung aller Würfel bei der letzten Auswertung (Median, entzerrt): ein einzelner Ausreißer zählt nicht.
    private var drift = (x: 0.0, y: 0.0)

    struct Spur {
        var id: Int
        var x: Double, y: Double          // Mitte, entzerrt (Einheit: Bildhöhe)
        var b: Double, h: Double          // Größe, entzerrt
        var stimmen = [Double](repeating: 0, count: 7)
        var treffer = 1
        var fehlt = 0
        var korrektur: Int?
        var fest: Int?
        var kandidat = 0, folge = 0
        var seite: Double { max(b, h) }
        var bester: Int { (1...6).max { stimmen[$0] < stimmen[$1] } ?? 1 }
        var rang: Double { (korrektur != nil ? 1e6 : 0) + (fest != nil ? 1e3 : 0) + stimmen.reduce(0, +) }
    }

    struct Messung { var x: Double, y: Double, b: Double, h: Double, augen: Int; var seite: Double { max(b, h) } }

    /// Geschätzte Kamerabewegung: p' = a · p + t (a als komplexe Zahl: Maßstab und Drehung).
    struct Abbildung {
        var ar = 1.0, ai = 0.0, tx = 0.0, ty = 0.0
        var massstab: Double { (ar * ar + ai * ai).squareRoot() }
        func auf(_ x: Double, _ y: Double) -> (Double, Double) { (ar * x - ai * y + tx, ai * x + ar * y + ty) }
    }

    public init(seitenverhaeltnis: Double = 9.0 / 16.0, festAb: Double = 3.2, anteil: Double = 0.6, vergessen: Double = 0.9,
                wechsel: Int = 5, sichtbarAb: Int = 2, geduld: Int = 15, geduldNeu: Int = 3, reichweite: Double = 0.8) {
        self.seitenverhaeltnis = seitenverhaeltnis; self.festAb = festAb; self.anteil = anteil; self.vergessen = vergessen
        self.wechsel = wechsel; self.sichtbarAb = sichtbarAb; self.geduld = geduld; self.geduldNeu = geduldNeu; self.reichweite = reichweite
    }

    /// Für ein einzelnes Standbild: eine Auswertung genügt, alles gilt als sicher (korrigierbar per Tipp).
    public static func einzelbild(seitenverhaeltnis: Double = 9.0 / 16.0) -> WuerfelVerfolger {
        WuerfelVerfolger(seitenverhaeltnis: seitenverhaeltnis, festAb: 1, sichtbarAb: 1)
    }

    // MARK: Auswertung

    /// Verarbeitet eine Auswertung und liefert die Anzeige (Lesereihenfolge: oben nach unten, links nach rechts).
    @discardableResult
    public mutating func verarbeite(_ gesehen: [GesehenerWuerfel]) -> [AngezeigterWuerfel] {
        let k = seitenverhaeltnis
        let mess = gesehen.map { Messung(x: Double($0.rahmen.midX) * k, y: Double($0.rahmen.midY), b: Double($0.rahmen.width) * k, h: Double($0.rahmen.height), augen: $0.augen) }
        let alt = spuren.map { ($0.x, $0.y) }

        // 1. Vorhersage
        for i in spuren.indices { spuren[i].x += drift.x; spuren[i].y += drift.y }

        // 2. Kamerabewegung aus allen Würfeln gemeinsam
        let kamera = Self.kamerabewegung(spuren, mess)
        if let a = kamera {
            let m = a.massstab
            for i in spuren.indices {
                (spuren[i].x, spuren[i].y) = a.auf(spuren[i].x, spuren[i].y)
                spuren[i].b *= m; spuren[i].h *= m
            }
        }

        // 3. Zuordnung: nächste Spur ähnlicher Größe zuerst
        var paare: [(spur: Int, mess: Int, kosten: Double)] = []
        for (j, m) in mess.enumerated() {
            for (i, s) in spuren.enumerated() where Self.groessePasst(s.seite, m.seite) {
                let d = hypot(s.x - m.x, s.y - m.y) / max(s.seite, 1e-9)
                if d < reichweite { paare.append((i, j, d)) }
            }
        }
        paare.sort { $0.kosten < $1.kosten }
        var spurBelegt = Set<Int>(), messBelegt = Set<Int>()
        var wege: [Double] = [], dxs: [Double] = [], dys: [Double] = []
        for p in paare where !spurBelegt.contains(p.spur) && !messBelegt.contains(p.mess) {
            spurBelegt.insert(p.spur); messBelegt.insert(p.mess)
            let m = mess[p.mess]
            var s = spuren[p.spur]
            // Lage glätten: kleines Zittern der Erkennung dämpfen, echter Bewegung zügig folgen.
            let rest = hypot(m.x - s.x, m.y - s.y) / max(s.seite, 1e-9)
            let alpha = rest < 0.1 ? 0.5 : 0.85
            s.x += alpha * (m.x - s.x); s.y += alpha * (m.y - s.y)
            s.b += 0.4 * (m.b - s.b); s.h += 0.4 * (m.h - s.h)
            // Gesamter Weg dieser Auswertung (Zittern zählt nicht als Bewegung).
            let dx = s.x - alt[p.spur].0, dy = s.y - alt[p.spur].1
            let weg = hypot(dx, dy) / max(s.seite, 1e-9)
            s.treffer += 1; s.fehlt = 0
            wege.append(weg); dxs.append(weg < 0.08 ? 0 : dx); dys.append(weg < 0.08 ? 0 : dy)
            // Bewegte Bilder sind unscharf: ihre Stimme zählt weniger.
            stimme(&s, m.augen, gewicht: weg < 0.12 ? 1 : max(0.2, 0.12 / weg))
            spuren[p.spur] = s
        }
        bewegung = wege.isEmpty ? nil : wege.sorted()[wege.count / 2]
        if wege.isEmpty { drift.x *= 0.6; drift.y *= 0.6 } else {
            drift.x = 0.5 * drift.x + 0.5 * dxs.sorted()[dxs.count / 2]; drift.y = 0.5 * drift.y + 0.5 * dys.sorted()[dys.count / 2]
        }

        // 4. Nicht wiedergefundene Spuren sind mit der Kamerabewegung mitgewandert und warten.
        for i in spuren.indices where !spurBelegt.contains(i) { spuren[i].fehlt += 1 }
        spuren.removeAll { s in
            let bleibt = s.fest != nil || s.korrektur != nil
            if s.fehlt > (bleibt ? geduld : geduldNeu) { return true }
            // Weit aus dem Bild gewandert.
            return s.x < -0.2 * k || s.x > 1.2 * k || s.y < -0.2 || s.y > 1.2
        }

        // 5. Neue Würfel. Die Würfel eines Wurfs sind gleich groß: Sind schon zwei sicher erkannt, wird ein Fund mit ganz anderer
        //    Größe (Krümel, Maserung, Spiegelung) nicht als Würfel angelegt.
        let feste = spuren.filter { $0.fest != nil || $0.korrektur != nil }.map(\.seite).sorted()
        let ueblich = feste.count >= 2 ? feste[feste.count / 2] : nil
        for (j, m) in mess.enumerated() where !messBelegt.contains(j) {
            if let u = ueblich, m.seite < 0.6 * u || m.seite > 1.67 * u { continue }
            var s = Spur(id: naechsteId, x: m.x, y: m.y, b: m.b, h: m.h)
            naechsteId += 1
            stimme(&s, m.augen, gewicht: 1)
            spuren.append(s)
        }

        // 6. Doppelte Spuren auf demselben Würfel: die schwächere fällt weg.
        var weg = Set<Int>()
        for i in spuren.indices { for j in spuren.indices where j > i && !weg.contains(i) && !weg.contains(j) {
            let a = spuren[i], b = spuren[j]
            if hypot(a.x - b.x, a.y - b.y) < 0.45 * max(a.seite, b.seite) { weg.insert(a.rang >= b.rang ? j : i) }
        } }
        if !weg.isEmpty { spuren = spuren.enumerated().filter { !weg.contains($0.offset) }.map(\.element) }
        return anzeige
    }

    private func stimme(_ s: inout Spur, _ augen: Int, gewicht: Double) {
        guard (1...6).contains(augen) else { return }
        for i in s.stimmen.indices { s.stimmen[i] *= vergessen }
        s.stimmen[augen] += gewicht
        let bester = s.bester, summe = s.stimmen.reduce(0, +)
        if s.stimmen[bester] >= festAb, s.stimmen[bester] >= anteil * summe { s.fest = bester }
        // Würfel gedreht oder neu gefallen: mehrere klare Auswertungen in Folge mit demselben anderen Wert ersetzen den festen sofort.
        guard let f = s.fest, gewicht >= 0.5 else { return }
        if augen == f { s.folge = 0; return }
        if augen == s.kandidat { s.folge += 1 } else { s.kandidat = augen; s.folge = 1 }
        if s.folge >= wechsel {
            s.stimmen = [Double](repeating: 0, count: 7)
            s.stimmen[augen] = max(festAb, Double(wechsel))
            s.fest = augen; s.folge = 0
        }
    }

    private static func groessePasst(_ a: Double, _ b: Double) -> Bool {
        let v = a / max(b, 1e-9)
        return v > 0.55 && v < 1.8
    }

    /// Schätzt die gemeinsame Bewegung aller Würfel (Kamera verschoben, gedreht, näher oder weiter weg).
    /// Jede Paarung Spur–Erkennung schlägt eine Verschiebung vor; die Verschiebung, unter der die meisten Spuren eine Erkennung treffen,
    /// gewinnt. Aus diesen Paaren folgen dann Maßstab und Drehung. `nil`, wenn weniger als zwei Würfel dazu passen
    /// (ein einzelner Würfel wird über die normale Zuordnung verfolgt).
    static func kamerabewegung(_ spuren: [Spur], _ mess: [Messung]) -> Abbildung? {
        guard spuren.count >= 2, mess.count >= 2 else { return nil }
        func treffer(_ tx: Double, _ ty: Double) -> [(Int, Int)] {
            var paare: [(Int, Int)] = [], belegt = Set<Int>()
            for (i, s) in spuren.enumerated() {
                var nah: (Int, Double)?
                for (j, m) in mess.enumerated() where !belegt.contains(j) && groessePasst(s.seite, m.seite) {
                    let d = hypot(s.x + tx - m.x, s.y + ty - m.y)
                    if d < 0.3 * s.seite, nah == nil || d < nah!.1 { nah = (j, d) }
                }
                if let (j, _) = nah { paare.append((i, j)); belegt.insert(j) }
            }
            return paare
        }
        var beste: (paare: [(Int, Int)], weite: Double)?
        for s in spuren { for m in mess where groessePasst(s.seite, m.seite) {
            let tx = m.x - s.x, ty = m.y - s.y, weite = hypot(tx, ty)
            guard weite < 0.5 else { continue }   // höchstens ein halbes Bild je Auswertung
            let p = treffer(tx, ty)
            if beste == nil || p.count > beste!.paare.count || (p.count == beste!.paare.count && weite < beste!.weite) { beste = (p, weite) }
        } }
        guard let b = beste, b.paare.count >= 2 else { return nil }
        // Ähnlichkeitsabbildung nach kleinsten Quadraten (komplexe Schreibweise).
        let n = Double(b.paare.count)
        var px = 0.0, py = 0.0, mx = 0.0, my = 0.0, seite = 0.0
        for (i, j) in b.paare { px += spuren[i].x; py += spuren[i].y; mx += mess[j].x; my += mess[j].y; seite += spuren[i].seite }
        px /= n; py /= n; mx /= n; my /= n; seite /= n
        var sp = 0.0, re = 0.0, im = 0.0
        for (i, j) in b.paare {
            let ax = spuren[i].x - px, ay = spuren[i].y - py, bx = mess[j].x - mx, by = mess[j].y - my
            sp += ax * ax + ay * ay; re += ax * bx + ay * by; im += ax * by - ay * bx
        }
        var a = Abbildung()
        // Nur wenn die Würfel weit genug auseinander liegen, sind Maßstab und Drehung verlässlich.
        if sp > n * seite * seite {
            let ar = re / sp, ai = im / sp, betrag = (ar * ar + ai * ai).squareRoot()
            if betrag > 0.7, betrag < 1.4, abs(atan2(ai, ar)) < 0.4 { a.ar = ar; a.ai = ai }
        }
        a.tx = mx - (a.ar * px - a.ai * py); a.ty = my - (a.ai * px + a.ar * py)
        return a
    }

    // MARK: Eingriffe

    /// Setzt den Wert eines Würfels von Hand (gilt als sicher, solange der Würfel auf dem Tisch bleibt).
    public mutating func korrigiere(id: Int, auf wert: Int) {
        guard (1...6).contains(wert), let i = spuren.firstIndex(where: { $0.id == id }) else { return }
        spuren[i].korrektur = wert
    }

    /// Hält den aktuell angezeigten Wert eines Würfels fest (wie eine Korrektur auf denselben Wert).
    public mutating func festhalten(id: Int) {
        guard let i = spuren.firstIndex(where: { $0.id == id }) else { return }
        spuren[i].korrektur = spuren[i].fest ?? spuren[i].bester
    }

    /// Fügt einen Würfel hinzu, den der Nutzer angetippt hat (von Hand bestätigt, gilt als sicher). Liegt dort schon ein Würfel,
    /// bleibt er unverändert und seine Nummer wird geliefert.
    @discardableResult
    public mutating func fuegeHinzu(_ w: GesehenerWuerfel) -> Int {
        let k = seitenverhaeltnis
        var s = Spur(id: naechsteId, x: Double(w.rahmen.midX) * k, y: Double(w.rahmen.midY), b: Double(w.rahmen.width) * k, h: Double(w.rahmen.height))
        if let da = spuren.first(where: { hypot($0.x - s.x, $0.y - s.y) < 0.45 * max($0.seite, s.seite) }) { return da.id }
        naechsteId += 1
        s.korrektur = w.augen; s.fest = w.augen
        if (1...6).contains(w.augen) { s.stimmen[w.augen] = festAb }
        spuren.append(s)
        return s.id
    }

    /// Nimmt einen Fund heraus, der kein Würfel ist (im angehaltenen Bild; im laufenden Bild würde er neu gefunden).
    public mutating func entferne(id: Int) { spuren.removeAll { $0.id == id } }

    public mutating func zuruecksetzen() { spuren = []; bewegung = nil; drift = (0, 0) }

    /// Die Kamera hat den Zoom um `faktor` geändert (größer als 1: näher heran): Die Spuren wandern um die Bildmitte mit
    /// und behalten Nummer und Wert.
    public mutating func zoome(um faktor: Double) {
        guard faktor > 0, faktor.isFinite else { return }
        let cx = 0.5 * seitenverhaeltnis, cy = 0.5
        for i in spuren.indices {
            spuren[i].x = cx + (spuren[i].x - cx) * faktor; spuren[i].y = cy + (spuren[i].y - cy) * faktor
            spuren[i].b *= faktor; spuren[i].h *= faktor
        }
        drift = (0, 0)
    }

    public var anzeige: [AngezeigterWuerfel] {
        let k = seitenverhaeltnis
        // Feste Würfel bleiben auch während kurzer Aussetzer sichtbar; neue erst nach mehreren Funden.
        let alle = spuren.filter { $0.fest != nil || $0.korrektur != nil || ($0.fehlt == 0 && $0.treffer >= sichtbarAb) }.map { s in
            AngezeigterWuerfel(id: s.id, rahmen: CGRect(x: (s.x - s.b / 2) / k, y: s.y - s.h / 2, width: s.b / k, height: s.h),
                               augen: s.korrektur ?? s.fest ?? s.bester, sicher: s.korrektur != nil || s.fest != nil)
        }
        guard let h = alle.map({ $0.rahmen.height }).max(), h > 0 else { return [] }
        return alle.sorted {
            let za = Int(($0.rahmen.midY / h).rounded()), zb = Int(($1.rahmen.midY / h).rounded())
            return za != zb ? za < zb : $0.rahmen.minX < $1.rahmen.minX
        }
    }
}

extension Array where Element == AngezeigterWuerfel {
    /// Summe der Augen aller Würfel.
    public var summe: Int { reduce(0) { $0 + $1.augen } }
    /// Alle Würfel sicher (und mindestens einer da).
    public var allesSicher: Bool { !isEmpty && allSatisfy(\.sicher) }
}
