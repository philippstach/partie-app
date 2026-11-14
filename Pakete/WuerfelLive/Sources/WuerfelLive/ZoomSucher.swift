// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Wählt im Hintergrund die beste Kamera-/Zoomstufe (Ultraweit, Weitwinkel, Tele): Ist die Erkennung auf der aktuellen Stufe
/// eine Weile unsicher, werden die anderen Stufen kurz ausprobiert und die beste bleibt. Reine Logik, ohne Kamera testbar.
public struct ZoomSucher: Sendable {
    public let stufen: Int
    public private(set) var aktuell: Int
    /// Auswertungen ohne sicheres Ergebnis, bevor andere Stufen probiert werden.
    public var geduld: Int
    /// Auswertungen je probierter Stufe (die ersten `einschwingen` zählen nicht, die Kamera stellt noch scharf).
    public var probeLaenge: Int
    public var einschwingen: Int

    private var unsicher = 0
    /// `true`, solange andere Stufen probiert werden (die Anzeige soll dann ruhig stehen bleiben).
    public var sondiert: Bool { probe != nil }
    private var probe: Probe?

    struct Probe { var reihe: [Int]; var n = 0; var beste = 0; var punkte: [Int: Int] = [:]; var ausgang: Int }

    public init(stufen: Int, start: Int, geduld: Int = 14, probeLaenge: Int = 9, einschwingen: Int = 3) {
        self.stufen = max(1, stufen); self.aktuell = min(max(0, start), max(0, stufen - 1))
        self.geduld = geduld; self.probeLaenge = probeLaenge; self.einschwingen = einschwingen
    }

    /// Meldet das Ergebnis einer Auswertung. Liefert die Stufe, auf die umgeschaltet werden soll (sonst `nil`).
    /// - punkte: Güte der Anzeige (z. B. 3 je sicherem, 1 je unsicherem Würfel); `allesSicher`: alle Würfel sicher.
    public mutating func beobachte(punkte: Int, allesSicher: Bool) -> Int? {
        guard stufen > 1 else { return nil }
        if var p = probe {
            p.n += 1
            if p.n > einschwingen { p.beste = max(p.beste, punkte) }
            // Früh fertig: alles sicher erkannt – hier bleiben.
            if allesSicher, p.n > einschwingen { probe = nil; unsicher = 0; return nil }
            guard p.n >= probeLaenge else { probe = p; return nil }
            p.punkte[aktuell] = p.beste
            if let naechste = p.reihe.first {
                p.reihe.removeFirst(); p.n = 0; p.beste = 0; probe = p; aktuell = naechste
                return naechste
            }
            // Alle probiert: die beste Stufe gewinnt, bei Gleichstand die Ausgangsstufe.
            let beste = p.punkte.max { a, b in a.value != b.value ? a.value < b.value : (a.key != p.ausgang && b.key == p.ausgang) }!.key
            probe = nil; unsicher = 0
            if beste != aktuell { aktuell = beste; return beste }
            return nil
        }
        if allesSicher { unsicher = 0; return nil }
        unsicher += 1
        guard unsicher >= geduld else { return nil }
        let reihe = (1..<stufen).map { (aktuell + $0) % stufen }
        probe = Probe(reihe: Array(reihe.dropFirst()), punkte: [aktuell: punkte], ausgang: aktuell)   // die Ausgangsstufe zählt mit ihrem letzten Ergebnis
        aktuell = reihe[0]
        return aktuell
    }

    /// Von Hand gewählt: Automatik pausiert, bis `neuStart` aufgerufen wird.
    public mutating func setze(_ stufe: Int) { aktuell = stufe; probe = nil; unsicher = 0 }
}
