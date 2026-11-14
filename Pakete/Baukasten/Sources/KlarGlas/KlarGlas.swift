// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – gemeinsamer Designkern aller Spiele (Paket `KlarGlas`, Design-Konzept 3.2, Handbuch ~/Claude/App/DESIGN.md).
// Die App-Farbe steckt NICHT hier, sondern im Asset „AccentColor“ (+ „AccentText“) der App. Alles hier nutzt `Color.appFlaeche`.
// Spiel-spezifische Farben (Spielersteine, Zellen …) gehören in die jeweilige App (`// design:spielinhalt-datei`), nicht ins Paket.
// Die Ansichten gibt es nur für iOS (`canImport(UIKit)`); die Logik (Theme-Werte, Gruß, Zeitformat, Serie, Speicher) baut auch
// auf dem Mac, damit `swift test` ohne Simulator läuft.

/// Das Paket selbst. `version` steht auf jedem Prüfbogen; `tor.sh` meldet Apps, die eine ältere Fassung eingebunden haben.
public enum KlarGlas {
    /// Fassung des Design-Pakets. Erhöhen bei jeder Änderung, Eintrag in `KLARGLAS-VERSIONEN.md` (was ist neu, wer muss nachziehen).
    public static let version = "2.51"
}

public enum Theme {
    // Alle Werte kommen aus `Design` (Design.swift) – dort ändern, nicht hier.
    /// Mindest-Tippfläche nach Apple-Richtlinie
    public static var tapSize: CGFloat { Design.Masse.tippflaeche }
    public static var wideColumnWidth: CGFloat { Design.Masse.breiteSpalte }

    // Radien (CI-Handbuch, DESIGN.md Teil A.4)
    public static var cardRadius: CGFloat { Design.Ecke.karte }
    public static var leistenRadius: CGFloat { Design.Ecke.leiste }
    public static var sheetRadius: CGFloat { Design.Ecke.sheet }
    public static var feldRadius: CGFloat { Design.Ecke.feld }   // Ziffernfelder, Kacheln, Würfel

    // Abstände (4-pt-Raster)
    public static var seitenRand: CGFloat { Design.Abstand.seite }
    public static var kartenAbstand: CGFloat { Design.Abstand.m }
    public static var innen: CGFloat { Design.Abstand.l }
    public static var rundKnopf: CGFloat { Design.Masse.rundKnopf }
    public static var rundKnopfKlein: CGFloat { Design.Masse.rundKnopfKlein }
    public static var hauptKnopfHoehe: CGFloat { Design.Masse.hauptKnopfHoehe }
    public static var titelGroesse: CGFloat { Design.Schrift.titel }
    /// Zähler-Chip unter dem Spielkopf (`StatusChip`)
    public static var chipHoehe: CGFloat { Design.Masse.chipHoehe }
    /// Innenrand der `SpielfeldKarte`
    public static let spielfeldRand: CGFloat = 6
}

/// Einhängepunkte für Apps mit wählbarer App-Farbe (Baukasten `AkzentSpeicher`), ohne dass das Paket den Baukasten kennt.
public enum KlarGlasHaken {
    /// Liefert die App-Farbe als Text, wenn sie vom Asset abweichen soll (z. B. wählbare App-Farbe). Beim App-Start setzen.
    public nonisolated(unsafe) static var accentText: (() -> Color)? = nil
    /// Liefert die gewählte App-Farbe als **Fläche**, nil = Voreinstellung (Asset). `Color.accentColor` folgt einer gewählten Farbe
    /// nicht (nur `.tint`), deshalb zeichnen alle Flächen mit `Color.appFlaeche`. Beim App-Start setzen.
    public nonisolated(unsafe) static var flaeche: (() -> Color?)? = nil
    /// Designwechsel (2.17): Spielart des gerade offenen Spiels, nil = Hülle. Daraus lesen die Bausteine in Tinte und Salon
    /// die Spielart-Farben (Knopf im Spiel, Farbblock, Punkt). Beim App-Start setzen.
    public nonisolated(unsafe) static var spielart: (() -> Design.Spielart?)? = nil
    /// Designwechsel (2.17): wird nach jedem Wechsel des Designs gerufen (App Group spiegeln, Widgets neu laden, Navigationsleiste).
    public nonisolated(unsafe) static var designGewechselt: ((DesignArt) -> Void)? = nil
    /// Designwechsel (2.17): Porträt zu einem Spielernamen (Foto, Farbe, Zeichen) für die Gewinnerseite; nil = kein Treffer
    /// (Computer, Solo). Die App sucht den Namen im Spielerverzeichnis.
    public nonisolated(unsafe) static var spielerBild: ((String) -> (bild: Data?, farbe: Color?, zeichen: String?)?)? = nil
    /// Designwechsel (2.17): Name des gerade offenen Spiels (Kopfzeile der Gewinnerseite in Salon); nil = keiner.
    public nonisolated(unsafe) static var spielName: (() -> String?)? = nil
}

