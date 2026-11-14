// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ArcadeKern

/// Ballwechsel: Schläger-Duell auf einem hochkant stehenden Feld. Spieler 0 unten, Spieler 1 oben (Mensch oder Computer).
/// Regeln: Der Ball wird mit jedem Schlag etwas schneller (Rückstellung nach jedem Punkt). Wer den Ball verpasst, gibt den Punkt ab.
/// Der Verlierer des Punktes bekommt den nächsten Ball. Wer zuerst `ziel` Punkte hat, gewinnt. Die Kante des Schlägers lenkt steiler ab.
/// Der Computer lässt sich Zeit zum Reagieren und irrt sich; er wird schwächer, wenn er zurückliegt, und stärker, wenn er führt.
public struct Ballwechsel: Equatable, Sendable, Codable {
    public static let hoehe = 1.6
    public static let schlaegerB = 0.21
    public static let schlaegerH = 0.026
    public static let randAbstand = 0.07            // Abstand der Schläger zum Feldrand
    public static let radius = 0.019
    public static let startTempo = 0.85
    public static let maxTempo = 2.5
    public static let pause = 1.1                   // Wartezeit vor jedem Aufschlag

    public private(set) var punkte = [0, 0]
    public private(set) var ballX = 0.5
    public private(set) var ballY = Ballwechsel.hoehe / 2
    public private(set) var vx = 0.0
    public private(set) var vy = 0.0
    public private(set) var schlaegerX = [0.5, 0.5]
    public private(set) var phase: ArcadePhase = .bereit
    public private(set) var rallye = 0
    public private(set) var laengsteRallye = 0
    public private(set) var imSpiel = false         // Ball fliegt (sonst Pause vor dem Aufschlag)
    public let ziel: Int
    public let computer: Bool
    public let stufe: Int                           // 1 leicht, 2 mittel, 3 schwer
    private var ziele = [0.5, 0.5]
    private var wartet = Ballwechsel.pause
    private var empfaenger = 1
    private var denkRest = 0.0
    private var fehler = 0.0
    private var zufall: ArcadeZufall

    public var gewinner: Int? { punkte[0] >= ziel ? 0 : (punkte[1] >= ziel ? 1 : nil) }
    public var vorbei: Bool { phase.istVorbei }
    public var tempo: Double { min(Ballwechsel.maxTempo, Ballwechsel.startTempo * pow(1.055, Double(rallye))) }
    public var aufschlagIn: Double { max(0, wartet) }

    public init(ziel: Int = 7, computer: Bool = true, stufe: Int = 2, zufall z: ArcadeZufall = ArcadeZufall()) {
        self.ziel = ziel; self.computer = computer; self.stufe = min(3, max(1, stufe)); zufall = z
        empfaenger = z0Empfaenger()
    }
    private mutating func z0Empfaenger() -> Int { zufall.wahr(0.5) ? 1 : 0 }

    public func schlaegerY(_ s: Int) -> Double { s == 0 ? Ballwechsel.hoehe - Ballwechsel.randAbstand - Ballwechsel.schlaegerH : Ballwechsel.randAbstand }

    public mutating func starte() { if phase == .bereit { phase = .laeuft } }
    /// Zielposition (Mitte) eines Menschen. Wirkt für Spieler 0 immer, für Spieler 1 nur im Zweispielermodus.
    public mutating func steuere(_ spieler: Int, x: Double) {
        guard spieler == 0 || !computer else { return }
        ziele[spieler] = begrenze(x, 0, 1)
    }

    private var menschSpeed: Double { 3.0 }
    /// Wie gut der Computer gerade spielt, 0 (schwach) … 1 (stark), mit Ausgleich nach Spielstand.
    public var computerStaerke: Double {
        let basis = [0.0, 0.25, 0.55, 0.85][stufe]
        // Führt der Computer, wird er etwas schwächer; liegt er zurück, etwas stärker.
        return begrenze(basis - 0.08 * Double(punkte[1] - punkte[0]), 0.05, 1)
    }

    // MARK: Schritt

