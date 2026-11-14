// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

// Design-Runde 3 (Leitbild „Spieltisch“): Der Tisch ist die eine Stelle für den Filzgrund und die Farben des Materials.
// Vorerst nur im Design „Tinte“. „Klar & Glas“ und „Salon“ bleiben, wie sie sind.

/// Feste Werte des Spieltischs: Filz, Elfenbein der Würfel, Schrift auf dem Filz.
public enum Tisch {
    /// Der Spieltisch gilt vorerst nur im Design „Tinte“.
    @MainActor public static var aktiv: Bool { Design.ist(.tinte) }

    /// Filz, wenn keine Spielart-Farbe bekannt ist (Violett der Würfelspiele).
    public static let violett = Color(hex: 0x5A4BB0)
    /// Helle Schrift und helles Material auf dem Filz.
    public static let elfenbein = Color(hex: 0xFFFDF6)
    /// Unterkante des hellen Würfels (leichter Verlauf, damit er nicht flach wirkt).
    public static let elfenbeinTief = Color(hex: 0xE6E1D2)
    /// Augen des hellen Würfels.
    public static let auge = Color(hex: 0x1D1B2E)
    /// Gehaltener Würfel: dunkel, damit er sich auf Papier und auf Filz abhebt.
    public static let dunkel = Color(hex: 0x2C2944)
    public static let dunkelTief = Color(hex: 0x19172B)
    /// Große Tinte-Runde, Punkt 11: Hinweise und Nebenzeilen auf dem Filz. Hell und gut lesbar statt blassgrau (`.secondary`, `schriftZweit`).
    public static let hinweis = Color(hex: 0xFFFDF6).opacity(0.86)
    /// Dritte Stufe auf dem Filz (Zähler, „Noch kein Zug“): ersetzt `.tertiary` und `schriftBlass`.
    public static let hinweisLeise = Color(hex: 0xFFFDF6).opacity(0.68)
}

private struct GeraeteSchemaKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

public extension EnvironmentValues {
    /// Hell oder dunkel, wie das Gerät eingestellt ist. Auf dem Filz ist `colorScheme` immer dunkel (`aufTisch()`); wer wissen muss,
    /// was am Gerät gilt (helles Rätselblatt nur bei hellem Gerät), liest diesen Wert. `nil` außerhalb des Spieltischs.
    var geraeteSchema: ColorScheme? {
        get { self[GeraeteSchemaKey.self] }
        set { self[GeraeteSchemaKey.self] = newValue }
    }
}

private struct TischFarbeKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

public extension EnvironmentValues {
    /// Spielart-Farbe des laufenden Spiels. Der `SpielRahmen` setzt sie, `TischGrund` färbt damit den Filz.
    var tischFarbe: Color? {
        get { self[TischFarbeKey.self] }
        set { self[TischFarbeKey.self] = newValue }
    }
}

/// Filzgrund des Spieltischs: Spielart-Farbe, abgedunkelt, mit einem Lichtfleck oben und dunklerem Rand unten.
/// Ohne Farbe nimmt er die Spielart-Farbe aus der Umgebung, sonst Violett.
public struct TischGrund: View {
    let farbe: Color?
    @Environment(\.tischFarbe) private var umgebungsFarbe

    public init(_ farbe: Color? = nil) { self.farbe = farbe }

    public var body: some View {
        let grund: Color = farbe ?? umgebungsFarbe ?? Tisch.violett
        ZStack {
            grund
            Color.black.opacity(0.40)
            RadialGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0)],
                           center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: 420)
            LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.30)], startPoint: .center, endPoint: .bottom)
        }
        .accessibilityHidden(true)
    }
}

private struct AufTisch: ViewModifier {
    @Environment(\.colorScheme) private var schema
    @Environment(\.geraeteSchema) private var aussen   // schon auf dem Filz (Übergabeseite im Spiel): der äußere Wert gilt
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    func body(content: Content) -> some View {
        let tisch = art == .tinte
        content
            // Große Tinte-Runde, Punkt 5: „Gerät weitergeben“ als ganze Filzseite über dem Spiel, sobald eine `SichtschutzKarte` sichtbar ist
            .overlayPreferenceValue(SichtschutzWunschKey.self) { wunsch in
                Group { if tisch, let wunsch { SichtschutzSeite(name: wunsch.name, farbe: wunsch.farbe, aufdecken: wunsch.aufdecken) } }
            }
            .background {
                Group {
                    if tisch { TischGrund() } else { Color.seitenGrund }
                }
                .ignoresSafeArea()
            }
            // Auf dem dunklen Filz gelten die dunklen Farbwerte, auch wenn das Gerät hell eingestellt ist (sonst dunkle Schrift auf Filz).
            .environment(\.colorScheme, tisch ? .dark : schema)
            .environment(\.geraeteSchema, aussen ?? schema)
            // Statusleiste (Uhr, Akku): Sie richtet sich nach dem Farbschema der Präsentation, nicht nach `\.colorScheme` darunter. Ohne diese Zeile
            // blieb sie auf hellen Geräten dunkel auf dem dunklen Filz (Zehntausend, Mäxchen, Minensuche; bei sehr dunklem Filz wählt das System hell von selbst).
            .preferredColorScheme(tisch ? .dark : nil)
            // AUS-008 (zweiter Anlauf): Auf dem iPad kam die Präsentationsvorgabe oben nicht bis zur Statusleiste (schwarze Uhr auf dunklem
            // Tisch). Nur die Leiste wird hell, solange der Tisch sichtbar ist; kein Farbschema des Fensters (`StatusLeiste.swift`).
            .statusLeisteHell(tisch)
    }
}