public extension Color {
    /// Schrift auf der App-Farbe. In `klar` immer weiß: die App-Farbe (Fläche) ist in hell und dunkel derselbe Mockup-Hex
    /// und erreicht mit Weiß mindestens 3:1 (Knopfschrift ist groß/fett, ab 17 pt semibold).
    /// In Tinte und Salon die Schrift auf der Spielart-Fläche bzw. auf der Hüllenfläche (je Design und Darstellung geprüft).
    static var onAccent: Color {
        let w = Design.werte
        guard w.art != .klar else { return .white }
        return Design.spielFarben?.aufFlaeche ?? w.aufHuelleFlaeche.color
    }

    /// App-Farbe als **Text** auf Kartenfläche (4,5:1): Asset `AccentText` der App (hell abgedunkelt, dunkel aufgehellt).
    /// Apps mit wählbarer App-Farbe setzen einmal beim Start `KlarGlasHaken.accentText`; ohne Haken gilt das Asset.
    static var accentText: Color { KlarGlasHaken.accentText?() ?? Color("AccentText", bundle: .main) }

    /// App-Farbe als **Fläche** (Symbole, Balken, Kacheln, Knöpfe): gewählte Farbe, sonst das Asset `AccentColor`.
    static var appFlaeche: Color { KlarGlasHaken.flaeche?() ?? Color.accentColor }

    /// Zarte App-Farb-Fläche für Chips, Fortschrittsspur, aktive Zeilen, Hinweiskarten (12 % der App-Farbe).
    static var accentSoft: Color { Color.appFlaeche.opacity(0.12) }

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Mischt Weiß (`anteil` > 0) oder Schwarz (`anteil` < 0) bei.
    static func schattiert(_ hex: UInt32, _ anteil: Double) -> Color {
        func kanal(_ shift: UInt32) -> Double {
            let v = Double((hex >> shift) & 0xFF) / 255
            return anteil >= 0 ? v + (1 - v) * anteil : v * (1 + anteil)
        }
        return Color(red: kanal(16), green: kanal(8), blue: kanal(0))
    }
}

/// Darstellung: System, Hell oder Dunkel (Einstellung „Aussehen“).
public enum Darstellung: String, CaseIterable, Identifiable, Sendable {
    case system, hell, dunkel

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .system: String(localized: "System", bundle: .module, comment: "Darstellung folgt dem System")
        case .hell: String(localized: "Hell", bundle: .module, comment: "Darstellung hell")
        case .dunkel: String(localized: "Dunkel", bundle: .module, comment: "Darstellung dunkel")
        }
    }

    public var farbschema: ColorScheme? {
        switch self {
        case .system: nil
        case .hell: .light
        case .dunkel: .dark
        }
    }
}

#if canImport(UIKit)

/// Überschrift in Karten („STUFE“ …) – überall gleich.
public struct SectionLabel: View {
    let text: Text
    @Environment(\.designArt) private var art
    public init(_ text: LocalizedStringKey) { self.text = Text(text) }
    /// Für Texte, die nie übersetzt oder als Markdown gelesen werden dürfen (Namen, Stufen).
    public init(verbatim text: String) { self.text = Text(verbatim: text) }
    public init(text: Text) { self.text = text }

