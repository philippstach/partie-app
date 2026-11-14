// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ArcadeKern

public struct Stein: Equatable, Sendable, Codable {
    public var spalte: Int
    public var zeile: Int
    public var leben: Int          // Treffer bis zum Bruch
    public var start: Int          // Anfangsleben (für die Farbe)
}

public struct Ball: Equatable, Sendable, Codable {
    public var x: Double, y: Double, vx: Double, vy: Double
}

public struct Gabe: Equatable, Sendable, Codable {
    public enum Art: Sendable, Codable { case breit, dreifach, leben }
    public var art: Art
    public var x: Double, y: Double
}

/// Mauerbrecher: Ein Ball prallt am Schläger ab und bricht eine Mauer, die langsam nach unten rückt.
/// Eigene Regeln: Serie (aufeinanderfolgende Treffer ohne Schläger erhöhen den Faktor bis ×4), Gaben fallen aus Steinen
/// (breiter Schläger, drei Bälle, Extraleben), die Mauer rückt nach unten. Drei Leben. Kein „Gewonnen“: Level um Level, bis es aus ist.
/// Spielfeld: 1 breit × `hoehe` hoch, y nach unten.
public struct Mauerbrecher: Equatable, Sendable, Codable {
    public static let hoehe = 1.5
    public static let spalten = 8
    public static let steinB = 1.0 / 8
    public static let steinH = 0.05
    public static let oben = 0.14
    public static let schlaegerY = 1.38
    public static let schlaegerH = 0.028
    public static let radius = 0.017
    public static let schlaegerSpeed = 2.4
    public static let startLeben = 3
    public static let abschussWarten = 3.0

    public private(set) var steine: [Stein] = []
    public private(set) var baelle: [Ball] = []
    public private(set) var gaben: [Gabe] = []
    public private(set) var schlaegerX = 0.5
    public private(set) var zielX = 0.5
    public private(set) var breitRest = 0.0
    public private(set) var verschiebung = 0.0        // wie weit die Mauer schon abgesunken ist
    public private(set) var leben = Mauerbrecher.startLeben
    public private(set) var stufe = 1
    public private(set) var punkte = 0
    public private(set) var serie = 0
    public private(set) var verloreneLeben = 0           // zählt jedes verlorene Leben (Rückmeldung)
    public private(set) var phase: ArcadePhase = .bereit
    public private(set) var haftet = true              // Ball liegt noch auf dem Schläger
    private var haftZeit = 0.0
    private var zufall: ArcadeZufall
    public let schwierigkeit: Int                      // 1 leicht, 2 mittel, 3 schwer
    private var treffer = 0                            // Steintreffer in diesem Level (Ballbeschleunigung)

    public var schlaegerBreite: Double { breitRest > 0 ? 0.30 : 0.19 }
    public var faktor: Int { min(4, 1 + serie / 4) }
    public var vorbei: Bool { phase.istVorbei }
    public var ballTempo: Double { ArcadeStufe.tempoFaktor(schwierigkeit) * Schwierigkeit.wert(start: 0.8, grenze: 1.5, t: Double(stufe - 1) + Double(treffer) / 40, halbwert: 4) }
    public var senkung: Double { 0.0035 + 0.0008 * Double(min(stufe, 8)) }

    public init(schwierigkeit st: Int = 2, zufall z: ArcadeZufall = ArcadeZufall()) {
        schwierigkeit = ArcadeStufe.begrenzt(st)
        zufall = z
        baueMauer()
        legeBallAuf()
    }

    public func steinKasten(_ s: Stein) -> Kasten {
        Kasten(x: Double(s.spalte) * Mauerbrecher.steinB, y: Mauerbrecher.oben + Double(s.zeile) * Mauerbrecher.steinH + verschiebung,
               b: Mauerbrecher.steinB, h: Mauerbrecher.steinH)
    }
    public var schlaeger: Kasten {
        Kasten(x: schlaegerX - schlaegerBreite / 2, y: Mauerbrecher.schlaegerY, b: schlaegerBreite, h: Mauerbrecher.schlaegerH)
    }

    // MARK: Aufbau