/// Große Tinte-Runde, Punkt 11 und 4: Hinweiszeile auf dem Filz. Hell, höchstens `zeilen` Zeilen, wächst bei großer Schrift nur begrenzt,
/// damit Würfel, Karten und Knöpfe Vorrang behalten. In den anderen Designs bleibt die Zeile, wie sie war.
private struct TischHinweis: ViewModifier {
    let zeilen: Int
    let sonst: Color?
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    func body(content: Content) -> some View {
        let tinte = art == .tinte
        // Klar und Salon bleiben, wie sie waren: `.secondary`, oder die Farbe, die vorher dort stand (`sonst`)
        let farbe: AnyShapeStyle = tinte ? AnyShapeStyle(Tisch.hinweis) : (sonst.map { AnyShapeStyle($0) } ?? AnyShapeStyle(HierarchicalShapeStyle.secondary))
        content
            .foregroundStyle(farbe)
            .lineLimit(tinte ? zeilen : nil)
            .minimumScaleFactor(tinte ? 0.8 : 1)
            .dynamicTypeSize(...(tinte ? DynamicTypeSize.accessibility1 : DynamicTypeSize.accessibility5))
    }
}

/// Große Tinte-Runde, Punkt 10: Aktion unten im Spiel als runder Knopf auf dem Filz (helle Schrift, zarte helle Fläche, feiner Rand).
/// Bricht nie um; bei großer Schrift wächst er begrenzt und verkleinert notfalls die Schrift.
public struct TischKnopfStil: ButtonStyle {
    @Environment(\.isEnabled) private var aktiv

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Tisch.elfenbein)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .frame(minHeight: Theme.tapSize)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.26 : 0.14)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.24), lineWidth: 1))
            .opacity(aktiv ? 1 : 0.45)
            .contentShape(.capsule)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

/// Blatt über dem Spieltisch: Auf dem Filz ist das Farbschema immer dunkel (`aufTisch()`), und ein Blatt erbt das. Das Blatt selbst hat aber den
/// Grund des Geräts (in Tinte hell ein helles Blatt) – Schrift und Knöpfe waren dann fast weiß auf Weiß. Mit diesem Modifier folgt das Blatt dem
/// Gerät. Auf das Innere des Blatts setzen (am Ende der Modifier-Kette des Blatt-Inhalts). Außerhalb des Spieltischs ohne Wirkung.
private struct BlattSchema: ViewModifier {
    @Environment(\.geraeteSchema) private var geraet

    func body(content: Content) -> some View {
        content.preferredColorScheme(geraet)
    }
}

private struct TischNebenKnopf: ViewModifier {
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    @ViewBuilder func body(content: Content) -> some View {
        if art == .tinte { content.buttonStyle(TischKnopfStil()) } else { content.nebenKnopf() }
    }
}

/// Große Tinte-Runde, Punkt 9 (Philipp: „Ja, aber nur bei hell“): Rätsel liegen als helles Blatt auf dem Filz, wie Karten und Würfel.
/// Nur in „Tinte“ und nur, wenn das Gerät hell eingestellt ist. Dann gelten im Blatt die hellen Farbwerte (dunkle Schrift auf Papier).
/// Bei dunklem Gerät und in den anderen Designs bleibt der Inhalt, wie er ist.
private struct RaetselBlatt: ViewModifier {
    let radius: CGFloat
    let innen: CGFloat
    @Environment(\.colorScheme) private var schema
    @Environment(\.geraeteSchema) private var geraet
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    func body(content: Content) -> some View {
        let hell = art == .tinte && geraet == .light
        content
            .padding(hell ? innen : 0)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(hell ? Tisch.elfenbein : Color.clear))
            .environment(\.colorScheme, hell ? .light : schema)
    }
}

private struct TischKarte: ViewModifier {
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    @ViewBuilder func body(content: Content) -> some View {
        if art == .tinte {
            content
                .padding(Theme.innen)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.10)))
        } else {
            content.card()
        }
    }
}

private struct TischFlaeche: ViewModifier {
    let radius: CGFloat
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    @ViewBuilder func body(content: Content) -> some View {
        if art == .tinte {
            content.background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color.white.opacity(0.10)))
        } else {
            content.designFlaeche(radius)
        }
    }
}

private struct TischLeiste: ViewModifier {
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    @ViewBuilder func body(content: Content) -> some View {
        if art == .tinte {
            // Auf dem Filz keine eigene Fläche (sonst ein dunkler Streifen), nur eine feine helle Linie an der Oberkante
            content.overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1).accessibilityHidden(true) }
        } else {
            content.glasLeiste()
        }
    }
}

