// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit) && canImport(GameKit)
import SwiftUI
import UIKit
import GameKit

/// Ein Game-Center-Freund, wie ihn die Freundesliste liefert (nur Kennung und Anzeigename).
public struct GCFreund: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public init(id: String, name: String) { self.id = id; self.name = name }
}

/// Game Center für Spiele zu zweit über das Netz (rundenbasiert, ohne eigenen Server).
/// Regeln: Die App bleibt ohne Konto voll nutzbar. Angemeldet wird nie beim Start, sondern erst, wenn jemand „Online“ antippt.
/// Die Freundesliste wird erst nach der Systemabfrage gelesen. Gespeichert wird nur die Kennung des Freundes, auf dem Gerät.
@MainActor
public final class GameCenterOnline: NSObject, ObservableObject {
    public static let gemeinsam = GameCenterOnline()

    @Published public private(set) var angemeldet = false
    @Published public private(set) var fehler: String?
    /// Die gerade geöffnete Partie (gewählt in der Partienliste oder neu eingeladen).
    @Published public private(set) var aktuellesMatch: GKTurnBasedMatch?
    /// Zählt jedes Ereignis zu einer Partie hoch, damit Ansichten den neuen Stand lesen.
    @Published public private(set) var ereignis = 0

    private var wartend: CheckedContinuation<Bool, Never>?
    private var registriert = false
    private weak var matchmaker: UIViewController?

    override private init() { super.init() }

    public var ichKennung: String { GKLocalPlayer.local.gamePlayerID }
    public var ichName: String { GKLocalPlayer.local.displayName }

    // MARK: Anmelden

