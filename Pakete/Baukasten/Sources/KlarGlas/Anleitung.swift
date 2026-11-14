// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Spielanleitung zum Durchwischen (KlarGlas 2.11).
// Ein Blatt mit Seiten (TabView): oben die Bühne mit einer kleinen Animation, darunter Titel und Text,
// unten Punkte und Hauptknopf. Jedes Spiel liefert nur die Schritte; Optik, Bewegung und Barrierefreiheit sind hier.
// Keine Anleitung beim ersten Start (Konzept 3.4): das Blatt öffnet der Regeln-Knopf.

#if canImport(UIKit)

/// Welche Geste der Finger auf der Bühne zeigt.
public enum AnleitungGeste: Sendable, Equatable {
    case keine
    /// Antippen an einem Punkt (0…1 in der Bühne), mit Welle.
    case tippen(UnitPoint = .center)
    /// Wischen von einem Punkt zum anderen (ohne Mitnahme).
    case wischen(von: UnitPoint, nach: UnitPoint)
    /// Ziehen: der Finger nimmt etwas mit. Das Spiel zeichnet das Mitgenommene selbst, es liest dafür `fortschritt`.
    case ziehen(von: UnitPoint, nach: UnitPoint)
    /// Gedrückt halten (Ring füllt sich).
    case halten(UnitPoint = .center)
}

/// Ein Schritt der Anleitung. Die Bühne bekommt `fortschritt` (0…1, wiederholt sich) für eigene Bewegung
/// und `aktiv` (false bei „Bewegung reduzieren“ oder wenn die Seite nicht sichtbar ist: dann ein ruhiges Standbild).
public struct AnleitungSchritt: Identifiable {
    public let id = UUID()
    let symbol: String
    let titel: Text
    let text: Text
    let geste: AnleitungGeste
    let buehne: (_ fortschritt: Double, _ aktiv: Bool) -> AnyView

    public init<Buehne: View>(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey,
                              geste: AnleitungGeste = .keine,
                              @ViewBuilder buehne: @escaping (_ fortschritt: Double, _ aktiv: Bool) -> Buehne) {
        self.init(symbol: symbol, titel: Text(titel), text: Text(text), geste: geste, buehne: buehne)
    }

    /// Mit fertig übersetzten Texten (`Text(verbatim:)`), wie bei `ErklaerSheet`.
    public init<Buehne: View>(symbol: String, titel: Text, text: Text, geste: AnleitungGeste = .keine,
                              @ViewBuilder buehne: @escaping (_ fortschritt: Double, _ aktiv: Bool) -> Buehne) {
        self.symbol = symbol; self.titel = titel; self.text = text; self.geste = geste
        self.buehne = { AnyView(buehne($0, $1)) }
    }

    /// Schritt nur mit Geste, ohne eigene Bühne (leere Fläche mit Finger).
    public init(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey, geste: AnleitungGeste) {
        self.init(symbol: symbol, titel: titel, text: text, geste: geste) { _, _ in Color.clear }
    }
}

/// Die Bühne: zarte Fläche in App-Farbe, Radius 20, eigener Inhalt, darüber der Finger.
/// Die Schleife läuft über `TimelineView`; bei „Bewegung reduzieren“ steht sie auf 0,5 (Standbild mit Finger in Mitte der Bewegung).
public struct AnleitungBuehne: View {
    let schritt: AnleitungSchritt
    let aktiv: Bool
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @Environment(\.designArt) private var art
    @Environment(\.colorScheme) private var schema
    private let dauer: Double = 2.4

    public init(schritt: AnleitungSchritt, aktiv: Bool) { self.schritt = schritt; self.aktiv = aktiv }