public extension View {
    /// Legt die Spielansicht auf den Spieltisch: in „Tinte“ Filz bis in die Ecken des Bildschirms und helle Schrift,
    /// in den anderen Designs der Seitengrund wie bisher. Ersetzt `.background(Color.seitenGrund)` der Spielansicht.
    /// Reihenfolge: `aufTisch()` steht NACH `.safeAreaInset(edge: .bottom) { … }` der Spielansicht. Nur dann liegt auch die untere
    /// Leiste auf dem Filz und bekommt die helle Schrift; davor gesetzt, bleibt die Leiste außerhalb (dunkle Schrift, Seitengrund).
    func aufTisch() -> some View { modifier(AufTisch()) }

    /// Untere Leiste auf dem Spieltisch: in „Tinte“ ohne eigene Fläche, nur eine feine helle Linie oben; sonst genau `glasLeiste()`.
    /// Ersetzt `.glasLeiste()` und `BottomBar(glas: true)` (dann `BottomBar { … }.tischLeiste()`) in Spielansichten auf dem Filz.
    func tischLeiste() -> some View { modifier(TischLeiste()) }

    /// Karte auf dem Spieltisch: in „Tinte“ eine runde, leicht aufgehellte Fläche auf dem Filz (Ecke 16, Innenabstand wie `card()`),
    /// in den anderen Designs genau `card()`. Für Flächen in Spielansichten, die mit `aufTisch()` auf dem Filz liegen.
    func spielTischKarte() -> some View { modifier(TischKarte()) }   // Integrator: Name ≠ KlarGlas.tischKarte (Startseite), sonst mehrdeutig in jedem Spiel

    /// Fläche auf dem Spieltisch ohne eigenen Innenabstand: in „Tinte“ runde, leicht aufgehellte Fläche (Weiß 10 %, Ecke `radius`),
    /// in den anderen Designs genau `designFlaeche(radius)`. Ersetzt `.designFlaeche(…)` in Spielansichten auf dem Filz.
    func tischFlaeche(_ radius: CGFloat) -> some View { modifier(TischFlaeche(radius: radius)) }

    /// Hinweiszeile auf dem Filz (Punkt 11 und 4): in „Tinte“ hell und höchstens `zeilen` Zeilen. Klar und Salon bleiben unverändert.
    /// Ersetzt `.foregroundStyle(.secondary)` an Hinweisen in Spielansichten auf dem Filz. Stand dort vorher eine andere Farbe,
    /// sie als `sonst` mitgeben: `.tischHinweis(sonst: Color.schriftZweit)`. Ans Ende der Modifier-Kette der Zeile setzen, dann gelten
    /// Zeilengrenzen, die dort schon stehen, in allen Designs weiter.
    func tischHinweis(zeilen: Int = 2, sonst: Color? = nil) -> some View { modifier(TischHinweis(zeilen: zeilen, sonst: sonst)) }

    /// Blatt über dem Spieltisch hell oder dunkel wie das Gerät (siehe `BlattSchema`). Für jedes Blatt mit eigenem Hintergrund, das ein Spiel auf dem Filz öffnet.
    func blattSchema() -> some View { modifier(BlattSchema()) }

    /// Nebenknopf unten im Spiel (Punkt 10): in „Tinte“ ein runder Knopf auf dem Filz, sonst genau `nebenKnopf()`.
    /// Ersetzt `.nebenKnopf()` in Spielansichten, die mit `aufTisch()` auf dem Filz liegen. Nur für `Button` und `Menu`.
    func tischNebenKnopf() -> some View { modifier(TischNebenKnopf()) }

    /// Rätsel als helles Blatt auf dem Filz (Punkt 9): nur in „Tinte“ bei hellem Gerät, sonst unverändert.
    /// Auf das Gitter des Rätsels setzen (nicht auf die ganze Spielansicht). `innen` ist der Rand des Blatts um das Gitter.
    func raetselBlatt(_ radius: CGFloat = 14, innen: CGFloat = 8) -> some View { modifier(RaetselBlatt(radius: radius, innen: innen)) }
}

/// Blatt 23 (FS-K): Abschnittstitel auf dem Filz statt `SectionLabel`. In Tinte hell: Großbuchstaben, 11,5 pt halbfett, gesperrt,
/// Elfenbein 78 %, darunter mit 8 pt Abstand eine helle Linie (1 pt) über die ganze Breite. In Klar und Salon genau `SectionLabel`.
/// Nicht syntaxgeprüft (Cloud-Chat).
public struct TischUeberschrift: View {
    let text: Text
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    public init(_ titel: LocalizedStringKey) { text = Text(titel) }
    /// Für Namen und andere Texte, die nicht übersetzt werden.
    public init(verbatim titel: String) { text = Text(verbatim: titel) }

    public var body: some View {
        if art == .tinte {
            VStack(alignment: .leading, spacing: 8) {
                text
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Tisch.elfenbein.opacity(0.78))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Rectangle().fill(Tisch.elfenbein).frame(height: 1)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        } else {
            SectionLabel(text: text)
        }
    }
}
#endif
