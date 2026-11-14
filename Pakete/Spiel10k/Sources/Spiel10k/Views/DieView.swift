// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei (Würfel sind Spielinhalt, DESIGN.md 3.6)
import SwiftUI
import KlarGlas
import SpieleKern

struct DieView: View {
    enum State { case unknown, free, selected, locked }

    let value: Int
    let state: State
    /// Tipp-Markierung („beste Auswahl“) – nur Hinweis, keine Auswahl
    var hinted = false
    var size: CGFloat = 58

    /// Mittelpunkte der Augen je Augenzahl: die eine Tabelle aus dem Kern.
    private static let pips = WuerfelFlaeche.punkte

    @Environment(\.designArt) private var art   // Designwechsel D.3

    /// Designwechsel D.3: Tinte und Salon zeichnen den Würfel des Designs (gemeinsam in SpieleKern); „Klar & Glas“ wie bisher.
    var body: some View {
        if WuerfelSatz.aktuell.bild(design: art) == .klar { klarKoerper } else { designKoerper }
    }

    private var designKoerper: some View {
        WuerfelFlaeche(augen: state == .unknown ? nil : value, gehalten: state == .selected, groesse: size)
            .overlay {
                if hinted {
                    RoundedRectangle(cornerRadius: WuerfelFlaeche.ecke(size)).strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [5, 4])).padding(-4)   // design:spielinhalt (Markierung auf dem Spielmaterial)
                }
            }
            .opacity(state == .locked ? 0.45 : 1)
            .overlay(alignment: .topTrailing) {
                if state == .locked {
                    WuerfelSchloss(groesse: size).offset(x: size * 0.1, y: -size * 0.1)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityText)
    }

    private var klarKoerper: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(background)
            RoundedRectangle(cornerRadius: size * 0.22)
                .strokeBorder(border, lineWidth: state == .selected ? 3 : 1.5)

            if state == .unknown {
                Image(systemName: "questionmark")
                    .font(.system(size: size * 0.35, weight: .semibold))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .foregroundStyle(.secondary)   // M-020: Platzhalter „?“ in dunkel besser lesbar
            } else {
                ForEach(Array((Self.pips[value] ?? []).enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(pipColor)
                        .frame(width: size * 0.17, height: size * 0.17)
                        .position(x: p.x * size, y: p.y * size)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if hinted {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))   // design:spielinhalt (Markierung auf dem Spielmaterial)
                    .padding(-4)
            }
        }
        .opacity(state == .locked ? 0.45 : 1)
        .overlay(alignment: .topTrailing) {
            if state == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: max(10, size * 0.16), weight: .bold))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .foregroundStyle(.secondary)
                    .padding(5)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var background: Color {
        switch state {
        case .selected: .accentColor.opacity(0.18)
        default: Color(.tertiarySystemBackground)
        }
    }

    private var border: Color {
        switch state {
        case .selected: .accentColor
        default: Color.primary.opacity(0.15)
        }
    }

    private var pipColor: Color { state == .selected ? .accentColor : .primary }

    private var accessibilityText: String {
        switch state {
        case .unknown: String(localized: "Noch nicht gewürfelt")
        case .free: hinted ? String(localized: "Würfel \(value), Tipp") : String(localized: "Würfel \(value)")
        case .selected: String(localized: "Würfel \(value), ausgewählt")
        case .locked: String(localized: "Würfel \(value), rausgelegt")
        }
    }
}

#Preview {
    HStack {
        DieView(value: 1, state: .free)
        DieView(value: 5, state: .selected)
        DieView(value: 6, state: .locked)
        DieView(value: 3, state: .unknown)
    }
    .padding()
}
