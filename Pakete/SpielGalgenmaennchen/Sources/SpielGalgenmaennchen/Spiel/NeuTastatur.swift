// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Tastatur von „Galgenmännchen“: Spalten und Tastenhöhe von außen, damit sie auf dem SE, dem Pro Max und dem iPad
/// den Rest des Bildschirms füllt. Treffer in der App-Farbe, Fehler blass und durchgestrichen.
struct NeuTastatur: View {
    let sprache: WordLanguage
    let geraten: [Character]
    let loesung: String
    var aktiv = true
    var spalten = 7
    var tastenHoehe: CGFloat = 48
    /// Im Lösen-Modus sind alle Tasten frei (es wird getippt, nicht geraten)
    var alleFrei = false
    let taste: (Character) -> Void

    private var reihen: [[Character]] {
        let schlicht = sprache.alphabet.filter(\.isASCII)
        let sonder = sprache.alphabet.filter { !$0.isASCII }
        var r = stride(from: 0, to: schlicht.count, by: spalten).map { Array(schlicht[$0 ..< min($0 + spalten, schlicht.count)]) }
        if !sonder.isEmpty { r.append(sonder) }
        return r
    }

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(reihen.enumerated()), id: \.offset) { _, reihe in
                HStack(spacing: 5) {
                    let links = (spalten - reihe.count) / 2, rechts = spalten - reihe.count - links
                    ForEach(0 ..< links, id: \.self) { _ in Color.clear.frame(maxWidth: .infinity).frame(height: 0) }
                    ForEach(reihe, id: \.self) { c in einTaste(c) }
                    ForEach(0 ..< rechts, id: \.self) { _ in Color.clear.frame(maxWidth: .infinity).frame(height: 0) }
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func zustand(_ c: Character) -> Zustand {
        guard !alleFrei, geraten.contains(c) else { return .frei }
        return loesung.contains(c) ? .treffer : .fehler
    }

    private enum Zustand { case frei, treffer, fehler }

    private func einTaste(_ c: Character) -> some View {
        let z = zustand(c)
        return Button { if z == .frei { taste(c) } } label: {
            Text(String(c))
                .font(.system(.title3, design: Design.zahlDesign, weight: .semibold))
                .strikethrough(z == .fehler)
                .foregroundStyle(z == .treffer ? AnyShapeStyle(Color.onAccent) : (z == .fehler ? AnyShapeStyle(Tisch.aktiv ? Tisch.hinweisLeise : Color.schriftBlass) : AnyShapeStyle(Tisch.aktiv ? Tisch.auge : Color.schrift)))   // Tinte: Elfenbein-Tasten auf dem Filz
                .frame(maxWidth: .infinity, minHeight: tastenHoehe)
                .background(z == .treffer ? AnyShapeStyle(Color.appFlaeche) : AnyShapeStyle(Design.ist(.klar) ? Color(.tertiarySystemFill) : (Tisch.aktiv ? (z == .fehler ? Color.white.opacity(0.10) : Tisch.elfenbein) : Color.feldGrund)), in: .rect(cornerRadius: Design.ist(.klar) ? 10 : Design.Ecke.klein))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(z == .frei && aktiv)
        .accessibilityLabel(String(c))
        .accessibilityValue(z == .treffer ? Text("Treffer") : z == .fehler ? Text("nicht im Wort") : Text(""))
        .accessibilityRemoveTraits(z == .frei ? [] : .isButton)
        .accessibilityIdentifier("galgen-neu-taste-\(c)")
    }
}
#endif