    public var body: some View {
        let bewegt = aktiv && !ruhig
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !bewegt)) { zeit in
            let t = bewegt ? zeit.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: dauer) / dauer : 0.5
            GeometryReader { geo in
                ZStack {
                    schritt.buehne(Self.weich(t), bewegt)
                        .frame(width: geo.size.width, height: geo.size.height)
                    fingerEbene(t, in: geo.size)
                }
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .background { buehnenFlaeche }
        .clipShape(.rect(cornerRadius: buehnenEcke, style: .continuous))
        // Design-Runde 5, Blatt 11 (nur Tinte): Die Bühne ist ein rundes Stück Filz, kein schwarz umrandeter Kasten mehr. Auf dem Filz
        // gelten die dunklen Farbwerte (wie bei `aufTisch()` in SpieleKern), damit Zeichnung und Finger hell sind.
        .environment(\.colorScheme, art == .tinte ? .dark : schema)
        .accessibilityHidden(true)   // Titel und Text tragen den Inhalt; die Bühne ist Zierde
    }

    /// klar: zarte App-Farbe. Tinte: Filz (siehe `buehnenFlaeche`). Salon: Farbblock in der Spielart-Farbe.
    private var buehnenGrund: Color {
        switch art {
        case .klar: .accentSoft
        case .tinte: .clear
        case .salon: Design.spielFarben?.flaeche ?? Color.appFlaeche
        }
    }

    /// Tinte: Ecke 20 pt, weich; sonst wie bisher der Kartenradius des Designs.
    private var buehnenEcke: CGFloat { art == .tinte ? 20 : Theme.cardRadius }

    /// Tinte: Filz in der Spielart-Farbe nach dem Rezept des Spieltischs (`TischGrund` in SpieleKern: Farbe, 40 % Schwarz, Lichtfleck),
    /// ohne Spielart das Violett der Würfelspiele. Klar und Salon: die Fläche wie bisher.
    @ViewBuilder private var buehnenFlaeche: some View {
        if art == .tinte {
            ZStack {
                Design.spielFarben?.flaeche ?? Color(hex: 0x5A4BB0)
                Color.black.opacity(0.40)
                RadialGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0)],
                               center: UnitPoint(x: 0.5, y: 0.38), startRadius: 0, endRadius: 260)
            }
        } else {
            buehnenGrund
        }
    }

    /// Farbe von Welle und Ring um den Finger: in Tinte Elfenbein auf dem Filz, sonst die Akzentfarbe wie bisher.
    private var zeigeFarbe: Color { art == .tinte ? Color(hex: 0xFFFDF6) : Color.accentText }

    /// Sanftes Ein- und Ausblenden an den Rändern der Schleife, damit der Sprung nicht auffällt.
    static func weich(_ t: Double) -> Double { t }
    /// 0…1…0 über die Schleife für Einblenden.
    private func huelle(_ t: Double) -> Double { min(1, min(t, 1 - t) * 6) }
    private func ease(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    @ViewBuilder
    private func fingerEbene(_ t: Double, in groesse: CGSize) -> some View {
        switch schritt.geste {
        case .keine:
            EmptyView()
        case .tippen(let p):
            let druck = t > 0.35 && t < 0.55
            let welle = max(0, min(1, (t - 0.45) / 0.45))
            ZStack {
                Circle().stroke(zeigeFarbe.opacity(0.5 * (1 - welle)), lineWidth: 3)
                    .frame(width: 30 + 60 * welle, height: 30 + 60 * welle)
                    .opacity(t > 0.45 ? 1 : 0)
                finger(druck: druck).offset(y: druck ? 4 : 14 * (1 - min(1, t / 0.35)))
            }
            .position(x: groesse.width * p.x, y: groesse.height * p.y)
            .opacity(huelle(t) > 0 ? 1 : 0.0)
        case .wischen(let von, let nach):
            let s = ease(min(1, max(0, (t - 0.15) / 0.65)))
            finger(druck: true)
                .position(x: groesse.width * (von.x + (nach.x - von.x) * s), y: groesse.height * (von.y + (nach.y - von.y) * s))
                .opacity(huelle(t))
        case .ziehen(let von, let nach):
            let s = ease(min(1, max(0, (t - 0.2) / 0.6)))
            finger(druck: t > 0.15 && t < 0.85)
                .position(x: groesse.width * (von.x + (nach.x - von.x) * s), y: groesse.height * (von.y + (nach.y - von.y) * s))
                .opacity(huelle(t))
        case .halten(let p):
            let f = ease(min(1, max(0, (t - 0.2) / 0.6)))
            ZStack {
                Circle().stroke(zeigeFarbe.opacity(0.25), lineWidth: 4).frame(width: 72, height: 72)
                Circle().trim(from: 0, to: f).stroke(zeigeFarbe, style: .init(lineWidth: 4, lineCap: .round))
                    .frame(width: 72, height: 72).rotationEffect(.degrees(-90))
                finger(druck: t > 0.2)
            }
            .position(x: groesse.width * p.x, y: groesse.height * p.y)
        }
    }

    private func finger(druck: Bool) -> some View {
        Image(systemName: art == .tinte ? "hand.point.up.left" : "hand.point.up.left.fill")
            .font(.system(size: 34))
            .foregroundStyle(art == .tinte ? Color(hex: 0xFFFDF6) : Color.white)
            .shadow(color: .black.opacity(0.28), radius: druck ? 3 : 8, y: druck ? 2 : 6)
            .scaleEffect(druck ? 0.92 : 1)
            .offset(x: 10, y: 14)   // Fingerspitze liegt auf dem Zielpunkt
    }
}

