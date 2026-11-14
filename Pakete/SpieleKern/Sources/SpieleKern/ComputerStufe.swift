// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(UIKit)
import SwiftUI
#endif

/// Stärke des Computergegners (gemeinsamer Baustein). Die Suchtiefe o. Ä. bleibt Sache des jeweiligen Spiels.
public enum ComputerStufe: Int, CaseIterable, Sendable, Identifiable {
    case leicht = 1, mittel, schwer
    public var id: Int { rawValue }

    private static func schluessel(_ spiel: String) -> String { "partie.stufe.\(spiel)" }

    /// Zuletzt gewählte Stufe dieses Spiels (Standard: mittel).
    public static func gespeichert(_ spiel: String, standard: ComputerStufe = .mittel) -> ComputerStufe {
        ComputerStufe(rawValue: UserDefaults.standard.integer(forKey: schluessel(spiel))) ?? standard
    }
    public func sichern(_ spiel: String) { UserDefaults.standard.set(rawValue, forKey: Self.schluessel(spiel)) }
}

#if canImport(UIKit)
/// Auswahl „Stärke des Computers“ (Leicht/Mittel/Schwer); merkt sich die Wahl je Spiel.
public struct ComputerStufePicker: View {
    let spiel: String
    @Binding var stufe: ComputerStufe

    public init(spiel: String, stufe: Binding<ComputerStufe>) { self.spiel = spiel; self._stufe = stufe }

    public var body: some View {
        Picker("Stärke des Computers", selection: $stufe) {
            Text("Leicht").tag(ComputerStufe.leicht)
            Text("Mittel").tag(ComputerStufe.mittel)
            Text("Schwer").tag(ComputerStufe.schwer)
        }
        .onChange(of: stufe) { _, neu in neu.sichern(spiel) }
    }
}
#endif
