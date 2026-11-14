// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ArcadeKern

public struct Zelle: Hashable, Sendable, Codable { public var x: Int; public var y: Int
    public init(x: Int, y: Int) { self.x = x; self.y = y } }

/// Steinfall: Fünferteile (Pentominos) fallen in ein Feld von 10 × 18; lückenlose Reihen lösen sich auf.
/// Regeln: Teil bewegen/drehen, weich oder hart fallen lassen. Landet ein Teil, bleibt kurz Zeit zum Verschieben (Landezeit).
/// Das Spiel endet nur, wenn ein neues Teil nicht mehr ins Feld passt. Es gibt kein „Gewonnen“, nur Punkte und Rekord.
public struct Steinfall: Equatable, Sendable, Codable {
    public static let breite = 10
    public static let hoehe = 18
    public static let landezeit = 0.45
    public static let maxVerschiebungen = 12

    /// Grundformen als (x, y)-Zellen, y nach unten.
    public static let formen: [[Zelle]] = [
        [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)],        // Stab
        [(0, 0), (0, 1), (0, 2), (0, 3), (1, 3)],        // Haken
        [(0, 0), (1, 0), (2, 0), (1, 1), (1, 2)],        // T
        [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1)],        // Schale
        [(0, 0), (1, 0), (1, 1), (1, 2), (2, 2)],        // Zacken
        [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)],        // Block
    ].map { $0.map { Zelle(x: $0.0, y: $0.1) } }

    public private(set) var feld: [[Int]]                 // [Zeile][Spalte]; 0 = leer, sonst Formnummer + 1
    public private(set) var form = 0
    public private(set) var zellen: [Zelle] = []          // aktuelle Zellen relativ zum Ankerpunkt
    public private(set) var ankerX = 0
    public private(set) var ankerY = 0
    public private(set) var naechste = 0
    public private(set) var punkte = 0
    public private(set) var reihen = 0
    public private(set) var phase: ArcadePhase = .bereit
    public var weich = false                              // Finger zieht nach unten
    private var zeit = 0.0
    private var landeZeit = 0.0
    private var verschiebungen = 0
    private var zufall: ArcadeZufall
    public let schwierigkeit: Int                      // 1 leicht, 2 mittel, 3 schwer
    private var beutel = Beutel(sorten: Steinfall.formen.count)

    public var stufe: Int { reihen / 6 + 1 }
    public var fallZeit: Double { Schwierigkeit.wert(start: 0.8, grenze: 0.09, t: Double(stufe - 1) * ArcadeStufe.kurvenFaktor(schwierigkeit), halbwert: 5) / ArcadeStufe.tempoFaktor(schwierigkeit) }
    public var vorbei: Bool { phase.istVorbei }

    public init(schwierigkeit st: Int = 2, zufall z: ArcadeZufall = ArcadeZufall()) {
        schwierigkeit = ArcadeStufe.begrenzt(st)
        zufall = z
        feld = Array(repeating: Array(repeating: 0, count: Steinfall.breite), count: Steinfall.hoehe)
        naechste = beutel.ziehe(&zufall)
        neuesTeil()
    }

    public mutating func starte() { if phase == .bereit { phase = .laeuft } }

    // MARK: Regeln

    public func kollidiert(_ z: [Zelle], _ ax: Int, _ ay: Int) -> Bool {
        for c in z {
            let x = ax + c.x, y = ay + c.y
            if x < 0 || x >= Steinfall.breite || y >= Steinfall.hoehe { return true }
            if y >= 0, feld[y][x] != 0 { return true }
        }
        return false
    }

    public var aktuelleFelder: [Zelle] { zellen.map { Zelle(x: ankerX + $0.x, y: ankerY + $0.y) } }

    /// Wo das Teil landen würde (Schatten).
    public var schatten: [Zelle] {
        var y = ankerY
        while !kollidiert(zellen, ankerX, y + 1) { y += 1 }
        return zellen.map { Zelle(x: ankerX + $0.x, y: y + $0.y) }
    }

    private var aktiv: Bool { phase.laeuft }

    private mutating func verschoben() {
        // Landezeit neu starten, aber nicht endlos (sonst könnte man ein Teil ewig in der Schwebe halten)
        if landeZeit > 0, verschiebungen < Steinfall.maxVerschiebungen { landeZeit = 0; verschiebungen += 1 }
    }

    @discardableResult
    public mutating func bewege(_ dx: Int) -> Bool {
        guard aktiv, !kollidiert(zellen, ankerX + dx, ankerY) else { return false }
        ankerX += dx; verschoben(); return true
    }

    @discardableResult
    public mutating func drehe() -> Bool {
        guard aktiv else { return false }
        var neu = zellen.map { Zelle(x: -$0.y, y: $0.x) }
        let mx = neu.map(\.x).min()!, my = neu.map(\.y).min()!
        neu = neu.map { Zelle(x: $0.x - mx, y: $0.y - my) }
        // Wandkorrektur: seitlich und notfalls ein Stück nach oben ausweichen
        for dy in [0, -1] { for kick in [0, -1, 1, -2, 2] where !kollidiert(neu, ankerX + kick, ankerY + dy) {
            zellen = neu; ankerX += kick; ankerY += dy; verschoben(); return true
        } }
        return false
    }

    /// Ein Feld nach unten. `true`, wenn das Teil dabei ein Feld gefallen ist.
    @discardableResult
    private mutating func faelltEinFeld() -> Bool {
        guard !kollidiert(zellen, ankerX, ankerY + 1) else { return false }
        ankerY += 1; return true
    }

    public mutating func hartFallen() {
        guard aktiv else { return }
        var n = 0
        while faelltEinFeld() { n += 1 }
        punkte += 2 * n
        festsetzen()
    }

    /// Ein Zeitschritt (fest 1/120 s).
    public mutating func schritt(_ dt: Double) {
        guard aktiv else { return }
        if kollidiert(zellen, ankerX, ankerY + 1) {
            landeZeit += dt
            if landeZeit >= Steinfall.landezeit || (weich && landeZeit >= 0.12) { festsetzen() }
            return
        }
        landeZeit = 0
        zeit += dt
        let intervall = weich ? min(fallZeit, 0.045) : fallZeit
        while zeit >= intervall && aktiv {
            zeit -= intervall
            if faelltEinFeld() { if weich { punkte += 1 } } else { break }
        }
    }

    private mutating func festsetzen() {
        for c in aktuelleFelder where c.y >= 0 { feld[c.y][c.x] = form + 1 }
        let voll = feld.indices.filter { !feld[$0].contains(0) }
        if !voll.isEmpty {
            for y in voll.reversed() { feld.remove(at: y) }
            for _ in voll { feld.insert(Array(repeating: 0, count: Steinfall.breite), at: 0) }
            reihen += voll.count
            punkte += [0, 100, 300, 600, 1000, 1500][min(voll.count, 5)] * stufe
        }
        neuesTeil()
    }

    private mutating func neuesTeil() {
        form = naechste
        naechste = beutel.ziehe(&zufall)
        zellen = Steinfall.formen[form]
        let b = zellen.map(\.x).max()! + 1
        ankerX = (Steinfall.breite - b) / 2; ankerY = 0
        zeit = 0; landeZeit = 0; verschiebungen = 0
        if kollidiert(zellen, ankerX, ankerY) { phase = .vorbei(grund: "Die Steine stoßen oben an") }
    }

    /// Für Tests: aufgelöste Reihen setzen (bestimmt die Stufe).
    public mutating func setzeReihen(_ n: Int) { reihen = n }

    /// Für Tests: Feld direkt setzen.
    public mutating func setzeFeld(_ f: [[Int]]) { feld = f }
}
