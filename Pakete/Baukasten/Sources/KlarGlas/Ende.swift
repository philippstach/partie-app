// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Ende-Bildschirme (Konzept 3.4 „Ende“, Beschluss E3: EIN Sieger-Baustein für alle Apps).
// Sieger: Teilen (Rundknopf oben links, optional), Schließen oben rechts, Symbolkreis ODER App-Motiv, Titel `.largeTitle` fett
// in Textfarbe, Untertitel grau, Karten (Stand, Rangliste, Info), unten Zweit- + Hauptknopf.
// Zwischenstand (Halbzeit, Runde, Spielerwechsel): derselbe Aufbau mit EINEM Hauptknopf „Weiter“.

/// Eine Zeile der Rangliste.
public struct RangEintrag: Identifiable {
    public var id: String { "\(name)|\(punkte)" }
    public let name: String
    public let punkte: String
    /// Optional: eigene Platzanzeige, z. B. „1.“ für beide bei Gleichstand. Ohne Angabe wird 1, 2, 3 … gezählt.
    public var platz: String? = nil

    public init(name: String, punkte: String, platz: String? = nil) {
        self.name = name; self.punkte = punkte; self.platz = platz
    }
}

/// Spielstand-Karte des Sieger-Bildschirms (Mockup Viererreihe: „7 : 4“ mit Namen darunter).
public struct SiegerStand {
    public let links: (zahl: String, name: String)
    public let rechts: (zahl: String, name: String)

    public init(links: (zahl: String, name: String), rechts: (zahl: String, name: String)) {
        self.links = links; self.rechts = rechts
    }
}

#if canImport(UIKit)

/// Eine Spalte der Spielstand-Karte: Zahl (Rounded, einzeilig, schrumpft bis 0,5) über dem Namen.
struct StandSpalte: View {
    let zahl: String
    let name: String
    let akzent: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: zahl)
                .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.5)
                .foregroundStyle(akzent ? Color.accentText : Color.primary)
            // 2.6 (Wunsch 14): Name einzeilig und schrumpfend statt mit Trennstrich („Compu-ter“) umgebrochen.
            Text(verbatim: name).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Gemeinsamer Aufbau von Sieger- und Zwischenstand-Bildschirm. Nicht direkt benutzen.
struct EndeKern<Motiv: View, Unten: View>: View {
    let symbol: String
    let titel: String
    let untertitel: String
    let rangliste: [RangEintrag]
    let info: String?
    let stand: SiegerStand?
    let ansehen: (() -> Void)?
    let teilen: (() -> Void)?
    let schliessen: (() -> Void)?
    let motiv: Motiv
    let unten: Unten

    init(symbol: String, titel: String, untertitel: String, rangliste: [RangEintrag], info: String?, stand: SiegerStand?,
         ansehen: (() -> Void)?, teilen: (() -> Void)?, schliessen: (() -> Void)?, motiv: Motiv, @ViewBuilder unten: () -> Unten) {
        self.symbol = symbol; self.titel = titel; self.untertitel = untertitel; self.rangliste = rangliste; self.info = info
        self.stand = stand; self.ansehen = ansehen; self.teilen = teilen; self.schliessen = schliessen
        self.motiv = motiv; self.unten = unten()
    }

    private var mitMotiv: Bool { Motiv.self != EmptyView.self }
    private var mitKopf: Bool { teilen != nil || schliessen != nil }
    @State private var sichtHoehe: CGFloat = 0   // Wunsch 7: kurzer Inhalt steht mittig, langer scrollt wie bisher
    @Environment(\.designArt) private var art
    @Environment(\.endeSpielName) private var spielName

    var body: some View {
        switch art {
        case .klar: klar
        case .tinte: protokoll
        case .salon: titelseite
        }
    }

    // MARK: Gemeinsames für Tinte und Salon

