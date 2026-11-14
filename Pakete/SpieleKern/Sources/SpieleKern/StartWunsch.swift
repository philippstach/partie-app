// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// KI-8: Wunsch „Neue Partie“ aus Siri, Kurzbefehlen oder Spotlight: wie viele Menschen und wie viele Computer mitspielen.
/// Die Hülle (`SpielRahmen`) löst ihn beim Erscheinen des Spiels ein, prüft ihn gegen die Grenzen des Spiels und startet.
/// Keine Oberfläche; das Spiel selbst weiß nichts davon.
public struct StartWunsch: Equatable, Sendable {
    /// Anzahl menschlicher Mitspieler; `nil` = nicht genannt (Vorgabe des Spiels).
    public var menschen: Int?
    /// Anzahl Computergegner (0 = keiner).
    public var computer: Int

    public init(menschen: Int? = nil, computer: Int = 0) { self.menschen = menschen; self.computer = computer }

    public struct Platz: Equatable, Sendable {
        public let name: String
        public let computer: Bool
        public init(name: String, computer: Bool) { self.name = name; self.computer = computer }
    }

    /// Die Plätze der Partie. `nil`, wenn nichts Besonderes gewünscht ist (oder das Spiel ein Einzelspiel ist): dann gilt die Vorgabe des Spiels.
    /// - Computer nur, wenn das Spiel sie kennt; sonst werden sie weggelassen.
    /// - Zu viele Plätze werden gekürzt (zuerst Computer), zu wenige mit Menschen aufgefüllt, bis die Mindestzahl des Spiels erreicht ist.
    /// - Namen der Menschen kommen der Reihe nach aus `vorgabeNamen` (Ich, zuletzt gespielte); danach bleibt der Name leer
    ///   (die Hülle nennt ihn „Spieler N“ und legt ihn nicht ins Verzeichnis).
    public func aufstellung(spielerzahl: ClosedRange<Int>, computerErlaubt: Bool, vorgabeNamen: [String]) -> [Platz]? {
        guard spielerzahl.upperBound > 1 else { return nil }
        let gewuenschteComputer = computerErlaubt ? max(0, computer) : 0
        if menschen == nil && gewuenschteComputer == 0 { return nil }
        var m = max(1, menschen ?? 1)
        var c = gewuenschteComputer
        let obergrenze = spielerzahl.upperBound
        if m > obergrenze { m = obergrenze }
        if m + c > obergrenze { c = obergrenze - m }
        if m + c < spielerzahl.lowerBound { m = spielerzahl.lowerBound - c }
        let menschenPlaetze = (0..<m).map { i in Platz(name: i < vorgabeNamen.count ? vorgabeNamen[i] : "", computer: false) }
        return menschenPlaetze + (0..<c).map { _ in Platz(name: "Computer", computer: true) }
    }
}

/// Übergabe des Wunsches von Siri/Kurzbefehlen an das Spiel (auch beim Kaltstart, bevor das Spiel erscheint).
/// Ein Wunsch gilt höchstens eine Minute und nur einmal; ein nicht eingelöster Wunsch (zum Beispiel wegen Kinder-Modus) startet später nichts.
@MainActor
public enum StartWunschPost {
    private static var offen: [String: (wunsch: StartWunsch, seit: Date)] = [:]
    public static let gueltigkeit: TimeInterval = 60

    public static func merken(_ spiel: String, _ wunsch: StartWunsch, jetzt: Date = Date()) {
        offen[spiel] = (wunsch, jetzt)
    }

    /// Gibt den Wunsch für dieses Spiel zurück und löscht ihn. `nil`, wenn keiner da ist oder er zu alt ist.
    public static func einloesen(_ spiel: String, jetzt: Date = Date()) -> StartWunsch? {
        guard let e = offen.removeValue(forKey: spiel), jetzt.timeIntervalSince(e.seit) <= gueltigkeit else { return nil }
        return e.wunsch
    }

    public static func verwerfen(_ spiel: String) { offen[spiel] = nil }
}
