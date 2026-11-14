// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Eingabezustand des laufenden Zugs, geteilt zwischen der Würfel-Karte (oben) und der
/// festen Aktionsleiste (unten). Nur Oberfläche – der Spielstand liegt im `GameStore`.
@MainActor @Observable
final class TurnInput {
    /// Echte Würfel: eingetippte Augen der Würfel, die aus dem aktuellen Wurf rausgelegt werden
    var pending: [Int] = {
        #if DEBUG
        // Screenshots: `-demoPending "1,5"` zeigt schon eingetippte Würfel
        return (UserDefaults.standard.string(forKey: "demoPending") ?? "").split(separator: ",").compactMap { Int($0) }
        #else
        return []
        #endif
    }()
    /// Punkte-Eingabe (echte Würfel): getippte Kacheln, die Summe zählt
    var tiles: [Int] = {
        #if DEBUG
        // Screenshots: `-demoTiles "100,100,50"`
        return (UserDefaults.standard.string(forKey: "demoTiles") ?? "").split(separator: ",").compactMap { Int($0) }
        #else
        return []
        #endif
    }()
    var points: Int { tiles.reduce(0, +) }
    private static let maxPoints = 99_950
    /// Kurze Sperre nach „Niete“ bzw. „Eintragen“, damit ein Doppeltipp nicht den Nächsten trifft
    var cooldown = false
    /// Digitale Würfel wackeln gerade
    var shaking = false

    // MARK: - Eingabeart (Blatt 15: Ansagen, Kamera, Scanner)

    /// Ansage der rausgelegten Würfel (Spracherkennung auf dem Gerät). Die Ansage füllt nur freie Plätze und trägt nie von selbst ein.
    let ansage = AnsageSteuerung()
    var kameraOffen = false
    var scannerOffen = false
    /// Kamera oder Scanner haben bei diesem Wurf Augen geliefert (sonst vergisst „Weiterwürfeln“/„Aufhören“ die gemerkte Eingabeart).
    var hilfeGenutzt = false

    /// Die rausgelegten Würfel als Plätze für die Ansage: schon getippte sind gefüllt, der Rest (bis `offen`) leer.
    func pendingBindung(offen: Int) -> Binding<[Int?]> {
        Binding(get: { (0..<max(offen, 0)).map { $0 < self.pending.count ? self.pending[$0] : nil } },
                set: { self.pending = Array($0.compactMap { $0 }.prefix(max(offen, 0))) })
    }

    /// Beim Spielerwechsel alles Eingetippte verwerfen
    func reset() {
        ansage.abbrechen()
        pending = []
        tiles = []
    }

    func startCooldown() {
        cooldown = true
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            cooldown = false
        }
    }

    // MARK: - Würfel

    /// Echte Würfel mit Augen-Eingabe statt digitalem Würfeln
    func manual(_ store: GameStore) -> Bool { store.game?.settings.diceMode == .real }

    /// Echte Würfel: Die Rausgelegt-Eingabe ist immer offen, solange kein Angebot wartet.
    func showEntry(_ store: GameStore) -> Bool {
        manual(store) && store.game?.offer == nil
    }

    /// Ein Tap auf eine Augen-Taste: ein rausgelegter Würfel mehr (höchstens so viele wie offen).
    func addPip(_ value: Int, store: GameStore) {
        guard pending.count < store.turn.openCount else { return }
        withAnimation(.snappy) { pending.append(value) }
    }

    func removeLastPip() {
        withAnimation(.snappy) { _ = pending.popLast() }
    }

    /// Punkte der eingetippten Würfel als ein Wurf; `nil` = zählt nicht
    func pendingScore(_ store: GameStore) -> Int? { store.keptScore(pending) }

    /// Eingetippte Würfel rauslegen – weiterwürfeln oder (`bank`) aufhören.
    func layOut(_ store: GameStore, bank: Bool) {
        guard pendingScore(store) != nil, !cooldown else { return }
        // Ganz von Hand getippt: Die App vergisst die gemerkte Eingabeart (Blatt 15).
        if !hilfeGenutzt && !ansage.hatEingetragen { WuerfelEingabeArt.merke(nil) }
        hilfeGenutzt = false; ansage.vergesseEintrag()
        if bank { startCooldown() }
        let dice = pending
        withAnimation(.snappy) {
            pending = []
            store.layOut(dice, bank: bank)
        }
    }

    /// Direkte Niete: Punkte des Zugs sind weg, weiter zum Nächsten (mit ↩︎ zurücknehmbar).
    func niete(_ store: GameStore) {
        guard !cooldown else { return }
        startCooldown()
        withAnimation(.snappy) {
            reset()
            store.submitNoPoints()
        }
    }

    /// Digital würfeln
    func roll(_ store: GameStore) {
        withAnimation(.easeInOut(duration: 0.12).repeatCount(3, autoreverses: true)) { shaking = true }
        Task {
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(.snappy) {
                shaking = false
                store.roll()
                if store.game?.settings.preselectsBest == true { store.selectBest() }
            }
        }
    }

    // MARK: - Punkte

    func addTile(_ value: Int) {
        guard points + value <= Self.maxPoints else { return }
        tiles.append(value)
    }

    func removeLastTile() {
        _ = tiles.popLast()
    }

    func clearTiles() {
        tiles = []
    }

    func submitPoints(_ store: GameStore) {
        guard GameStore.isValidEntry(points), !cooldown else { return }
        store.submitPoints(points)
        clearTiles()
        startCooldown()
    }
}

/// Feste Leiste am unteren Rand (Spiel, Sieger, Setup): Hauptaktionen immer erreichbar.
struct BottomBar<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.tischGross) private var tischGross
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .frame(maxWidth: tischGross ? Theme.tischKnopfBreite : (sizeClass == .regular ? Theme.wideColumnWidth : 520))
            .frame(maxWidth: .infinity)
            // iPhone: deckend wie eine Karte, damit umrandete Knöpfe gut sichtbar bleiben.
            // Spieltisch (Build 10): keine eigene Fläche, die Knöpfe stehen auf dem Seitenhintergrund.
            // K-033: Tinte und Salon: Leiste in der Seitenfarbe des Designs (kein weißer Streifen auf Papiergrund).
            // Die Fläche lag bisher als kartenGrund über dem Papiergrund aus NeuSpielView.aktionsGrund.
            .background {
                if !tischGross {
                    if Design.ist(.klar) {
                        Color.kartenGrund
                            .ignoresSafeArea(edges: .bottom)
                            .shadow(color: .black.opacity(0.08), radius: 6, y: -2)
                    } else if !Tisch.aktiv {   // Runde 5, Paket W: in Tinte liegt der Knopf auf dem Filz, kein schwarzer Streifen
                        Color.seitenGrund
                            .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
    }
}
