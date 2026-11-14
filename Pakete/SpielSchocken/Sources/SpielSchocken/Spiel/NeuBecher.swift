// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Wie ein Würfel gerade liegt: leicht versetzt und gedreht, nachdem er gerollt ist.
/// (Früher in Views/GameView.swift der Alt-Fassung; seit dem Kern-Umbau hier.)
struct WuerfelLage: Equatable {
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var winkel: Double = 0
    static let ruhig = WuerfelLage()
}


/// Becher-Zone: nimmt die ganze Resthöhe. Oben die Wertung des Wurfs, darunter die herausgelegten Würfel klein,
/// in der Mitte die Würfel im Becher groß. Bei der Rundenwertung zeigt sie stattdessen die Karte der Runde.
struct NeuBecher: View {
    let z: Spielzustand
    var hoechsteKante: Double
    @Environment(NeuEingabe.self) private var e
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var lagen: [WuerfelLage] = Array(repeating: .ruhig, count: 3)
    @Namespace private var wuerfelRaum

    /// Bauplan T3-2 / Blatt 27: breiter Tintentisch (iPad), nicht bei den größten Schriften.
    private var breitTisch: Bool { Tisch.aktiv && sizeClass == .regular && !typeSize.isAccessibilitySize }

    private var ohneBewegung: Bool { preferences.reduceAnimations || systemReduceMotion }

    /// Besitzer und Zug, der gerade auf dem Tisch liegt (laufend oder zuletzt beendet).
    private var sichtbar: (spieler: Int, zug: Zug)? {
        guard let zug = z.runde.zug else { return nil }
        if z.phase == .zugEnde, let s = z.aktuellerSpieler { return (s, zug) }
        if zug.fertig && z.phase != .rundenwertung { return nil }
        if !zug.fertig, let s = z.aktuellerSpieler { return (s, zug) }
        guard let last = z.runde.zuege.last else { return nil }
        return (last.spieler, zug)
    }

