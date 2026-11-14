// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ActivityKit
import SpieleKern
import KlarGlas

/// E5: Verbindet `LaufendePartie` (Rahmen/Spiele) mit der Live Activity. Es läuft höchstens eine Aktivität; ist der Nutzer in den
/// Einstellungen der Live Activities dagegen, passiert nichts. Aktivitäten enden mit der Partie oder spätestens nach vier Stunden.
@MainActor
enum AktivitaetVerwalter {
    private static var aktivitaet: Activity<PartieAktivitaet>?

    static func anmelden() {
        LaufendePartie.beginnHaken = { beginnen($0) }
        LaufendePartie.aenderungHaken = { aktualisieren($0) }
        LaufendePartie.endeHaken = { beenden() }
        // Reste einer früheren App-Sitzung (App beendet, Aktivität blieb stehen) sofort aufräumen
        Task { for a in Activity<PartieAktivitaet>.activities { await a.end(nil, dismissalPolicy: .immediate) } }
    }

    static func beginnen(_ z: LaufendePartie.Zustand) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        beenden()
        let farbe = SpielKatalog.modul(z.spielID)?.gattung.klarFarbe.flaeche ?? Familienfarbe.nachtblau.flaeche
        let attribute = PartieAktivitaet(spielID: z.spielID, spielName: z.spielName, farbeHex: farbe, spieler: z.spieler, beginn: z.beginn)
        let inhalt = ActivityContent(state: PartieAktivitaet.ContentState(amZug: z.amZug, stand: z.stand), staleDate: z.beginn.addingTimeInterval(4 * 3600))
        aktivitaet = try? Activity.request(attributes: attribute, content: inhalt, pushType: nil)
        // C-020: staleDate beendet nichts; deshalb nach 4 Stunden selbst beenden, solange die App läuft
        let id = aktivitaet?.id
        Task { try? await Task.sleep(for: .seconds(4 * 3600)); if let id, aktivitaet?.id == id { beenden() } }
    }

    static func aktualisieren(_ z: LaufendePartie.Zustand) {
        guard let a = aktivitaet else { return }
        let inhalt = ActivityContent(state: PartieAktivitaet.ContentState(amZug: z.amZug, stand: z.stand), staleDate: z.beginn.addingTimeInterval(4 * 3600))
        Task { await a.update(inhalt) }
    }

    static func beenden() {
        guard let a = aktivitaet else { return }
        aktivitaet = nil
        Task { await a.end(nil, dismissalPolicy: .immediate) }
    }
}
