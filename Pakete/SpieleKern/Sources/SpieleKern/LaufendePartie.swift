// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation

/// E5: Meldet der Hülle, dass eine Partie mit mehreren Menschen läuft (Hot-Seat), damit sie eine Live Activity
/// (Sperrbildschirm, Dynamic Island) zeigen kann. Der Rahmen meldet Beginn und Ende; ein Spiel kann zusätzlich
/// `LaufendePartie.zug(...)` rufen, wenn es weiß, wer dran ist. Ohne Haken (Tests, Einzel-App) passiert nichts.
public enum LaufendePartie {
    public struct Zustand: Equatable, Sendable {
        public var spielID: String
        public var spielName: String
        public var spieler: [String]
        public var amZug: String?
        public var stand: String?
        public var beginn: Date
        public init(spielID: String, spielName: String, spieler: [String], amZug: String? = nil, stand: String? = nil, beginn: Date = Date()) {
            self.spielID = spielID; self.spielName = spielName; self.spieler = spieler; self.amZug = amZug; self.stand = stand; self.beginn = beginn
        }
    }

    /// Die Hülle setzt diese Haken beim App-Start.
    nonisolated(unsafe) public static var beginnHaken: (@MainActor (Zustand) -> Void)?
    nonisolated(unsafe) public static var aenderungHaken: (@MainActor (Zustand) -> Void)?
    nonisolated(unsafe) public static var endeHaken: (@MainActor () -> Void)?
    /// Beobachtbarer Halter des Zustands, damit Ansichten (z. B. der Tisch-Modus auf dem iPad, E8) bei Zugwechseln neu zeichnen.
    @Observable @MainActor public final class Halter {
        public fileprivate(set) var zustand: Zustand?
        fileprivate init() {}
    }
    @MainActor public static let halter = Halter()
    /// Zuletzt gemeldeter Zustand (nil = keine Partie mit mehreren Menschen).
    @MainActor public static var aktuell: Zustand? { halter.zustand }

    /// Eine Live Activity lohnt sich erst, wenn mindestens zwei Menschen am selben Gerät spielen.
    public static func lohnt(menschen: Int) -> Bool { menschen >= 2 }

    @MainActor public static func beginnen(spielID: String, spielName: String, menschen: [String], computerAnzahl: Int = 0) {
        guard lohnt(menschen: menschen.count) else { beenden(); return }
        let z = Zustand(spielID: spielID, spielName: spielName, spieler: menschen, amZug: menschen.first)
        halter.zustand = z
        beginnHaken?(z)
    }

    /// Das Spiel meldet, wer dran ist (und optional den Stand als Kurztext, z. B. „Anna 12 · Ben 8“).
    @MainActor public static func zug(amZug: String?, stand: String? = nil) {
        guard var z = aktuell else { return }
        guard z.amZug != amZug || z.stand != stand else { return }
        z.amZug = amZug; z.stand = stand
        halter.zustand = z
        aenderungHaken?(z)
    }

    @MainActor public static func beenden() {
        guard aktuell != nil else { return }
        halter.zustand = nil
        endeHaken?()
    }
}
