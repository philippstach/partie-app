// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – die fünf Knopfstile (Konzept 3.3: Haupt, Zweit, Rund, Aktion, Sheet-Pille) sowie Status-Pille und Status-Chip.
// Kein Textlink als Knopf, kein eigener Knopf-Hintergrund in den Apps.

#if canImport(UIKit)

/// Hauptknopf: volle Pille, App-Farbe, weiße Schrift, 54 pt hoch, volle Breite. Pro Bildschirm höchstens einer.
/// Tinte: Pille in Tinte mit Papier-Schrift. Salon: Rechteck (Radius 0) in Espresso bzw. im Spiel in der Spielart-Farbe,
/// Text links, Pfeil „→“ rechts (nur wenn die Breite reicht), 16 pt fett, Sperrung 0,02 em.
public struct HauptKnopfStil: ButtonStyle {
    @Environment(\.isEnabled) private var aktiv
    @Environment(\.designArt) private var art
    @Environment(\.knopfFarben) private var eigeneFarben
    /// `hell`: weiße Pille mit Schrift in der App-Farbe, nur auf dem dunklen Sammlungs-Grund (`spieleabendGrund`).
    var hell = false
    public init(hell: Bool = false) { self.hell = hell }

    public func makeBody(configuration: Configuration) -> some View {
        switch art {
        case .klar:
            configuration.label
                .font(.headline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)   // 2.25 (F-AWS-M-015): wächst mit der Schrift bis accessibility2
                .foregroundStyle(hell ? Color.appFlaeche : Color.onAccent)
                .frame(maxWidth: .infinity, minHeight: Theme.hauptKnopfHoehe)
                .background(hell ? Color.white : Color.appFlaeche, in: .capsule)
                .shadow(color: .black.opacity(hell ? 0.3 : 0), radius: 12, y: 6)
                .opacity(aktiv ? (configuration.isPressed ? 0.85 : 1) : 0.6)
        case .tinte:
            configuration.label
                .font(.headline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundStyle(eigeneFarben?.schrift ?? Color.schriftAufKnopf)
                .frame(maxWidth: .infinity, minHeight: Theme.hauptKnopfHoehe)
                .background(eigeneFarben?.flaeche ?? Color.knopfFlaeche, in: Pille())
                .contentShape(.capsule)
                .opacity(aktiv ? (configuration.isPressed ? 0.8 : 1) : 0.6)
        case .salon:
            SalonKnopfInhalt(label: configuration.label, pfeil: true)
                .foregroundStyle(eigeneFarben?.schrift ?? Color.schriftAufKnopf)
                .frame(maxWidth: .infinity, minHeight: Theme.hauptKnopfHoehe)
                .background(eigeneFarben?.flaeche ?? Color.knopfFlaeche)
                .contentShape(.rect)
                .opacity(aktiv ? (configuration.isPressed ? 0.8 : 1) : 0.6)
        }
    }
}

/// Inhalt eines Salon-Knopfs: Text links, optional Pfeil „→“ rechts; passt beides nicht, bleibt nur der Text (schrumpft).
struct SalonKnopfInhalt<Inhalt: View>: View {
    let label: Inhalt
    let pfeil: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if pfeil {
                HStack(spacing: Design.Abstand.s) {
                    label.fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 8)
                    Text(verbatim: "→").accessibilityHidden(true)
                }
            }
            label.fixedSize(horizontal: true, vertical: false).frame(maxWidth: .infinity, alignment: .leading)
            label.lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(Design.Schrift.text(16, gewicht: .bold, relativ: .headline, hoechstens: 1.25))
        .tracking(0.32)   // 0,02 em bei 16 pt
        .padding(.horizontal, 20)
    }
}

private struct KnopfFarbenSchluessel: EnvironmentKey {
    static let defaultValue: (flaeche: Color, schrift: Color)? = nil
}