    public var body: some View {
        switch art {
        case .klar:
            text
                .textCase(.uppercase)
                .font(.caption.weight(.semibold))
                // F-AWS-N-020 (Philipp 12.11.): Deckelung aufgehoben – die Zwischenüberschrift wächst mit der Schrift (vorher Wunsch 10, xxxLarge)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
        case .tinte:
            // Label-Rolle mit Tinte-Linie darunter (Entwurf R2 `.cap`)
            VStack(alignment: .leading, spacing: 6) {
                text.designLabel().accessibilityAddTraits(.isHeader)
                ZeilenLinie(stark: true)
            }
            .padding(.top, 6)
        case .salon:
            text.designLabel().accessibilityAddTraits(.isHeader)
        }
    }
}

struct CardStyle: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        if art == .klar {
            content
                .padding(sizeClass == .regular ? 22 : Theme.innen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.kartenGrund, in: .rect(cornerRadius: Theme.cardRadius))
        } else {
            // Tinte und Salon: keine Karte, sondern eine Zeile mit Haarlinie unten (kein Grund, keine Rundung).
            content
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .linieUnten()
        }
    }
}

/// Glas für Leisten: Liquid Glass ab iOS 26, davor Material.
struct GlasLeiste: ViewModifier {
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        if art != .klar {
            // Tinte und Salon: kein Glas, Papier mit Linie an der Oberkante
            content.background { Color.seitenGrund.overlay(alignment: .top) { ZeilenLinie() }.ignoresSafeArea(edges: .bottom) }
        } else if #available(iOS 26, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: Theme.leistenRadius))
                .padding(.horizontal, 8)
        } else {
            content.background { Rectangle().fill(.bar).ignoresSafeArea(edges: .bottom) }
        }
    }
}

/// Nebenknopf: Pille aus Glas (iOS 26), davor eine Material-Pille.
public struct GlasKnopfStil: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.designArt) private var art
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 18)
            .frame(minHeight: Theme.tapSize)
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
        if art == .tinte {
            label.foregroundStyle(Color.schrift).overlay { Pille(einzug: Design.werte.knopfRand / 2).stroke(Color.linieStark, lineWidth: Design.werte.knopfRand) }
                .contentShape(.capsule)
        } else if art == .salon {
            label.foregroundStyle(Color.schrift).overlay { Rectangle().strokeBorder(Color.linieStark, lineWidth: Design.werte.knopfRand) }
                .contentShape(.rect)
        } else if #available(iOS 26, *) {
            label.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            label.background(.ultraThinMaterial, in: .capsule)
        }
    }
}

public extension View {
    /// Karte: Fläche `kartenGrund`, Radius 20, Innenabstand 16 (iPad 22). Tinte und Salon: Zeile mit Haarlinie unten.
    func card() -> some View { modifier(CardStyle()) }

    /// Hauptknopf (System-Variante): volle Pille in der App-Farbe, Schrift `onAccent`. Pro Bildschirm höchstens einer.
    /// Für den 54-pt-Hauptknopf des Mockups `hauptKnopf()` verwenden. Tinte und Salon: die Knopfform des Designs in klein.
    func prominentButton() -> some View { modifier(ProminentKnopf()) }

    func glasKnopf() -> some View { buttonStyle(GlasKnopfStil()) }
    func glasLeiste() -> some View { modifier(GlasLeiste()) }

    /// Sheets auf dem iPad als Formular-Blatt (iOS 18) statt bildschirmfüllend.
    @ViewBuilder
    func formSheet() -> some View {
        if #available(iOS 18, *) { self.presentationSizing(.form) } else { self }
    }

