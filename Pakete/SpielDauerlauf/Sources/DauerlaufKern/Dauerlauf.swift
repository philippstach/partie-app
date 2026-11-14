// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ArcadeKern

public struct Hindernis: Equatable, Sendable, Codable {
    public enum Art: Sendable, Codable { case huerde, spalt, balken }
    public var art: Art
    public var x: Double          // linke Kante in Weltkoordinaten
    public var breite: Double
    public var rechts: Double { x + breite }
}

public struct Perle: Equatable, Sendable, Codable {
    public var x: Double
    public var y: Double          // Höhe über dem Boden
    public var weg = false
}

/// Dauerlauf: Ein Läufer rennt von allein, immer schneller. Tippen = springen (Hürden, Löcher), nach unten wischen = ducken (Balken).
/// Seitenansicht: Sichtfeld 1 breit × `sichtHoehe` hoch, Läufer fest bei `laeuferX`. Alle Maße in Bildbreiten, Zeit in Sekunden.
/// Fairness: Zwischen zwei Hindernissen liegt immer mindestens Flugzeit + Reaktionszeit bei dem Tempo, das dort gelaufen wird.
public struct Dauerlauf: Equatable, Sendable, Codable {
    public static let sichtHoehe = 0.62
    public static let laeuferX = 0.2
    public static let schwerkraft = 4.2
    public static let sprung = 1.5
    public static let flugZeit = 2 * sprung / schwerkraft          // ≈ 0,71 s
    public static let laeuferHoehe = 0.10
    public static let geduckt = 0.05
    public static let halbBreite = 0.02
    public static let fuss = 0.012
    public static let huerdeHoehe = 0.09
    public static let balkenUnten = 0.07
    public static let balkenOben = 0.16
    public static let duckDauer = 0.5
    public static let puffer = 0.12                                // Sprung kurz vor der Landung wird gemerkt
    public static let hufZeit = 0.08                               // Sprung kurz nach dem Verlassen des Bodens geht noch

    public private(set) var zeit = 0.0
    public private(set) var distanz = 0.0
    public private(set) var y = 0.0
    public private(set) var vy = 0.0
    public private(set) var duckRest = 0.0
    public private(set) var hindernisse: [Hindernis] = []
    public private(set) var perlen: [Perle] = []
    public private(set) var gesammelt = 0
    public private(set) var phase: ArcadePhase = .bereit
    private var sprungPuffer = 0.0
    private var duckPuffer = 0.0
    private var luftZeit = 0.0
    private var naechsteX = 0.9
    private var zufall: ArcadeZufall
    public let schwierigkeit: Int                             // 1 leicht, 2 mittel, 3 schwer

    public var vorbei: Bool { phase.istVorbei }
    public var meter: Int { Int(distanz * 20) }
    public var punkte: Int { meter + gesammelt * 10 }
    public var tempo: Double { tempo(zeit) }
    public func tempo(_ t: Double) -> Double { ArcadeStufe.tempoFaktor(schwierigkeit) * Schwierigkeit.wert(start: 0.45, grenze: 1.05, t: t, halbwert: 45) }
    public var geduckt: Bool { duckRest > 0 && y == 0 }
    public var hoehe: Double { geduckt ? Dauerlauf.geduckt : Dauerlauf.laeuferHoehe }
    public var weltX: Double { distanz + Dauerlauf.laeuferX }
    public var aufDemBoden: Bool { y == 0 }

    public init(schwierigkeit st: Int = 2, zufall z: ArcadeZufall = ArcadeZufall()) {
        schwierigkeit = ArcadeStufe.begrenzt(st)
        zufall = z
        erzeuge(bis: 3)
    }

    public mutating func starte() { if phase == .bereit { phase = .laeuft } }

    public mutating func springe() {
        guard phase.laeuft else { return }
        sprungPuffer = Dauerlauf.puffer
    }

    /// Duckt den Läufer; in der Luft fällt er schneller und ist nach der Landung gleich geduckt.
    public mutating func ducke() {
        guard phase.laeuft else { return }
        if y == 0 { duckRest = Dauerlauf.duckDauer }
        else { vy = min(vy, 0) - 1.2; duckPuffer = 0.3 }
    }

    // MARK: Boden

    private func traegt(_ x: Double) -> Bool {
        let l = x - Dauerlauf.fuss, r = x + Dauerlauf.fuss
        return !hindernisse.contains { $0.art == .spalt && $0.x <= l && $0.rechts >= r }
    }

