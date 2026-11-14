// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import ArcadeKern
import KlarGlas

public extension View {
    /// Speichern und Fortsetzen für Arcade-Spiele: Eine laufende Partie wird gesichert, sobald die App inaktiv wird oder in den Hintergrund geht
    /// (beim bewussten Beenden über die Rückfrage merkt der Rahmen sich das in `SpielStand.verworfen`). Beim Ende wird der Stand gelöscht. Beim Fortsetzen startet die `ArcadeHuelle` in der Pause.
    /// Das Spiel lädt den Stand selbst (`ArcadeStand.laden`) in seinem `init`.
    func arcadeStand<T: Codable>(_ spiel: String, phase: ArcadePhase, zustand: @escaping () -> T) -> some View {
        modifier(ArcadeStandModifier(spiel: spiel, phase: phase, zustand: zustand))
    }
}

/// Lesen des gesicherten Stands mit Stimmigkeitsprüfung: Eine laufende Partie, sonst `nil` (dann beginnt das Spiel frisch).
public enum ArcadeStand {
    public static func laden<T: Codable>(_ typ: T.Type, spiel: String, phase: (T) -> ArcadePhase) -> T? {
        guard let z = SpielStand.laden(T.self, spiel: spiel) else { return nil }
        guard phase(z).laeuft else { SpielStand.loeschen(spiel); return nil }
        return z
    }
}

struct ArcadeStandModifier<T: Codable>: ViewModifier {
    let spiel: String
    let phase: ArcadePhase
    let zustand: () -> T
    @Environment(\.scenePhase) private var szene

    func body(content: Content) -> some View {
        content
            .onChange(of: szene) { _, s in if s != .active { sichern() } }
            .onDisappear { SpielStand.sichernBeimVerlassen(zustand(), spiel: spiel, laeuft: phase.laeuft) }   // auch beim Wegwischen der Ansicht
            .onChange(of: phase) { _, p in if p.istVorbei { SpielStand.loeschen(spiel) } }
    }

    private func sichern() {
        if phase.laeuft { SpielStand.sichern(zustand(), spiel: spiel) }
    }
}
#endif

#if canImport(UIKit)
import SwiftUI

/// Auswahl „Leicht / Mittel / Schwer“ vor dem Start eines Arcade-Spiels ohne Computergegner; merkt sich die Wahl je Spiel.
public struct ArcadeStufeWahl: View {
    let spiel: String
    @State private var stufe: Int
    let wechseln: (Int) -> Void

    public init(spiel: String, stufe: Int, wechseln: @escaping (Int) -> Void) {
        self.spiel = spiel; self.wechseln = wechseln; _stufe = State(initialValue: stufe)
    }

    public var body: some View {
        Picker("Schwierigkeit", selection: $stufe) {
            Text("Leicht").tag(1)
            Text("Mittel").tag(2)
            Text("Schwer").tag(3)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.seitenRand)
        .onChange(of: stufe) { _, neu in
            ComputerStufe(rawValue: neu)?.sichern(spiel)
            wechseln(neu)
        }
    }
}
#endif