    public mutating func schritt(_ dt: Double) {
        guard phase.laeuft else { return }
        bewegeSchlaeger(dt)
        if !imSpiel {
            wartet -= dt
            if wartet <= 0 { schlage_auf() }
            return
        }
        ballX += vx * dt; ballY += vy * dt
        let r = Ballwechsel.radius
        if ballX < r { ballX = r; vx = abs(vx) }
        if ballX > 1 - r { ballX = 1 - r; vx = -abs(vx) }
        // Schläger
        for s in 0..<2 {
            let y = schlaegerY(s)
            let trifftZeit = s == 0 ? (vy > 0 && ballY + r >= y && ballY - r <= y + Ballwechsel.schlaegerH)
                                    : (vy < 0 && ballY - r <= y + Ballwechsel.schlaegerH && ballY + r >= y)
            if trifftZeit, abs(ballX - schlaegerX[s]) <= Ballwechsel.schlaegerB / 2 + r * 0.6 {
                let off = begrenze((ballX - schlaegerX[s]) / (Ballwechsel.schlaegerB / 2), -1, 1)
                rallye += 1; laengsteRallye = max(laengsteRallye, rallye)
                let v = tempo
                var a = off * 1.0
                if abs(a) < 0.12 { a = (zufall.wahr(0.5) ? 1 : -1) * 0.12 }
                vx = v * sin(a)
                vy = (s == 0 ? -1 : 1) * v * cos(a)
                ballY = s == 0 ? y - r : y + Ballwechsel.schlaegerH + r
                if computer && s == 0 { neuerFehler() }
            }
        }
        // Punkt
        if ballY > Ballwechsel.hoehe + r * 2 { punkt(fuer: 1) }
        else if ballY < -r * 2 { punkt(fuer: 0) }
    }

    private mutating func neuerFehler() {
        let e = [0.0, 0.22, 0.12, 0.17][stufe] * (1.6 - computerStaerke)
        fehler = zufall.zahl(-1...1) * e
    }

    private mutating func punkt(fuer s: Int) {
        punkte[s] += 1
        imSpiel = false; rallye = 0; wartet = Ballwechsel.pause
        ballX = 0.5; ballY = Ballwechsel.hoehe / 2; vx = 0; vy = 0
        empfaenger = 1 - s
        if gewinner != nil { phase = .vorbei(grund: "Spielende") }
    }

    private mutating func schlage_auf() {
        imSpiel = true
        let a = zufall.zahl(-0.45...0.45)
        let v = Ballwechsel.startTempo
        vx = v * sin(a); vy = (empfaenger == 0 ? 1 : -1) * v * cos(a)
        neuerFehler()
    }

    // MARK: Schläger bewegen

    private mutating func bewegeSchlaeger(_ dt: Double) {
        let half = Ballwechsel.schlaegerB / 2
        if computer {
            denkRest -= dt
            if denkRest <= 0 {
                denkRest = [0, 0.28, 0.16, 0.12][stufe] * (1.5 - computerStaerke)
                if imSpiel && vy < 0 { ziele[1] = begrenze(vorhersage() + fehler, 0, 1) }
                else if !imSpiel || vy >= 0 { ziele[1] = 0.5 + (ballX - 0.5) * 0.3 }        // zurück zur Mitte, leicht dem Ball zugewandt
            }
        }
        for s in 0..<2 {
            let speed = (s == 1 && computer) ? [0, 0.5, 0.68, 0.76][stufe] * (0.75 + 0.5 * computerStaerke) : menschSpeed
            let d = ziele[s] - schlaegerX[s], m = speed * dt
            schlaegerX[s] = begrenze(schlaegerX[s] + max(-m, min(m, d)), half, 1 - half)
        }
    }

    /// Wo der Ball am oberen Schläger ankommt (mit Wandabprallern, Faltung der Bahn).
    public func vorhersage() -> Double {
        guard vy < 0 else { return ballX }
        let t = (ballY - (schlaegerY(1) + Ballwechsel.schlaegerH)) / -vy
        let r = Ballwechsel.radius, breite = 1 - 2 * r
        var x = ballX - r + vx * t
        x = x.truncatingRemainder(dividingBy: 2 * breite); if x < 0 { x += 2 * breite }
        if x > breite { x = 2 * breite - x }
        return x + r
    }

    /// Nur für Tests.
    public mutating func setzeRallye(_ n: Int) { rallye = n }
}