    // MARK: Hindernisse

    private mutating func erzeuge(bis grenze: Double) {
        while naechsteX < grenze {
            let w = zufall.zahl(0...1)
            let art: Hindernis.Art = w < 0.4 ? .huerde : (w < 0.7 ? .spalt : .balken)
            let breite: Double
            switch art {
            case .huerde: breite = zufall.zahl(0.05...0.08)
            case .spalt: breite = zufall.zahl(0.12...0.19)
            case .balken: breite = zufall.zahl(0.09...0.15)
            }
            let h = Hindernis(art: art, x: naechsteX, breite: breite)
            hindernisse.append(h)
            switch art {
            case .huerde, .spalt:
                for i in 0..<3 {     // Perlenbogen über Hürde oder Spalt
                    let t = Double(i) / 2
                    perlen.append(Perle(x: h.x + h.breite * t, y: 0.14 + 0.08 * (1 - abs(2 * t - 1))))
                }
            case .balken:
                perlen.append(Perle(x: h.x + h.breite / 2, y: 0.03))
            }
            // Abstand in Zeit: Flug + Reaktion; später auch dichter, aber nie unter Flug + etwas Luft
            let s = Schwierigkeit.anteil(max(naechsteX, 0), halbwert: 40)
            let reaktion = Schwierigkeit.wert(start: 0.85, grenze: 0.30, t: s, halbwert: 1) + zufall.zahl(0...0.5) * (1 - 0.6 * s)
            let v = tempo(zeit + 3)
            naechsteX = h.rechts + v * (Dauerlauf.flugZeit + reaktion)
        }
    }

    // MARK: Schritt

    public mutating func schritt(_ dt: Double) {
        guard phase.laeuft else { return }
        zeit += dt
        distanz += tempo * dt
        if duckRest > 0 { duckRest = max(0, duckRest - dt) }
        sprungPuffer = max(0, sprungPuffer - dt)
        duckPuffer = max(0, duckPuffer - dt)

        let stuetze = traegt(weltX)
        let amBoden = y == 0 && stuetze
        if y == 0 && !stuetze { luftZeit += dt } else if y > 0 { luftZeit += dt } else { luftZeit = 0 }

        // Absprung (Puffer + Hufzeit)
        if sprungPuffer > 0, amBoden || (luftZeit < Dauerlauf.hufZeit && vy <= 0 && y > -0.01 && !amBoden && y <= 0.0001 && stuetze) || (luftZeit > 0 && luftZeit < Dauerlauf.hufZeit && y == 0) {
            vy = Dauerlauf.sprung; y = max(y, 0.0001); sprungPuffer = 0; duckRest = 0; luftZeit = Dauerlauf.hufZeit
        }

        if y > 0 || vy != 0 || !stuetze {
            vy -= Dauerlauf.schwerkraft * dt
            y += vy * dt
            if vy <= 0, y <= 0, traegt(weltX) || y > -0.04 && traegt(weltX) {
                y = 0; vy = 0; luftZeit = 0
                if duckPuffer > 0 { duckRest = Dauerlauf.duckDauer; duckPuffer = 0 }
            }
        }
        if y < -0.12 { phase = .vorbei(grund: "Ins Loch gefallen"); return }

        // Zusammenstöße
        let x0 = weltX - Dauerlauf.halbBreite, x1 = weltX + Dauerlauf.halbBreite
        let oben = y + hoehe
        for h in hindernisse where h.rechts > x0 && h.x < x1 {
            switch h.art {
            case .huerde where y < Dauerlauf.huerdeHoehe - 0.012:
                phase = .vorbei(grund: "Gegen eine Hürde gelaufen"); return
            case .balken where y < Dauerlauf.balkenOben && oben > Dauerlauf.balkenUnten + 0.01:
                phase = .vorbei(grund: "Gegen einen Balken gelaufen"); return
            default: break
            }
        }
        for i in perlen.indices where !perlen[i].weg && abs(perlen[i].x - weltX) < 0.045 && perlen[i].y >= y - 0.03 && perlen[i].y <= oben + 0.04 {
            perlen[i].weg = true; gesammelt += 1
        }
        erzeuge(bis: distanz + 2.5)
        hindernisse.removeAll { $0.rechts < distanz - 0.2 }
        perlen.removeAll { $0.x < distanz - 0.2 }
    }

    /// Nur für Tests: freie Bahn.
    public mutating func testLeeren() { hindernisse = []; perlen = []; naechsteX = 1e9 }
}
