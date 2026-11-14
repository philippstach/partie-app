// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
// design:spielinhalt-datei

/// Kennung einer Figur: Spieler-Index und Figur-Index (0–3).
struct FigurID: Hashable, Sendable {
    var spieler: Int
    var figur: Int
}

/// Vorschau eines Zugs: Geisterstein auf dem Zielfeld (relative Position des Spielers).
struct Geist: Equatable {
    var spieler: Int
    var rel: Int
    var schlaegt: Bool
}

/// Staffelt das Erscheinen: Felder von der Mitte nach außen (insgesamt 400 ms, je Feld 120 ms Einblenden, Skalierung 0,6 → 1).
/// Figuren („hüpfen ins Haus“) folgen danach, je Sitz 80 ms versetzt.
private struct Aufbau: ViewModifier {
    enum Art { case feld(abstand: CGFloat), figur(sitz: Int) }
    let art: Art
    let aktiv: Bool
    let fertig: Bool

    func body(content: Content) -> some View {
        if aktiv {
            switch art {
            case let .feld(abstand):
                content
                    .opacity(fertig ? 1 : 0)
                    .scaleEffect(fertig ? 1 : 0.6)
                    .animation(.easeOut(duration: 0.12).delay(Double(abstand) / 7.1 * 0.28), value: fertig)
            case let .figur(sitz):
                content
                    .opacity(fertig ? 1 : 0)
                    .scaleEffect(fertig ? 1 : 0.5)
                    .offset(y: fertig ? 0 : -16)
                    .animation(.spring(duration: 0.4, bounce: 0.35).delay(0.4 + Double(sitz) * 0.08), value: fertig)
            }
        } else {
            content
        }
    }
}

/// Kurze Effekte auf einer Figur. Der Zähler löst die Animation aus (jede Erhöhung = ein Durchlauf).
struct Marke: Equatable {
    var id: FigurID
    var zaehler: Int
}

/// Ring, der an einem Brettfeld aufblitzt (Rauswurf).
struct Blitz: Equatable {
    var punkt: Rasterpunkt
    var zaehler: Int
}

/// Staubwölkchen in Sitzfarbe am Schlagfeld.
struct StaubMarke: Equatable {
    var punkt: Rasterpunkt
    var sitz: Int
    var zaehler: Int
}

struct BrettEffekte: Equatable {
    /// Ring am Schlagfeld
    var blitz: Blitz?
    /// Staubwölkchen am Schlagfeld
    var staub: StaubMarke?
    /// Nur für das Demo-Bild: Ring und Staub in diesem Fortschritt (0…1) einfrieren
    var aufprallStand: CGFloat?
    /// Zähler: Das ganze Brett zittert kurz (4 pt)
    var zittern = 0
    /// Figur wackelt (nicht beweglich angetippt)
    var wackeln: Marke?
    /// Hüpfer mit kleinem Bogen (Skalierung 1,0 → 1,15 → 1,0)
    var hupf: Marke?
    /// Flug zurück ins Haus (Bogen nach oben)
    var flug: Marke?
    /// Glanz in der App-Farbe (Ziel)
    var glanz: Marke?
    /// Eingefrorener Flug für das Demo-Szenario `capture`: Anteil des Wegs von Feld zu Haus (0…1)
    var eingefroren: [FigurID: CGFloat] = [:]
}

