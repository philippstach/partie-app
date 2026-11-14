// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

// Designwechsel: Die Startseite hat je Design einen eigenen Aufbau (`StartSeite.klar`, `StartTinte`, `StartSalon`),
// aber EINE Logik. `StartSeite` hält Zustand und Blätter und reicht den Aufbauten dieses Modell: dieselben Daten,
// dieselben Aktionen. Nichts geht verloren: Tagesaufgabe, Spieleabend, Statistik, Anpassen, Suche, Spieler,
// Einstellungen, Zufall und Glossar sind in allen drei Aufbauten erreichbar.

/// Wohin ein Start-Aufbau führen kann. `StartSeite.zeigen` öffnet das passende Blatt.
enum StartZiel {
    case einstellungen, spieler, statistik, suche, hinzufuegen, glossar, turnier, zufall
    /// Die Sammlung („Alle Spiele“), optional mit Filter und Spielerzahl vorbelegt.
    case sammlung(filter: SammlungStart.Filter = .alle, spielerzahl: Int = 0)
}

/// Daten und Aktionen der Startseite für die Aufbauten Tinte und Salon.
@MainActor
struct StartModell {
    let kacheln: [any SpielModul]
    let weiterspielen: [any SpielModul]
    let layout: StartLayout
    let bearbeiten: Binding<Bool>
    /// Tagesaufgabe sichtbar (nicht im Ruhe- oder Kinder-Modus und nicht ausgeschaltet).
    let tagesaufgabe: Bool
    let turnier: Turnier?
    let oeffnen: (String) -> Void
    /// „Weiterspielen“ (Kachel, Stapel, „Zuletzt“): öffnet gleich die laufende Partie statt der Spielseite. Ohne Angabe wie `oeffnen`.
    var weiter: ((String) -> Void)?
    let zeigen: (StartZiel) -> Void
    /// Alle offenen Partien für den Stapel der Tinte-Startseite (bis zu sechs, zuletzt gespielt zuerst, je Spiel eine).
    /// `weiterspielen` (drei) bleibt für die Liste „Zuletzt“ und für Klar und Salon, wie es ist. Leer: Der Stapel nimmt `weiterspielen`.
    var offen: [any SpielModul] = []

    func fortsetzen(_ id: String) { (weiter ?? oeffnen)(id) }

    /// Anzahl der sichtbaren Spiele je Spielart (für „Kapitel“ und die Kapitälchen-Zeile).
    func anzahl(_ g: Gattung) -> Int { SpielKatalog.sichtbar.filter { $0.gattung == g }.count }
    /// Spielarten mit mindestens einem sichtbaren Spiel, in der Reihenfolge der Listen.
    var spielarten: [Gattung] { SpielZeilen.spielarten.filter { anzahl($0) > 0 } }
}

/// Zeilen-Werkzeug beim Anpassen der Startseite (Tinte und Salon): entfernen, nach oben, nach unten.
struct StartAnpassenKnoepfe: View {
    let id: String
    let layout: StartLayout

    var body: some View {
        HStack(spacing: 0) {
            knopf("chevron.up", "Nach vorn") { layout.verschiebe(id, um: -1) }
            knopf("chevron.down", "Nach hinten") { layout.verschiebe(id, um: 1) }
            knopf("minus.circle", "Von der Startseite entfernen") { layout.entfernen(id) }
        }
    }

    private func knopf(_ symbol: String, _ titel: LocalizedStringKey, aktion: @escaping () -> Void) -> some View {
        Button { withAnimation { aktion() } } label: {
            Image(systemName: symbol).font(.body).foregroundStyle(Color.schrift)
                .frame(width: 40, height: Theme.tapSize).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(titel))
    }
}

/// Wörter, die umbrechen (Kapitälchen-Zeile des Salon-Starts): legt die Teile zeilenweise von links nach rechts.
struct UmbruchZeile: Layout {
    var abstand: CGFloat = 14
    var zeilenAbstand: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let breite = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, zeile: CGFloat = 0, maxBreite: CGFloat = 0
        for s in subviews {
            let g = s.sizeThatFits(.unspecified)
            if x > 0, x + g.width > breite { x = 0; y += zeile + zeilenAbstand; zeile = 0 }
            x += g.width + abstand; zeile = max(zeile, g.height); maxBreite = max(maxBreite, x - abstand)
        }
        return CGSize(width: breite.isFinite ? breite : maxBreite, height: y + zeile)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, zeile: CGFloat = 0
        for s in subviews {
            let g = s.sizeThatFits(.unspecified)
            if x > bounds.minX, x + g.width > bounds.maxX { x = bounds.minX; y += zeile + zeilenAbstand; zeile = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(g))
            x += g.width + abstand; zeile = max(zeile, g.height)
        }
    }
}

/// Fußleiste der Startseiten in Tinte und Salon: der Hauptknopf auf dem Seitengrund, darüber eine feine Linie.
/// Hängt per `safeAreaInset` unter der Rollansicht: Die Liste endet über der Leiste, nichts scheint hinter oder unter dem Knopf durch,
/// und die Leiste wächst mit großer Schrift mit (keine feste Reserve unter der Liste).
struct StartFuss: View {
    let titel: LocalizedStringKey
    /// Tinte auf dem iPad: der Knopf ist höchstens 440 pt breit und steht in der Mitte (Blatt 6). Salon und iPhone: wie bisher.
    var schmal = false
    let aktion: () -> Void

    var body: some View {
        Button(titel, action: aktion)
            .hauptKnopf()
            .padding(.horizontal, Theme.seitenRand).padding(.top, 10).padding(.bottom, 8)
            .frame(maxWidth: schmal ? 440 + 2 * Theme.seitenRand : Theme.wideColumnWidth).frame(maxWidth: .infinity)
            .background(Color.seitenGrund.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { ZeilenLinie() }
    }
}

/// Symbolkachel einer Zeile der Einstellungen. Klar: bunte Systemfarbe wie bisher. Tinte und Salon: Kachel in der Akzentrolle des Designs.
struct EinstellungsKachel: View {
    let symbol: String
    let farbe: Color

    var body: some View {
        let klar = Design.ist(.klar)
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(klar ? Color.white : Color.accentText)
            .frame(width: 28, height: 28)
            .background(klar ? farbe : Color.accentSoft, in: .rect(cornerRadius: klar ? 7 : Design.Ecke.klein))
    }
}
