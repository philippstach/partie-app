// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Bausteine des Spielbildschirms (Konzept 3.4 „Spiel“): Spielkopf, Aktionsleiste, Spielfeld-Karte, Spielerleiste.
// Unten ENTWEDER Aktionsleiste ODER Zweit- + Hauptknopf, ohne Leiste dahinter. Rückgängig, Tipp, Fahne, Notizen nie im Kopf.

#if canImport(UIKit)

private struct RegelnOeffnenKey: EnvironmentKey { static let defaultValue: (() -> Void)? = nil }
private struct RegelnKnopfKey: EnvironmentKey { static let defaultValue = false }
public extension EnvironmentValues {
    /// Öffnet die Regeln/Anleitung des laufenden Spiels (vom Spielrahmen gesetzt), z. B. aus dem Spielmenü.
    var regelnOeffnen: (() -> Void)? {
        get { self[RegelnOeffnenKey.self] }
        set { self[RegelnOeffnenKey.self] = newValue }
    }
    /// true = der `SpielKopf` zeigt selbst einen Buch-Knopf „Regeln“ (Standard aus). Der Spielrahmen schaltet ihn ein;
    /// Spiele mit eigenem Regeln-Eintrag im Menü (Arcade-Hülle) schalten ihn für ihren Kopf wieder aus.
    var regelnKnopf: Bool {
        get { self[RegelnKnopfKey.self] }
        set { self[RegelnKnopfKey.self] = newValue }
    }
}

/// Spielkopf: links runder Home-Knopf (`house`, fragt nicht nach, E6), Mitte Status-Pille, rechts EIN runder Knopf
/// (Menü „…“ oder Pause; beide nur, wenn beides nötig).
public struct SpielKopf<Rechts: View>: View {
    let linksSymbol: String
    let linksBeschriftung: Text
    let mitte: String
    var mitteKurz: String? = nil
    var mitteMinimal: String? = nil
    let linksAktion: () -> Void
    let rechts: Rechts
    @Environment(\.regelnOeffnen) private var regelnOeffnen
    @Environment(\.regelnKnopf) private var regelnKnopf
    @Environment(\.designArt) private var art
    @Environment(\.colorScheme) private var farbschema
    /// Kurzes Wort für den linken Knopf in Tinte und Salon („Start“), wenn links Home steht.
    private var linksWort: Text?

    /// Ohne `linksSymbol`/`linksBeschriftung` steht links Home („Zum Start“).
    public init(linksSymbol: String = "house", linksBeschriftung: LocalizedStringKey? = nil, mitte: String,
                mitteKurz: String? = nil, mitteMinimal: String? = nil,
                linksAktion: @escaping () -> Void, @ViewBuilder rechts: () -> Rechts) {
        self.linksSymbol = linksSymbol
        self.linksBeschriftung = linksBeschriftung.map { Text($0) } ?? Text("Zum Start", bundle: .module)
        self.linksWort = linksBeschriftung == nil ? Text("Start", bundle: .module) : nil
        self.mitte = mitte; self.mitteKurz = mitteKurz; self.mitteMinimal = mitteMinimal
        self.linksAktion = linksAktion; self.rechts = rechts()
    }