    private mutating func baueMauer() {
        steine = []; verschiebung = 0; treffer = 0
        let zeilen = min(4 + stufe / 2, 8)
        let muster = (stufe - 1) % 4
        for z in 0..<zeilen { for s in 0..<Mauerbrecher.spalten {
            switch muster {
            case 1 where (s + z) % 2 == 1: continue                                  // Schachbrett
            case 2 where s < z / 2 || s >= Mauerbrecher.spalten - z / 2: continue    // Trichter
            case 3 where s % 3 == 2 && z > 0: continue                               // Säulen mit Lücken
            default: break
            }
            let schwer = Double(stufe - 1) * 0.12 + Double(zeilen - z) * 0.03
            let l = zufall.wahr(min(0.5, schwer)) ? (zufall.wahr(0.3) ? 3 : 2) : 1
            steine.append(Stein(spalte: s, zeile: z, leben: l, start: l))
        } }
    }

    private mutating func legeBallAuf() {
        haftet = true; haftZeit = 0
        baelle = [Ball(x: schlaegerX, y: Mauerbrecher.schlaegerY - Mauerbrecher.radius - 0.002, vx: 0, vy: 0)]
    }

    // MARK: Eingabe

    public mutating func starte() { if phase == .bereit { phase = .laeuft } }
    public mutating func zielen(_ x: Double) { zielX = begrenze(x, 0, 1) }

    /// Ball vom Schläger abschießen (leicht schräg, je nach Lage des Schlägers).
    public mutating func abschuss() {
        guard phase.laeuft, haftet, !baelle.isEmpty else { return }
        haftet = false
        let w = zufall.zahl(-0.35...0.35)
        let v = ballTempo
        baelle[0].vx = v * sin(w); baelle[0].vy = -v * cos(w)
    }

    // MARK: Schritt

    public mutating func schritt(_ dt: Double) {
        guard phase.laeuft else { return }
        // Schläger folgt dem Finger mit Höchstgeschwindigkeit (kein „Teleportieren“)
        let d = zielX - schlaegerX, m = Mauerbrecher.schlaegerSpeed * dt
        schlaegerX = begrenze(schlaegerX + max(-m, min(m, d)), schlaegerBreite / 2, 1 - schlaegerBreite / 2)
        if breitRest > 0 { breitRest = max(0, breitRest - dt) }
        verschiebung += senkung * dt * (haftet ? 0.3 : 1)
        if haftet {
            haftZeit += dt
            baelle[0].x = schlaegerX
            if haftZeit >= Mauerbrecher.abschussWarten { abschuss() }
        } else {
            for i in baelle.indices { bewege(i, dt) }
        }
        baelle.removeAll { $0.y > Mauerbrecher.hoehe + 0.05 }
        // Gaben
        for i in gaben.indices { gaben[i].y += 0.35 * dt }
        let sk = schlaeger
        for g in gaben where Kasten(x: g.x - 0.025, y: g.y - 0.02, b: 0.05, h: 0.04).schneidet(sk) { nimm(g) }
        gaben.removeAll { Kasten(x: $0.x - 0.025, y: $0.y - 0.02, b: 0.05, h: 0.04).schneidet(sk) || $0.y > Mauerbrecher.hoehe }
        // Verloren / Level geschafft / Mauer zu tief
        if baelle.isEmpty && !haftet {
            leben -= 1; serie = 0; verloreneLeben += 1
            if leben <= 0 { phase = .vorbei(grund: "Alle Bälle verloren"); return }
            legeBallAuf()
        }
        if steine.isEmpty {
            punkte += 200 * stufe; stufe += 1; baueMauer(); gaben = []; legeBallAuf(); serie = 0
        }
        if let tief = steine.map({ steinKasten($0).unten }).max(), tief >= Mauerbrecher.schlaegerY - 0.02 {
            phase = .vorbei(grund: "Die Mauer hat dich erreicht")
        }
    }

    private mutating func nimm(_ g: Gabe) {
        switch g.art {
        case .breit: breitRest = 14
        case .leben: leben = min(5, leben + 1)
        case .dreifach:
            guard !haftet, let b = baelle.first else { return }
            for w in [-0.5, 0.5] {
                let v = (b.vx * b.vx + b.vy * b.vy).squareRoot()
                let a = atan2(b.vx, -b.vy) + w
                baelle.append(Ball(x: b.x, y: b.y, vx: v * sin(a), vy: -abs(v * cos(a)) - 0.2))
            }
        }
        punkte += 25
    }