    /// Ob der Titel der Name des Siegers ist (dann wird die Schlagzeile „Clara\ngewinnt.“). Erkannt am ersten Platz der
    /// Rangliste oder am Spielerverzeichnis; „Remis“, „Geschafft!“, „Verloren“ usw. bleiben, wie das Spiel sie liefert.
    private var titelIstName: Bool {
        guard !titel.isEmpty else { return false }
        if let erster = rangliste.first, erster.name == titel { return true }
        return KlarGlasHaken.spielerBild?(titel) != nil
    }
    private var schlagzeile: Text {
        titelIstName ? Text("\(titel)\ngewinnt.", bundle: .module) : Text(verbatim: titel)
    }
    private var datumKurz: String { Date.now.formatted(.dateTime.day().month(.abbreviated)) }
    /// 2.26 G-017/N-024: Name des Spiels für die Kopfzeile, in allen drei Designs gleich: vom Spiel gesetzt (`endeSpielName`),
    /// sonst vom Haken der App (aktuelles Spiel). Vorher hatte Klar & Glas gar keinen, Tinte nur mit `endeSpielName`.
    private var nameDesSpiels: String? { spielName ?? KlarGlasHaken.spielName?() }
    /// 2.26 G-017: Untertitel nur, wenn er nicht den Sieger wiederholt („Anna“ als Titel und „Anna gewinnt.“ darunter).
    private var zeigtUntertitel: Bool {
        guard !untertitel.isEmpty else { return false }
        return !(titelIstName && untertitel.localizedCaseInsensitiveContains(titel))
    }
    /// Zeilen des Hinweistexts (jede Zeile eine Tabellenzeile).
    private var infoZeilen: [String] { (info ?? "").split(separator: "\n").map(String.init).filter { !$0.isEmpty } }
    /// Art des Ausgangs, am Symbol abgelesen (die Spiele liefern `trophy`, `flag.checkered`, `xmark`, `equal.circle.fill` …).
    private enum Ausgang { case sieg, niederlage, remis }
    private var ausgang: Ausgang {
        if symbol.hasPrefix("equal") { return .remis }
        if symbol.hasPrefix("flag.checkered") || symbol.hasPrefix("xmark") { return .niederlage }
        return .sieg
    }

    // MARK: Tinte – Protokollseite