/// Zeichnet das Brett aus Lage + Theme (Geometrie aus `Brettgeometrie`, = `brett.json`).
/// Enthält keine Farbwerte: alles kommt aus `BrettTheme`.
struct BrettView<Mitte: View>: View {
    let lage: Lage
    let theme: BrettTheme
    var beweglich: Set<FigurID> = []
    var geist: Geist?
    /// Figur, die über allen anderen liegen soll (die gerade zieht).
    var vorne: FigurID?
    /// „Bewegung reduzieren“ oder „Animationen aus“: kein Pulsieren, dafür dickerer Ring.
    var bewegungReduziert = false
    var beschreibung: (FigurID) -> String = { _ in "" }
    var onFigur: (FigurID) -> Void = { _ in }
    var onVorschau: (FigurID, Bool) -> Void = { _, _ in }
    var effekte = BrettEffekte()
    /// Sitz des Spielers, der dran ist: sein Farbpunkt liegt in der Mitte, der Würfel auf seinem Würfelplatz.
    var dranSitz: Int?
    /// Sieger-Moment: Spieler-Index des Siegers. Das Brett dimmt, seine Figuren leuchten.
    var sieger: Int?
    /// Das Brett baut sich beim Erscheinen gestaffelt auf (Felder, Häuser, Ziele, dann Figuren).
    var aufbau = false
    /// „Neue Partie“: Antippen eines Hauses wählt den Sitz (Farbe). `hausMarkiert` bekommt einen Rahmen in der App-Farbe.
    var hausTippen: ((Int) -> Void)?
    var hausMarkiert: Int?
    /// VoiceOver-Beschreibung eines Hauses (nur mit `hausTippen`)
    var hausBeschreibung: (Int) -> String = { _ in "" }
    /// Der Würfel (2 × 2 Zellen groß, bekommt die Kantenlänge einer Zelle). Er rutscht zum Spieler, der dran ist.
    @ViewBuilder var mitte: (CGFloat) -> Mitte

    @State private var puls = false
    @State private var aufgebaut = false

    private var raster: Int { Brettgeometrie.raster }

