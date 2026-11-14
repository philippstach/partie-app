// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Designwechsel (KlarGlas 2.17): kleine gemeinsame Teile der Designs Tinte und Salon. Beide arbeiten mit Zeilen und
// Linien statt Karten: Haarlinie unter jeder Zeile, starke Linie am Abschnittsanfang, Wörter mit Unterstrich statt
// Knopfflächen, Labels in gesperrten Großbuchstaben. In `klar` werden diese Teile nicht benutzt.

#if canImport(UIKit)

/// Waagerechte Linie zwischen Zeilen: fein (`linie`) oder stark (`linieStark`, Abschnittsanfang, Tabellenkopf).
public struct ZeilenLinie: View {
    var stark = false
    var staerke: CGFloat? = nil
    var farbe: Color? = nil

    public init(stark: Bool = false, staerke: CGFloat? = nil, farbe: Color? = nil) {
        self.stark = stark; self.staerke = staerke; self.farbe = farbe
    }

    public var body: some View {
        Rectangle().fill(farbe ?? (stark ? Color.linieStark : Color.linie))
            .frame(height: staerke ?? Design.werte.linienStaerke)
            .accessibilityHidden(true)
    }
}

public extension View {
    /// Linie an der Unterkante (Zeilen in Tinte und Salon).
    func linieUnten(stark: Bool = false, staerke: CGFloat? = nil, farbe: Color? = nil) -> some View {
        overlay(alignment: .bottom) { ZeilenLinie(stark: stark, staerke: staerke, farbe: farbe) }
    }

    /// Label-Rolle: SF 11 fett, Großbuchstaben, gesperrt (Tinte 0,12 em, Salon 0,14 em). In `klar` caption halbfett.
    func designLabel(_ farbe: Color? = nil) -> some View {
        font(Design.Schrift.label)
            .tracking(Design.Schrift.labelSperrung)
            .textCase(.uppercase)
            .foregroundStyle(farbe ?? Color.schriftZweit)
    }

    /// Wort mit Unterstrich (Tinte: Knöpfe als unterstrichene Wörter; aktiv 2 pt). Der Strich sitzt 3 pt unter der Schrift.
    func unterstrichen(_ staerke: CGFloat = 1, farbe: Color? = nil) -> some View {
        padding(.bottom, 3)
            .overlay(alignment: .bottom) { Rectangle().fill(farbe ?? Color.schrift).frame(height: staerke).accessibilityHidden(true) }
    }

    /// Fläche eines Spielfeld-Abschnitts: in „Klar & Glas“ Kartengrund mit Rundung `radius` (wie `.background(Color.kartenGrund, in: .rect(cornerRadius:))`),
    /// in Tinte und Salon keine Karte, nur eine Haarlinie unten (Zeilen auf Papier statt Kasten).
    func designFlaeche(_ radius: CGFloat) -> some View { modifier(DesignFlaecheStil(radius: radius)) }

    /// Farbblock (Salon): Fläche in einer Farbe mit der passenden Schrift als Vordergrund, ohne Rundung.
    func farbblock(_ flaeche: Color, schrift: Color) -> some View {
        foregroundStyle(schrift).background(flaeche)
    }
}

private struct DesignFlaecheStil: ViewModifier {
    let radius: CGFloat
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    func body(content: Content) -> some View {
        if art == .klar { content.background(Color.kartenGrund, in: .rect(cornerRadius: radius)) } else { content.linieUnten() }
    }
}

/// Pillenform der Tinte-Knöpfe als eigener Pfad (Rechteck mit Radius = halbe Höhe). `einzug` rückt die Form nach innen, damit ein Rand
/// der Stärke w mit `Pille(einzug: w / 2).stroke(…, lineWidth: w)` genau innerhalb der Fläche liegt.
/// (Die System-Kapsel zeichnete mit Rand in der Bildprobe kleine Striche an den Enden.)
struct Pille: Shape {
    var einzug: CGFloat = 0
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: einzug, dy: einzug)
        return Path(roundedRect: r, cornerRadius: max(0, r.height / 2), style: .circular)
    }
}

/// Zeile einer Liste in Tinte und Salon: Inhalt, Mindesthöhe, Haarlinie unten. Ersetzt dort die Karte.
public struct DesignZeile<Inhalt: View>: View {
    var hoehe: CGFloat = 50
    var linie = true
    let inhalt: Inhalt

    public init(hoehe: CGFloat = 50, linie: Bool = true, @ViewBuilder inhalt: () -> Inhalt) {
        self.hoehe = hoehe; self.linie = linie; self.inhalt = inhalt()
    }

    public var body: some View {
        inhalt
            .frame(maxWidth: .infinity, minHeight: hoehe, alignment: .leading)
            .overlay(alignment: .bottom) { if linie { ZeilenLinie() } }
            .contentShape(.rect)
    }
}

/// Formularzeile (Tinte, Salon): Label in Großbuchstaben links, Wert in Serifenschrift rechts.
public struct DesignWertZeile: View {
    let label: Text
    let wert: Text
    var hervorgehoben = false

    public init(label: Text, wert: Text, hervorgehoben: Bool = false) {
        self.label = label; self.wert = wert; self.hervorgehoben = hervorgehoben
    }

    public var body: some View {
        DesignZeile(hoehe: Design.ist(.salon) ? 44 : 48) {
            HStack(alignment: .firstTextBaseline, spacing: Design.Abstand.m) {
                label.designLabel().lineLimit(2)
                Spacer(minLength: 8)
                wert.font(Design.ist(.salon) ? Design.Schrift.serif(24, gewicht: .bold, relativ: .title2) : Design.Schrift.serif(20, relativ: .title3))
                    .monospacedDigit()
                    .foregroundStyle(hervorgehoben ? Color.accentText : Color.schrift)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Auswahlkreis (Radio) der Formularblätter in Tinte: 22 pt, 1,5-pt-Rand, gewählt mit gefülltem Kern.
struct AuswahlKreis: View {
    let gewaehlt: Bool
    var body: some View {
        Circle().strokeBorder(Color.linieStark, lineWidth: 1.5)
            .frame(width: 22, height: 22)
            .overlay { if gewaehlt { Circle().fill(Color.linieStark).padding(4) } }
            .accessibilityHidden(true)
    }
}

/// Schalter als Kästchen (Tinte: Varianten im Blatt „Neues Spiel“) bzw. als Rechteck mit Haken (Salon).
public struct KaestchenStil: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .center, spacing: Design.Abstand.m) {
                Rectangle().strokeBorder(Color.linieStark, lineWidth: Design.ist(.salon) ? 2 : 1.5)
                    .background(configuration.isOn && Design.ist(.salon) ? Color.linieStark : Color.clear)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Design.ist(.salon) ? Color.seitenGrund : Color.schrift)
                        }
                    }
                    .accessibilityHidden(true)
                configuration.label.frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Theme.tapSize)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // 2.36 N-003 (zweiter Anlauf): 2.34 setzte eine Bedienungshilfe-Darstellung (`accessibilityRepresentation` mit einem
        // System-Toggle). Am Gerät (Build 19, iPad mini, Tinte/Salon) kam daraus weiter eine CheckBox ohne Namen, der Text stand
        // als eigenes Element daneben. Jetzt ist der Knopf selbst das eine Element: Name aus dem Label-Text (das Kästchen ist
        // ausgeblendet), Merkmal „Schalter“ und „ausgewählt“, wenn er an ist. Keine neuen Texte.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}

#endif