    /// Glasfläche (Rund-Knöpfe, Pillen über Inhalt): Liquid Glass ab iOS 26, davor Material. Kein Schatten, kein Rand.
    @ViewBuilder
    func glasFlaeche<S: Shape>(_ form: S) -> some View {
        if Design.art != .klar {
            // Tinte und Salon kennen kein Glas: Papierfläche mit feiner Linie
            self.background(Color.kartenGrund, in: form).overlay { form.stroke(Color.linie, lineWidth: 1) }
        } else if #available(iOS 26, *) {
            self.glassEffect(.regular, in: form)
        } else {
            self.background(.ultraThinMaterial, in: form)
        }
    }

    /// Karte mit Tipp-Aktion (ganze Fläche tippbar, Knopf-Merkmal für VoiceOver).
    func kartenAktion(_ aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) { self }
            .buttonStyle(KartenTippStil())
    }
}

/// `prominentButton()`: in klar der System-Stil, in Tinte und Salon die gefüllte Knopfform des Designs (44 pt hoch).
struct ProminentKnopf: ViewModifier {
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        if art == .klar {
            content.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).foregroundStyle(Color.onAccent)
        } else {
            content.buttonStyle(KompaktKnopfStil(gefuellt: true))
        }
    }
}

struct KartenTippStil: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(.rect(cornerRadius: Theme.cardRadius))
    }
}

/// Fester Fuß am unteren Rand (Knöpfe immer sichtbar). Standard (Mockup): **ohne Glasleiste**, denn Haupt- und Zweitknopf
/// (Glas-Pille + App-Farbe) tragen ihre Fläche selbst, eine Leiste dahinter wäre Glas auf Glas (DESIGN.md A.5).
/// `glas: true` nur für Fälle mit reinem Inhalt ohne eigene Knopfflächen (z. B. Textknöpfe).
public struct BottomBar<Content: View>: View {
    var glas = false
    let content: Content

    public init(glas: Bool = false, @ViewBuilder content: () -> Content) {
        self.glas = glas
        self.content = content()
    }

    public var body: some View {
        let kern = content
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        if glas { kern.glasLeiste() } else { kern }
    }
}

/// Nebeneinander – bei sehr großer Schrift (Bedienungshilfen) untereinander.
public struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var spacing: CGFloat = 10
    let content: Content

    public init(spacing: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        layout { content }
    }
}

// MARK: - Fensterfarbe

private struct FensterVersionSchluessel: EnvironmentKey { static let defaultValue = 0 }

public extension EnvironmentValues {
    /// Zählt hoch, nachdem die Fensterfarbe (UIKit) auf eine neue App-Farbe gesetzt wurde. Menü-Picker übernehmen die Farbe nur beim
    /// Aufbau: wer `.id(fensterVersion)` an einen Picker hängt, baut ihn danach neu auf und zeigt sofort die neue Farbe.
    var fensterVersion: Int {
        get { self[FensterVersionSchluessel.self] }
        set { self[FensterVersionSchluessel.self] = newValue }
    }
}

/// Setzt die Tint-Farbe der Fenster (UIKit). Nötig für Bausteine, die `.tint` nicht übernehmen, z. B. den Wert eines Menü-Pickers
/// („Wörter auf: Deutsch ⌃“). Apps mit wählbarer App-Farbe hängen `.fensterTint(farbe)` einmal an die Wurzelansicht.
/// Nicht für App-Erweiterungen (Widgets): dort gibt es kein `UIApplication`.
@available(iOSApplicationExtension, unavailable)
public struct FensterTintStil: ViewModifier {
    let farbe: Color
    @State private var version = 0

    public init(farbe: Color) { self.farbe = farbe }

    public func body(content: Content) -> some View {
        content
            .environment(\.fensterVersion, version)
            .onAppear { Self.setze(farbe) }
            .onChange(of: farbe) { _, neu in
                Self.setze(neu)
                version += 1   // erst nach dem Setzen: Picker mit .id(fensterVersion) bauen sich mit der neuen Farbe auf
            }
    }

    @MainActor private static func setze(_ farbe: Color) {
        let ui = UIColor(farbe)
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for fenster in scene.windows { fenster.tintColor = ui }
        }
    }
}

public extension View {
    @available(iOSApplicationExtension, unavailable)
    func fensterTint(_ farbe: Color) -> some View { modifier(FensterTintStil(farbe: farbe)) }
}

#endif
