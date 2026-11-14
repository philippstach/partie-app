// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Würfelhäute (Spielmaterial, wählbar); kein Gold-Ton mehr
import SwiftUI
import KlarGlas
import SpieleKern

private struct WuerfelStilKey: EnvironmentKey {
    static let defaultValue = WuerfelStil.klassisch
}

extension EnvironmentValues {
    var wuerfelStil: WuerfelStil {
        get { self[WuerfelStilKey.self] }
        set { self[WuerfelStilKey.self] = newValue }
    }
}

private func dyn(_ hell: UInt32, _ dunkel: UInt32) -> Color {
    func ui(_ h: UInt32) -> UIColor {
        UIColor(red: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
    }
    return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? ui(dunkel) : ui(hell) })
}

/// Farben der Würfel-Stile (DESIGN „F9 Würfel-Stile“).
extension WuerfelStil {
    var flaeche: Color {
        switch self {
        case .klassisch: dyn(0xFFFFFF, 0x2C2C2E)
        case .gold: dyn(0xA37A1A, 0xC9A54E)
        case .nacht: dyn(0x2A2A2C, 0x1C1C1E)
        case .elfenbein: dyn(0xF3EAD3, 0xD8CBA8)
        }
    }

    var augen: Color {
        switch self {
        case .klassisch: .primary
        case .gold: dyn(0xFFF8E6, 0xFFF8E6)
        case .nacht: dyn(0xC0987C, 0xC0987C)   // warmes Braun (Familienfarbe Braun, Text dunkel) statt Gold
        case .elfenbein: dyn(0x5A4220, 0x5A4220)
        }
    }

    /// nil = kein Rand
    var rand: Color? {
        switch self {
        case .klassisch: Color.primary.opacity(0.15)
        case .gold: nil
        case .nacht: dyn(0x4A3A1C, 0x4A3A1C)
        case .elfenbein: dyn(0xE2D5B4, 0xE2D5B4)
        }
    }

    var name: LocalizedStringKey {
        switch self {
        case .klassisch: "Klassisch"
        case .gold: "Gold"
        case .nacht: "Nacht"
        case .elfenbein: "Elfenbein"
        }
    }
}

/// Würfel mit Augen. `draussen`: herausgelegt (goldener Rand, Schloss). `umgedreht`: eine zur Eins gedrehte Sechs.
struct DieView: View {
    enum Zustand { case unbekannt, frei, gewaehlt, draussen }

    @Environment(\.wuerfelStil) private var stil
    let wert: Int
    var zustand: Zustand = .frei
    var umgedreht = false
    var size: CGFloat = 64

    /// Mittelpunkte der Augen je Augenzahl: die eine Tabelle aus dem Kern.
    private static let augen = WuerfelFlaeche.punkte

    private var markiert: Bool { zustand == .draussen || zustand == .gewaehlt }

    /// Herausgelegte Würfel behalten in jedem Stil den goldenen Rand; beim Stil Gold ist er `onAccent`.
    private var markierung: Color { stil == .gold ? Color.onAccent : Color.accentColor }

    @Environment(\.designArt) private var art   // Designwechsel D.3

    /// Designwechsel D.3: Tinte und Salon zeichnen den Würfel des Designs (gemeinsam in SpieleKern), solange der Würfel-Stil „klassisch“ gewählt ist
    /// (die anderen Stile sind eine bewusste Wahl des Nutzers und bleiben). „Klar & Glas“ wie bisher.
    var body: some View {
        if WuerfelSatz.aktuell.bild(design: art) == .klar || stil != .klassisch { klarKoerper } else { designKoerper }
    }

    private var designKoerper: some View {
        WuerfelFlaeche(augen: zustand == .unbekannt ? nil : wert, gehalten: markiert, groesse: size)
            .overlay(alignment: .bottomTrailing) {
                if zustand == .draussen {
                    WuerfelSchloss(groesse: size).offset(x: size * 0.1, y: size * 0.1)
                }
            }
            .overlay(alignment: .topTrailing) {
                if umgedreht {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill").font(.system(size: max(14, size * 0.28)))
                        .foregroundStyle(Color.appFlaeche, Color.seitenGrund).offset(x: 4, y: -4)
                }
            }
    }

    private var klarKoerper: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18).fill(stil.flaeche)
            if markiert {
                RoundedRectangle(cornerRadius: size * 0.18).strokeBorder(markierung, lineWidth: 2)
            } else if let rand = stil.rand {
                RoundedRectangle(cornerRadius: size * 0.18).strokeBorder(rand, lineWidth: 1.5)
            }
            if zustand == .unbekannt {
                Image(systemName: "questionmark")
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(stil.augen.opacity(0.4))
            } else {
                ForEach(Array((Self.augen[wert] ?? []).enumerated()), id: \.offset) { _, p in
                    Circle().fill(stil.augen)
                        .frame(width: size * 0.17, height: size * 0.17)
                        .position(x: p.x * size, y: p.y * size)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            if zustand == .draussen {
                Image(systemName: "lock.fill")
                    .font(.system(size: max(10, size * 0.18), weight: .bold))
                    .foregroundStyle(markierung)
                    .padding(4)
            }
        }
        .overlay(alignment: .topTrailing) {
            if umgedreht {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: max(14, size * 0.28)))
                    .foregroundStyle(Color.accentColor, stil.flaeche)
                    .offset(x: 4, y: -4)
            }
        }
    }
}

/// Ein Deckel: flache goldene Scheibe mit dezentem Innenring, ohne Aufdruck.
struct DeckelView: View {
    var size: CGFloat = 22

    var body: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.85))
            .overlay(Circle().inset(by: size * 0.18).strokeBorder(Color.onAccent.opacity(0.4), lineWidth: 1))
            .overlay(Circle().strokeBorder(Color.onAccent.opacity(0.85), lineWidth: 1.2))   // Fund 13: heller Rand, damit der Stock auf lila Tisch lesbar bleibt
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Deckel eines Spielers: bis 6 überlappend, ab 7 eine Scheibe mit Zahl.
struct DeckelReihe: View {
    let anzahl: Int

    var body: some View {
        Group {
            if anzahl == 0 {
                Text("–").foregroundStyle(.tertiary)
            } else if anzahl <= 6 {
                HStack(spacing: -7) {
                    ForEach(0..<anzahl, id: \.self) { _ in DeckelView(size: 18).transition(.scale.combined(with: .opacity)) }
                }
            } else {
                HStack(spacing: 4) {
                    DeckelView(size: 18)
                    Text("× \(anzahl)").font(.subheadline.weight(.semibold).monospacedDigit())
                }
            }
        }
        .animation(.spring(duration: 0.35), value: anzahl)
    }
}

/// Der Stock als lockerer Stapel. Die Höhe ist genau die des Stapels (Deckel 22 pt + 2,2 pt je weiterer Deckel), und der Stapel ist darin
/// mittig gesetzt. Vorher stand der unterste Deckel mittig im Rahmen und der Stapel wuchs nach oben aus ihm heraus (KI-002).
struct StockView: View {
    let anzahl: Int

    var body: some View {
        let n = min(anzahl, 12)
        let hub: CGFloat = 2.2
        let anstieg = CGFloat(max(n - 1, 0)) * hub
        ZStack {
            ForEach(0..<n, id: \.self) { i in
                DeckelView(size: 22)
                    .offset(x: CGFloat((i * 7) % 5 - 2) * 3, y: CGFloat(-i) * hub + anstieg / 2)
            }
        }
        .frame(width: 44, height: 22 + anstieg)
        .animation(.spring(duration: 0.35), value: anzahl)
    }
}
