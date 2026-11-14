// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
import UIKit


private extension View {
    /// Tastatur: Leertaste würfelt, 1–4 ziehen die Figur mit dieser Nummer.
    func tastenkuerzel(_ spiel: SpielController) -> some View {
        background {
            ZStack {
                Button("") { spiel.wuerfelnTippen() }.keyboardShortcut(.space, modifiers: [])
                ForEach(0 ..< 4, id: \.self) { i in
                    Button("") {
                        if let z = spiel.zustand { spiel.figurTippen(FigurID(spieler: z.amZug, figur: i)) }
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
                }
            }
            .opacity(0).allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

// MARK: - Brett mit Namen und Würfel

/// Das Brett in der Spielkarte: Namen der Spieler in den Ecken außerhalb des Bretts, Würfel beim Spieler, Banner oben.
struct BrettMitNamen: View {
    @Environment(SpielController.self) private var spiel
    @Environment(AppPreferences.self) private var prefs
    let z: Spielzustand
    @Environment(\.brettTheme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            HStack { name(sitz: 0); Spacer(); name(sitz: 1) }
            BrettView(lage: spiel.lage, theme: theme,
                      beweglich: spiel.beschaeftigt ? [] : z.bewegliche,
                      geist: spiel.geist,
                      vorne: spiel.vorne,
                      bewegungReduziert: spiel.bewegungReduziert,
                      beschreibung: beschreibung,
                      onFigur: { spiel.figurTippen($0) },
                      onVorschau: { spiel.vorschau($0, aktiv: $1) },
                      effekte: spiel.effekte,
                      dranSitz: z.phase == .vorbei ? nil : z.aktuellerSpieler.sitz,
                      sieger: spiel.feiert,
                      aufbau: true) { zelle in
                WuerfelPlatz(z: z, zelle: zelle)
            }
            HStack { name(sitz: 3); Spacer(); name(sitz: 2) }
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    @ViewBuilder
    private func name(sitz: Int) -> some View {
        if let i = z.spieler.firstIndex(where: { $0.sitz == sitz }) {
            let s = z.spieler[i]
            HStack(spacing: Design.Abstand.xs) {
                Image(systemName: theme.symbol(sitz)).font(.caption2.weight(.bold))
                Text(s.name).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(theme.textfarbe(sitz))
            .accessibilityHidden(true)
        } else {
            Color.clear.frame(height: 1)
        }
    }

    /// VoiceOver: „Blau, Figur 2, Feld 14 von 40, beweglich: zieht auf Feld 17 und wirft Grün raus.“
    private func beschreibung(_ id: FigurID) -> String {
        let sitz = z.lage.sitze[id.spieler]
        let farbe = theme.name(sitz)
        let rel = spiel.lage.figuren[id.spieler][id.figur]
        var text: String
        if rel == Brettmass.haus {
            text = L("a11y.figur.haus", farbe, id.figur + 1)
        } else if rel >= Brettmass.zielErstes {
            text = L("a11y.figur.ziel", farbe, id.figur + 1)
        } else {
            text = L("a11y.figur.feld", farbe, id.figur + 1, rel + 1)
        }
        if !spiel.beschaeftigt, let zug = z.zug(fuer: id), z.bewegliche.contains(id) || rel == Brettmass.haus {
            text += ", " + (zug.nach >= Brettmass.zielErstes ? L("a11y.beweglichZiel") : L("a11y.beweglich", zug.nach + 1))
            if let q = zug.schlaegt, let opfer = z.spieler[safe: q] {
                text += " " + L("a11y.schlaegt", theme.name(opfer.sitz))
            }
        }
        return text
    }
}

/// Der Würfel auf dem Würfelplatz (2 × 2 Zellen, ganze Fläche ist tippbar), darunter die Fehlversuche.
struct WuerfelPlatz: View {
    @Environment(SpielController.self) private var spiel
    let z: Spielzustand
    let zelle: CGFloat

    var body: some View {
        let eingabe = z.erwartetEingabe && !spiel.beschaeftigt
        let kannWuerfeln = z.phase == .vorWurf && !spiel.beschaeftigt && !z.aktuellerSpieler.wuerfeltEcht
        let dran = z.aktuellerSpieler
        Button { spiel.wuerfelnTippen() } label: {
            ZStack {
                DieView(wert: eingabe ? nil : (spiel.wuerfelt ? spiel.wuerfelFlaeche : spiel.letzteAugen),
                        aktiv: kannWuerfeln || eingabe,
                        gedimmt: !eingabe && (spiel.keinZug || (z.partie.spielzug.augen == nil && spiel.letzteAugen != nil)),
                        size: max(zelle * 1.6, 52),
                        leerSymbol: eingabe ? "hand.raised" : "dice")
                    .modifier(WuerfelWackeln(zaehler: spiel.wurfZaehler, aktiv: !spiel.bewegungReduziert))
                    .modifier(WuerfelPlopp(zaehler: spiel.plopp, aktiv: !spiel.bewegungReduziert))
                    .offset(y: z.versucheUebrig != nil ? -zelle * 0.12 : 0)
                if z.versucheUebrig != nil {
                    HStack(spacing: Design.Abstand.xs) {
                        ForEach(0 ..< 3, id: \.self) { i in
                            Circle().fill(i < z.partie.spielzug.fehlversuche ? Color.secondary : Color.clear)
                                .overlay(Circle().strokeBorder(Color.secondary, lineWidth: 1.2))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .offset(y: max(zelle * 0.8, 26) + zelle * 0.12 + 3)
                    .accessibilityHidden(true)
                }
            }
            .frame(width: max(zelle * 2, 56), height: max(zelle * 2, 56))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(false)
        .accessibilityLabel(eingabe ? L("echt.frage", dran.name) : (spiel.letzteAugen.map { L("a11y.wuerfel", $0) } ?? L("a11y.wuerfelNochNicht")))
        .accessibilityValue(dran.name)
        .accessibilityAddTraits(kannWuerfeln ? .isButton : [])
    }
}

// MARK: - Spielerleiste



private struct Pulsieren: ViewModifier {
    let zaehler: Int?

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat(1), trigger: zaehler) { view, s in
            view.scaleEffect(s)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(zaehler == nil ? 1 : 1.3, duration: 0.18)
                CubicKeyframe(1, duration: 0.25)
            }
        }
    }
}

// MARK: - Hinweiszeile

struct HinweisZeile: View {
    @Environment(GameStore.self) private var store
    @Environment(SpielController.self) private var spiel
    @State private var aufleuchten = false

    var body: some View {
        if let z = store.zustand {
            HStack(spacing: Design.Abstand.m) {
                if let b = spiel.banner {
                    // Rauswurf, „… ist im Ziel!“, „… fängt an“: in der Karte unter dem Brett, das Brett bleibt frei
                    HStack(spacing: Design.Abstand.s) {
                        if let l = b.links { AvatarBadge(avatar: l.avatar, sitz: l.sitz, size: 30) }
                        Text(b.text).font(.subheadline.weight(.bold)).lineLimit(2).minimumScaleFactor(0.8)
                        if let r = b.rechts { AvatarBadge(avatar: r.avatar, sitz: r.sitz, size: 30) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(b)
                    .transition(.opacity)
                } else if let w = spiel.eingetippt, spiel.kannZuruecknehmen {
                    // Echter Würfel: 3 Sekunden „Eingetippt: 4 · Ändern“ (Ändern = Rückgängig bis vor diese Eingabe)
                    HStack(spacing: 6) {
                        Text(L("echt.eingetippt", w)).font(.subheadline.weight(.medium))
                        Text("·").foregroundStyle(.secondary)
                        Button(L("echt.aendern")) { spiel.zuruecknehmen() }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText)
                            .frame(minHeight: Theme.tapSize)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(spiel.hinweis)
                        .font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                        .transaction { $0.animation = nil }          // kein Überblenden: sonst liegen alter und neuer Text übereinander
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if z.aktuellerSpieler.istComputer && z.phase == .computer && !spiel.schnell {
                    Button(L("knopf.schneller")) { spiel.schneller() }
                        .buttonStyle(AkzentPilleStil(gefuellt: false)).frame(width: 130)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)         // bei größter Schrift nicht die halbe Seite
            .padding(.horizontal, 12)
            .frame(minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 14).fill(Color.seitenGrund)   // K-034: deckend unterlegt, sonst scheint das Brett durch
                RoundedRectangle(cornerRadius: 14).fill(Tisch.aktiv ? Color.white.opacity(0.14) : Color.kartenGrund)
                RoundedRectangle(cornerRadius: 14).fill(Color.appFlaeche.opacity(aufleuchten ? 0.28 : 0))     // kurzes Aufleuchten
            }
            .animation(.easeOut(duration: 0.5), value: aufleuchten)
            .onChange(of: spiel.banner) { _, neu in
                guard neu != nil, !spiel.bewegungReduziert else { return }
                aufleuchten = true
                Task { try? await Task.sleep(for: .milliseconds(250)); aufleuchten = false }
            }
            .accessibilityElement(children: .contain)
        }
    }
}

/// Eingabeleiste für den echten Würfel: sechs Würfelflächen mit Augen, ein Tipp übernimmt sofort.
struct EingabeLeiste: View {
    @Environment(SpielController.self) private var spiel
    let z: Spielzustand

    var body: some View {
        let name = z.aktuellerSpieler.name
        VStack(spacing: Design.Abstand.s) {
            if let w = spiel.weitergebenText { Text(w).font(.subheadline.weight(.bold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText) }
            Text(L("echt.frage", name)).font(.subheadline.weight(.semibold))
            if let n = z.versucheUebrig {
                Text(n == 1 ? L("hinweis.versuch1") : L("hinweis.versuche", n)).font(.caption).foregroundStyle(.secondary)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) { flaechen(1 ... 6) }
                VStack(spacing: 6) {
                    HStack(spacing: Design.Abstand.s) { flaechen(1 ... 3) }
                    HStack(spacing: Design.Abstand.s) { flaechen(4 ... 6) }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Tisch.aktiv ? Color.white.opacity(0.14) : Color.accentSoft, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }

    private func flaechen(_ bereich: ClosedRange<Int>) -> some View {
        ForEach(Array(bereich), id: \.self) { k in
            Button { spiel.eintippen(k) } label: {
                DieView(wert: k, size: 52)
                    .frame(minWidth: 56, minHeight: 56)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(k)")
            .accessibilityHint(L("echt.frage", z.aktuellerSpieler.name))
        }
    }
}


// MARK: - Sieger-Moment

/// Unter dem Brett: großer Avatar und Name des Siegers (statt der Hinweiszeile).
struct SiegerBanner: View {
    let z: Spielzustand
    let sieger: Int
    @State private var gross = false

    var body: some View {
        let s = z.spieler[sieger]
        HStack(spacing: 14) {
            AvatarBadge(avatar: s.avatar, sitz: s.sitz, size: 96)
                .scaleEffect(gross ? 1 : 0.2)
            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                Text(z.serieEntschieden ? L("sieg.serie") : (s.istComputer ? L("ende.vorbei") : L("ende.gewonnen")))
                    .font(.system(.title, design: Design.zahlDesign, weight: .black)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText)
                Text(s.name).font(.title3.weight(.bold)).foregroundStyle(BrettTheme.standard.textfarbe(s.sitz))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .tischFlaeche(14)
        .onAppear { withAnimation(.spring(duration: 0.6, bounce: 0.4)) { gross = true } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("ende.sieger", s.name))
    }
}

/// Konfetti in der Farbe des Siegers über dem ganzen Bildschirm; ein Tipp springt zum Ende-Bild.
struct SiegerKonfetti: View {
    @Environment(SpielController.self) private var spiel
    let sieger: Int

    var body: some View {
        ZStack {
            Color.clear.contentShape(.rect)
            if !spiel.bewegungReduziert, let z = spiel.zustand {
                Konfetti(farbe: BrettTheme.standard.farbe(z.spieler[sieger].sitz))
            }
        }
        .ignoresSafeArea()
        .onTapGesture { spiel.siegerMomentUeberspringen() }
        .accessibilityHidden(true)
    }
}