    private var protokoll: some View {
        VStack(spacing: Theme.kartenAbstand) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: Design.Abstand.s) {
                        // F-AWS-N-024: Spielname vor dem Datum, wenn das Spiel ihn über `endeSpielName` mitgibt
                        ((nameDesSpiels.map { Text(verbatim: "\($0) · ") } ?? Text(verbatim: ""))
                            + Text("Protokoll · \(datumKurz)", bundle: .module))
                            .font(Design.Schrift.serif(18, relativ: .body, kursiv: true)).foregroundStyle(Color.schriftZweit)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Spacer(minLength: 8)
                        // Design-Runde 5 (Blatt 8): „Teilen“ und Schließen als eingefasste Knöpfe statt Wort mit Linie und losem Zeichen
                        if let teilen {
                            Button(action: teilen) {
                                Text("Teilen", bundle: .module).font(.callout.weight(.semibold)).foregroundStyle(Color.schrift)
                                    .lineLimit(1)
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: Theme.tapSize)
                                    .overlay(Capsule().strokeBorder(Color.schrift, lineWidth: 1.5))
                                    .contentShape(.capsule)
                            }
                            .buttonStyle(.plain)
                        }
                        if let schliessen {
                            Button(action: schliessen) {
                                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.schrift)
                                    .frame(width: Theme.tapSize, height: Theme.tapSize)
                                    .overlay(Circle().strokeBorder(Color.schrift, lineWidth: 1.5))
                                    .contentShape(.circle)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Schließen", bundle: .module))
                        }
                    }
                    .frame(minHeight: Theme.tapSize)
                    schlagzeile
                        .font(Design.Schrift.schlagzeileSchrift())
                        .tracking(-0.02 * Design.Schrift.schlagzeile)
                        .foregroundStyle(Color.schrift)
                        .lineLimit(3).minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 30)
                    if zeigtUntertitel {
                        Text(verbatim: untertitel).font(.subheadline.monospacedDigit()).foregroundStyle(Color.schriftZweit)
                            .padding(.top, 6)
                    }
                    if !rangliste.isEmpty {
                        ZeilenLinie(stark: true).padding(.top, 18)
                        ForEach(Array(rangliste.enumerated()), id: \.element.id) { i, e in
                            HStack(alignment: .firstTextBaseline, spacing: Design.Abstand.s) {
                                Text(verbatim: "\(e.platz ?? "\(i + 1)") · \(e.name)")
                                    .font(Design.Schrift.serif(17, relativ: .body)).lineLimit(1).minimumScaleFactor(0.6)
                                Spacer(minLength: 8)
                                Text(verbatim: e.punkte).font(Design.Schrift.zahl(.body).weight(i == 0 ? .bold : .regular))
                                    .lineLimit(1).minimumScaleFactor(0.6)
                            }
                            .foregroundStyle(Color.schrift)
                            .frame(minHeight: 36)
                            .linieUnten()
                            .accessibilityElement(children: .combine)
                        }
                    }
                    if let stand {
                        DesignWertZeile(label: Text(verbatim: "\(stand.links.name) · \(stand.rechts.name)"),
                                        wert: Text(verbatim: "\(stand.links.zahl) : \(stand.rechts.zahl)"))
                    }
                    ForEach(infoZeilen, id: \.self) { zeile in
                        DesignZeile(hoehe: 48) {
                            Text(verbatim: zeile).font(Design.Schrift.serif(17, relativ: .body)).foregroundStyle(Color.schrift)
                                .fixedSize(horizontal: false, vertical: true).padding(.vertical, 8)
                        }
                    }
                    if mitMotiv { motiv.padding(.top, 16) }   // Motiv der Spiele (Brett usw.) ohne Kartenfläche
                    if let ansehen {
                        Button(action: ansehen) {
                            Text("Partie ansehen", bundle: .module).font(.callout.weight(.semibold)).foregroundStyle(Color.schrift)
                                .lineLimit(1)
                                .padding(.horizontal, 16)
                                .frame(minHeight: Theme.tapSize)
                                .overlay(Capsule().strokeBorder(Color.schrift, lineWidth: 1.5))
                                .contentShape(.capsule)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 14)
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .padding(.bottom, Theme.seitenRand)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            unten
        }
        .padding(.horizontal, Theme.seitenRand)
        .padding(.bottom, 8)
        .iPadSpalte()
        .background(Color.seitenGrund)
    }

    // MARK: Salon – Titelseite

    /// Seitenfarbe und Schrift: Sieg Bordeaux, Niederlage Espresso, Remis Nachtblau; Zwischenstand (ohne Kopf) die
    /// Spielart-Farbe. Schrift Creme bzw. die Schrift auf der Spielart-Fläche.
    private var salonSeite: (flaeche: Color, schrift: Color) {
        let w = Design.werte
        if !mitKopf, let f = Design.spielFarben { return (f.flaecheFuerKleineSchrift, f.aufFlaeche) }
        let paar: (flaeche: UInt32, schrift: UInt32)?
        switch ausgang {
        case .sieg: paar = w.siegerSeite
        case .niederlage: paar = w.niederlageSeite
        case .remis: paar = w.remisSeite
        }
        guard let paar else { return (Color.hinweisFlaecheHuelle, w.aufHuelleFlaeche.color) }
        return (Color(hex: paar.flaeche), Color(hex: paar.schrift))
    }

    private var titelseite: some View {
        let seite = salonSeite
        let portraet = titelIstName ? KlarGlasHaken.spielerBild?(titel) : nil
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if mitKopf {
                        HStack(spacing: Design.Abstand.s) {
                            if let teilen {
                                Button(action: teilen) {
                                    Text("Teilen", bundle: .module).frame(minHeight: Theme.tapSize, alignment: .leading).contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer(minLength: 4)
                            Text(verbatim: [nameDesSpiels, datumKurz].compactMap { $0 }.joined(separator: " · "))
                                .lineLimit(1).minimumScaleFactor(0.6)
                            Spacer(minLength: 4)
                            if let schliessen {
                                Button(action: schliessen) {
                                    Text("Schließen", bundle: .module).frame(minHeight: Theme.tapSize, alignment: .trailing).contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .font(Design.Schrift.label).tracking(Design.Schrift.labelSperrung).textCase(.uppercase)
                    }
                    // Porträt des Siegers (150 pt, Creme-Rand 5 pt), linksbündig; ohne Person ein Kreis in der Spielart-Farbe mit dem Symbol.
                    Group {
                        if let portraet {
                            SpielerAvatar(name: titel, farbe: portraet.farbe, groesse: 150, symbol: portraet.zeichen, bild: portraet.bild)
                                .overlay { Circle().strokeBorder(seite.schrift, lineWidth: 5) }
                        } else {
                            Image(systemName: symbol).font(.system(size: 60, weight: .bold)).foregroundStyle(seite.schrift)
                                .frame(width: 150, height: 150)
                                .background(mitKopf ? (Design.spielFarben?.flaeche ?? Color.white.opacity(0.14)) : seite.schrift.opacity(0.14), in: Circle())
                                .overlay { Circle().strokeBorder(seite.schrift, lineWidth: 5) }
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.top, mitKopf ? 20 : 36)
                    // Die Schlagzeile schneidet das Porträt nur an (Entwurf: Text liegt über dem Bild). Sie liegt in der Ebene darüber,
                    // damit der erste Buchstabe nie vom Porträt verdeckt wird; die Überlappung ist kleiner als der Leerraum über der Oberlänge.
                    schlagzeile
                        .font(Design.Schrift.schlagzeileSchrift().leading(.tight))
                        .tracking(-0.03 * Design.Schrift.schlagzeile)
                        .lineSpacing(-Design.Schrift.schlagzeile * 0.08)
                        .lineLimit(3).minimumScaleFactor(0.4)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, -14)
                        .zIndex(1)
                    if zeigtUntertitel {
                        Text(verbatim: untertitel).font(Design.Schrift.serif(18, gewicht: .light, relativ: .body, kursiv: true))
                            .monospacedDigit().fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 14)
                    }
                    if mitMotiv { motiv.padding(.top, 18) }   // große Motive (Brett) stehen unter der Schlagzeile
                    let rest = Array(rangliste.enumerated()).filter { !titelIstName || $0.offset > 0 }
                    if !rest.isEmpty || stand != nil || !infoZeilen.isEmpty {
                        ZeilenLinie(farbe: seite.schrift.opacity(0.33)).padding(.top, 24)
                        ForEach(rest, id: \.element.id) { i, e in
                            salonZeile(Text(verbatim: "\(e.platz ?? "\(i + 1)") · \(e.name)"), wert: e.punkte, linie: seite.schrift)
                        }
                        if let stand {
                            salonZeile(Text(verbatim: "\(stand.links.name) · \(stand.rechts.name)"),
                                       wert: "\(stand.links.zahl) : \(stand.rechts.zahl)", linie: seite.schrift)
                        }
                        ForEach(infoZeilen, id: \.self) { zeile in
                            salonZeile(Text(verbatim: zeile), wert: nil, linie: seite.schrift)
                        }
                    }
                    if let ansehen {
                        Button(action: ansehen) {
                            Text("Partie ansehen", bundle: .module).font(Design.Schrift.label).tracking(Design.Schrift.labelSperrung).textCase(.uppercase)
                                .unterstrichen(2, farbe: seite.schrift).frame(minHeight: Theme.tapSize)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .padding(.bottom, Theme.seitenRand)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            // Unten zwei Rechteck-Knöpfe ohne Abstand: Rand-Knopf und gefüllter Knopf in der Schriftfarbe der Seite.
            unten.environment(\.knopfFarben, (flaeche: seite.schrift, schrift: seite.flaeche))
        }
        .foregroundStyle(seite.schrift)
        .padding(.horizontal, Theme.seitenRand)
        .padding(.bottom, 8)
        .iPadSpalte()
        .background(seite.flaeche.ignoresSafeArea())
    }

    private func salonZeile(_ text: Text, wert: String?, linie: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Abstand.s) {
            text.font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            if let wert {
                Text(verbatim: wert).font(Design.Schrift.serif(20, gewicht: .bold, relativ: .title3)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(minHeight: 40)
        .overlay(alignment: .bottom) { ZeilenLinie(farbe: linie.opacity(0.33)) }
        .accessibilityElement(children: .combine)
    }

    // MARK: Klar & Glas (unverändert)

    private var klar: some View {
        VStack(spacing: Theme.kartenAbstand) {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    if mitKopf {
                        // 2.26 T-021/G-017: Kopf mit dem Namen des Spiels; „Teilen“ als beschrifteter Knopf statt kleinem Symbolkreis.
                        HStack(spacing: Design.Abstand.s) {
                            if let teilen {
                                Button(action: teilen) {
                                    Label { Text("Teilen", bundle: .module) } icon: { Image(systemName: "square.and.arrow.up") }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.accentText)
                                        .padding(.horizontal, 14)
                                        .frame(minHeight: Theme.tapSize)
                                        .glasFlaeche(.capsule)
                                        .contentShape(.capsule)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer(minLength: 4)
                            if let schliessen {
                                RundKnopf(symbol: "xmark", beschriftungText: Text("Schließen", bundle: .module), klein: false, aktion: schliessen)
                            }
                        }
                        .overlay {
                            if let n = nameDesSpiels {
                                Text(verbatim: n).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                    .padding(.horizontal, 120)   // frei von Teilen und Schließen
                                    .accessibilityAddTraits(.isHeader)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 6) {
                        if !mitMotiv {
                            Image(systemName: symbol)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color.appFlaeche)
                                .frame(width: 88, height: 88)
                                .background(Color.accentSoft, in: .circle)
                                .accessibilityHidden(true)
                        }
                        Text(verbatim: titel).font(.system(.largeTitle, design: .default).weight(.bold))
                            .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                        if zeigtUntertitel {
                            Text(verbatim: untertitel).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, mitKopf ? 8 : 24)
                    if mitMotiv { motiv }
                    if let stand {
                        // Wunsch 9 (2.4): Zahlen bleiben einzeilig (schrumpfen), bei großer Schrift stehen beide Werte untereinander.
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                StandSpalte(zahl: stand.links.zahl, name: stand.links.name, akzent: true)
                                Text(verbatim: ":").font(.title3).foregroundStyle(.secondary)
                                StandSpalte(zahl: stand.rechts.zahl, name: stand.rechts.name, akzent: false)
                            }
                            VStack(spacing: 10) {
                                StandSpalte(zahl: stand.links.zahl, name: stand.links.name, akzent: true)
                                Divider()
                                StandSpalte(zahl: stand.rechts.zahl, name: stand.rechts.name, akzent: false)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // 2.6 (Wunsch 14): Spielstand-Karte wächst nur bis xxxLarge
                        .card()
                    }
                    if !rangliste.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(rangliste.enumerated()), id: \.element.id) { i, e in
                                // 2.8 (Wunsch 16): Platz einzeilig und so breit wie nötig (bei AXXXL brach „1.“ in zwei Zeilen),
                                // Name und Punkte einzeilig mit Schrumpfen, die ganze Karte wächst nur bis xxxLarge (wie SiegerStand).
                                HStack(spacing: Design.Abstand.m) {
                                    Text(verbatim: e.platz ?? "\(i + 1)").font(.system(.body, design: .rounded).weight(.bold))
                                        .lineLimit(1).fixedSize()
                                        .foregroundStyle(i == 0 ? Color.accentText : Color.secondary).frame(minWidth: 22, alignment: .leading)
                                    Text(verbatim: e.name).font(.body).lineLimit(1).minimumScaleFactor(0.6)
                                    Spacer(minLength: 8)
                                    Text(verbatim: e.punkte).font(.system(.body, design: .rounded).weight(.bold).monospacedDigit())
                                        .lineLimit(1).minimumScaleFactor(0.6)
                                }
                                .padding(.vertical, 12)
                                if i < rangliste.count - 1 { Divider() }
                            }
                        }
                        .padding(.horizontal, Theme.innen)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .background(Color.kartenGrund, in: .rect(cornerRadius: Theme.cardRadius))
                    }
                    if let info {
                        Text(verbatim: info).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading).card()
                    }
                    if let ansehen {
                        Button(action: ansehen) {
                            Text("Partie ansehen", bundle: .module).font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, Theme.seitenRand)   // 2.5 (Wunsch 13): wie das Neues-Spiel-Blatt, 16 pt Luft vor den Knöpfen
                .frame(maxWidth: .infinity, minHeight: sichtHoehe)
            }
            .background(GeometryReader { g in Color.clear.preference(key: InhaltHoehe.self, value: g.size.height) })
            .onPreferenceChange(InhaltHoehe.self) { sichtHoehe = $0 }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            // 2.5 (Wunsch 13): Langer Inhalt (z. B. Brett bei XXXL) wird unten weich ausgeblendet statt hart abgeschnitten.
            .mask {
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: Theme.seitenRand)
                }
            }
            unten
        }
        .padding(.horizontal, Theme.seitenRand)
        .padding(.bottom, 8)
        .iPadSpalte()
        .background(Color.seitenGrund)
    }
}

/// Sieger-/Ende-Bildschirm für alle Apps (E3). Symbol: `trophy` Sieg, `flag.checkered`/`xmark` verloren, `checkmark.seal` geschafft.
/// Optional: `motiv` (ViewBuilder-Slot, z. B. Brett, Ballons, Kartenfächer, Sieger-Avatar) steht statt Symbolkreis unter dem Titel,
/// `stand` zeigt eine Spielstand-Karte („7 : 4“), `ansehen` einen Textknopf („Partie ansehen“), `teilen` den Rundknopf oben links.
/// Unten: Zweitknopf („Zum Start“) + Hauptknopf („Revanche“, „Nächstes“). Der Spielinhalt (Rang, Punkte) kommt von außen.
public struct SiegerBildschirm<Motiv: View>: View {
    let symbol: String
    let titel: String
    let untertitel: String
    let rangliste: [RangEintrag]
    var info: String? = nil
    var stand: SiegerStand? = nil
    var ansehen: (() -> Void)? = nil
    var teilen: (() -> Void)? = nil
    let sekundaerTitel: LocalizedStringKey
    let primaerTitel: LocalizedStringKey
    let schliessen: () -> Void
    let sekundaer: () -> Void
    let primaer: () -> Void
    let motiv: Motiv
    @Environment(\.designArt) private var art

    public init(symbol: String, titel: String, untertitel: String, rangliste: [RangEintrag] = [], info: String? = nil,
                stand: SiegerStand? = nil, ansehen: (() -> Void)? = nil, teilen: (() -> Void)? = nil,
                sekundaerTitel: LocalizedStringKey, primaerTitel: LocalizedStringKey,
                schliessen: @escaping () -> Void, sekundaer: @escaping () -> Void, primaer: @escaping () -> Void,
                @ViewBuilder motiv: () -> Motiv) {
        self.symbol = symbol; self.titel = titel; self.untertitel = untertitel; self.rangliste = rangliste; self.info = info
        self.stand = stand; self.ansehen = ansehen; self.teilen = teilen
        self.sekundaerTitel = sekundaerTitel; self.primaerTitel = primaerTitel
        self.schliessen = schliessen; self.sekundaer = sekundaer; self.primaer = primaer; self.motiv = motiv()
    }

    public var body: some View {
        EndeKern(symbol: symbol, titel: titel, untertitel: untertitel, rangliste: rangliste, info: info, stand: stand,
                 ansehen: ansehen, teilen: teilen, schliessen: schliessen, motiv: motiv) {
            // Salon: zwei Rechteck-Knöpfe ohne Abstand
            AdaptiveStack(spacing: art == .salon ? 0 : Design.Abstand.s) {
                Button(action: sekundaer) { Text(sekundaerTitel).lineLimit(1).minimumScaleFactor(0.7) }.zweitKnopf()
                Button(action: primaer) { Text(primaerTitel).lineLimit(1).minimumScaleFactor(0.7) }.hauptKnopf()
            }
        }
    }
}

public extension SiegerBildschirm where Motiv == EmptyView {
    init(symbol: String, titel: String, untertitel: String, rangliste: [RangEintrag] = [], info: String? = nil,
         stand: SiegerStand? = nil, ansehen: (() -> Void)? = nil, teilen: (() -> Void)? = nil,
         sekundaerTitel: LocalizedStringKey, primaerTitel: LocalizedStringKey,
         schliessen: @escaping () -> Void, sekundaer: @escaping () -> Void, primaer: @escaping () -> Void) {
        self.init(symbol: symbol, titel: titel, untertitel: untertitel, rangliste: rangliste, info: info, stand: stand,
                  ansehen: ansehen, teilen: teilen, sekundaerTitel: sekundaerTitel, primaerTitel: primaerTitel,
                  schliessen: schliessen, sekundaer: sekundaer, primaer: primaer, motiv: { EmptyView() })
    }
}

/// Zwischenstand (Halbzeit, Rundenende, Spielerwechsel): derselbe Aufbau wie der Sieger-Bildschirm, unten EIN Hauptknopf „Weiter“.
/// Kein Schließen-Knopf: Weiter ist der einzige Weg. Symbol z. B. `flag`, `arrow.triangle.2.circlepath`, `person.fill`.
public struct ZwischenstandBildschirm<Motiv: View>: View {
    let symbol: String
    let titel: String
    let untertitel: String
    let rangliste: [RangEintrag]
    var info: String? = nil
    var stand: SiegerStand? = nil
    let weiterTitel: Text
    let weiter: () -> Void
    let motiv: Motiv

    public init(symbol: String, titel: String, untertitel: String, rangliste: [RangEintrag] = [], info: String? = nil,
                stand: SiegerStand? = nil, weiterTitel: LocalizedStringKey? = nil, weiter: @escaping () -> Void,
                @ViewBuilder motiv: () -> Motiv) {
        self.symbol = symbol; self.titel = titel; self.untertitel = untertitel; self.rangliste = rangliste; self.info = info
        self.stand = stand; self.weiterTitel = weiterTitel.map { Text($0) } ?? Text("Weiter", bundle: .module)
        self.weiter = weiter; self.motiv = motiv()
    }

    public var body: some View {
        EndeKern(symbol: symbol, titel: titel, untertitel: untertitel, rangliste: rangliste, info: info, stand: stand,
                 ansehen: nil, teilen: nil, schliessen: nil, motiv: motiv) {
            Button(action: weiter) { weiterTitel.lineLimit(1).minimumScaleFactor(0.7) }.hauptKnopf()
        }
    }
}

public extension ZwischenstandBildschirm where Motiv == EmptyView {
    init(symbol: String, titel: String, untertitel: String, rangliste: [RangEintrag] = [], info: String? = nil,
         stand: SiegerStand? = nil, weiterTitel: LocalizedStringKey? = nil, weiter: @escaping () -> Void) {
        self.init(symbol: symbol, titel: titel, untertitel: untertitel, rangliste: rangliste, info: info, stand: stand,
                  weiterTitel: weiterTitel, weiter: weiter, motiv: { EmptyView() })
    }
}

#endif


private struct EndeSpielNameSchluessel: EnvironmentKey { static let defaultValue: String? = nil }
public extension EnvironmentValues {
    /// Name des Spiels für die Kopfzeile der Endseite (Tinte: „Minensuche · Protokoll · 12. Nov“). Ein Spiel setzt ihn mit
    /// `.environment(\.endeSpielName, "Minensuche")` auf seinen Sieger- oder Endbildschirm.
    var endeSpielName: String? {
        get { self[EndeSpielNameSchluessel.self] }
        set { self[EndeSpielNameSchluessel.self] = newValue }
    }
}
