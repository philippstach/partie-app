// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import Combine
import ArcadeKern

/// Liefert den Takt für Arcade-Spiele: ruft `schritt(dt)` mit festem Zeitschritt (1/120 s, `FesterTakt`) so oft auf, wie Zeit vergangen ist.
struct ArcadeTaktStil: ViewModifier {
    let aktiv: Bool
    let schritt: (Double) -> Void
    @State private var letzte: Date?
    @State private var takt = FesterTakt()
    private let uhr = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content.onReceive(uhr) { jetzt in
            defer { letzte = jetzt }
            guard aktiv, let l = letzte else { takt.zuruecksetzen(); return }
            for _ in 0..<takt.schritte(fuer: jetzt.timeIntervalSince(l)) { schritt(FesterTakt.schritt) }
        }
    }
}

struct ComputerZugStil<ID: Equatable>: ViewModifier {
    let aktiv: Bool
    let id: ID
    let verzoegerung: Double
    var tempoFolgen = true
    let aktion: @MainActor () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: id, initial: true) { _, _ in start() }
            .onChange(of: aktiv) { _, _ in start() }
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in tick() }
    }

    @State private var verbleibend: Double?

    /// 1.0 (M2): Die Denkpause folgt der Einstellung „Tempo des Computers“.
    private func start() { verbleibend = aktiv ? (tempoFolgen ? verzoegerung * ComputerTempo.global.faktor : verzoegerung) : nil }
    private func tick() {
        guard var v = verbleibend else { return }
        v -= 0.1
        if v <= 0 { verbleibend = nil; aktion() } else { verbleibend = v }
    }
}

public extension View {
    /// Computerzug mit kurzer Denkpause: Läuft, solange `aktiv` wahr ist; ändert sich `id`, startet die Pause neu.
    /// `tempoFolgen: false` für Spiele, in denen die Pause zur Spielstärke gehört (Reaktionsspiele wie Spit).
    func computerZug<ID: Equatable>(aktiv: Bool, id: ID, verzoegerung: Double = 0.9, tempoFolgen: Bool = true, aktion: @escaping @MainActor () -> Void) -> some View {
        modifier(ComputerZugStil(aktiv: aktiv, id: id, verzoegerung: verzoegerung, tempoFolgen: tempoFolgen, aktion: aktion))
    }
    /// Spieltakt für Arcade-Spiele (siehe `ArcadeTaktStil`). Bei `aktiv == false` läuft die Uhr weiter, ruft aber nichts auf.
    func arcadeTakt(aktiv: Bool = true, _ schritt: @escaping (Double) -> Void) -> some View {
        modifier(ArcadeTaktStil(aktiv: aktiv, schritt: schritt))
    }
}
#endif
