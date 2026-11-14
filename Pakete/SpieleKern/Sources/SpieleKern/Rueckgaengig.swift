// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation

/// F2: Einheitliches „Rückgängig“ für Rätsel. Merkt sich jeden früheren Spielstand (bis `grenze`); ein Tipp auf „Rückgängig“ stellt den letzten wieder her.
/// Nutzung im Spiel: `@State private var undo = RueckgaengigVerlauf<Modell>()`, `.rueckgaengigMerken(spiel, in: undo)` an die Spielansicht,
/// im Menü `Button("Rückgängig", systemImage: "arrow.uturn.backward") { undo.zurueck(&spiel) }.disabled(!undo.kann)`, und `undo.leeren()` beim Neubeginn.
@Observable @MainActor
public final class RueckgaengigVerlauf<Z: Equatable> {
    private var stapel: [Z] = []
    private var ueberspringen = false
    private let grenze: Int
    public var kann: Bool { !stapel.isEmpty }
    public init(grenze: Int = 500) { self.grenze = grenze }

    /// Neubeginn: Verlauf löschen; die nächste Zustandsänderung (das neue Spiel selbst) wird nicht gemerkt.
    public func leeren() { stapel.removeAll(); ueberspringen = true }

    public func merke(alt: Z) {
        if ueberspringen { ueberspringen = false; return }
        stapel.append(alt)
        if stapel.count > grenze { stapel.removeFirst() }
    }

    /// Stellt den letzten Stand wieder her. Gibt `false` zurück, wenn nichts mehr da ist.
    @discardableResult
    public func zurueck(_ zustand: inout Z) -> Bool {
        guard let letzter = stapel.popLast() else { return false }
        ueberspringen = true
        zustand = letzter
        return true
    }
}

#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Merkt jeden früheren Stand von `zustand` im Verlauf.
    func rueckgaengigMerken<Z: Equatable>(_ zustand: Z, in verlauf: RueckgaengigVerlauf<Z>) -> some View {
        onChange(of: zustand) { alt, _ in verlauf.merke(alt: alt) }
    }
}
#endif
