// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG
import Foundation

/// Nur Debug-Bauten: Startargument `-testZustand kurzVorEnde|ende` zusammen mit `-startetMit <spiel-id>` legt vor dem Öffnen des
/// Spiels einen Spielstand ab, der über die normale Spiellogik (feste Zugfolge, festgelegter Zufall) kurz vor dem Ende oder am Ende steht.
/// Das Spiel lädt ihn wie eine fortgesetzte Partie; der Rahmen öffnet es direkt („Weiterspielen“). Liste: TESTZUSTAENDE.md.
/// In Release-Bauten gibt es nichts davon (die ganze Datei und alle Aufrufer stehen unter `#if DEBUG`).
public enum Testzustand {
    public enum Art: String, Sendable { case kurzVorEnde, ende }

    /// Gewünschter Zustand aus `-testZustand` (nil = kein Testzustand).
    public static var art: Art? { UserDefaults.standard.string(forKey: "testZustand").flatMap(Art.init(rawValue:)) }

    /// Legt einen Stand unter der Speicherkennung des Spiels ab, dazu die Aufstellung (lauter Menschen, „Spieler 1“…) und den
    /// Wunsch „gleich weiterspielen“. Eine eventuell vorhandene echte Partie dieses Spiels wird dabei überschrieben (nur Debug).
    @MainActor
    public static func ablegen<T: Encodable>(_ stand: T, kennung: String, spieler: Int = 1) {
        SpielStand.verworfen.remove(kennung)
        SpielStand.sichern(stand, spiel: kennung)
        melden(kennung: kennung, spieler: spieler)
    }

    /// Für Spiele mit eigener Ablage: das Spiel schreibt seinen Stand selbst, hier nur Aufstellung und Direktstart.
    @MainActor
    public static func melden(kennung: String, spieler: Int = 1, namen: [String]? = nil, computer: Set<Int> = []) {
        let n = namen ?? (1...max(1, spieler)).map { "Spieler \($0)" }
        LetzteRunde(plaetze: n.enumerated().map { .init(name: $1, computer: computer.contains($0)) }).speichern(kennung)
        OffenesSpiel.setze(kennung, offen: true)
        OffenesSpiel.direktMerken(kennung)
    }

    /// Probiert feste Seeds der Reihe nach; der erste Lauf mit `treffer` gewinnt (sonst der letzte). Alles bleibt deterministisch.
    public static func suche<S>(seeds: ClosedRange<UInt64> = 1...60, _ versuch: (UInt64) -> (stand: S, treffer: Bool)) -> S {
        var letzter: S?
        for seed in seeds {
            let r = versuch(seed)
            if r.treffer { return r.stand }
            letzter = r.stand
        }
        return letzter!
    }

    /// Wiederholt `schritt`, bis `fertig` gilt oder `grenze` Schritte gemacht sind (Schutz vor Endlosschleifen). Gibt die Schrittzahl zurück.
    @discardableResult
    public static func spiele<S>(_ s: inout S, grenze: Int = 20_000, fertig: (S) -> Bool, schritt: (inout S) -> Void) -> Int {
        var n = 0
        while n < grenze, !fertig(s) { schritt(&s); n += 1 }
        return n
    }
}

#if canImport(UIKit)
import SwiftUI

public extension View {
    /// Nur Debug (immer in `#if DEBUG` aufrufen): Bei `-testZustand ende` meldet das Spiel kurz nach dem Laden des Endstands selbst das Ende,
    /// so wie es nach dem letzten Zug geschähe. Für Spiele, die das Ende nur nach einem Zug prüfen.
    func testEndeMelden(_ aktion: @escaping @MainActor () -> Void) -> some View {
        task {
            guard Testzustand.art == .ende else { return }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await aktion()
        }
    }
}
#endif
#endif
