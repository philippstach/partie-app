// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ArcadeKern

/// Eine Wolke. Weltkoordinaten: x von 0 bis 1 (links nach rechts), y wächst nach OBEN.
public struct Wolke: Equatable, Sendable, Identifiable, Codable {
    public enum Art: Sendable, Codable { case fest, wandernd, bruechig, feder }
    public let id: Int
    public var art: Art
    public var basisX: Double       // Mitte (bei wandernden: Mittelpunkt der Bewegung)
    public var y: Double
    public var breite: Double
    public var ausschlag = 0.0      // wandernd: halbe Strecke
    public var tempo = 0.0
    public var phase = 0.0
    public var zerfall: Double?     // brüchig: Restzeit, nachdem jemand gelandet ist
    public var weg = false
}

/// Wolkenhüpfer: Der Hüpfer springt von allein; man lenkt ihn nur seitlich (am Rand kommt er auf der anderen Seite wieder heraus).
/// Er landet nur beim Fallen auf Wolken. Fällt er unten aus dem Bild, ist das Spiel aus. Punkte = erreichte Höhe.
/// Garantie: Jede Lücke zwischen zwei Wolkenreihen ist kleiner als die Sprunghöhe, und jede Reihe enthält eine feste oder wandernde Wolke.
public struct Wolkenhuepfer: Equatable, Sendable, Codable {
    public static let sichtHoehe = 1.6
    public static let schwerkraft = 2.4
    public static let sprungHoehe = 0.36
    public static let federHoehe = 0.78
    public static let halbBreite = 0.035
    public static let maxLuecke = 0.30                       // < 0,85 × Sprunghöhe
    public static let wolkenDicke = 0.03

    public private(set) var x = 0.5
    public private(set) var y = 0.12
    public private(set) var vy = 0.0
    public private(set) var kamera = 0.0
    public private(set) var hoechste = 0.0
    public private(set) var wolken: [Wolke] = []
    public private(set) var phase: ArcadePhase = .bereit
    public private(set) var zeit = 0.0
    public private(set) var spruenge = 0
    private var obenY = 0.0
    private var naechsteID = 0
    private var zufall: ArcadeZufall
    public let schwierigkeit: Int                      // 1 leicht, 2 mittel, 3 schwer

    public var punkte: Int { Int(hoechste * 50) }
    public var vorbei: Bool { phase.istVorbei }
    /// Anteil der Schwierigkeit 0…1 (nach Höhe).
    public var schwere: Double { Schwierigkeit.anteil(hoechste * ArcadeStufe.kurvenFaktor(schwierigkeit), halbwert: 25) }
    public static var sprungGeschwindigkeit: Double { sqrt(2 * schwerkraft * sprungHoehe) }
    public static var federGeschwindigkeit: Double { sqrt(2 * schwerkraft * federHoehe) }

    public init(schwierigkeit st: Int = 2, zufall z: ArcadeZufall = ArcadeZufall()) {
        schwierigkeit = ArcadeStufe.begrenzt(st)
        zufall = z
        wolken.append(Wolke(id: 0, art: .fest, basisX: 0.5, y: 0.05, breite: 0.34)); naechsteID = 1
        obenY = 0.05
        erzeuge()
    }

    public mutating func starte() {
        guard phase == .bereit else { return }
        phase = .laeuft; vy = Wolkenhuepfer.sprungGeschwindigkeit
    }

    public func wolkenX(_ w: Wolke) -> Double { w.art == .wandernd ? w.basisX + w.ausschlag * sin(zeit * w.tempo + w.phase) : w.basisX }

    /// Seitlich verschieben (Finger). Am Rand taucht der Hüpfer auf der anderen Seite auf.
    public mutating func lenke(um dx: Double) {
        guard phase.laeuft else { return }
        x += dx
        if x < 0 || x > 1 { x -= x.rounded(.down) }          // auch bei sehr großen Sprüngen (schneller Wisch) im Feld
    }

    private mutating func erzeuge() {
        while obenY < kamera + Wolkenhuepfer.sichtHoehe + 0.8 {
            let s = schwere
            let luecke = begrenze(Schwierigkeit.wert(start: 0.12, grenze: Wolkenhuepfer.maxLuecke - 0.02, t: s, halbwert: 1) + zufall.zahl(-0.03...0.03), 0.1, Wolkenhuepfer.maxLuecke)
            obenY += luecke
            let breite = Schwierigkeit.wert(start: 0.26, grenze: 0.15, t: s, halbwert: 1)
            // Sichere Wolke der Reihe: fest oder wandernd
            let wandert = zufall.wahr(0.15 + 0.4 * s)
            var sicher = Wolke(id: naechsteID, art: wandert ? .wandernd : .fest, basisX: zufall.zahl(breite / 2 + 0.02...1 - breite / 2 - 0.02), y: obenY, breite: breite)
            naechsteID += 1
            if wandert { sicher.ausschlag = zufall.zahl(0.12...0.25); sicher.tempo = zufall.zahl(0.8...1.6) * (1 + s * 0.6); sicher.phase = zufall.zahl(0...6.28)
                sicher.basisX = begrenze(sicher.basisX, sicher.ausschlag + breite / 2, 1 - sicher.ausschlag - breite / 2) }
            wolken.append(sicher)
            // Zusätzliche Wolken: brüchig (Falle für Gierige, nie nötig) oder Feder
            if zufall.wahr(0.25 + 0.3 * s) {
                var art = Wolke.Art.bruechig
                if zufall.wahr(0.3 - 0.15 * s) { art = .feder }
                let bx = zufall.zahl(breite / 2 + 0.02...1 - breite / 2 - 0.02)
                wolken.append(Wolke(id: naechsteID, art: art, basisX: bx, y: obenY + zufall.zahl(-0.05...0.05), breite: breite)); naechsteID += 1
            }
        }
    }

    public mutating func schritt(_ dt: Double) {
        guard phase.laeuft else { return }
        zeit += dt
        let vorher = y
        vy -= Wolkenhuepfer.schwerkraft * dt
        y += vy * dt
        // Landen: nur beim Fallen, Füße kreuzen die Wolkenoberseite
        if vy < 0 {
            for i in wolken.indices where !wolken[i].weg {
                let w = wolken[i]
                let oben = w.y + Wolkenhuepfer.wolkenDicke
                guard vorher >= oben - 1e-9, y <= oben else { continue }
                let wx = wolkenX(w)
                if abs(x - wx) <= w.breite / 2 + Wolkenhuepfer.halbBreite * 0.6 || abs(abs(x - wx) - 1) <= w.breite / 2 + Wolkenhuepfer.halbBreite * 0.6 {
                    y = oben
                    vy = w.art == .feder ? Wolkenhuepfer.federGeschwindigkeit : Wolkenhuepfer.sprungGeschwindigkeit
                    spruenge += 1
                    if w.art == .bruechig { wolken[i].zerfall = 0.0; wolken[i].weg = true }   // bricht beim Betreten (ein Sprung noch)
                    break
                }
            }
        }
        hoechste = max(hoechste, y)
        kamera = max(kamera, y - 0.9)
        wolken.removeAll { $0.y < kamera - 0.3 }
        erzeuge()
        if y < kamera - 0.05 { phase = .vorbei(grund: "Du bist unten aus dem Bild gefallen") }
    }

    /// Nur für Tests: Hüpfer auf eine Höhe setzen (ohne Landung).
    public mutating func testSetzeHoehe(_ h: Double) { hoechste = max(hoechste, h); y = max(y, h) }
}