/// Das fertige Blatt: `.sheet { AnleitungBlatt(titel: "Yacht", schritte: …) }`. Wischen links/rechts blättert,
/// „Weiter“ blättert ebenso und wird auf der letzten Seite zu „Los geht’s“. Überspringen ist immer möglich.
public struct AnleitungBlatt: View {
    let titel: Text
    let schritte: [AnleitungSchritt]
    let fertig: () -> Void
    let ausfuehrlich: AnyView?
    let logo: AnyView?
    @State private var seite = 0
    @State private var ausfuehrlichOffen = false
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @Environment(\.designArt) private var art

    public init(titel: LocalizedStringKey, schritte: [AnleitungSchritt], fertig: @escaping () -> Void) {
        self.init(titel: Text(titel), schritte: schritte, fertig: fertig)
    }
    public init(titel: Text, schritte: [AnleitungSchritt], fertig: @escaping () -> Void) {
        self.titel = titel; self.schritte = schritte; self.fertig = fertig; self.ausfuehrlich = nil; self.logo = nil
    }
    /// Mit der bisherigen Regelseite als Nachschlagewerk: auf der letzten Seite erscheint „Alle Regeln lesen“.
    public init<Detail: View>(titel: LocalizedStringKey, schritte: [AnleitungSchritt], fertig: @escaping () -> Void,
                              logo: AnyView? = nil, @ViewBuilder ausfuehrlich: () -> Detail) {
        self.titel = Text(titel); self.schritte = schritte; self.fertig = fertig; self.ausfuehrlich = AnyView(ausfuehrlich()); self.logo = logo
    }

    private var letzte: Bool { seite >= schritte.count - 1 }

    private func springen(_ ziel: Int) {
        let z = min(max(ziel, 0), schritte.count - 1)
        guard z != seite else { return }
        withAnimation(ruhig ? nil : .smooth) { seite = z }
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if let logo { logo.frame(width: 36, height: 36).clipShape(.rect(cornerRadius: 9)).accessibilityHidden(true) }
                titel.font(art == .klar ? .headline : Design.Schrift.name).accessibilityAddTraits(.isHeader)
                Spacer()
                // Bleibt auf der letzten Seite im Layout (unsichtbar), damit der Kopf nicht springt
                Button(action: fertig) {
                    if art == .tinte { Text("Überspringen").unterstrichen(1, farbe: Color.schriftZweit) } else { Text("Überspringen") }
                }
                    .font(.subheadline).foregroundStyle(art == .tinte ? Color.schriftZweit : Color.secondary)
                    .frame(minHeight: Theme.tapSize)
                    .opacity(letzte ? 0 : 1).disabled(letzte).accessibilityHidden(letzte)
            }
            .padding(.horizontal, Theme.seitenRand + 4)
            .padding(.top, 8)