    var body: some View {
        GeometryReader { geo in
            let seite = min(geo.size.width, geo.size.height)
            let z = seite / CGFloat(raster)
            ZStack {
                if let fl = theme.flaeche {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fl)
                    if theme.koernung { Koernung().clipShape(.rect(cornerRadius: 12)) }
                }
                flaechen(z)
                felder(z)
                figuren(z, nur: sieger.map { s in { $0 != s } })
                if sieger != nil {
                    // Schleier (schwarz 35 %) über Feldern und fremden Figuren, unter den Siegerfiguren: nichts scheint durch
                    RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.35)).allowsHitTesting(false)
                    figuren(z, nur: sieger.map { s in { $0 == s } })
                }
                if let geist { geistView(geist, z) }
                if let hausTippen { hausFlaechen(hausTippen, z) }
                AufprallEffekt(blitz: effekte.blitz, staub: effekte.staub, stand: effekte.aufprallStand, theme: theme, z: z)
                if let dranSitz {
                    mittePunkt(dranSitz, z)
                    mitte(z)
                        .modifier(Hub(trigger: dranSitz, hub: -z * 0.9, dauer: 0.35, aktiv: !bewegungReduziert))
                        .position(wuerfelOrt(dranSitz, z))
                        .animation(bewegungReduziert ? nil : .easeInOut(duration: 0.35), value: dranSitz)
                }
            }
            .modifier(BrettZittern(zaehler: effekte.zittern))
            .frame(width: seite, height: seite)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L("a11y.brett"))
        .onAppear {
            aufgebaut = true
            guard !bewegungReduziert else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { puls = true }
        }
    }

    // MARK: Teile

    /// Abstand eines Rasterpunkts von der Brettmitte (in Zellen)
    private func abstandMitte(_ p: Rasterpunkt) -> CGFloat {
        let dx = CGFloat(p.x) - 5, dy = CGFloat(p.y) - 5
        return (dx * dx + dy * dy).squareRoot()
    }

    private func belegt(_ sitz: Int) -> Bool { lage.sitze.contains(sitz) }

    /// Würfelplatz je Sitz: die freie 2 × 2-Fläche zur Mitte hin (DESIGN.md).
    private func wuerfelOrt(_ sitz: Int, _ z: CGFloat) -> CGPoint {
        let ecke = [(2, 2), (7, 2), (7, 7), (2, 7)][sitz % 4]
        return CGPoint(x: CGFloat(ecke.0 + 1) * z, y: CGFloat(ecke.1 + 1) * z)
    }

    /// Mittelzelle (5,5): Punkt in der Farbe des Spielers, der dran ist.
    private func mittePunkt(_ sitz: Int, _ z: CGFloat) -> some View {
        Circle().fill(theme.farbe(sitz))
            .overlay(Image(systemName: theme.symbol(sitz)).font(.system(size: z * 0.28, weight: .bold)).foregroundStyle(theme.figurSymbol))   // design:spielinhalt (Beschriftung auf dem Spielmaterial, skaliert mit der Zellgröße)
            .frame(width: z * 0.6, height: z * 0.6)
            .position(mittelpunkt(Rasterpunkt(x: 5, y: 5), z))
            .animation(bewegungReduziert ? nil : .easeInOut(duration: 0.25), value: sitz)
            .accessibilityHidden(true)
    }

    private func mittelpunkt(_ p: Rasterpunkt, _ z: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(p.x) + 0.5) * z, y: (CGFloat(p.y) + 0.5) * z)
    }

    private func flaechen(_ z: CGFloat) -> some View {
        ZStack {
            ForEach(0 ..< Brettmass.sitze, id: \.self) { s in
                let punkte = Brettgeometrie.haus[s]
                let x0 = CGFloat(punkte.map(\.x).min() ?? 0) * z
                let y0 = CGFloat(punkte.map(\.y).min() ?? 0) * z
                RoundedRectangle(cornerRadius: min(theme.hausRadius, z * 0.7), style: .continuous)
                    .fill(belegt(s) ? theme.flaechenFarbe(s).opacity(theme.hausFuellung) : theme.neutralFlaeche)
                    .frame(width: 2 * z - z * 0.1, height: 2 * z - z * 0.1)
                    .modifier(Aufbau(art: .feld(abstand: abstandMitte(Brettgeometrie.haus[s][0])), aktiv: aufbau && !bewegungReduziert, fertig: aufgebaut))
                    .position(x: x0 + z, y: y0 + z)
                if belegt(s) {
                    Image(systemName: theme.symbol(s))
                        .font(.system(size: z * 0.42, weight: .bold))   // design:spielinhalt (Beschriftung auf dem Spielmaterial, skaliert mit der Zellgröße)
                        .foregroundStyle(theme.farbe(s).opacity(0.35))
                        .position(x: x0 + z, y: y0 + z)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// Durchsichtige Tippflächen über den vier Häusern (Sitzwahl in „Neue Partie“).
    private func hausFlaechen(_ aktion: @escaping (Int) -> Void, _ z: CGFloat) -> some View {
        ZStack {
            ForEach(0 ..< Brettmass.sitze, id: \.self) { s in
                let punkte = Brettgeometrie.haus[s]
                let x0 = CGFloat(punkte.map(\.x).min() ?? 0) * z
                let y0 = CGFloat(punkte.map(\.y).min() ?? 0) * z
                RoundedRectangle(cornerRadius: min(theme.hausRadius, z * 0.7), style: .continuous)
                    .strokeBorder(theme.markierung, lineWidth: hausMarkiert == s ? 3 : 0)
                    .background(Color.clear)
                    .frame(width: 2 * z, height: 2 * z)
                    .contentShape(.rect)
                    .onTapGesture { aktion(s) }
                    .position(x: x0 + z, y: y0 + z)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(hausBeschreibung(s))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(hausMarkiert == s ? .isSelected : [])
            }
        }
    }

    private func felder(_ z: CGFloat) -> some View {
        let d = z * theme.feldAnteil
        return ZStack {
            // Laufbahn
            ForEach(0 ..< Brettmass.lauf, id: \.self) { i in
                let startSitz = Brettgeometrie.start.firstIndex(of: i)
                let p = mittelpunkt(Brettgeometrie.laufbahn[i], z)
                if let s = startSitz, belegt(s) {
                    Circle().fill(theme.flaechenFarbe(s).opacity(theme.startFuellung))
                        .overlay(Circle().strokeBorder(theme.flaechenFarbe(s), lineWidth: 1.5))
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: d * 0.4, weight: .bold))   // design:spielinhalt (Beschriftung auf dem Spielmaterial, skaliert mit der Zellgröße)
                                .foregroundStyle(theme.farbe(s))
                                .rotationEffect(.degrees(Double(s) * 90))
                        )
                        .frame(width: d, height: d)
                        .modifier(Aufbau(art: .feld(abstand: abstandMitte(Brettgeometrie.laufbahn[i])), aktiv: aufbau && !bewegungReduziert, fertig: aufgebaut))
                        .position(p)
                } else {
                    Circle().fill(theme.feldFuellung)
                        .overlay(Circle().strokeBorder(theme.feldRand, lineWidth: 1))
                        .overlay { if theme.gepraegt { Praegung(oben: theme.praegungOben) } }
                        .frame(width: d, height: d)
                        .modifier(Aufbau(art: .feld(abstand: abstandMitte(Brettgeometrie.laufbahn[i])), aktiv: aufbau && !bewegungReduziert, fertig: aufgebaut))
                        .position(p)
                }
            }
            // Ziele
            ForEach(0 ..< Brettmass.sitze, id: \.self) { s in
                ForEach(0 ..< 4, id: \.self) { k in
                    let p = mittelpunkt(Brettgeometrie.ziel[s][k], z)
                    if belegt(s) {
                        Circle().fill(theme.flaechenFarbe(s).opacity(theme.zielFuellung))
                            .overlay(Circle().strokeBorder(theme.flaechenFarbe(s).opacity(theme.zielRand), lineWidth: 1.5))
                            .frame(width: d, height: d)
                            .position(p)
                    } else {
                        Circle().fill(theme.neutralFlaeche)
                            .frame(width: d, height: d)
                            .position(p)
                    }
                }
                // Hausfelder (leere Plätze)
                ForEach(0 ..< 4, id: \.self) { k in
                    Circle().strokeBorder(belegt(s) ? theme.farbe(s).opacity(0.45) : Color.clear, lineWidth: 1.5)
                        .frame(width: d, height: d)
                        .position(mittelpunkt(Brettgeometrie.haus[s][k], z))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func figuren(_ z: CGFloat, nur: ((Int) -> Bool)? = nil) -> some View {
        let d = z * theme.figurAnteil
        return ZStack {
            ForEach(Array(lage.sitze.enumerated()).filter { nur?($0.offset) ?? true }, id: \.offset) { p, sitz in
                ForEach(0 ..< lage.figuren[p].count, id: \.self) { k in
                    let id = FigurID(spieler: p, figur: k)
                    let rel = lage.figuren[p][k]
                    figur(id: id, sitz: sitz, d: d)
                        .modifier(Aufbau(art: .figur(sitz: sitz), aktiv: aufbau && !bewegungReduziert, fertig: aufgebaut))
                        .position(figurPunkt(sitz: sitz, rel: rel, k: k, id: id, z))
                        .zIndex(vorne == id ? 2 : (beweglich.contains(id) ? 1 : 0))
                }
            }
        }
    }

    private func figurPunkt(sitz: Int, rel: Int, k: Int, id: FigurID, _ z: CGFloat) -> CGPoint {
        let a = mittelpunkt(Brettgeometrie.punkt(sitz: sitz, rel: rel, figur: k), z)
        guard let t = effekte.eingefroren[id] else { return a }
        let h = mittelpunkt(Brettgeometrie.haus[sitz][k], z)
        return CGPoint(x: a.x + (h.x - a.x) * t, y: a.y + (h.y - a.y) * t - z * 0.6 * sin(t * .pi))
    }

    private func figurFuellung(_ sitz: Int, _ d: CGFloat) -> AnyShapeStyle {
        guard theme.glanz else { return AnyShapeStyle(theme.farbe(sitz)) }
        return AnyShapeStyle(RadialGradient(colors: [theme.farbe(sitz).mischen(mit: .white, 0.4), theme.farbe(sitz)],
                                            center: UnitPoint(x: 0.3, y: 0.28), startRadius: 0, endRadius: d * 0.7))
    }

    private func figur(id: FigurID, sitz: Int, d: CGFloat) -> some View {
        let kannZiehen = beweglich.contains(id)
        let leuchtet = sieger == id.spieler
        let ring = bewegungReduziert ? 4.0 : 3.0
        return ZStack {
            if leuchtet {
                Circle().fill(theme.farbe(sitz).opacity(0.35))
                    .frame(width: d * 1.7, height: d * 1.7)
                    .blur(radius: d * 0.25)
                    .scaleEffect(bewegungReduziert ? 1 : (puls ? 1.15 : 0.95))
                Circle().strokeBorder(theme.markierung, lineWidth: 3)
                    .frame(width: d + 8, height: d + 8)
            }
            if kannZiehen {
                Circle().strokeBorder(theme.markierung, lineWidth: ring)
                    .frame(width: d + ring * 2 + 2, height: d + ring * 2 + 2)
                    .scaleEffect(bewegungReduziert ? 1 : (puls ? 1.08 : 1.0))
            }
            Circle().fill(figurFuellung(sitz, d))
                .overlay(Circle().strokeBorder(theme.figurRing, lineWidth: 2))
                .overlay(alignment: .topLeading) {
                    if theme.glanz {
                        Circle().fill(Color.white.opacity(0.7))
                            .frame(width: d * theme.glanzGroesse, height: d * theme.glanzGroesse)
                            .blur(radius: d * 0.02)
                            .offset(x: d * 0.18, y: d * 0.15)
                    }
                }
                .overlay(
                    Image(systemName: theme.symbol(sitz))
                        .font(.system(size: d * 0.42, weight: .bold))   // design:spielinhalt (Beschriftung auf dem Spielmaterial, skaliert mit der Zellgröße)
                        .foregroundStyle(theme.figurSymbol)
                )
                .frame(width: d, height: d)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .frame(width: max(d, Theme.tapSize), height: max(d, Theme.tapSize))
        .contentShape(Circle())
        .modifier(Wackeln(aktiv: effekte.wackeln?.id == id, zaehler: effekte.wackeln?.zaehler ?? 0))
        .modifier(Bogen(aktiv: effekte.hupf?.id == id, zaehler: effekte.hupf?.zaehler ?? 0, skala: 1.15, hub: 0, dauer: 0.09))
        .modifier(Bogen(aktiv: effekte.flug?.id == id, zaehler: effekte.flug?.zaehler ?? 0, skala: 1.1, hub: -d * 1.1, dauer: 0.45, drehung: 540))
        .modifier(Glanz(aktiv: effekte.glanz?.id == id, zaehler: effekte.glanz?.zaehler ?? 0, farbe: theme.markierung, d: d))
        .onTapGesture { onFigur(id) }
        .onLongPressGesture(minimumDuration: 30, maximumDistance: 30, perform: {}, onPressingChanged: { onVorschau(id, $0) })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(beschreibung(id))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onFigur(id) }
    }

    private func geistView(_ g: Geist, _ z: CGFloat) -> some View {
        let d = z * theme.figurAnteil
        let sitz = lage.sitze[g.spieler]
        return Circle().fill(theme.farbe(sitz).opacity(0.35))
            .overlay(Circle().strokeBorder(theme.markierung, style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
            .overlay {
                if g.schlaegt {
                    // „×“ in der App-Farbe, 50 % der Figur, mit 2 pt Rand in Hintergrundfarbe (hell und dunkel gut zu sehen)
                    ZStack {
                        Image(systemName: "xmark").font(.system(size: d * 0.5 + 4, weight: .black)).foregroundStyle(Color.kartenGrund)   // design:spielinhalt (Beschriftung auf dem Spielmaterial, skaliert mit der Zellgröße)
                        Image(systemName: "xmark").font(.system(size: d * 0.5, weight: .heavy)).foregroundStyle(theme.markierung)   // design:spielinhalt (Beschriftung auf dem Spielmaterial, skaliert mit der Zellgröße)
                    }
                }
            }
            .frame(width: d, height: d)
            .position(mittelpunkt(Brettgeometrie.punkt(sitz: sitz, rel: g.rel, figur: 0), z))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Kurzes Wackeln, wenn eine nicht bewegliche Figur angetippt wurde.
private struct Wackeln: ViewModifier {
    let aktiv: Bool
    let zaehler: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 0.0, trigger: aktiv ? zaehler : 0) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(aktiv ? -5 : 0, duration: 0.05)
                CubicKeyframe(aktiv ? 5 : 0, duration: 0.08)
                CubicKeyframe(aktiv ? -3 : 0, duration: 0.08)
                CubicKeyframe(0, duration: 0.05)
            }
        }
    }
}

/// Hebt eine View kurz an, wenn sich `trigger` ändert (der Würfel rutscht im Bogen zum nächsten Spieler).
private struct Hub<T: Equatable>: ViewModifier {
    let trigger: T
    let hub: CGFloat
    let dauer: Double
    let aktiv: Bool

    func body(content: Content) -> some View {
        if aktiv {
            content.keyframeAnimator(initialValue: CGFloat(0), trigger: trigger) { view, h in
                view.offset(y: h)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(hub, duration: dauer / 2)
                    CubicKeyframe(0, duration: dauer / 2)
                }
            }
        } else {
            content
        }
    }
}

/// Ring und Staubwölkchen am Schlagfeld. Läuft über einen eigenen Fortschritt `t` (0 → 1 in 0,5 s), der bei jedem neuen Rauswurf
/// (neuer Zähler) von vorn startet.
private struct AufprallEffekt: View {
    let blitz: Blitz?
    let staub: StaubMarke?
    let stand: CGFloat?
    let theme: BrettTheme
    let z: CGFloat
    @State private var t: CGFloat = 1

    var body: some View {
        let p = stand ?? t
        let sichtbar = p < 1
        ZStack {
            if let blitz {
                Circle().strokeBorder(theme.markierung, lineWidth: 4)
                    .frame(width: z * 0.8, height: z * 0.8)
                    .scaleEffect(0.6 + 2.0 * p)
                    .opacity(sichtbar ? Double(1 - p) : 0)
                    .position(punkt(blitz.punkt))
            }
            if let staub {
                ForEach(0 ..< 6, id: \.self) { i in
                    let winkel = Double(i) * .pi / 3 + 0.4
                    Circle().fill(theme.farbe(staub.sitz).opacity(0.7))
                        .frame(width: z * 0.34, height: z * 0.34)
                        .scaleEffect(1 - 0.6 * p)
                        .offset(x: cos(winkel) * z * (0.2 + 0.9 * p), y: sin(winkel) * z * (0.2 + 0.9 * p))
                        .opacity(sichtbar ? Double(1 - p) : 0)
                        .position(punkt(staub.punkt))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: blitz?.zaehler) { _, neu in
            guard neu != nil, stand == nil else { return }
            Task { @MainActor in
                var ohne = Transaction()
                ohne.disablesAnimations = true
                withTransaction(ohne) { t = 0 }
                await Task.yield()
                withAnimation(.easeOut(duration: 0.5)) { t = 1 }
            }
        }
    }

    private func punkt(_ p: Rasterpunkt) -> CGPoint {
        CGPoint(x: (CGFloat(p.x) + 0.5) * z, y: (CGFloat(p.y) + 0.5) * z)
    }
}

/// Das Brett zittert beim Aufprall eines Rauswurfs kurz (4 pt, 250 ms).
private struct BrettZittern: ViewModifier {
    let zaehler: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat(0), trigger: zaehler) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(zaehler == 0 ? 0 : 4, duration: 0.04)
                LinearKeyframe(-4, duration: 0.06)
                LinearKeyframe(3, duration: 0.06)
                LinearKeyframe(-2, duration: 0.05)
                LinearKeyframe(0, duration: 0.04)
            }
        }
    }
}

/// Bogen: Skalierung und Hub über die Dauer (Hüpfer, Flug ins Haus).
private struct Bogen: ViewModifier {
    let aktiv: Bool
    let zaehler: Int
    let skala: CGFloat
    let hub: CGFloat
    let dauer: Double
    var drehung: Double = 0

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: BogenWert(), trigger: aktiv ? zaehler : 0) { view, w in
            view.scaleEffect(w.skala).offset(y: w.hub).rotationEffect(.degrees(w.winkel))
        } keyframes: { _ in
            KeyframeTrack(\.winkel) {
                LinearKeyframe(aktiv ? drehung : 0, duration: dauer)
                LinearKeyframe(0, duration: 0.001)
            }
            KeyframeTrack(\.skala) {
                CubicKeyframe(aktiv ? skala : 1, duration: dauer / 2)
                CubicKeyframe(1, duration: dauer / 2)
            }
            KeyframeTrack(\.hub) {
                CubicKeyframe(aktiv ? hub : 0, duration: dauer / 2)
                CubicKeyframe(0, duration: dauer / 2)
            }
        }
    }
}

