// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(GameKit)
import GameKit
#endif

/// Game Center, vorsichtig: aus, bis eine App es in der Konfiguration einschaltet. Nie automatische Anmeldung beim Start
/// (die App muss ohne Konto voll nutzbar bleiben), sondern erst, wenn jemand „Bestenliste“ antippt.
/// Voraussetzungen pro App: Capability „Game Center“, Bestenlisten/Erfolge in App Store Connect, Datenschutzangaben prüfen.
public struct GameCenterKonfiguration: Sendable {
    public var bestenlisten: [String]     // IDs aus App Store Connect
    public var erfolge: [String]
    public init(bestenlisten: [String] = [], erfolge: [String] = []) { self.bestenlisten = bestenlisten; self.erfolge = erfolge }
}

@MainActor
public protocol SpielDienst: AnyObject {
    var angemeldet: Bool { get }
    func anmelden() async
    func meldeWert(_ wert: Int, bestenliste: String) async
    func meldeErfolg(_ id: String, prozent: Double) async
}

/// Tut nichts. Ist die Voreinstellung, solange eine App kein Game Center hat.
@MainActor
public final class KeinSpielDienst: SpielDienst {
    public init() {}
    public var angemeldet: Bool { false }
    public func anmelden() async {}
    public func meldeWert(_ wert: Int, bestenliste: String) async {}
    public func meldeErfolg(_ id: String, prozent: Double) async {}
}

#if canImport(GameKit)
@MainActor
public final class GameCenterDienst: SpielDienst {
    public init() {}
    public var angemeldet: Bool { GKLocalPlayer.local.isAuthenticated }

    public func anmelden() async {
        guard !GKLocalPlayer.local.isAuthenticated else { return }
        await withCheckedContinuation { (weiter: CheckedContinuation<Void, Never>) in
            var fertig = false
            GKLocalPlayer.local.authenticateHandler = { _, _ in
                // Der Anmeldedialog erscheint vom System; wir warten nur auf das erste Ergebnis.
                if !fertig { fertig = true; weiter.resume() }
            }
        }
    }

    public func meldeWert(_ wert: Int, bestenliste: String) async {
        guard angemeldet else { return }
        try? await GKLeaderboard.submitScore(wert, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [bestenliste])
    }

    public func meldeErfolg(_ id: String, prozent: Double) async {
        guard angemeldet else { return }
        let erfolg = GKAchievement(identifier: id)
        erfolg.percentComplete = min(max(prozent, 0), 100)
        erfolg.showsCompletionBanner = true
        try? await GKAchievement.report([erfolg])
    }
}
#endif