            TabView(selection: $seite) {
                ForEach(Array(schritte.enumerated()), id: \.element.id) { i, schritt in
                    seiteAnsicht(schritt, aktiv: i == seite).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Blatt 26b (Philipp 14.11.): kein „Weiter“. Gewischt wird mit dem Finger oder durch Tippen auf die Punkte.
            // Der Hauptknopf „Los geht’s“ erscheint nur auf der letzten Seite, über den festen Elementen unten.
            if letzte {
                Button(action: fertig) { Text("Los geht’s").frame(maxWidth: .infinity) }
                    .hauptKnopf()
                    .padding(.horizontal, Theme.seitenRand + 4)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }

            if ausfuehrlich != nil {
                // Auf allen Seiten sichtbar: die ausführlichen Regeln zum Nachschlagen
                Button { ausfuehrlichOffen = true } label: {
                    Label("Alle Regeln lesen", systemImage: "book").frame(maxWidth: .infinity)
                }
                .zweitKnopf()
                .sheet(isPresented: $ausfuehrlichOffen) { ausfuehrlich }
                .padding(.horizontal, Theme.seitenRand + 4)
                .padding(.bottom, 12)
            }

            punkte
                .padding(.bottom, 16)
        }
        .animation(ruhig ? nil : .smooth, value: letzte)
        .background(Color.seitenGrund)
        .designWurzel()
    }