private struct BogenWert {
    var skala: CGFloat = 1
    var hub: CGFloat = 0
    var winkel: Double = 0
}

/// Kurzer Glanz in der App-Farbe um eine Figur (Ziel erreicht).
private struct Glanz: ViewModifier {
    let aktiv: Bool
    let zaehler: Int
    let farbe: Color
    let d: CGFloat

    func body(content: Content) -> some View {
        content.overlay {
            Circle().strokeBorder(farbe, lineWidth: 3)
                .frame(width: d, height: d)
                .keyframeAnimator(initialValue: GlanzWert(), trigger: aktiv ? zaehler : 0) { view, w in
                    view.scaleEffect(w.skala).opacity(w.deckkraft)
                } keyframes: { _ in
                    KeyframeTrack(\.skala) {
                        CubicKeyframe(aktiv ? 1.9 : 1, duration: 0.5)
                    }
                    KeyframeTrack(\.deckkraft) {
                        LinearKeyframe(aktiv ? 1 : 0, duration: 0.05)
                        LinearKeyframe(0, duration: 0.45)
                    }
                }
                .allowsHitTesting(false)
        }
    }
}

private struct GlanzWert {
    var skala: CGFloat = 1
    var deckkraft: Double = 0
}

extension BrettView where Mitte == EmptyView {
    init(lage: Lage, theme: BrettTheme) {
        self.init(lage: lage, theme: theme, mitte: { _ in EmptyView() })
    }
}