    /// Meldet bei Game Center an (das System zeigt bei Bedarf selbst den Anmeldedialog). `false`, wenn der Spieler nicht angemeldet ist.
    @discardableResult
    public func anmelden() async -> Bool {
        if GKLocalPlayer.local.isAuthenticated { angemeldet = true; registrieren(); return true }
        return await withCheckedContinuation { (weiter: CheckedContinuation<Bool, Never>) in
            wartend?.resume(returning: false)
            wartend = weiter
            GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
                Task { @MainActor in self?.anmeldeErgebnis(vc, error) }
            }
        }
    }

    private func anmeldeErgebnis(_ vc: UIViewController?, _ error: Error?) {
        if let vc { Self.zeige(vc); return }   // Anmeldedialog: Ergebnis folgt im nächsten Aufruf
        let ok = GKLocalPlayer.local.isAuthenticated
        angemeldet = ok
        if ok { fehler = nil; registrieren() } else { fehler = error?.localizedDescription ?? String(localized: "Du bist bei Game Center nicht angemeldet.") }
        wartend?.resume(returning: ok)
        wartend = nil
    }

    private func registrieren() {
        guard !registriert else { return }
        registriert = true
        GKLocalPlayer.local.register(self)
    }

    // MARK: Freunde

    /// Die Freunde in Game Center. Beim ersten Mal fragt das System, ob die App die Liste lesen darf.
    public func freunde() async -> [GCFreund] {
        guard await anmelden() else { return [] }
        do {
            let liste = try await GKLocalPlayer.local.loadFriends()
            fehler = nil
            return liste.map { GCFreund(id: $0.gamePlayerID, name: $0.displayName) }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            fehler = String(localized: "Die Freundesliste ist nicht freigegeben. Du kannst sie in den Einstellungen unter Game Center erlauben.")
            return []
        }
    }

    // MARK: Partien

    /// Zeigt die Systemansicht zum Einladen von Freunden und zur Liste der laufenden Partien (Zwei-Personen-Partie, abwechselnd).
    public func partienZeigen() async {
        guard await anmelden() else { return }
        let anfrage = GKMatchRequest()
        anfrage.minPlayers = 2
        anfrage.maxPlayers = 2
        anfrage.inviteMessage = String(localized: "Magst du eine Partie Viererreihe spielen?")
        let vc = GKTurnBasedMatchmakerViewController(matchRequest: anfrage)
        vc.turnBasedMatchmakerDelegate = self
        vc.showExistingMatches = true
        matchmaker = vc
        Self.zeige(vc)
    }

    public func schliessen() { aktuellesMatch = nil }

    /// Meine Nummer in der Partie: 1 = hat die Partie begonnen (Rot), 2 = eingeladen (Blau). `nil`, wenn ich nicht dabei bin.
    public func meineNummer(_ m: GKTurnBasedMatch) -> Int? {
        m.participants.firstIndex { $0.player?.gamePlayerID == GKLocalPlayer.local.gamePlayerID }.map { $0 + 1 }
    }

    public func gegner(_ m: GKTurnBasedMatch) -> GKPlayer? {
        m.participants.first { $0.player != nil && $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID }?.player
    }

    public func amZug(_ m: GKTurnBasedMatch) -> Bool {
        m.status == .open && m.currentParticipant?.player?.gamePlayerID == GKLocalPlayer.local.gamePlayerID
    }

    /// Gibt den Zug an den anderen weiter. `daten`: der ganze Stand (der Gegner liest daraus die Partie).
    public func zugAbgeben(_ m: GKTurnBasedMatch, daten: Data) async -> Bool {
        guard let andere = m.participants.first(where: { $0 !== m.currentParticipant }) else { return false }
        do {
            try await m.endTurn(withNextParticipants: [andere], turnTimeout: GKTurnTimeoutNone, match: daten)
            ereignis += 1
            return true
        } catch {
            fehler = error.localizedDescription
            return false
        }
    }

    /// Beendet die Partie. `ichGewonnen`: `true` gewonnen, `false` verloren, `nil` unentschieden.
    public func beenden(_ m: GKTurnBasedMatch, daten: Data, ichGewonnen: Bool?) async -> Bool {
        let ich = m.currentParticipant
        for p in m.participants {
            switch ichGewonnen {
            case .some(true): p.matchOutcome = (p === ich) ? .won : .lost
            case .some(false): p.matchOutcome = (p === ich) ? .lost : .won
            case nil: p.matchOutcome = .tied
            }
        }
        do {
            try await m.endMatchInTurn(withMatch: daten)
            ereignis += 1
            return true
        } catch {
            fehler = error.localizedDescription
            return false
        }
    }

    /// Gibt die Partie auf (ich verliere). Nur sinnvoll, wenn ich am Zug bin; sonst bleibt die Partie offen.
    public func aufgeben(_ m: GKTurnBasedMatch) async {
        guard amZug(m), let andere = m.participants.first(where: { $0 !== m.currentParticipant }) else { return }
        try? await m.participantQuitInTurn(with: .quit, nextParticipants: [andere], turnTimeout: GKTurnTimeoutNone, match: m.matchData ?? Data())
        ereignis += 1
    }

    // MARK: Anzeigen

    static func zeige(_ vc: UIViewController) {
        guard let szene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              var oben = (szene.windows.first(where: \.isKeyWindow) ?? szene.windows.first)?.rootViewController else { return }
        while let weiter = oben.presentedViewController { oben = weiter }
        oben.present(vc, animated: true)
    }
}

extension GameCenterOnline: GKLocalPlayerListener, GKTurnBasedEventListener, GKTurnBasedMatchmakerViewControllerDelegate {
    nonisolated public func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        Task { @MainActor in
            if didBecomeActive || self.aktuellesMatch?.matchID == match.matchID {
                self.matchmaker?.dismiss(animated: true)
                self.aktuellesMatch = match
            }
            self.ereignis += 1
        }
    }

    nonisolated public func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        Task { @MainActor in
            if self.aktuellesMatch?.matchID == match.matchID { self.aktuellesMatch = match }
            self.ereignis += 1
        }
    }

    nonisolated public func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        Task { @MainActor in await self.aufgeben(match) }
    }

    nonisolated public func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        Task { @MainActor in viewController.dismiss(animated: true) }
    }

    nonisolated public func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        Task { @MainActor in
            self.fehler = error.localizedDescription
            viewController.dismiss(animated: true)
        }
    }
}
#endif