    private mutating func bewege(_ i: Int, _ dt: Double) {
        var b = baelle[i]
        b.x += b.vx * dt; b.y += b.vy * dt
        let r = Mauerbrecher.radius
        if b.x < r { b.x = r; b.vx = abs(b.vx) }
        if b.x > 1 - r { b.x = 1 - r; b.vx = -abs(b.vx) }
        if b.y < r { b.y = r; b.vy = abs(b.vy) }
        // Schläger: Abprallwinkel nach Trefferstelle
        let sk = schlaeger
        if b.vy > 0, b.y + r >= sk.y, b.y - r <= sk.unten, b.x >= sk.x - r * 0.5, b.x <= sk.rechts + r * 0.5 {
            let off = begrenze((b.x - schlaegerX) / (schlaegerBreite / 2), -1, 1)
            var a = off * 1.05                                  // bis ≈ 60° von der Senkrechten
            if abs(a) < 0.18 { a = (zufall.wahr(0.5) ? 1 : -1) * zufall.zahl(0.18...0.35) }   // nie ewig senkrecht hin und her
            let v = ballTempo
            b.vx = v * sin(a); b.vy = -v * cos(a); b.y = sk.y - r
            serie = 0
        }
        // Steine: tiefsten Eindringling zuerst
        var best: (index: Int, seite: Seite, tiefe: Double)?
        for (k, s) in steine.enumerated() {
            if let h = Treffer.kreis(x: b.x, y: b.y, r: r, kasten: steinKasten(s)), h.tiefe > (best?.tiefe ?? 0) { best = (k, h.seite, h.tiefe) }
        }
        if let h = best {
            switch h.seite {
            case .links: b.vx = -abs(b.vx); b.x -= h.tiefe
            case .rechts: b.vx = abs(b.vx); b.x += h.tiefe
            case .oben: b.vy = -abs(b.vy); b.y -= h.tiefe
            case .unten: b.vy = abs(b.vy); b.y += h.tiefe
            }
            treffe(h.index, bei: (b.x, b.y))
        }
        // Tempo auf den Sollwert, nie zu flach (sonst hüpft der Ball ewig waagerecht)
        let v = ballTempo * (b.vx == 0 && b.vy == 0 ? 0 : 1)
        if v > 0 {
            var a = atan2(b.vx, -b.vy)                           // Winkel zur Senkrechten (nach oben = 0)
            let flach = 0.30                                      // mindestens 0,30 rad (≈ 17°) über der Waagerechten
            let maxA = Double.pi / 2 - flach
            if abs(a) <= Double.pi / 2 {                          // fliegt nach oben
                a = begrenze(a, -maxA, maxA)
            } else {                                              // fliegt nach unten
                let s = a > 0 ? Double.pi - a : -Double.pi - a    // Spiegeln: Winkel zur Senkrechten nach unten
                let c = begrenze(s, -maxA, maxA)
                a = a > 0 ? Double.pi - c : -Double.pi - c
            }
            b.vx = v * sin(a); b.vy = -v * cos(a)
        }
        baelle[i] = b
    }

    private mutating func treffe(_ index: Int, bei p: (Double, Double)) {
        treffer += 1
        serie += 1
        steine[index].leben -= 1
        if steine[index].leben <= 0 {
            let s = steine[index]
            punkte += 10 * s.start * faktor * stufe.clamped(1, 5)
            steine.remove(at: index)
            if zufall.wahr(0.16) {
                let art: Gabe.Art = zufall.wahr(0.12) ? .leben : (zufall.wahr(0.5) ? .breit : .dreifach)
                gaben.append(Gabe(art: art, x: p.0, y: p.1))
            }
        } else {
            punkte += 5 * faktor
        }
    }

    /// Nur für Tests.
    public mutating func testSteineLeeren() { steine = []; }
}

private extension Int {
    func clamped(_ lo: Int, _ hi: Int) -> Int { Swift.min(Swift.max(self, lo), hi) }
}