public extension EnvironmentValues {
    /// Eigene Farben für Haupt- und Zweitknopf in Tinte und Salon, wenn sie auf einer Farbfläche stehen
    /// (Salon-Gewinnerseite: Creme-Knopf mit Bordeaux-Schrift). `flaeche` füllt den Hauptknopf und ist Rand und Schrift
    /// des Zweitknopfs; `schrift` steht auf dem Hauptknopf. In `klar` ohne Wirkung.
    var knopfFarben: (flaeche: Color, schrift: Color)? {
        get { self[KnopfFarbenSchluessel.self] }
        set { self[KnopfFarbenSchluessel.self] = newValue }
    }
}

/// Zweitknopf neben dem Hauptknopf (zum Beispiel „Sichern“ neben „Weiterwürfeln“): Glas-Pille gleicher Höhe.
/// Tinte: Pille mit 1,5-pt-Rand ohne Füllung. Salon: Rechteck mit 2-pt-Rand ohne Füllung.
public struct ZweitKnopfStil: ButtonStyle {
    @Environment(\.isEnabled) private var aktiv
    @Environment(\.designArt) private var art
    @Environment(\.knopfFarben) private var eigeneFarben
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        switch art {
        case .klar:
            configuration.label
                .font(.headline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, minHeight: Theme.hauptKnopfHoehe)
                .glasFlaeche(.capsule)
                .opacity(aktiv ? (configuration.isPressed ? 0.7 : 1) : 0.4)
        case .tinte:
            configuration.label
                .font(.headline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundStyle(eigeneFarben?.flaeche ?? Color.schrift)
                .frame(maxWidth: .infinity, minHeight: Theme.hauptKnopfHoehe)
                .overlay { Pille(einzug: Design.werte.knopfRand / 2).stroke(eigeneFarben?.flaeche ?? Color.linieStark, lineWidth: Design.werte.knopfRand) }
                .contentShape(.capsule)
                .opacity(aktiv ? (configuration.isPressed ? 0.6 : 1) : 0.4)
        case .salon:
            SalonKnopfInhalt(label: configuration.label, pfeil: false)
                .foregroundStyle(eigeneFarben?.flaeche ?? Color.schrift)
                .frame(maxWidth: .infinity, minHeight: Theme.hauptKnopfHoehe)
                .overlay { Rectangle().strokeBorder(eigeneFarben?.flaeche ?? Color.linieStark, lineWidth: Design.werte.knopfRand) }
                .contentShape(.rect)
                .opacity(aktiv ? (configuration.isPressed ? 0.6 : 1) : 0.4)
        }
    }
}

/// Pille im Erklär-Blatt: gefüllt = App-Farbe/weiß (Hauptaktion), sonst zarte App-Farb-Fläche mit Text in `accentText`.
/// Tinte: gefüllt = Tinte-Pille, sonst Pille mit Rand. Salon: gefülltes Rechteck bzw. Rechteck mit Rand.
public struct AkzentPilleStil: ButtonStyle {
    let gefuellt: Bool
    @Environment(\.designArt) private var art
    public init(gefuellt: Bool) { self.gefuellt = gefuellt }