    /// Linker Knopf: klar der Rundknopf; Tinte auf dunklem Grund (Filz) ein Rundknopf mit Fassung und `chevron.left`
    /// (Design-Runde 5, Blatt 2), auf hellem Grund „‹ Start“ als unterstrichenes Wort; Salon „← START“ als Label.
    /// Reicht der Platz nicht, bleibt nur das Symbol.
    @ViewBuilder private var links: some View {
        switch art {
        case .klar:
            RundKnopf(symbol: linksSymbol, beschriftungText: linksBeschriftung, aktion: linksAktion)
        case .tinte:
            if farbschema == .dark {
                // Design-Runde 5 (Blatt 2): am Tisch ein runder Knopf wie Regeln und „Mehr“, kein unterstrichenes Wort auf dem Filz.
                // Home wird zum Pfeil nach links; ein eigenes Symbol (z. B. Pause) bleibt.
                RundKnopf(symbol: linksSymbol == "house" ? "chevron.left" : linksSymbol, beschriftungText: linksBeschriftung, aktion: linksAktion)
            } else {
                Button(action: linksAktion) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 3) {
                            Text(verbatim: "‹")
                            (linksWort ?? linksBeschriftung).unterstrichen(1)
                        }
                        .font(.body.weight(.semibold)).lineLimit(1).fixedSize()
                        Image(systemName: linksSymbol).font(.system(size: 19))
                    }
                    .foregroundStyle(Color.schrift)
                    .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityLabel(linksBeschriftung)
            }
        case .salon:
            Button(action: linksAktion) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        Text(verbatim: "←")
                        (linksWort ?? linksBeschriftung).textCase(.uppercase)
                    }
                    .font(Design.Schrift.text(13, gewicht: .bold, relativ: .footnote, hoechstens: 1.25)).tracking(1.6).lineLimit(1).fixedSize()
                    Image(systemName: linksSymbol).font(.system(size: 19, weight: .bold))
                }
                .foregroundStyle(Color.schrift)
                .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityLabel(linksBeschriftung)
        }
    }

    public var body: some View {
        HStack {
            links
            Spacer(minLength: 8)
            StatusPille(text: mitte, kurz: mitteKurz, minimal: mitteMinimal)
            Spacer(minLength: 8)
            HStack(spacing: Design.Abstand.xs) {
                if regelnKnopf, let regelnOeffnen { RundKnopf(symbol: "book", beschriftung: "Regeln", aktion: regelnOeffnen) }
                rechts
            }
        }
        .padding(.horizontal, Theme.seitenRand)
    }
}

public extension SpielKopf where Rechts == EmptyView {
    init(linksSymbol: String = "house", linksBeschriftung: LocalizedStringKey? = nil, mitte: String,
         mitteKurz: String? = nil, mitteMinimal: String? = nil, linksAktion: @escaping () -> Void) {
        self.init(linksSymbol: linksSymbol, linksBeschriftung: linksBeschriftung, mitte: mitte, mitteKurz: mitteKurz,
                  mitteMinimal: mitteMinimal, linksAktion: linksAktion, rechts: { EmptyView() })
    }
}

/// Ein Eintrag der Aktionsleiste.
public struct AktionsEintrag: Identifiable {
    /// Stabil (kein UUID), damit SwiftUI die Knöpfe beim Neuzeichnen nicht neu aufbaut
    public var id: String { symbol }
    public let symbol: String
    public let titel: LocalizedStringKey
    public var aktiv = false
    public var gesperrt = false
    public let aktion: () -> Void

    public init(symbol: String, titel: LocalizedStringKey, aktiv: Bool = false, gesperrt: Bool = false, aktion: @escaping () -> Void) {
        self.symbol = symbol; self.titel = titel; self.aktiv = aktiv; self.gesperrt = gesperrt; self.aktion = aktion
    }
}

/// Leiste runder Aktionsknöpfe (44 pt) mit Beschriftung darunter: Zurück, Löschen, Notizen, Tipp.
/// Aktiv (zum Beispiel Notizen an) = App-Farbe gefüllt, weißes Symbol; sonst Glas.
/// Tinte: unterstrichene Wörter statt Kreisen (aktiv 2-pt-Unterstrich). Salon: Kapitälchen-Wörter (aktiv in der
/// Spielart-Textfarbe mit Unterstrich). Reicht die Breite nicht, steht das Symbol über dem Wort.
public struct AktionsLeiste: View {
    let eintraege: [AktionsEintrag]
    @Environment(\.designArt) private var art

    public init(eintraege: [AktionsEintrag]) { self.eintraege = eintraege }

