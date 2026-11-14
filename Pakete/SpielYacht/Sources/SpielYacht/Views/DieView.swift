// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

struct DieView: View {
    enum State { case unknown, free, held }

    let value: Int
    let state: State
    var size: CGFloat = 58
    /// Tipp-Hilfe: dieser Würfel sollte gehalten werden (gestrichelter Rand, zusätzlich zur Beschriftung)
    var hinted = false
    /// Der Würfel liegt auf dem Farbband der Würfelzone (Salon): dann ohne feine Linie.
    var aufBand = false

    /// Mittelpunkte der Augen je Augenzahl: die eine Tabelle aus dem Kern.
    private static let pips = WuerfelFlaeche.punkte

    @Environment(\.designArt) private var art   // Designwechsel D.3

    /// Designwechsel D.3: Tinte und Salon zeichnen den Würfel des Designs (gemeinsam in SpieleKern); „Klar & Glas“ wie bisher.
    var body: some View {
        if WuerfelSatz.aktuell.bild(design: art) == .klar { klarKoerper } else { designKoerper }
    }

    private var designKoerper: some View {
        WuerfelFlaeche(augen: state == .unknown ? nil : value, gehalten: state == .held, groesse: size, aufBand: aufBand)
            .overlay {
                if hinted && state != .held {
                    RoundedRectangle(cornerRadius: WuerfelFlaeche.ecke(size)).strokeBorder(Color.appFlaeche, style: StrokeStyle(lineWidth: 2.5, dash: [5, 4])).padding(-3)   // design:spielinhalt (Markierung auf dem Spielmaterial)
                }
            }
            .overlay(alignment: .topTrailing) {
                if state == .held {
                    WuerfelSchloss(groesse: size).offset(x: size * 0.1, y: -size * 0.1)
                }
            }
    }

    private var klarKoerper: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22).fill(background)
            RoundedRectangle(cornerRadius: size * 0.22)
                .strokeBorder(border, lineWidth: state == .held ? 3 : 1.5)

            if state == .unknown {
                Image(systemName: "questionmark")
                    .font(.system(size: size * 0.35, weight: .semibold)) // design:spielinhalt
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(Array((Self.pips[value] ?? []).enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(state == .held ? Color.accentText : .primary)
                        .frame(width: size * 0.17, height: size * 0.17)
                        .position(x: p.x * size, y: p.y * size)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if hinted && state != .held {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .strokeBorder(Color.appFlaeche, style: StrokeStyle(lineWidth: 2.5, dash: [5, 4]))   // design:spielinhalt (Markierung auf dem Spielmaterial)
                    .padding(-3)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Zusätzlich zur Farbe ein Symbol, damit „gehalten“ nicht nur an der Farbe hängt
            if state == .held {
                Image(systemName: "lock.fill")
                    .font(.system(size: max(10, size * 0.18), weight: .bold)) // design:spielinhalt
                    .foregroundStyle(Color.accentText)
                    .padding(4)
            }
        }
    }

    private var background: Color {
        state == .held ? Color.appFlaeche.opacity(0.18) : Color(.tertiarySystemBackground)
    }

    private var border: Color {
        state == .held ? Color.appFlaeche : Color.primary.opacity(0.15)
    }
}

#Preview {
    HStack {
        DieView(value: 1, state: .free)
        DieView(value: 5, state: .held)
        DieView(value: 3, state: .unknown)
    }
    .padding()
}
