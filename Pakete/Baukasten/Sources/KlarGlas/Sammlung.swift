// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Bausteine der Sammlungs-Startseite „Spieleabend“ (Partie, Entwurf C vom 05.11.2026, Philipps Wahl).
// Dunkler Nachtblau-Grund wie ein Spieltisch, Zeilen mit Bildfeld in der Spielart-Farbe, darin gezeichnetes Spielmaterial
// statt eines SF-Symbols, Filterchips je Spielart, weißer Hauptknopf. Die Spielart-Farben kommen aus der App (SpieleKern).

/// Was man in einem Spiel in die Hand nimmt: Grundlage der gezeichneten Miniatur (`MiniaturAnsicht`).
public enum Miniatur: String, CaseIterable, Sendable {
    case kartenfaecher, kartenstapel      // Karten
    case zahlenkarten                     // 2.45: Zahlenkarten 10 · 11 · 12 (Elfer raus)
    case wuerfel, becher                  // Würfel
    case brett, schach, ludo, mulden, sechseck   // Brett
    case zahlengitter, bildgitter, minen, bloecke, paare   // Rätsel
    case buchstaben, pfeilraetsel, galgen // Wort
    case ziegel, laeufer, schlaeger       // Arcade
    case domino, turm, labyrinth          // 2.9: Domino-Steine, Turm von Hanoi, Irrgarten
}

/// „Farben unterscheidbar“ (G2, Farbsehschwäche): Die App setzt den Wert aus ihren Einstellungen; Bausteine und Spiele zeigen dann
/// zusätzlich zur Farbe ein Zeichen oder Muster (Spielart-Symbol, Spielerfarben mit Muster). Voreinstellung aus.
public struct FarbenUnterscheidbarKey: EnvironmentKey { public static let defaultValue = false }
public extension EnvironmentValues {
    var farbenUnterscheidbar: Bool { get { self[FarbenUnterscheidbarKey.self] } set { self[FarbenUnterscheidbarKey.self] = newValue } }
}

#if canImport(UIKit)

/// Dunkler Grund der Sammlung: Nachtblau-Verlauf, Inhalt in der dunklen Darstellung (weiße Schrift, helle Glasknöpfe).
/// Tinte und Salon: kein Tischgrund und keine erzwungene dunkle Darstellung, nur der Seitengrund des Designs.
public struct SpieleabendGrund: ViewModifier {
    let farbe: Color
    @Environment(\.designArt) private var art

    public func body(content: Content) -> some View {
        if art == .klar { klar(content) } else { content.background { Color.seitenGrund.ignoresSafeArea() } }
    }

    private func klar(_ content: Content) -> some View {
        content
            .background {
                ZStack {
                    Color(red: 0.055, green: 0.106, blue: 0.180)   // design:spielinhalt Tischgrund
                    RadialGradient(colors: [farbe.opacity(0.95), farbe.opacity(0.35), .clear],
                                   center: .init(x: 0.5, y: -0.1), startRadius: 0, endRadius: 520)
                }
                .ignoresSafeArea()
            }
            .colorScheme(.dark)
    }
}

/// Helle Karte auf dem dunklen Spieltisch: in klar die helle Darstellung erzwingen, in Tinte und Salon nichts
/// (dort gibt es keinen Tisch; die Zeile folgt der gewählten Darstellung).
struct TischKarte: ViewModifier {
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        if art == .klar { content.colorScheme(.light) } else { content }
    }
}

public extension View {
    /// Startseite als Spieltisch: dunkler Verlauf in der Hüllenfarbe, Inhalt dunkel dargestellt.
    func spieleabendGrund(_ farbe: Color) -> some View { modifier(SpieleabendGrund(farbe: farbe)) }

    /// Für Karten, die auf dem Spieltisch hell bleiben sollen (ersetzt `.colorScheme(.light)` an der Karte).
    func tischKarte() -> some View { modifier(TischKarte()) }
}

/// Zeile der Sammlung: links ein Bildfeld in der Spielart-Farbe mit Miniatur, rechts Name und Untertitel. Ganze Zeile tippbar.
/// `hell`: Fassung für helle Blätter (Neues Spiel, Suche, Was spielen wir): Kartenfläche statt durchscheinendem Weiß.
public struct SpielZeile: View {
    let name: String
    let untertitel: Text
    let farbe: Color
    let miniatur: Miniatur
    var favorit = false
    var hell = false
    var zeichen: String?
    var marke: LocalizedStringKey?
    let aktion: () -> Void
    @Environment(\.dynamicTypeSize) private var schrift
    @Environment(\.designArt) private var art
    /// Nummer oder Zusatz rechts (Salon: „01“); von außen über `spielZeileZusatz` gesetzt.
    @Environment(\.spielZeileZusatz) private var zusatz

