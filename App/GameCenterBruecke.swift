// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import GameKit
import SpieleKern

/// Game Center in der Hülle (1.0): Bestenlisten und Erfolge. Die Regeln dazu stehen getestet in `GameCenterRegeln` (SpieleKern).
/// Grundsätze: Die App bleibt ohne Konto voll nutzbar. Aus im Kinder-Modus und wenn der Schalter in den Einstellungen aus ist.
/// Werte, die ohne Anmeldung entstehen, werden gemerkt und beim nächsten Anmelden nachgeliefert. Statistik und Namen bleiben auf dem Gerät.
@MainActor
final class GameCenterBruecke: NSObject, GKGameCenterControllerDelegate {
    static let geteilt = GameCenterBruecke()
    static let schalterKey = "gameCenterAn"

    private let defaults = UserDefaults.standard
    private let offenKey = "gameCenter.offen"          // [Bestenliste: Wert], noch nicht gesendet
    private let gesendetKey = "gameCenter.erfolge"     // [Erfolg: Prozent], schon gesendet
    private var anmeldungLaeuft = false

    /// Darf Game Center gerade benutzt werden?
    var aktiv: Bool { (defaults.object(forKey: Self.schalterKey) as? Bool ?? false) && !Modi.kinder }
    var angemeldet: Bool { GKLocalPlayer.local.isAuthenticated }

    // MARK: Anmeldung

    /// Beim Start aufrufen. Meldet im Hintergrund an; Apple zeigt den Anmeldedialog nur, wenn nötig.
    func anmelden() {
        guard aktiv, !anmeldungLaeuft else { return }
        anmeldungLaeuft = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, _ in
            Task { @MainActor in
                guard let self else { return }
                if let controller { Self.oben()?.present(controller, animated: true); return }
                if GKLocalPlayer.local.isAuthenticated { await self.nachliefern() }
            }
        }
    }

    // MARK: Melden

    /// Nach jeder beendeten Partie: Bestenliste und Erfolge aktualisieren.
    func partieBeendet(_ e: PartieErgebnis, statistik: StatistikDienst, ich: UUID?) {
        guard aktiv else { return }
        if let m = GameCenterRegeln.meldung(fuer: e, ich: ich) { merken(m) }
        erfolgeNeuBerechnen(statistik: statistik, ich: ich)
        Task { await nachliefern() }
    }

    private var offen: [String: Int] {
        get { defaults.dictionary(forKey: offenKey) as? [String: Int] ?? [:] }
        set { defaults.set(newValue, forKey: offenKey) }
    }
    private var gesendet: [String: Double] {
        get { defaults.dictionary(forKey: gesendetKey) as? [String: Double] ?? [:] }
        set { defaults.set(newValue, forKey: gesendetKey) }
    }
    private var erfolgeOffen: [String: Double] = [:]

    private func merken(_ m: GameCenterRegeln.Meldung) {
        var o = offen
        let zeit = GameCenterRegeln.bestenlisten.first { $0.id == m.bestenliste }?.art == .zeit
        if let alt = o[m.bestenliste] { o[m.bestenliste] = zeit ? min(alt, m.wert) : max(alt, m.wert) } else { o[m.bestenliste] = m.wert }
        offen = o
    }

    private func erfolgeNeuBerechnen(statistik: StatistikDienst, ich: UUID?) {
        let f = GameCenterRegeln.fortschritt(ereignisse: statistik.ereignisse, ich: ich, tagesSerie: Tagesaufgabe.serie(statistik)) { id in
            let m = SpielKatalog.modul(id)
            let land = SpielMetadaten.info(id).land
            return .init(gattung: m?.gattung.rawValue, land: land.isEmpty ? nil : land)
        }
        let schon = gesendet
        for (id, p) in f where p > (schon[id] ?? 0) { erfolgeOffen[id] = p }
    }

    private func nachliefern() async {
        guard aktiv, angemeldet else { return }
        for (liste, wert) in offen {
            do {
                try await GKLeaderboard.submitScore(wert, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [liste])
                var o = offen; o[liste] = nil; offen = o
            } catch { /* bleibt gemerkt, nächster Versuch beim nächsten Mal */ }
        }
        guard !erfolgeOffen.isEmpty else { return }
        let paket = erfolgeOffen.map { id, p -> GKAchievement in
            let a = GKAchievement(identifier: id)
            a.percentComplete = min(max(p, 0), 100)
            a.showsCompletionBanner = true
            return a
        }
        do {
            try await GKAchievement.report(paket)
            var g = gesendet
            for (id, p) in erfolgeOffen { g[id] = p }
            gesendet = g
            erfolgeOffen = [:]
        } catch { /* nächstes Mal */ }
    }

    // MARK: Anzeige

    /// Öffnet die Bestenlisten und Erfolge von Apple.
    func zeigen() {
        guard aktiv, angemeldet else { anmeldungLaeuft = false; anmelden(); return }   // C-004: Sperre lösen, sonst passiert nach einer abgebrochenen Anmeldung nichts
        let c = GKGameCenterViewController(state: .dashboard)
        c.gameCenterDelegate = self
        Self.oben()?.present(c, animated: true)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in gameCenterViewController.dismiss(animated: true) }
    }

    private static func oben() -> UIViewController? {
        let szene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
        var vc = szene?.keyWindow?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }
}

/// Einstellungen: Schalter und Knopf für die Bestenlisten.
struct GameCenterAbschnitt: View {
    @AppStorage(GameCenterBruecke.schalterKey) private var an = false
    @AppStorage(Modi.kinderKey) private var kinder = false

    var body: some View {
        Section {
            Toggle(isOn: Binding(get: { an && !kinder }, set: { an = $0; if $0 { GameCenterBruecke.geteilt.anmelden() } })) {
                // Fund sp-10: Zwei lose Texte als Beschriftung ließen den langen Text in einer schmalen Spalte neben dem Schalter stehen.
                // Ein Stapel in voller Breite, Text links, Schalter rechts, wie bei den anderen Zeilen.
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Center")
                    Text(kinder ? "Im Kinder-Modus ist Game Center aus." : "Schickt deine besten Zeiten und Punkte an die Bestenlisten von Apple und schaltet Erfolge frei. Ohne Anmeldung bei Apple bleibt alles auf diesem Gerät.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(kinder)
            if an && !kinder {
                Button { GameCenterBruecke.geteilt.zeigen() } label: { Label("Bestenlisten und Erfolge", systemImage: "trophy") }
            }
        }
    }
}