    public var body: some View {
        if art == .klar { klar } else { woerter }
    }

    /// Tinte und Salon: Wörter nebeneinander; passt das nicht, Symbol über Wort.
    private var woerter: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: Design.Abstand.m) {
                ForEach(eintraege) { e in
                    wortKnopf(e) { wort(e).fixedSize() }
                    if e.id != eintraege.last?.id { Spacer(minLength: 0) }
                }
            }
            HStack(alignment: .top, spacing: Design.Abstand.xs) {
                ForEach(eintraege) { e in
                    wortKnopf(e) {
                        VStack(spacing: Design.Abstand.xs) {
                            Image(systemName: e.symbol).font(.system(size: 19, weight: art == .salon ? .bold : .regular))
                                .frame(height: 26)
                            wort(e, klein: true).lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.horizontal, Theme.seitenRand)
    }

    private func wortKnopf<V: View>(_ e: AktionsEintrag, @ViewBuilder inhalt: () -> V) -> some View {
        Button(action: e.aktion) {
            inhalt()
                .foregroundStyle(e.aktiv && art == .salon ? Color.accentText : Color.schrift)
                .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize)   // 2.34 N-007: auch breit genug
                .contentShape(.rect)
                .opacity(e.gesperrt ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(e.gesperrt)
        .accessibilityLabel(Text(e.titel))
        .accessibilityAddTraits(e.aktiv ? .isSelected : [])
    }

    @ViewBuilder private func wort(_ e: AktionsEintrag, klein: Bool = false) -> some View {
        if art == .salon {
            Text(e.titel)
                .font(Design.Schrift.text(klein ? 10 : 13, gewicht: .bold, relativ: .footnote, hoechstens: 1.2))
                .tracking(klein ? 0.8 : 1.3).textCase(.uppercase)
                .unterstrichen(2, farbe: e.aktiv ? Color.accentText : Color.clear)
        } else {
            Text(e.titel)
                .font(Design.Schrift.text(klein ? 11 : 15, gewicht: .semibold, relativ: .subheadline, hoechstens: 1.2))
                .unterstrichen(e.aktiv ? 2 : 1)
        }
    }

    private var klar: some View {
        HStack(alignment: .top) {
            ForEach(eintraege) { e in
                Button(action: e.aktion) {
                    VStack(spacing: Design.Abstand.xs) {
                        ZStack {
                            if e.aktiv {
                                Circle().fill(Color.appFlaeche)
                            } else {
                                Color.clear.glasFlaeche(.circle)
                            }
                            Image(systemName: e.symbol)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(e.aktiv ? Color.onAccent : .primary)
                        }
                        .frame(width: Theme.rundKnopf, height: Theme.rundKnopf)
                        // N-20: Beschriftung bleibt auch bei Bedienungshilfen-Größen sichtbar, nur die Schriftgröße ist nach oben begrenzt
                        Text(e.titel).font(.caption2).foregroundStyle(.secondary)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
                    .opacity(e.gesperrt ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .disabled(e.gesperrt)
                .accessibilityLabel(Text(e.titel))
                .accessibilityAddTraits(e.aktiv ? .isSelected : [])
            }
        }
        .padding(.horizontal, Theme.seitenRand)
    }
}

/// Spielfeld als flache Karte: Kartenfläche, Radius 20, 6 pt Rand, kein Rahmen, kein Schatten. Das Brett/Raster kommt von der App.
/// Alternative laut Konzept: Spielinhalt direkt auf dem Grund (dann diesen Baustein nicht benutzen).
public struct SpielfeldKarte<Inhalt: View>: View {
    let inhalt: Inhalt

    public init(@ViewBuilder inhalt: () -> Inhalt) { self.inhalt = inhalt() }

    @Environment(\.designArt) private var art

    public var body: some View {
        if art == .klar {
            inhalt
                .padding(Theme.spielfeldRand)
                .background(Color.kartenGrund, in: .rect(cornerRadius: Theme.cardRadius))
        } else {
            // Tinte und Salon: kein Grund, der Inhalt steht direkt auf dem Papier (gleicher Rand, damit Bretter gleich groß bleiben)
            inhalt.padding(Theme.spielfeldRand)
        }
    }
}

/// Avatar eines Spielers: grauer Kreis mit Anfangsbuchstabe, Ring in der Spielerfarbe (Spielerfarben nur im Inhalt, Konzept 3.3).
public struct SpielerAvatar: View {
    let name: String
    let farbe: Color?
    var groesse: CGFloat = 36
    /// Avatar-Zeichen (Emoji) statt der Initiale (2.7, Wunsch 15).
    var symbol: String? = nil
    /// Foto als Bilddaten (2.12); hat Vorrang vor Zeichen und Initiale.
    var bild: Data? = nil

    @Environment(\.designArt) private var art

    public init(name: String, farbe: Color?, groesse: CGFloat = 36, symbol: String? = nil, bild: Data? = nil) {
        self.name = name; self.farbe = farbe; self.groesse = groesse; self.symbol = symbol; self.bild = bild
    }

    public var body: some View {
        if art == .klar { klar } else { gefuellt }
    }

    /// Tinte: gefüllter Kreis in der Spielerfarbe mit weißer Initiale (Foto bleibt Foto).
    /// Salon: gefüllter Kreis, Initiale in Serifenschrift, ab 56 pt mit Creme-Rand (4 pt).
    private var gefuellt: some View {
        let initiale = name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
        let rand: CGFloat = art == .salon && groesse >= 56 ? (groesse >= 120 ? 5 : 4) : 0
        return Group {
            if let bild, let foto = UIImage(data: bild) {
                Image(uiImage: foto).resizable().scaledToFill()
            } else if let symbol, !symbol.isEmpty {
                Text(verbatim: symbol).font(.system(size: groesse * 0.55))
            } else {
                Text(verbatim: initiale)
                    .font(.system(size: groesse * 0.42, weight: art == .salon ? .medium : .bold, design: art == .salon ? .serif : .default))
                    .foregroundStyle(farbe == nil ? Color.schrift : Color.white)
            }
        }
        .frame(width: groesse, height: groesse)
        .background(farbe ?? Color.feldGrund, in: .circle)
        .clipShape(.circle)
        .overlay { if rand > 0 { Circle().strokeBorder(Color.seitenGrund, lineWidth: rand) } }
        .accessibilityHidden(true)
    }

    private var klar: some View {
        let initiale = name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
        return Group {
            if let bild, let foto = UIImage(data: bild) {
                Image(uiImage: foto).resizable().scaledToFill()
            } else if let symbol, !symbol.isEmpty {
                Text(verbatim: symbol).font(.system(size: groesse * 0.55))
            } else {
                Text(verbatim: initiale).font(.system(size: groesse * 0.42, weight: .semibold)).foregroundStyle(.primary)
            }
        }
            .frame(width: groesse, height: groesse)
            .background(Color.feldGrund, in: .circle)
            .clipShape(.circle)
            .overlay { if let farbe { Circle().strokeBorder(farbe, lineWidth: 2.5) } }
            .accessibilityHidden(true)
    }
}

/// Spielerleiste im Spiel: Karte ohne Rand mit Avataren, Namen und Wert (Punkte, Würfe). Aktiver Spieler = accentSoft-Fläche
/// + Spielerfarbpunkt. Für 2–6 Spieler; bei großer Schrift wächst die Karte, nicht die Leiste.
public struct SpielerLeiste: View {
    public struct Eintrag: Identifiable {
        public let id: String
        public let name: String
        public let farbe: Color?
        public let wert: String?
        public init(id: String, name: String, farbe: Color? = nil, wert: String? = nil) {
            self.id = id; self.name = name; self.farbe = farbe; self.wert = wert
        }
    }

    let eintraege: [Eintrag]
    let aktiv: String?
    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar
    @Environment(\.designArt) private var art

    /// Formzeichen je Sitz („Farben unterscheidbar“, G2): Kreis, Quadrat, Dreieck, Raute, Stern, Sechseck.
    public static let sitzZeichen = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill", "star.fill", "hexagon.fill"]

    public init(eintraege: [Eintrag], aktiv: String?) {
        self.eintraege = eintraege; self.aktiv = aktiv
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Design.Abstand.xs) {
            ForEach(Array(eintraege.enumerated()), id: \.element.id) { i, e in
                let istDran = e.id == aktiv
                let zeichen = Self.sitzZeichen[i % Self.sitzZeichen.count]
                VStack(spacing: Design.Abstand.xs) {
                    SpielerAvatar(name: e.name, farbe: e.farbe)
                        .overlay(alignment: .bottomTrailing) {
                            if farbenUnterscheidbar, let farbe = e.farbe {
                                Image(systemName: zeichen).font(.system(size: 9, weight: .bold)).foregroundStyle(farbe)
                                    .frame(width: 16, height: 16).background(art == .klar ? Color.kartenGrund : Color.seitenGrund, in: Circle())
                                    .offset(x: 3, y: 3)
                            }
                        }
                    HStack(spacing: Design.Abstand.xs) {
                        if istDran, let farbe = e.farbe {
                            if farbenUnterscheidbar { Image(systemName: zeichen).font(.system(size: 8)).foregroundStyle(farbe) }
                            else { Circle().fill(farbe).frame(width: 7, height: 7) }
                        }
                        // Salon: beide Namen in der Serife (aktiv fett mit Punkt, sonst normal); Tinte: halbfett bzw. normal. Nicht aktiv in „Schrift zweit“.
                        Text(verbatim: e.name)
                            .font(art == .salon ? Design.Schrift.serif(15, gewicht: istDran ? .bold : .regular, relativ: .caption, hoechstens: 1.2)
                                                : .caption.weight(istDran ? .semibold : .regular))
                            .foregroundColor(art != .klar && !istDran ? (art == .tinte ? Color.schrift.opacity(0.82) : Color.schriftZweit) : nil)   // 2.49: Tinte nicht dran lesbarer
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    if let wert = e.wert {
                        Text(verbatim: wert).font(Design.Schrift.zahl(.subheadline).weight(.bold).monospacedDigit())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8).padding(.horizontal, 4)
                .background(aktivGrund(istDran), in: .rect(cornerRadius: art == .tinte ? 18 : Theme.feldRadius, style: .continuous))   // Design-Runde 3: in Tinte rund
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(leiste(e, istDran: istDran))
            }
        }
        .padding(.horizontal, art == .klar ? 8 : 0).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(art == .klar ? Color.kartenGrund : Color.clear, in: .rect(cornerRadius: Theme.cardRadius))
        .overlay(alignment: .bottom) { if art != .klar { ZeilenLinie() } }
    }

    /// Fläche hinter dem aktiven Spieler: klar zarte App-Farbe, Tinte durchscheinende Schriftfarbe (14 %), Salon keine (dort trägt die Schrift).
    private func aktivGrund(_ istDran: Bool) -> Color {
        guard istDran else { return .clear }
        switch art {
        case .klar: return .accentSoft
        case .tinte: return Color.schrift.opacity(0.14)   // Design-Runde 3: durchscheinend statt Feldgrund; hell auf dem Filz, zart auf Papier
        case .salon: return .clear
        }
    }

    private func leiste(_ e: Eintrag, istDran: Bool) -> Text {
        var t = Text(verbatim: e.name)
        if let wert = e.wert { t = t + Text(verbatim: ", \(wert)") }
        if istDran { t = t + Text(verbatim: ", ") + Text("ist dran", bundle: .module) }
        return t
    }
}

#endif