    /// `zeichen`: SF-Symbol der Spielart in der Ecke des Bildfelds („Farben unterscheidbar“).
    /// `marke`: kleine Pille rechts neben dem Namen („Neu“), in der Spielart-Farbe.
    public init(name: String, untertitel: Text, farbe: Color, miniatur: Miniatur, favorit: Bool = false, hell: Bool = false,
                zeichen: String? = nil, marke: LocalizedStringKey? = nil, aktion: @escaping () -> Void) {
        self.name = name; self.untertitel = untertitel; self.farbe = farbe; self.miniatur = miniatur
        self.favorit = favorit; self.hell = hell; self.zeichen = zeichen; self.marke = marke; self.aktion = aktion
    }

    public var body: some View {
        Button(action: aktion) {
            switch art {
            case .klar: klar
            case .tinte: tinte
            case .salon: salon
            }
        }
        .buttonStyle(KartenTippStil())
        .accessibilityElement(children: .ignore)
        // F-AWS-N-008: Spielart und Spielerzahl gehören in den Vorlesetext, auch wenn nur das Label ausgelesen wird
        .accessibilityLabel((favorit ? Text("\(name), ") + Text("Favorit", bundle: .module) : Text(verbatim: name)) + (marke.map { Text(", ") + Text($0, bundle: .module) } ?? Text(verbatim: "")) + Text(verbatim: ", ") + untertitel)
        .accessibilityAddTraits(.isButton)
    }

    /// Rechts in der Zeile (Tinte, Salon): Marke „Neu“, Herz für Favoriten, Zusatz.
    @ViewBuilder private var rechts: some View {
        if let marke {
            Text(marke, bundle: .module).font(Design.Schrift.label).tracking(Design.Schrift.labelSperrung).textCase(.uppercase)
                .foregroundStyle(Color.schrift).unterstrichen(1)
        }
        if favorit {
            Image(systemName: "heart.fill").font(.footnote).foregroundStyle(Color.schriftZweit)
        }
        if let zusatz {
            Text(verbatim: zusatz).font(art == .salon ? Design.Schrift.label : .footnote.monospacedDigit())
                .tracking(art == .salon ? Design.Schrift.labelSperrung : 0)
                .foregroundStyle(art == .salon ? Color.schrift : Color.schriftZweit)
        }
    }

    /// Tinte: Tintenpunkt (10 pt) in der Spielart-Farbe, Name in Serifenschrift, Untertitel klein, rechts der Zusatz. Kein Bildfeld.
    private var tinte: some View {
        HStack(spacing: Design.Abstand.m) {
            ZStack {
                Circle().fill(farbe).frame(width: 10, height: 10)
                if let zeichen {   // „Farben unterscheidbar“: Zeichen der Spielart statt des Punkts
                    Image(systemName: zeichen).font(.caption.weight(.bold)).foregroundStyle(Color.schrift)
                        .frame(width: 22, height: 22).background(Color.seitenGrund)
                }
            }
            .frame(width: zeichen == nil ? 10 : 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: name).font(Design.Schrift.name).foregroundStyle(Color.schrift).lineLimit(2).minimumScaleFactor(0.7)
                untertitel.font(.footnote).foregroundStyle(Color.schriftZweit).lineLimit(schrift.isAccessibilitySize ? 3 : 1)
            }
            Spacer(minLength: 8)
            rechts
        }
        .frame(minHeight: schrift.isAccessibilitySize ? 88 : 64)
        .linieUnten()
        .contentShape(.rect)
    }

    /// Salon: Farbstreifen (14 pt) links über die volle Höhe, Name in Serifenschrift 24, rechts Nummer oder Zusatz.
    private var salon: some View {
        HStack(spacing: 0) {
            farbe.frame(width: 14)
                .overlay(alignment: .top) {
                    if let zeichen {
                        Image(systemName: zeichen).font(.system(size: 8, weight: .bold)).foregroundStyle(.white).padding(.top, 6)
                    }
                }
                .padding(.trailing, 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: name).font(Design.Schrift.name).tracking(-0.4).foregroundStyle(Color.schrift)
                    .lineLimit(2).minimumScaleFactor(0.7)
                untertitel.font(.caption.weight(.semibold)).foregroundStyle(Color.schriftZweit).lineLimit(schrift.isAccessibilitySize ? 3 : 1)
            }
            Spacer(minLength: 8)
            HStack(spacing: Design.Abstand.s) { rechts }.padding(.trailing, 2)
        }
        .frame(minHeight: schrift.isAccessibilitySize ? 88 : 64)
        .linieUnten()
        .contentShape(.rect)
    }

    private var klar: some View {
            HStack(spacing: 14) {
                ZStack(alignment: .topLeading) {
                    farbe
                    MiniaturAnsicht(miniatur, farbe: farbe, groesse: hell ? 1.15 : 1.35)
                    if let zeichen {
                        Image(systemName: zeichen).font(.caption2.weight(.bold)).foregroundStyle(farbe)
                            .frame(width: 20, height: 20).background(.white, in: Circle()).padding(6)
                    }
                }
                .frame(width: schrift.isAccessibilitySize ? 64 : (hell ? 96 : 112))   // F-AWS-K-004: bei großer Schrift schmalere Miniatur, mehr Platz für den Namen
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: Design.Abstand.s) {
                        Text(verbatim: name).font(.title3.weight(.bold)).lineLimit(2).minimumScaleFactor(0.7)
                        if let marke {
                            Text(marke, bundle: .module).font(.caption2.weight(.bold)).foregroundStyle(.white)
                                .padding(.horizontal, 7).frame(minHeight: 18).background(farbe, in: Capsule())
                        }
                    }
                    untertitel.font(.subheadline).foregroundStyle(.secondary).lineLimit(schrift.isAccessibilitySize ? 3 : 1)
                }
                Spacer(minLength: 0)
                if favorit {
                    Image(systemName: "heart.fill").font(.subheadline).foregroundStyle(.secondary)
                        .padding(.trailing, 14).accessibilityLabel(Text("Favorit", bundle: .module))
                }
            }
            .frame(minHeight: schrift.isAccessibilitySize ? 120 : (hell ? 80 : 96))
            .background(hell ? Color.kartenGrund : Color.white.opacity(0.07), in: .rect(cornerRadius: Theme.cardRadius))
            .clipShape(.rect(cornerRadius: Theme.cardRadius))
            .contentShape(.rect(cornerRadius: Theme.cardRadius))
    }
}