/// Geprägtes Feld: Innenschatten oben (schwarz 12 %, 1,5 pt) und helle Kante unten (weiß 30 %).
private struct Praegung: View {
    var oben: CGFloat = 0.12

    var body: some View {
        ZStack {
            Circle().strokeBorder(LinearGradient(colors: [Color.black.opacity(oben), .clear], startPoint: .top, endPoint: .center), lineWidth: 1.5)
            Circle().strokeBorder(LinearGradient(colors: [.clear, Color.white.opacity(0.3)], startPoint: .center, endPoint: .bottom), lineWidth: 1.5)
        }
    }
}

/// Papierfaser: sehr kleine, unscharfe Flecken mit höchstens 1,5 % Deckkraft (keine sichtbaren Punkte).
private struct Koernung: View {
    var body: some View {
        Canvas { ctx, size in
            var zustand: UInt64 = 0x9E37_79B9_7F4A_7C15
            func zufall() -> CGFloat {
                zustand = zustand &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat(zustand >> 33) / CGFloat(UInt32.max >> 1)
            }
            ctx.addFilter(.blur(radius: 1.6))
            let n = Int(size.width * size.height / 140)
            for _ in 0 ..< n {
                let x = zufall() * size.width, y = zufall() * size.height
                let laenge = 5 + zufall() * 9
                let winkel = zufall() * .pi
                var pfad = Path()
                pfad.move(to: CGPoint(x: x, y: y))
                pfad.addLine(to: CGPoint(x: x + cos(winkel) * laenge, y: y + sin(winkel) * laenge))
                let hell = zufall() > 0.5
                ctx.stroke(pfad, with: .color((hell ? Color.white : Color.black).opacity(0.015)), lineWidth: 1.6)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension Color {
    /// Mischt diese Farbe mit einer anderen (0 = diese, 1 = andere).
    func mischen(mit anderen: Color, _ anteil: CGFloat) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(anderen).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(red: r1 + (r2 - r1) * anteil, green: g1 + (g2 - g1) * anteil, blue: b1 + (b2 - b1) * anteil)
    }
}