    public func makeBody(configuration: Configuration) -> some View {
        switch art {
        case .klar:
            configuration.label
                .font(.headline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundStyle(gefuellt ? Color.onAccent : Color.accentText)
                .frame(maxWidth: .infinity, minHeight: Theme.tapSize + 4)
                .background(gefuellt ? Color.appFlaeche : Color.accentSoft, in: .capsule)
                .opacity(configuration.isPressed ? 0.8 : 1)
        case .tinte:
            configuration.label
                .font(.headline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundStyle(gefuellt ? Color.schriftAufKnopf : Color.schrift)
                .frame(maxWidth: .infinity, minHeight: Theme.tapSize + 4)
                .background(gefuellt ? Color.knopfFlaeche : Color.clear, in: Pille())
                .overlay { if !gefuellt { Pille(einzug: Design.werte.knopfRand / 2).stroke(Color.linieStark, lineWidth: Design.werte.knopfRand) } }
                .contentShape(.capsule)
                .opacity(configuration.isPressed ? 0.7 : 1)
        case .salon:
            configuration.label
                .font(Design.Schrift.text(16, gewicht: .bold, relativ: .headline, hoechstens: 1.25))
                .lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(gefuellt ? Color.schriftAufKnopf : Color.schrift)
                .frame(maxWidth: .infinity, minHeight: Theme.tapSize + 4)
                .background(gefuellt ? Color.knopfFlaeche : Color.clear)
                .overlay { if !gefuellt { Rectangle().strokeBorder(Color.linieStark, lineWidth: Design.werte.knopfRand) } }
                .contentShape(.rect)
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}

/// Kleiner Knopf in Inhaltsbreite für Tinte und Salon (ersetzt dort die System-Stile „bordered“ und „borderedProminent“):
/// gefüllt in der Knopffarbe oder nur mit Rand; Tinte als Pille, Salon als Rechteck.
struct KompaktKnopfStil: ButtonStyle {
    let gefuellt: Bool
    @Environment(\.isEnabled) private var aktiv
    @Environment(\.designArt) private var art

    func makeBody(configuration: Configuration) -> some View {
        let rand = Design.werte.knopfRand
        let inhalt = configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(gefuellt ? Color.schriftAufKnopf : Color.schrift)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)   // 2.34 N-007: Tippfläche mindestens 44 pt
        Group {
            if art == .salon {
                inhalt.background(gefuellt ? Color.knopfFlaeche : Color.clear)
                    .overlay { if !gefuellt { Rectangle().strokeBorder(Color.linieStark, lineWidth: rand) } }
                    .contentShape(.rect)
            } else {
                inhalt.background(gefuellt ? Color.knopfFlaeche : Color.clear, in: Pille())
                    .overlay { if !gefuellt { Pille(einzug: rand / 2).stroke(Color.linieStark, lineWidth: rand) } }
                    .contentShape(.capsule)
            }
        }
        .opacity(aktiv ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

/// `nebenKnopf()`: in klar der System-Stil „bordered“, in Tinte und Salon ein kleiner Knopf mit Rand.
struct NebenKnopf: ViewModifier {
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        if art == .klar { content.buttonStyle(.bordered).controlSize(.large) } else { content.buttonStyle(KompaktKnopfStil(gefuellt: false)) }   // 2.34 K-037: else-Zweig stand im Kommentar
    }
}

public extension View {
    func hauptKnopf() -> some View { buttonStyle(HauptKnopfStil()) }
    /// Hauptknopf auf dem dunklen Sammlungs-Grund: weiß, Schrift in der App-Farbe.
    func hauptKnopf(hell: Bool) -> some View { buttonStyle(HauptKnopfStil(hell: hell)) }
    func zweitKnopf() -> some View { buttonStyle(ZweitKnopfStil()) }
    /// Zweit-/Nebenknopf in Spielen (klar: der System-Stil „bordered“; Tinte und Salon: Rand ohne Füllung).
    /// Stil hier ändern = überall geändert.
    func nebenKnopf() -> some View { modifier(NebenKnopf()) }
}

/// Runder Glas-Knopf (44 pt, Symbol). Für Einstellungen, Regeln, Home, Pause, Menü, Teilen, Schließen. Symbol immer neutral.
public struct RundKnopf: View {
    let symbol: String
    let beschriftung: Text
    var klein = false
    /// F-AWS-N-020: wächst mit der Schriftgröße (Fläche und Symbol, bis zum Doppelten); sonst bei xxxLarge gedeckelt.
    var wachsend = false
    let aktion: () -> Void

    public init(symbol: String, beschriftung: LocalizedStringKey, klein: Bool = false, wachsend: Bool = false, aktion: @escaping () -> Void) {
        self.symbol = symbol; self.beschriftung = Text(beschriftung); self.klein = klein; self.wachsend = wachsend; self.aktion = aktion
    }

    public init(symbol: String, beschriftungText: Text, klein: Bool = false, wachsend: Bool = false, aktion: @escaping () -> Void) {
        self.symbol = symbol; self.beschriftung = beschriftungText; self.klein = klein; self.wachsend = wachsend; self.aktion = aktion
    }

    public var body: some View {
        Button(action: aktion) { RundKnopfFlaeche(symbol: symbol, klein: klein, wachsend: wachsend) }
            .buttonStyle(.plain)
            .dynamicTypeSize(...(wachsend ? DynamicTypeSize.accessibility5 : DynamicTypeSize.xxxLarge))
            .accessibilityLabel(beschriftung)
    }
}

/// Rundknopf, der ein Menü öffnet (Baustein-Wunsch 2): „…“ rechts im `SpielKopf` mit Regeln, Teilen, Verwerfen als Einträgen.
/// Sieht aus wie `RundKnopf`; der Inhalt ist wie bei `Menu` (`Button`, `Divider`, `Section`). Standard-Symbol `ellipsis`.
public struct RundKnopfMenue<Inhalt: View>: View {
    let symbol: String
    let beschriftung: Text
    var klein = false
    let inhalt: () -> Inhalt

    public init(symbol: String = "ellipsis", beschriftung: LocalizedStringKey, klein: Bool = false,
                @ViewBuilder inhalt: @escaping () -> Inhalt) {
        self.symbol = symbol; self.beschriftung = Text(beschriftung); self.klein = klein; self.inhalt = inhalt
    }

    public init(symbol: String = "ellipsis", beschriftungText: Text, klein: Bool = false,
                @ViewBuilder inhalt: @escaping () -> Inhalt) {
        self.symbol = symbol; self.beschriftung = beschriftungText; self.klein = klein; self.inhalt = inhalt
    }

    public var body: some View {
        // 2.26 N-023: Die Fläche ist reine Grafik; ohne `accessibilityHidden` lag im Baum ein namenloser Knopf im Knopf „Mehr“.
        Menu { inhalt() } label: { RundKnopfFlaeche(symbol: symbol, klein: klein).accessibilityHidden(true) }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityLabel(beschriftung)
            // 2.35 N-023: Am Gerät lag trotz 2.26 noch ein namenloser Knopf auf der Fläche (Menüstil „button“).
            // VoiceOver bekommt deshalb ein schlichtes Menü mit Namen und demselben Inhalt.
            .accessibilityRepresentation { Menu { inhalt() } label: { beschriftung } }
    }
}

/// Gemeinsame Glasfläche von `RundKnopf` und `RundKnopfMenue` (Tippfläche 44 pt, Symbol neutral).
/// Tinte und Salon: Symbol ohne Fläche (Tinte normal, Salon fett), Tippfläche 44 pt.
/// Tinte auf dunklem Grund (Filz am Tisch, Kopf der Spielseite, dunkle Darstellung): runde Fassung, damit der Knopf als Knopf
/// zu erkennen ist (Design-Runde 5, Blatt 2). Fläche Weiß 14 %, Rand Weiß 28 %, 1 pt, Zeichen hell.
struct RundKnopfFlaeche: View {
    let symbol: String
    let klein: Bool
    var wachsend = false
    @Environment(\.designArt) private var art
    @Environment(\.colorScheme) private var farbschema
    @ScaledMetric(relativeTo: .body) private var skala: CGFloat = 1

    var body: some View {
        let f = wachsend ? min(skala, 2) : 1
        let d = (klein ? Theme.rundKnopfKlein : Theme.rundKnopf) * f
        if art == .klar {
            Image(systemName: symbol)
                .font(.system(size: (klein ? 14 : 17) * f, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: d, height: d)
                .glasFlaeche(.circle)
                .frame(width: Theme.tapSize * f, height: Theme.tapSize * f)   // Tippfläche bleibt ≥ 44
                .contentShape(.circle)
        } else if art == .tinte && farbschema == .dark {
            Image(systemName: symbol)
                .font(.system(size: (klein ? 14 : 17) * f, weight: .semibold))
                .foregroundStyle(Color(hex: 0xFFFDF6))
                .frame(width: d, height: d)
                .background(Circle().fill(Color.white.opacity(0.14)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 1))
                .frame(width: Theme.tapSize * f, height: Theme.tapSize * f)   // Tippfläche bleibt ≥ 44
                .contentShape(.circle)
        } else {
            Image(systemName: symbol)
                .font(.system(size: (klein ? 16 : 19) * f, weight: art == .salon ? .bold : .regular))
                .foregroundStyle(.primary)
                .frame(width: Theme.tapSize * f, height: Theme.tapSize * f)
                .contentShape(.rect)
        }
    }
}

/// Status-/Zeit-Pille aus Glas, mittig im Spielkopf („Mittel · 04:12“). Immer einzeilig.
/// `kurz` ist die kompakte Form (z. B. nur die Zeit), die bei wenig Platz (kleines iPhone,
/// lange Sprache, größte Schrift) statt des vollen Textes erscheint. Ohne `kurz` wird nur skaliert.
public struct StatusPille: View {
    let text: String
    var kurz: String? = nil
    /// Allerkürzeste Form (z. B. nur Fehler und Zeit), wenn auch `kurz` nicht passt
    var minimal: String? = nil

    @Environment(\.designArt) private var art

    public init(text: String, kurz: String? = nil, minimal: String? = nil) {
        self.text = text; self.kurz = kurz; self.minimal = minimal
    }

    @ViewBuilder
    private func pille(_ t: String, skalieren: Bool) -> some View {
        switch art {
        case .klar:
            Text(verbatim: t)
                .font(.system(.subheadline, design: .rounded).weight(.medium).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(skalieren ? 0.6 : 1)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .glasFlaeche(.capsule)
                .layoutPriority(1)
        case .tinte:
            // Serifentext ohne Fläche (19 pt)
            Text(verbatim: t)
                .font(Design.Schrift.serif(19, gewicht: .medium, relativ: .headline, hoechstens: 1.2).monospacedDigit())
                .foregroundStyle(Color.schrift)
                .lineLimit(1)
                .minimumScaleFactor(skalieren ? 0.6 : 1)
                .padding(.vertical, 8)
                .layoutPriority(1)
        case .salon:
            // Kapitälchen-Label (11 pt fett, Sperrung 0,14 em)
            Text(verbatim: t)
                .font(Design.Schrift.label.monospacedDigit())
                .tracking(Design.Schrift.labelSperrung)
                .textCase(.uppercase)
                .foregroundStyle(Color.schrift)
                .lineLimit(1)
                .minimumScaleFactor(skalieren ? 0.6 : 1)
                .padding(.vertical, 8)
                .layoutPriority(1)
        }
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            pille(text, skalieren: false)
            if let kurz { pille(kurz, skalieren: false) }
            pille(minimal ?? kurz ?? text, skalieren: true)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: text))
    }
}

/// Zähler-Chip unter dem Spielkopf (Tipps, Minen, Ballons, Fehler): zarte App-Farb-Fläche, 28 pt, Text in `accentText`.
/// Kein Glas (das ist die Status-Pille), kein loser Text. Mehrere Chips stehen in einer `HStack(spacing: Design.Abstand.s)`.
public struct StatusChip: View {
    /// Tonlage des Chips: `akzent` (App-Farbe), `warnung` (Systemrot, z. B. „liegt hinten“), `neutral` (grau).
    public enum Ton: Sendable { case akzent, warnung, neutral }
    let symbol: String?
    let text: Text
    let beschriftung: Text?
    let ton: Ton
    let farbe: Color?

    /// `beschriftung`: VoiceOver-Text, wenn der sichtbare Text allein nicht reicht („3“ → „3 Tipps übrig“).
    public init(symbol: String? = nil, text: String, beschriftung: LocalizedStringKey? = nil) {
        self.symbol = symbol; self.text = Text(verbatim: text); self.beschriftung = beschriftung.map { Text($0) }; self.ton = .akzent; self.farbe = nil
    }
    /// Lokalisierter oder zusammengesetzter Text; `farbe` färbt den Chip (z. B. Spielerfarbe in einer Legende), sonst gilt `ton`.
    public init(symbol: String? = nil, text: Text, ton: Ton = .akzent, farbe: Color? = nil, beschriftung: Text? = nil) {
        self.symbol = symbol; self.text = text; self.beschriftung = beschriftung; self.ton = ton; self.farbe = farbe
    }

    private var vordergrund: Color {
        if let farbe { return farbe }
        switch ton { case .akzent: return .accentText; case .warnung: return Color(.systemRed); case .neutral: return .secondary }
    }
    private var grund: Color {
        if let farbe { return farbe.opacity(0.14) }
        switch ton { case .akzent: return .accentSoft; case .warnung: return Color(.systemRed).opacity(0.14); case .neutral: return Color(.tertiarySystemFill) }
    }

    @Environment(\.designArt) private var art

    public var body: some View {
        Group {
            switch art {
            case .klar:
                HStack(spacing: 5) {
                    if let symbol {
                        Image(systemName: symbol).font(.caption.weight(.semibold)).accessibilityHidden(true)
                    }
                    text
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .lineLimit(1)
                }
                .foregroundStyle(vordergrund)
                .padding(.horizontal, 12)
                .frame(minHeight: Theme.chipHoehe)
                .background(grund, in: .capsule)
            case .tinte:
                // Wort ohne Fläche und ohne Linie (Design-Runde 5, Blatt 2: Der Chip ist ein Hinweis, kein Knopf)
                HStack(spacing: 5) {
                    if let symbol {
                        Image(systemName: symbol).font(.caption).accessibilityHidden(true)
                    }
                    text
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .lineLimit(1)
                }
                .foregroundStyle(ton == .neutral && farbe == nil ? Color.schriftZweit : vordergrund)
                .frame(minHeight: Theme.chipHoehe - 4)
            case .salon:
                // Kapitälchen-Wort in der Farbe des Tons, keine Fläche
                HStack(spacing: 5) {
                    if let symbol {
                        Image(systemName: symbol).font(.caption2.weight(.bold)).accessibilityHidden(true)
                    }
                    text
                        .font(Design.Schrift.text(12, gewicht: .bold, relativ: .caption).monospacedDigit())
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .lineLimit(1)
                }
                .foregroundStyle(ton == .neutral && farbe == nil ? Color.schriftZweit : (ton == .akzent && farbe == nil ? Color.schrift : vordergrund))   // 2.22: App-Farbe auf Spielart-Grund (Klondike) war rosa auf rot
                .frame(minHeight: Theme.chipHoehe)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(beschriftung ?? text)
    }
}

public extension View {
    /// Kurzer Hinweis über dem Inhalt („Spiel gespeichert“, „Jetzt am Zug“): Karte ohne Glas, mit Schatten. Eigene Innenabstände setzen.
    /// Tinte: Papierzettel mit Tinte-Rand. Salon: Balken in der Schriftfarbe (Espresso) mit Creme-Schrift.
    func toast() -> some View { modifier(ToastStil()) }
}

struct ToastStil: ViewModifier {
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        switch art {
        case .klar:
            content.background(Color.kartenGrund, in: .rect(cornerRadius: Theme.cardRadius))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        case .tinte:
            content.foregroundStyle(Color.schrift)
                .background(Color.kartenGrund)
                .overlay { Rectangle().strokeBorder(Color.linieStark, lineWidth: 1) }
        case .salon:
            content.foregroundStyle(Color.seitenGrund)
                .background(Color.schrift)
        }
    }
}

#endif