private struct SpielZeileZusatzSchluessel: EnvironmentKey { static let defaultValue: String? = nil }
public extension EnvironmentValues {
    /// Zusatz rechts in einer `SpielZeile` der Designs Tinte und Salon (Nummer „01“, „12 Partien“). In klar ohne Wirkung.
    var spielZeileZusatz: String? {
        get { self[SpielZeileZusatzSchluessel.self] }
        set { self[SpielZeileZusatzSchluessel.self] = newValue }
    }
}

/// Zwischenüberschrift mit Farbpunkt der Spielart („● Karten · 19“), für Gruppen in Blättern und Listen.
public struct SpielartLabel: View {
    let text: Text
    let farbe: Color
    public init(_ text: LocalizedStringKey, farbe: Color) { self.text = Text(text); self.farbe = farbe }
    public init(text: Text, farbe: Color) { self.text = text; self.farbe = farbe }
    @Environment(\.designArt) private var art

    public var body: some View {
        switch art {
        case .klar:
            HStack(spacing: Design.Abstand.s) {
                Circle().fill(farbe).frame(width: 10, height: 10).accessibilityHidden(true)
                text.font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
        case .tinte:
            // Abschnitts-Label mit Tintenpunkt und Tinte-Linie darunter
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: Design.Abstand.s) {
                    Circle().fill(farbe).frame(width: 8, height: 8).accessibilityHidden(true)
                    text.designLabel()
                }
                ZeilenLinie(stark: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
        case .salon:
            // Kapitälchen-Label mit kleinem Farbfeld der Spielart
            HStack(spacing: Design.Abstand.s) {
                farbe.frame(width: 14, height: 14).accessibilityHidden(true)
                text.designLabel(Color.schrift)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
            .accessibilityAddTraits(.isHeader)
        }
    }
}

/// Großes Bildfeld eines Spiels (Spielprofil, Ende): Spielart-Farbe als Karte mit der Miniatur in doppelter Größe.
public struct SpielBild: View {
    let farbe: Color
    let miniatur: Miniatur
    var hoehe: CGFloat = 120
    public init(farbe: Color, miniatur: Miniatur, hoehe: CGFloat = 120) { self.farbe = farbe; self.miniatur = miniatur; self.hoehe = hoehe }
    @Environment(\.designArt) private var art

    public var body: some View {
        switch art {
        case .klar, .salon:
            // Salon: Farbblock in der Spielart-Farbe mit Miniatur (ohne Rundung, die Ecke kommt aus dem Design)
            ZStack { farbe; MiniaturAnsicht(miniatur, farbe: farbe, groesse: hoehe / 60) }
                .frame(maxWidth: .infinity).frame(height: hoehe)
                .clipShape(.rect(cornerRadius: Theme.cardRadius))
                .accessibilityHidden(true)
        case .tinte:
            // Schmale Zeile: Tintenpunkt in der Spielart-Farbe und die Miniatur als Strichzeichnung auf Papier
            let h = min(hoehe, 72)
            HStack(spacing: Design.Abstand.m) {
                Circle().fill(farbe).frame(width: 10, height: 10)
                Spacer(minLength: 0)
                MiniaturAnsicht(miniatur, farbe: farbe, groesse: h / 52, strich: true)
            }
            .frame(maxWidth: .infinity).frame(height: h)
            .linieUnten()
            .accessibilityHidden(true)
        }
    }
}

/// Filterchip der Sammlung: Pille, aktiv weiß mit dunkler Schrift, sonst durchscheinend; optional ein Farbpunkt (Spielart).
public struct FilterChip: View {
    let titel: Text
    let punkt: Color?
    let symbol: String?
    let aktiv: Bool
    let aktion: () -> Void

    public init(_ titel: LocalizedStringKey, punkt: Color? = nil, symbol: String? = nil, aktiv: Bool, aktion: @escaping () -> Void) {
        self.titel = Text(titel); self.punkt = punkt; self.symbol = symbol; self.aktiv = aktiv; self.aktion = aktion
    }

    public init(text: Text, punkt: Color? = nil, symbol: String? = nil, aktiv: Bool, aktion: @escaping () -> Void) {
        self.titel = text; self.punkt = punkt; self.symbol = symbol; self.aktiv = aktiv; self.aktion = aktion
    }

    @Environment(\.designArt) private var art

    public var body: some View {
        Button(action: aktion) {
            switch art {
            case .klar:
                HStack(spacing: 7) {
                    if let punkt { Circle().fill(punkt).frame(width: 9, height: 9) }
                    if let symbol { Image(systemName: symbol).font(.caption.weight(.semibold)) }
                    titel.font(.subheadline.weight(.semibold)).lineLimit(1)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: Theme.rundKnopfKlein)
                .foregroundStyle(aktiv ? Color.black.opacity(0.9) : Color.white)
                .background(aktiv ? Color.white : Color.white.opacity(0.1), in: .capsule)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            case .tinte:
                // Wort mit Unterstrich, aktiv 2 pt; der Tintenpunkt nennt die Spielart
                HStack(spacing: 6) {
                    if let punkt { Circle().fill(punkt).frame(width: 8, height: 8) }
                    if let symbol { Image(systemName: symbol).font(.caption) }
                    titel.font(.subheadline.weight(aktiv ? .bold : .medium)).lineLimit(1)
                }
                .foregroundStyle(Color.schrift)
                .unterstrichen(aktiv ? 2 : 1, farbe: aktiv ? Color.schrift : Color.linie)
                .padding(.horizontal, 4)
                .frame(minHeight: Theme.tapSize)
                .contentShape(.rect)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            case .salon:
                // Kapitälchen-Wort, aktiv mit 2-pt-Unterstrich; ein kleines Farbfeld nennt die Spielart
                HStack(spacing: 6) {
                    if let punkt { punkt.frame(width: 9, height: 9) }
                    if let symbol { Image(systemName: symbol).font(.caption2.weight(.bold)) }
                    titel.font(Design.Schrift.text(12, gewicht: .bold, relativ: .caption, hoechstens: 1.25)).tracking(1.5).textCase(.uppercase).lineLimit(1)
                }
                .foregroundStyle(aktiv ? Color.schrift : Color.schriftZweit)
                .unterstrichen(2, farbe: aktiv ? Color.schrift : Color.clear)
                .padding(.horizontal, 4)
                .frame(minHeight: Theme.tapSize)
                .contentShape(.rect)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(aktiv ? .isSelected : [])
    }
}

/// Gezeichnetes Spielmaterial (Kartenfächer, Würfel, Brett, Gitter, Buchstaben …) auf einem Grundmaß von 64 × 48 pt.
/// `groesse` skaliert; `farbe` ist die Fläche dahinter (für farbige Zellen und Steine).
/// `strich` (Design Tinte): dasselbe Motiv als Strichzeichnung in Tinte auf Papier, ohne Farbfläche dahinter und ohne Schatten;
/// die Teile sind Papier mit Tinte-Rand, die Spielart-Farbe bleibt der einzige Farbton.
public struct MiniaturAnsicht: View {
    let art: Miniatur
    let farbe: Color
    var groesse: CGFloat = 1
    var strich = false

    public init(_ art: Miniatur, farbe: Color, groesse: CGFloat = 1, strich: Bool = false) {
        self.art = art; self.farbe = farbe; self.groesse = groesse; self.strich = strich
    }

    private let druckfarbe = Color(red: 0.07, green: 0.07, blue: 0.08)   // design:spielinhalt Druckfarbe der Karten und Würfel
    private let herzfarbe = Color(red: 0.84, green: 0.15, blue: 0.17)    // design:spielinhalt Herz/Karo
    /// Druckfarbe: fest (klar, Salon) bzw. die Schriftfarbe des Designs (Strichzeichnung, auch im Dunkeln lesbar).
    private var tinte: Color { strich ? Color.schrift : druckfarbe }
    private var herz: Color { strich ? (DesignWerte.tinte.palette?[.karten]?.text ?? herzfarbe) : herzfarbe }
    /// Papier der Teile (Karten, Würfel, Kacheln): Weiß bzw. in der Strichzeichnung der Kartengrund.
    private var blatt: Color { strich ? Color.kartenGrund : .white }
    /// Direkt auf den Grund Gezeichnetes (Ziegel, Läufer, Galgen): Weiß auf der Farbfläche bzw. Tinte auf Papier.
    private var zeichen: Color { strich ? Color.schrift : .white }

    /// Ein Teil des Spielmaterials: gefüllte Form mit weichem Schatten bzw. in der Strichzeichnung mit Tinte-Rand.
    private func teil<S: Shape>(_ form: S, fuellung: Color? = nil) -> some View {
        form.fill(fuellung ?? blatt)
            .overlay { if strich { form.stroke(tinte, lineWidth: 0.8) } }
            .shadow(color: .black.opacity(strich ? 0 : 0.18), radius: strich ? 0 : 1, y: strich ? 0 : 1)
    }

    public var body: some View {
        ZStack { inhalt }
            .frame(width: 64, height: 48)
            .scaleEffect(groesse)
            .frame(width: 64 * groesse, height: 48 * groesse)
            .accessibilityHidden(true)
    }

    // MARK: Teile

    private func karte<V: View>(_ x: CGFloat, _ y: CGFloat, drehung: Double = 0, fuellung: Color? = nil, @ViewBuilder _ inhalt: () -> V) -> some View {
        teil(RoundedRectangle(cornerRadius: 4), fuellung: fuellung)
            .frame(width: 22, height: 30)
            .overlay(alignment: .topLeading) { inhalt().padding(.init(top: 2, leading: 3, bottom: 0, trailing: 0)) }
            .rotationEffect(.degrees(drehung))
            .position(x: x + 11, y: y + 15)
    }

    private func wuerfel(_ x: CGFloat, _ y: CGFloat, augen: Int, drehung: Double = 0) -> some View {
        let muster: [Int: [Int]] = [1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]]
        return teil(RoundedRectangle(cornerRadius: 6))
            .frame(width: 22, height: 22)
            .overlay {
                let z = muster[augen] ?? []
                VStack(spacing: 2) {
                    ForEach(0..<3) { r in
                        HStack(spacing: 2) {
                            ForEach(0..<3) { c in
                                Circle().fill(tinte).frame(width: 4, height: 4).opacity(z.contains(r * 3 + c) ? 1 : 0)
                            }
                        }
                    }
                }
            }
            .rotationEffect(.degrees(drehung))
            .position(x: x + 11, y: y + 11)
    }

    private func augen(_ z: [Int]) -> some View {
        VStack(spacing: 1.5) {
            ForEach(0..<3) { r in HStack(spacing: 1.5) { ForEach(0..<3) { c in Circle().fill(tinte).frame(width: 3, height: 3).opacity(z.contains(r * 3 + c) ? 1 : 0) } } }
        }
    }

    private func gitter(_ zellen: [(Color, String)], spalten: Int = 3, breite: CGFloat = 40) -> some View {
        let z = breite / CGFloat(spalten)
        return VStack(spacing: 0) {
            ForEach(0..<(zellen.count / spalten), id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<spalten, id: \.self) { c in
                        let (f, t) = zellen[r * spalten + c]
                        ZStack {
                            f == .white ? blatt : f
                            Text(verbatim: t).font(.system(size: z * 0.62, weight: .semibold, design: strich ? .serif : .rounded))
                                .foregroundStyle(f == .white ? tinte : .white)
                        }
                        .frame(width: z, height: z)
                        .overlay(Rectangle().stroke(strich ? tinte.opacity(0.45) : Color.black.opacity(0.12), lineWidth: 0.5))
                    }
                }
            }
        }
        .frame(width: breite, height: breite)
        .background(blatt)
        .clipShape(.rect(cornerRadius: strich ? 0 : 4))
        .overlay { if strich { Rectangle().stroke(tinte, lineWidth: 1) } }
        .shadow(color: .black.opacity(strich ? 0 : 0.18), radius: strich ? 0 : 1, y: strich ? 0 : 1)
    }

    private func brettfeld(_ steine: [Int: Color], figuren: [Int: String] = [:]) -> some View {
        let dunkel = Color(red: 0.17, green: 0.18, blue: 0.20)   // design:spielinhalt dunkles Brettfeld
        return VStack(spacing: 0) {
            ForEach(0..<4) { r in
                HStack(spacing: 0) {
                    ForEach(0..<4) { c in
                        let i = r * 4 + c
                        let dk = (r + c) % 2 == 1
                        ZStack {
                            if strich { dk ? tinte.opacity(0.16) : blatt } else { dk ? dunkel : Color.white }
                            if let s = steine[i] {
                                Circle().fill(s == .white ? blatt : s).padding(2)
                                    .overlay(Circle().stroke(strich ? tinte : Color.black.opacity(0.2), lineWidth: 0.6).padding(2))
                            }
                            if let f = figuren[i] {
                                Text(verbatim: f).font(.system(size: 8)).foregroundStyle(dk && !strich ? .white : tinte)
                            }
                        }
                        .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .clipShape(.rect(cornerRadius: strich ? 0 : 4))
        .overlay { if strich { Rectangle().stroke(tinte, lineWidth: 1) } }
        .shadow(color: .black.opacity(strich ? 0 : 0.18), radius: strich ? 0 : 1, y: strich ? 0 : 1)
    }

    private func kachel(_ text: String, x: CGFloat, y: CGFloat, drehung: Double = 0, breite: CGFloat = 18) -> some View {
        teil(RoundedRectangle(cornerRadius: 3))
            .frame(width: breite, height: 18)
            .overlay(Text(verbatim: text).font(.system(size: 11, weight: .bold, design: strich ? .serif : .default)).foregroundStyle(tinte))
            .rotationEffect(.degrees(drehung))
            .position(x: x + breite / 2, y: y + 9)
    }

    private func ziegelreihe(_ y: CGFloat, deckkraft: Double) -> some View {
        HStack(spacing: 1.5) { ForEach(0..<4) { _ in RoundedRectangle(cornerRadius: 1.5).fill(zeichen).frame(width: 14, height: 6) } }
            .opacity(deckkraft).position(x: 32, y: y)
    }

    // MARK: Motive

    @ViewBuilder private var inhalt: some View {
        switch art {
        case .kartenfaecher:
            karte(6, 8, drehung: -14) { Text("♠").font(.system(size: 11, weight: .bold)).foregroundStyle(tinte) }
            karte(20, 5, drehung: -2) { Text("♥").font(.system(size: 11, weight: .bold)).foregroundStyle(herz) }
            karte(34, 7, drehung: 12) { Text("♣").font(.system(size: 11, weight: .bold)).foregroundStyle(tinte) }
        case .zahlenkarten:
            karte(6, 8, drehung: -14) { Text(verbatim: "10").font(.system(size: 10, weight: .bold)).foregroundStyle(tinte) }
            karte(20, 5, drehung: -2) { Text(verbatim: "11").font(.system(size: 10, weight: .bold)).foregroundStyle(herz) }
            karte(34, 7, drehung: 12) { Text(verbatim: "12").font(.system(size: 10, weight: .bold)).foregroundStyle(tinte) }
        case .kartenstapel:
            karte(8, 10, fuellung: farbe) { EmptyView() }
            karte(14, 7, fuellung: farbe.opacity(0.85)) { EmptyView() }
            karte(34, 8) { Text("7♦").font(.system(size: 10, weight: .bold)).foregroundStyle(herz) }
        case .wuerfel:
            wuerfel(8, 6, augen: 5, drehung: -12); wuerfel(34, 12, augen: 3, drehung: 10); wuerfel(20, 26, augen: 6, drehung: 4)
        case .becher:
            if strich {
                teil(UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 9, bottomTrailingRadius: 9, topTrailingRadius: 5))
                    .frame(width: 30, height: 38).position(x: 23, y: 25)
            } else {
                UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 9, bottomTrailingRadius: 9, topTrailingRadius: 5)
                    .fill(.white).frame(width: 30, height: 38).shadow(color: .black.opacity(0.2), radius: 1, y: 1).position(x: 23, y: 25)
            }
            wuerfel(36, 22, augen: 6, drehung: 14)
        case .brett:
            brettfeld([5: tinte, 7: .white, 9: .white, 14: tinte])
        case .schach:
            brettfeld([:], figuren: [1: "♞", 6: "♚", 10: "♙", 12: "♜"])
        case .ludo:
            teil(Circle()).frame(width: 40, height: 40)
            ForEach(Array([(16, 10, Color(red: 0.9, green: 0.28, blue: 0.3)), (32, 10, Color(red: 0.18, green: 0.44, blue: 0.92)),
                           (16, 26, Color(red: 0.08, green: 0.63, blue: 0.44)), (32, 26, Color(red: 0.95, green: 0.69, blue: 0.11))].enumerated()), id: \.offset) { _, p in   // design:spielinhalt Spielerfarben
                Circle().fill(p.2).frame(width: 12, height: 12).position(x: CGFloat(p.0) + 6, y: CGFloat(p.1) + 6)
            }
        case .mulden:
            teil(RoundedRectangle(cornerRadius: 9)).frame(width: 56, height: 32)
            ForEach(0..<3) { i in
                Circle().fill(farbe.opacity(0.35)).frame(width: 13, height: 13).position(x: CGFloat(11 + i * 16) + 6, y: 18)
                Circle().fill(farbe.opacity(0.6)).frame(width: 13, height: 13).position(x: CGFloat(11 + i * 16) + 6, y: 31)
            }
        case .sechseck:
            ForEach(Array([(16, 12, 0.55), (32, 12, -1), (48, 12, 0.55), (24, 26, -1), (40, 26, 1), (32, 40, 0.55)].enumerated()), id: \.offset) { _, h in
                Sechseck().fill(h.2 < 0 ? tinte : (strich ? farbe.opacity(h.2) : Color.white.opacity(h.2))).frame(width: 14, height: 14).position(x: CGFloat(h.0), y: CGFloat(h.1))
            }
        case .zahlengitter:
            gitter([(.white, "5"), (farbe, "3"), (.white, ""), (.white, ""), (.white, "7"), (.white, ""), (.white, "1"), (.white, ""), (farbe, "9")])
        case .bildgitter:
            gitter([(farbe, ""), (.white, ""), (farbe, ""), (farbe, ""), (farbe, ""), (farbe, ""), (.white, ""), (farbe, ""), (.white, "")])
        case .minen:
            let zu = Color(red: 0.91, green: 0.91, blue: 0.93)   // design:spielinhalt verdecktes Feld
            gitter([(.white, "1"), (zu, ""), (zu, ""), (.white, "2"), (.white, "1"), (zu, ""), (farbe, "⚑"), (.white, "1"), (zu, "")])
        case .bloecke:
            ForEach(Array([(0, 3, 1.0), (1, 3, 1.0), (2, 3, 1.0), (1, 2, 1.0), (3, 3, 1.0), (3, 2, 1.0), (3, 1, 1.0), (0, 0, 0.6), (1, 0, 0.6)].enumerated()), id: \.offset) { _, b in
                RoundedRectangle(cornerRadius: 2).fill(zeichen).opacity(b.2).frame(width: 9, height: 9)
                    .position(x: CGFloat(12 + b.0 * 10) + 4.5, y: CGFloat(4 + b.1 * 10) + 4.5)
            }
        case .paare:
            ForEach(0..<4) { i in
                let offen = i == 1 || i == 2
                RoundedRectangle(cornerRadius: 4).fill(offen ? blatt : farbe.opacity(0.7))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(strich ? tinte : .white, lineWidth: strich ? 0.8 : (offen ? 0 : 1.5)))
                    .frame(width: 20, height: 20)
                    .overlay(Text(offen ? "🐟" : "").font(.system(size: 11)))
                    .shadow(color: .black.opacity(strich ? 0 : 0.18), radius: strich ? 0 : 1, y: strich ? 0 : 1)
                    .position(x: CGFloat(4 + (i % 2) * 22 + (i > 1 ? 18 : 0)) + 10, y: CGFloat(i > 1 ? 20 : 4) + 10)
            }
        case .buchstaben:
            ForEach(Array("WORT".enumerated()), id: \.offset) { i, c in
                kachel(String(c), x: CGFloat(i * 15) - 1, y: 15, drehung: i % 2 == 1 ? 3 : -3)
            }
        case .pfeilraetsel:
            gitter([(farbe, "➜"), (.white, "H"), (.white, "U"), (.white, ""), (.white, "A"), (.white, ""), (.white, ""), (.white, "S"), (farbe, "➜")])
        case .galgen:
            ForEach(Array("HA_S_".enumerated()), id: \.offset) { i, c in
                kachel(c == "_" ? "" : String(c), x: CGFloat(i * 12) + 2, y: 24, breite: 11)
            }
            Path { p in
                p.move(to: .init(x: 25, y: 22)); p.addLine(to: .init(x: 25, y: 2)); p.addLine(to: .init(x: 37, y: 2)); p.addLine(to: .init(x: 37, y: 6))
                p.addEllipse(in: .init(x: 34.4, y: 6.4, width: 5.2, height: 5.2))
                p.move(to: .init(x: 37, y: 12)); p.addLine(to: .init(x: 37, y: 18)); p.move(to: .init(x: 34, y: 15)); p.addLine(to: .init(x: 40, y: 15))
            }
            .stroke(zeichen, style: .init(lineWidth: 1.8, lineCap: .round))
        case .ziegel:
            ziegelreihe(7, deckkraft: 1); ziegelreihe(15, deckkraft: 0.75)
            Circle().fill(zeichen).frame(width: 7, height: 7).position(x: 33, y: 28)
            RoundedRectangle(cornerRadius: 2).fill(zeichen).frame(width: 22, height: 5).position(x: 33, y: 42)
        case .laeufer:
            Path { p in
                p.addEllipse(in: .init(x: 26, y: 6, width: 8, height: 8))
                p.move(to: .init(x: 28, y: 16)); p.addLine(to: .init(x: 35, y: 20)); p.addLine(to: .init(x: 32, y: 29)); p.addLine(to: .init(x: 40, y: 37))
                p.move(to: .init(x: 35, y: 20)); p.addLine(to: .init(x: 41, y: 18)); p.addLine(to: .init(x: 46, y: 23))
                p.move(to: .init(x: 32, y: 29)); p.addLine(to: .init(x: 24, y: 35)); p.addLine(to: .init(x: 19, y: 44))
            }
            .stroke(zeichen, style: .init(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            Rectangle().fill(zeichen.opacity(0.6)).frame(width: 56, height: 2).position(x: 32, y: 46)
        case .domino:
            ForEach(Array([(10, 14, -8.0, [0, 8], [0, 4, 8]), (34, 20, 6.0, [4], [0, 2, 6, 8])].enumerated()), id: \.offset) { _, d in
                teil(RoundedRectangle(cornerRadius: 3)).frame(width: 18, height: 34)
                    .overlay {
                        VStack(spacing: 0) {
                            augen(d.3).frame(height: 16)
                            Rectangle().fill(Color.black.opacity(0.25)).frame(width: 12, height: 1)
                            augen(d.4).frame(height: 16)
                        }
                    }
                    .rotationEffect(.degrees(d.2)).position(x: CGFloat(d.0) + 9, y: CGFloat(d.1) + 10)
            }
        case .turm:
            RoundedRectangle(cornerRadius: 1.5).fill(zeichen.opacity(0.7)).frame(width: 3, height: 40).position(x: 32, y: 26)
            ForEach(Array([30, 24, 18, 12].enumerated()), id: \.offset) { i, w in
                teil(Capsule()).frame(width: CGFloat(w), height: 7)
                    .position(x: 32, y: CGFloat(42 - i * 8))
            }
            RoundedRectangle(cornerRadius: 2).fill(zeichen).frame(width: 44, height: 4).position(x: 32, y: 46)
        case .labyrinth:
            teil(RoundedRectangle(cornerRadius: 4)).frame(width: 40, height: 40).position(x: 32, y: 24)
            Path { p in
                p.move(to: .init(x: 16, y: 8)); p.addLine(to: .init(x: 16, y: 40))
                p.move(to: .init(x: 24, y: 16)); p.addLine(to: .init(x: 40, y: 16)); p.addLine(to: .init(x: 40, y: 32))
                p.move(to: .init(x: 24, y: 24)); p.addLine(to: .init(x: 32, y: 24)); p.addLine(to: .init(x: 32, y: 40))
                p.move(to: .init(x: 48, y: 8)); p.addLine(to: .init(x: 48, y: 32))
            }
            .stroke(farbe, style: .init(lineWidth: 2.5, lineCap: .round))
            Circle().fill(farbe).frame(width: 6, height: 6).position(x: 20, y: 12)
            Image(systemName: "flag.fill").font(.system(size: 8)).foregroundStyle(farbe).position(x: 44, y: 38)
        case .schlaeger:
            RoundedRectangle(cornerRadius: 2).fill(zeichen).frame(width: 5, height: 20).position(x: 8, y: 20)
            RoundedRectangle(cornerRadius: 2).fill(zeichen).frame(width: 5, height: 20).position(x: 56, y: 30)
            Rectangle().fill(zeichen.opacity(0.4)).frame(width: 2, height: 40).position(x: 32, y: 24)
            Circle().fill(zeichen).frame(width: 7, height: 7).position(x: 36, y: 22)
        }
    }
}

/// Regelmäßiges Sechseck (Spitze oben) für die Sechseck-Miniatur.
struct Sechseck: Shape {
    func path(in r: CGRect) -> Path {
        let m = CGPoint(x: r.midX, y: r.midY), rad = min(r.width, r.height) / 2
        var p = Path()
        for k in 0..<6 {
            let a = Double.pi / 3 * Double(k) + .pi / 6
            let pt = CGPoint(x: m.x + rad * cos(a), y: m.y + rad * sin(a))
            k == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

#endif