    private func seiteAnsicht(_ schritt: AnleitungSchritt, aktiv: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Abstand.l) {
                AnleitungBuehne(schritt: schritt, aktiv: aktiv)
                HStack(spacing: 10) {
                    if art == .klar {
                        Image(systemName: schritt.symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.accentText)
                            .frame(width: 30, height: 30)
                            .background(Color.accentSoft, in: .circle)
                            .accessibilityHidden(true)
                        schritt.titel.font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    } else {
                        // Tinte und Salon: Symbol ohne Fläche, Titel in Serifenschrift
                        Image(systemName: schritt.symbol)
                            .font(.system(size: 18, weight: art == .salon ? .bold : .light))
                            .foregroundStyle(Color.accentText)
                            .accessibilityHidden(true)
                        schritt.titel.font(Design.Schrift.serif(art == .salon ? 30 : 26, gewicht: art == .salon ? .bold : .medium, relativ: .title2, hoechstens: 1.25))
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                schritt.text.font(.body).foregroundStyle(art == .tinte ? Color.schriftZweit : Color.primary.opacity(0.88))   // Blatt 26b: kräftiger statt .secondary (Tinte bleibt schriftZweit aus 2.48)
            }
            .padding(.horizontal, Theme.seitenRand + 4)
            .padding(.top, 12)
            .frame(maxWidth: Theme.wideColumnWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        // Blatt 26b: weicher Auslauf unten, wenn der Text länger ist als der Platz
        .mask(VStack(spacing: 0) { Color.black; LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 18) })
    }

    private var punkte: some View {
        HStack(spacing: Design.Abstand.s) {
            ForEach(0..<schritte.count, id: \.self) { i in
                Capsule()
                    .fill(art == .klar ? (i == seite ? Color.appFlaeche : Color.appFlaeche.opacity(0.25))
                                       : (i == seite ? Color.schrift : Color.schrift.opacity(0.25)))
                    .frame(width: i == seite ? 22 : 8, height: art == .klar ? 8 : (art == .salon ? 4 : 6))
            }
        }
        .animation(ruhig ? nil : .smooth, value: seite)
        // Blatt 26b: Punkte tippbar (rechte Hälfte weiter, linke zurück) und für VoiceOver einstellbar
        .padding(.horizontal, 24).frame(minHeight: Theme.tapSize)
        .contentShape(.rect)
        .overlay {
            GeometryReader { g in
                HStack(spacing: 0) {
                    Color.clear.contentShape(.rect).onTapGesture { springen(seite - 1) }
                    Color.clear.contentShape(.rect).onTapGesture { springen(seite + 1) }
                }.frame(width: g.size.width, height: g.size.height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Seite \(seite + 1) von \(schritte.count)"))
        .accessibilityAdjustableAction { richtung in
            switch richtung { case .increment: springen(seite + 1); case .decrement: springen(seite - 1); @unknown default: break }
        }
    }
}

// MARK: Bausteine für Bühnen (gezeichnetes Spielmaterial, ohne Spielabhängigkeit)

/// Würfel mit Augen (1…6), `gehalten` zeichnet einen App-Farb-Ring.
public struct AnleitungWuerfel: View {
    let augen: Int; let groesse: CGFloat; let gehalten: Bool
    @Environment(\.colorScheme) private var schema
    public init(augen: Int, groesse: CGFloat = 52, gehalten: Bool = false) {
        self.augen = min(6, max(1, augen)); self.groesse = groesse; self.gehalten = gehalten
    }
    private var punkte: [CGPoint] {
        switch augen {
        case 1: [.init(x: 0.5, y: 0.5)]
        case 2: [.init(x: 0.28, y: 0.28), .init(x: 0.72, y: 0.72)]
        case 3: [.init(x: 0.27, y: 0.27), .init(x: 0.5, y: 0.5), .init(x: 0.73, y: 0.73)]
        case 4: [.init(x: 0.28, y: 0.28), .init(x: 0.72, y: 0.28), .init(x: 0.28, y: 0.72), .init(x: 0.72, y: 0.72)]
        case 5: [.init(x: 0.28, y: 0.28), .init(x: 0.72, y: 0.28), .init(x: 0.5, y: 0.5), .init(x: 0.28, y: 0.72), .init(x: 0.72, y: 0.72)]
        default: [.init(x: 0.3, y: 0.25), .init(x: 0.7, y: 0.25), .init(x: 0.3, y: 0.5), .init(x: 0.7, y: 0.5), .init(x: 0.3, y: 0.75), .init(x: 0.7, y: 0.75)]
        }
    }
    public var body: some View {
        ZStack {
            if Design.art == .klar {
                RoundedRectangle(cornerRadius: groesse * 0.22).fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            } else {
                RoundedRectangle(cornerRadius: Design.ist(.salon) ? 4 : 8).fill(Color.kartenGrund)
                    .overlay { if Design.ist(.tinte) { RoundedRectangle(cornerRadius: 8).strokeBorder(Color.linieStark, lineWidth: 1.5) } }
            }
            ForEach(Array(punkte.enumerated()), id: \.offset) { _, p in
                Circle().fill(Color.accentText).frame(width: groesse * 0.15, height: groesse * 0.15)
                    .position(x: groesse * p.x, y: groesse * p.y)
            }
            if gehalten { RoundedRectangle(cornerRadius: groesse * 0.22).stroke(Color.appFlaeche, lineWidth: 3) }
        }
        .frame(width: groesse, height: groesse)
        // Design-Runde 5, Blatt 11 (Nacharbeit): Die Bühne ist in Tinte dunkel gestellt (Filz). Würfel bleiben helles Material mit dunklen Augen.
        .environment(\.colorScheme, Design.art == .tinte ? .light : schema)
    }
}

/// Spielkarte (Wert + Farbzeichen), Hochformat.
public struct AnleitungKarte: View {
    let wert: String; let zeichen: String; let rot: Bool; let breite: CGFloat; let verdeckt: Bool
    @Environment(\.colorScheme) private var schema
    public init(_ wert: String, _ zeichen: String = "♥", rot: Bool = true, breite: CGFloat = 54, verdeckt: Bool = false) {
        self.wert = wert; self.zeichen = zeichen; self.rot = rot; self.breite = breite; self.verdeckt = verdeckt
    }
    public var body: some View {
        ZStack {
            if Design.art == .klar {
                RoundedRectangle(cornerRadius: breite * 0.14).fill(verdeckt ? Color.appFlaeche : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.14), radius: 3, y: 2)
            } else {
                RoundedRectangle(cornerRadius: Design.ist(.salon) ? 3 : 4).fill(verdeckt ? Color.appFlaeche : Color.kartenGrund)
                    .overlay { RoundedRectangle(cornerRadius: Design.ist(.salon) ? 3 : 4).strokeBorder(Design.ist(.tinte) ? Color.linieStark : Color.linie, lineWidth: 1) }
            }
            if verdeckt {
                RoundedRectangle(cornerRadius: breite * 0.1).stroke(.white.opacity(0.6), lineWidth: 2).padding(breite * 0.1)
            } else {
                VStack(spacing: 0) {
                    Text(wert).font(.system(size: breite * 0.38, weight: .bold, design: Design.zahlDesign))
                    Text(zeichen).font(.system(size: breite * 0.34))
                }
                .foregroundStyle(rot ? (Design.art == .klar ? Color.red : (Design.werte.palette?[.karten]?.text ?? Color.red)) : (Design.art == .klar ? Color.primary : Color.schrift))
            }
        }
        .frame(width: breite, height: breite * 1.4)
        // Blatt 11 (Nacharbeit): Karten bleiben in Tinte helles Papier, auch auf dem Filz der Bühne und im dunklen Modus.
        .environment(\.colorScheme, Design.art == .tinte ? .light : schema)
    }
}

/// Quadratische Kachel/Zelle mit Text (Sudoku, Minensuche, Rätsel).
public struct AnleitungKachel: View {
    let text: String; let groesse: CGFloat; let hervorgehoben: Bool; let aufgedeckt: Bool
    @Environment(\.colorScheme) private var schema
    public init(_ text: String = "", groesse: CGFloat = 44, hervorgehoben: Bool = false, aufgedeckt: Bool = true) {
        self.text = text; self.groesse = groesse; self.hervorgehoben = hervorgehoben; self.aufgedeckt = aufgedeckt
    }
    public var body: some View {
        RoundedRectangle(cornerRadius: Theme.feldRadius * groesse / 44)
            .fill(hervorgehoben ? Color.appFlaeche : (aufgedeckt ? (Design.art == .klar ? Color(.systemBackground) : Color.kartenGrund) : Color.appFlaeche.opacity(0.35)))
            .overlay { if Design.art == .tinte { RoundedRectangle(cornerRadius: Theme.feldRadius * groesse / 44).strokeBorder(Color.linieStark, lineWidth: 1) } }
            .overlay(Text(text).font(.system(size: groesse * 0.5, weight: .bold, design: Design.zahlDesign))
                .foregroundStyle(hervorgehoben ? Color.onAccent : Color.accentText))
            .frame(width: groesse, height: groesse)
            // Blatt 11 (Nacharbeit): Kacheln bleiben in Tinte hell mit dunkler Schrift (sonst wird `kartenGrund` auf dem Filz fast schwarz).
            .environment(\.colorScheme, Design.art == .tinte ? .light : schema)
    }
}

/// Raster aus Textzeilen, das bei `umschalten` von `vorher` zu `nachher` wechselt (kleiner Pop). Zeichen:
/// `.` leer · `#` Block · `*` App-Farbe · `~` zarte App-Farbe · Kleinbuchstabe = Farbfeld (r g b y v o) · alles andere = Text auf weißer Kachel.
public struct AnleitungRaster: View {
    let vorher: [String]; let nachher: [String]; let p: Double; let zelle: CGFloat; let ab: Double
    public init(_ vorher: [String], _ nachher: [String]? = nil, p: Double, zelle: CGFloat = 44, umschaltenAb: Double = 0.5) {
        self.vorher = vorher; self.nachher = nachher ?? vorher; self.p = p; self.zelle = zelle; self.ab = umschaltenAb
    }
    private static let farben: [Character: Color] = ["r": .red, "g": .green, "b": .blue, "y": .yellow, "v": .purple, "o": .orange]
    public var body: some View {
        let zustand = p >= ab ? nachher : vorher
        let pop = 1 + 0.12 * max(0, 1 - abs(p - ab) * 14)
        VStack(spacing: Design.Abstand.xs) {
            ForEach(0..<zustand.count, id: \.self) { r in
                HStack(spacing: Design.Abstand.xs) {
                    ForEach(Array(zustand[r].enumerated()), id: \.offset) { c, ch in
                        let geaendert = r < nachher.count && c < nachher[r].count && r < vorher.count && c < vorher[r].count
                            && Array(vorher[r])[c] != Array(nachher[r])[c]
                        feld(ch).scaleEffect(geaendert ? pop : 1)
                    }
                }
            }
        }
    }
    @ViewBuilder private func feld(_ ch: Character) -> some View {
        switch ch {
        case " ": Color.clear.frame(width: zelle, height: zelle)
        case ".": AnleitungKachel("", groesse: zelle)
        case "#": RoundedRectangle(cornerRadius: Theme.feldRadius * zelle / 44).fill(Color.appFlaeche.opacity(0.22)).frame(width: zelle, height: zelle)
        case "*": AnleitungKachel("", groesse: zelle, hervorgehoben: true)
        case "~": RoundedRectangle(cornerRadius: Theme.feldRadius * zelle / 44).fill(Color.appFlaeche.opacity(0.45)).frame(width: zelle, height: zelle)
        default:
            if let f = Self.farben[ch] {
                RoundedRectangle(cornerRadius: Theme.feldRadius * zelle / 44).fill(f.opacity(0.9)).frame(width: zelle, height: zelle)
            } else { AnleitungKachel(String(ch), groesse: zelle) }
        }
    }
}


public extension UnitPoint {
    /// Mitte einer Rasterzelle in der Bühne (Raster mit `zelle` 44 pt + 4 pt Abstand, Bühne etwa 340 × 240 pt), für `.tippen(.zelle(…))`.
    static func zelle(_ zeile: Int, _ spalte: Int, zeilen: Int, spalten: Int, zelle: CGFloat = 44) -> UnitPoint {
        UnitPoint(x: 0.5 + (Double(spalte) - Double(spalten - 1) / 2) * Double(zelle + 4) / 340,
                  y: 0.5 + (Double(zeile) - Double(zeilen - 1) / 2) * Double(zelle + 4) / 240)
    }
}

public extension AnleitungSchritt {
    /// Schritt mit `AnleitungRaster`: Das Raster wechselt in der Mitte der Schleife von `vorher` zu `nachher`.
    static func raster(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey, geste: AnleitungGeste = .keine,
                       _ vorher: [String], _ nachher: [String]? = nil, zelle: CGFloat = 44) -> AnleitungSchritt {
        AnleitungSchritt(symbol: symbol, titel: titel, text: text, geste: geste) { p, _ in
            AnleitungRaster(vorher, nachher, p: p, zelle: zelle)
        }
    }
    /// Schritt mit einem großen, atmenden Symbol als Bühne (für Regeln ohne Spielfeldbild).
    static func bild(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey, bild: String, geste: AnleitungGeste = .keine) -> AnleitungSchritt {
        AnleitungSchritt(symbol: symbol, titel: titel, text: text, geste: geste) { p, _ in
            Image(systemName: bild).font(.system(size: 76)).foregroundStyle(Color.appFlaeche)
                .scaleEffect(1 + 0.08 * sin(p * .pi * 2))
        }
    }
}

/// Weicher 0…1-Verlauf eines Abschnitts der Schleife: `abschnitt(p, von: 0.2, bis: 0.6)`.
public func anleitungAbschnitt(_ p: Double, von: Double, bis: Double) -> Double {
    let x = min(1, max(0, (p - von) / (bis - von)))
    return x * x * (3 - 2 * x)
}

#if DEBUG
#Preview("Anleitung") {
    AnleitungBlatt(titel: "Beispiel", schritte: [
        AnleitungSchritt(symbol: "hand.tap", titel: "Tippen", text: "Tippe auf ein Feld, um deinen Stein zu setzen.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.55))) { _, _ in
            RoundedRectangle(cornerRadius: Theme.feldRadius).fill(Color.appFlaeche).frame(width: 90, height: 90)
        },
        AnleitungSchritt(symbol: "hand.draw", titel: "Ziehen", text: "Ziehe den Stein an seinen neuen Platz.",
                         geste: .ziehen(von: UnitPoint(x: 0.3, y: 0.6), nach: UnitPoint(x: 0.7, y: 0.4))) { p, _ in
            GeometryReader { g in
                let s = min(1, max(0, (p - 0.2) / 0.6))
                Circle().fill(Color.appFlaeche).frame(width: 56, height: 56)
                    .position(x: g.size.width * (0.3 + 0.4 * s), y: g.size.height * (0.6 - 0.2 * s))
            }
        },
        AnleitungSchritt(symbol: "flag.checkered", titel: "Gewinnen", text: "Wer zuerst am Ziel ist, gewinnt.", geste: .keine),
    ], fertig: {})
    .tint(.indigo)
}
#endif

#endif