    var body: some View {
        Group {
            if z.phase == .rundenwertung {
                NeuRundenKarte(z: z).frame(maxWidth: .infinity, maxHeight: .infinity).tischFlaeche(Design.Ecke.karte)   // die Liste „Die Würfe der Runde“ bleibt eine Tafel
            } else if Tisch.aktiv {
                becher.frame(maxWidth: .infinity, maxHeight: .infinity)   // Blatt 21 (W2-S): Tinte: Würfel direkt auf dem Filz, kein Kasten
            } else {
                becher.frame(maxWidth: .infinity, maxHeight: .infinity).tischFlaeche(Design.Ecke.karte)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Überschrift in Tinte (Blatt 21): kleine Zeile ohne Linie statt `SectionLabel`.
    private func tintenUeberschrift(_ t: Text) -> some View {
        t.textCase(.uppercase).tracking(1.4)
            .font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Tisch.elfenbein.opacity(0.72))
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }

    private var becher: some View {
        let mensch = z.phase == .nachWurf
        let zug = sichtbar?.zug
        let wurf = zug?.wurf ?? []
        let flipp = Set(wurf.indices.filter { wurf[$0] == 6 }.prefix(e.umdrehen))
        let draussen = zug?.draussen ?? []
        return GeometryReader { geo in
            let breite = geo.size.width - 32
            let kante = max(40, min(hoechsteKante, (breite - 28) / 3, geo.size.height * 0.34))
            let klein = typeSize.isAccessibilitySize ? kante : kante * 0.62
            VStack(spacing: 10) {
                kopfzeile(zug, mensch: mensch)
                // herausgelegt: klein, oben
                VStack(spacing: Design.Abstand.xs) {
                    if Tisch.aktiv { tintenUeberschrift(Text("Draußen")) } else { SectionLabel("Draußen") }
                    HStack(spacing: Design.Abstand.s) {
                        ForEach(Array(draussen.enumerated()), id: \.offset) { _, w in
                            DieView(wert: w, zustand: .draussen, size: klein)
                                .accessibilityLabel(String(localized: "Würfel: \(neuZahlWort(w)), draußen"))
                        }
                        ForEach(wurf.indices.filter { e.auswahl.contains($0) || flipp.contains($0) }, id: \.self) { i in
                            DieView(wert: flipp.contains(i) ? 1 : wurf[i], zustand: .draussen, umgedreht: flipp.contains(i), size: klein)
                                .accessibilityLabel(String(localized: "Würfel: \(neuZahlWort(flipp.contains(i) ? 1 : wurf[i])), draußen"))
                                .matchedGeometryEffect(id: i, in: wuerfelRaum)
                        }
                        if draussen.isEmpty && e.auswahl.isEmpty && flipp.isEmpty {
                            Text("noch nichts herausgelegt").font(.footnote).tischHinweis(sonst: Color.schriftZweit)
                        }
                    }
                    .frame(minHeight: klein)
                    .modifier(AblageRahmen(aktiv: breitTisch, klein: klein))
                    .animation(ohneBewegung ? nil : .spring(duration: 0.3), value: e.auswahl)
                    .animation(ohneBewegung ? nil : .spring(duration: 0.3), value: e.umdrehen)
                }
                Spacer(minLength: 0)
                // im Becher: groß, mittig
                VStack(spacing: Design.Abstand.xs) {
                    if Tisch.aktiv { tintenUeberschrift(Text("Im Becher")) } else { SectionLabel("Im Becher") }
                    HStack(spacing: 14) {
                        if wurf.isEmpty {
                            ForEach(0..<(3 - draussen.count), id: \.self) { _ in DieView(wert: 1, zustand: .unbekannt, size: kante) }
                        } else {
                            ForEach(wurf.indices.filter { !e.auswahl.contains($0) && !flipp.contains($0) }, id: \.self) { i in
                                wuerfelKnopf(i, wert: wurf[i], kante: kante, aktiv: mensch && !e.wirbelt)
                                    .matchedGeometryEffect(id: i, in: wuerfelRaum)
                            }
                        }
                    }
                    .frame(minHeight: kante)
                    .animation(ohneBewegung ? nil : .spring(duration: 0.3), value: e.auswahl)
                    .animation(ohneBewegung ? nil : .spring(duration: 0.3), value: e.umdrehen)
                    if mensch && breitTisch { hinweis }
                }
                Spacer(minLength: 0)
                if mensch && !breitTisch { hinweis }
            }
            .padding(16)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var hinweis: some View {
        Text(z.optionen.herauslegen == .einsen ? "Tippe Einsen an, um sie herauszulegen." : "Tippe Würfel an, um sie herauszulegen.")
            .font(breitTisch ? .body : .footnote).multilineTextAlignment(.center).tischHinweis()
    }

    private func kopfzeile(_ zug: Zug?, mensch: Bool) -> some View {
        VStack(spacing: 2) {
            if let s = sichtbar?.spieler, let zug {
                Text(s == z.aktuellerSpieler ? z.namen[s] : z.hatGeworfen(s))
                    .font(breitTisch ? .callout.weight(.semibold) : .footnote.weight(.semibold)).tischHinweis(zeilen: 1, sonst: Color.schriftZweit)
                Text(e.wirbelt ? " " : zug.wertung().name)
                    .font(breitTisch ? .system(size: 38, weight: .black, design: Design.zahlDesign) : .system(.title, design: Design.zahlDesign, weight: .black))
                    .foregroundStyle((Tisch.aktiv ? Tisch.elfenbein : Color.accentText))
                    .contentTransition(.numericText())
                    // N-028: bei großer Schrift umbrechen statt auf eine Zeile zu quetschen
                    .minimumScaleFactor(0.7).lineLimit(typeSize.isAccessibilitySize && !Tisch.aktiv ? 3 : 1)
                Text("Wurf \(zug.wuerfe) von \(zug.maxWuerfe)").font(breitTisch ? .callout : .footnote).tischHinweis(zeilen: 1, sonst: Color.schriftZweit)
                if mensch, let t = e.hilfeText(z), preferences.hilfen {
                    Text(t).font(breitTisch ? .callout.weight(.semibold) : .footnote.weight(.semibold)).foregroundStyle((Tisch.aktiv ? Tisch.elfenbein : Color.accentText)).multilineTextAlignment(.center).lineLimit(Tisch.aktiv ? 2 : nil).minimumScaleFactor(Tisch.aktiv ? 0.8 : 1)
                }
            } else {
                Text("Noch nicht geworfen").font(.title3.weight(.semibold)).tischHinweis(zeilen: 1, sonst: Color.schriftZweit)
            }
        }
        // N-028: Zeilen behalten ihre Höhe und stapeln sich, statt sich zu überlagern
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("wertung")
    }

    private func wuerfelKnopf(_ i: Int, wert: Int, kante: Double, aktiv: Bool) -> some View {
        let rollt = e.wirbelt && !e.gelandet.contains(i)
        let angezeigt = rollt ? e.gezeigt[i % 3] : wert
        let lage = lagen[i % 3]
        return Button { e.tippe(z, i, preferences: preferences) } label: {
            DieView(wert: angezeigt, size: kante)
                .rotationEffect(.degrees(rollt ? Double(angezeigt * 9 - 30) : lage.winkel))
                .offset(x: rollt ? CGFloat(e.gezeigt[(i + 1) % 3]) * 3 - 10 : lage.dx,
                        y: rollt ? CGFloat(e.gezeigt[(i + 2) % 3]) * 2 - 7 : lage.dy)
                .overlay(alignment: .top) {
                    if e.tippSichtbar, z.runde.zug.map({ e.tippIndizes($0).contains(i) }) == true {
                        Circle().fill(Color.accentColor).frame(width: 14, height: 14)
                            .overlay(Circle().strokeBorder(Color.onAccent, lineWidth: 2))
                            .offset(y: -6)
                    }
                }
                .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(aktiv)
        .keyboardShortcut(KeyEquivalent(Character("\(min(i + 1, 3))")), modifiers: [])
        .accessibilityLabel(String(localized: "Würfel \(i + 1): \(neuZahlWort(wert)), im Becher"))
        .accessibilityHint(aktiv ? String(localized: "Doppeltippen zum Herauslegen") : "")
        .modifier(WackelEffekt(zaehler: e.wackeln))
        .onChange(of: e.wirbelt) { _, jetzt in
            if jetzt { lagen = (0..<3).map { _ in WuerfelLage(dx: .random(in: -9...9), dy: .random(in: -6...6), winkel: .random(in: -18...18)) } }
            else { withAnimation(.spring(duration: 0.4).delay(0.35)) { lagen = Array(repeating: .ruhig, count: 3) } }
        }
    }
}

/// Karte der gewerteten Runde: Satz zur Deckelbewegung, schlechtester und bester Wurf, die Würfe in Spielreihenfolge.
struct NeuRundenKarte: View {
    let z: Spielzustand

    var body: some View {
        VStack(spacing: Design.Abstand.m) {
            if let text = z.bannerText, let a = z.runde.ausgang {
                VStack(spacing: Design.Abstand.xs) {
                    Text(text).font(.headline).multilineTextAlignment(.center)
                    if let v = z.haelfte.verlierer {
                        Text(z.hatAlleDeckel(v, z.haelfte.art.titel)).font(.subheadline).multilineTextAlignment(.center)
                    } else {
                        Text(z.beginntNaechste(a.verlierer)).font(.subheadline).multilineTextAlignment(.center).tischHinweis()
                    }
                }
                .accessibilityElement(children: .combine)
            }
            VStack(spacing: 6) {
                TischUeberschrift("Die Würfe der Runde")
                ForEach(Array(z.runde.zuege.enumerated()), id: \.offset) { _, p in
                    let verloren = z.runde.ausgang?.verlierer == p.spieler
                    let gewonnen = z.runde.ausgang?.gewinner == p.spieler
                    HStack(spacing: Design.Abstand.s) {
                        Text(z.avatare[p.spieler]).font(.title3)
                        Text(z.namen[p.spieler]).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(p.ergebnis.wertung.name) · \(wuerfeText(p.ergebnis.wuerfe))").font(.subheadline.monospacedDigit())
                        Image(systemName: verloren ? "arrow.down.circle.fill" : (gewonnen ? "arrow.up.circle.fill" : "circle"))
                            .foregroundStyle(verloren ? Color.meldungRot : (gewonnen ? Color.meldungGruen : Color.secondary.opacity(0.4)))
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Self.sprechtext(z, p, verloren: verloren, gewonnen: gewonnen))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    static func sprechtext(_ z: Spielzustand, _ p: ZugProtokoll, verloren: Bool, gewonnen: Bool) -> Text {
        var t = Text("\(z.namen[p.spieler]): \(p.ergebnis.wertung.name), \(wuerfeText(p.ergebnis.wuerfe))")
        if verloren { t = t + Text(", schlechtester Wurf") } else if gewonnen { t = t + Text(", bester Wurf") }
        return t
    }
}


/// Bauplan T3-2: sichtbare Ablage für „Draußen“ auf dem breiten Tintentisch; sonst unverändert.
private struct AblageRahmen: ViewModifier {
    let aktiv: Bool
    let klein: CGFloat
    func body(content: Content) -> some View {
        if aktiv {
            content
                .padding(12)
                .frame(minWidth: klein * 3 + 2 * Design.Abstand.s + 24, minHeight: klein + 24)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Tisch.elfenbein.opacity(0.28), lineWidth: 1))
        } else { content }
    }
}
