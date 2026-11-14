// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielbildschirm von „Rauswurf“: kein Scrollen.
/// iPhone von oben: Kopf · Spielerleiste (Haus/Ziel) · Brett volle Breite · Rest (Hinweis, Eingabeleiste, Verlauf) · Würfeln · Aktionsleiste.
/// iPad hoch: Brett 640 pt mittig, darunter Rest. iPad quer: Brett links, Seitenspalte rechts (Spieler, Hinweis, Verlauf, Knöpfe).
struct NeuSpielView: View {
    @Environment(GameStore.self) private var store
    @Environment(SpielController.self) private var spiel
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    let abbrechen: () -> Void
    @State private var showWuerfel = false
    @State private var tippText: String?
    @State private var leisteH: CGFloat = 50

    private var z: Spielzustand? { store.zustand }

    var body: some View {
        VStack(spacing: 0) {
            kopf
            if let z {
                GeometryReader { geo in inhalt(z, geo.size) }
            } else {
                Color.clear
            }
        }
        .overlay { if let sieger = spiel.feiert, !spiel.endeSichtbar { SiegerKonfetti(sieger: sieger) } }
        .overlay { startEinblendung }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher; das Blatt danach bleibt im System-Aussehen
        .sheet(isPresented: $showWuerfel) { WuerfelStatistikView() }
        .onChange(of: spiel.ansage) { _, neu in if !neu.isEmpty { AccessibilityNotification.Announcement(neu).post() } }
        .onChange(of: store.partieID) { _, _ in spiel.starten() }
        .onAppear { spiel.starten() }
        .onChange(of: showWuerfel) { _, offen in if offen { spiel.anhalten() } else { spiel.starten() } }
        .onChange(of: scenePhase) { _, phase in if phase == .active { spiel.starten() } else { spiel.anhalten() } }
        .onDisappear { spiel.anhalten() }
        .beimSchuetteln { spiel.wuerfelnTippen() }   // Schütteln würfelt: Erkennung und Schalter kommen aus dem Kern
        .onChange(of: z?.partie.spielzug.stand) { _, _ in tippText = nil }
    }

    // MARK: Aufbau

    private func inhalt(_ z: Spielzustand, _ size: CGSize) -> some View {
        let layout = NeuLayout.entscheide(breite: size.width, hoehe: size.height + 56, sizeClass: sizeClass, grosseSchrift: typeSize.isAccessibilitySize)
        return Group {
            if layout == .breitQuer { quer(z, size) } else { hochformat(z, size, breit: layout.breit) }
        }
        .frame(width: size.width, height: size.height, alignment: art == .tinte ? .top : .center)   // Tinte: Reicht die Höhe einmal nicht, läuft der Rest unten über, nicht nach oben in den Kopf
    }

    /// Höhe der Spielerleiste für die Rechnung: nie kleiner als die runde Tinte-Leiste (Bild, Name, Wert), auch bevor sie gemessen ist.
    private var leisteHoehe: CGFloat { max(leisteH, art == .tinte ? (typeSize.isAccessibilitySize ? 96 : 72) : 0) }

    /// Höhe der Aktionszeile für die Rechnung. In Tinte stehen die drei runden Knöpfe bei großer Schrift untereinander.
    /// Gemessene Höhe der Aktionsknöpfe. Auf einem schmalen iPhone stehen die drei runden Knöpfe in Tinte untereinander (3 Zeilen statt 1);
    /// die feste Schätzung 64 pt war dann zu klein, das Brett zu groß und die untere Leiste ragte aus dem Bild (KI-003).
    @State private var aktionH: CGFloat = 0
    private var aktionHoehe: CGFloat { max(art == .tinte && typeSize >= .xxxLarge ? 3 * Theme.tapSize + 16 + 8 : 64, aktionH) }

    /// Breite der Brettkarte: so groß wie möglich, ohne dass der Rest (Hinweis, Aktionen) herausfällt. Die Karte ist rund 40 pt höher als breit.
    private func brettBreite(_ z: Spielzustand, _ size: CGSize, breit: Bool) -> CGFloat {
        let rand: CGFloat = breit ? 24 : 12
        let restMin: CGFloat = z.erwartetEingabe && !spiel.beschaeftigt ? 150 : (breit ? 110 : 72)   // K-034: Karte (52 pt) braucht Platz, sonst überlappt sie das Brett
        let aktion: CGFloat = aktionHoehe + (zeigtWuerfelKnopf(size) ? 58 : 0)
        let frei = size.height - (leisteHoehe + aktion + restMin + 3 * 8 + 40 + 8)
        return max(220, min(size.width - 2 * rand, frei, breit ? (art == .tinte ? 900 : 640) : .infinity))   // Große Tinte-Runde, Punkt 13: auf dem iPad nutzt das Brett die Fläche
    }

    /// Der Hauptknopf „Würfeln“ braucht Höhe: erst ab einem hohen Bildschirm (nicht auf dem SE)
    private func zeigtWuerfelKnopf(_ size: CGSize) -> Bool { size.height >= 640 && !typeSize.isAccessibilitySize }

    @ViewBuilder private func hochformat(_ z: Spielzustand, _ size: CGSize, breit: Bool) -> some View {
        if art == .tinte && typeSize.isAccessibilitySize {
            hochformatGrosseSchrift(z, size, breit: breit)
        } else {
            hochformatNormal(z, size, breit: breit)
        }
    }

    /// Tinte, größte Schrift: Nichts wird gekürzt oder weggelassen. Spielerleiste, Brett, Hinweis, Würfeln und Aktionen stehen untereinander
    /// und lassen sich scrollen; das Brett nimmt die ganze Breite.
    private func hochformatGrosseSchrift(_ z: Spielzustand, _ size: CGSize, breit: Bool) -> some View {
        let rand: CGFloat = breit ? 24 : 12
        let w = max(220, min(size.width - 2 * rand, breit ? 900 : .infinity))
        return ScrollView {
            VStack(spacing: Design.Abstand.s) {
                NeuSpielerLeiste(z: z).padding(.horizontal, rand)
                brettKarte(z).frame(width: w, height: w + 40)
                rest(z).frame(maxWidth: max(w, 300)).padding(.horizontal, 12)
                wuerfelKnopf(z).padding(.horizontal, rand)
                aktionen(z)
            }
            .padding(.top, 4).padding(.bottom, 12)
            .frame(maxWidth: .infinity)
        }
    }

    private func hochformatNormal(_ z: Spielzustand, _ size: CGSize, breit: Bool) -> some View {
        let w = brettBreite(z, size, breit: breit)
        return VStack(spacing: Design.Abstand.s) {
            NeuSpielerLeiste(z: z).padding(.horizontal, breit ? 24 : 12)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { leisteH = $0 }
            brettKarte(z).frame(width: w, height: w + 40)
            rest(z).frame(maxWidth: max(w, 300), maxHeight: .infinity, alignment: .top).padding(.horizontal, 12).clipped().zIndex(1)
            if zeigtWuerfelKnopf(size) { wuerfelKnopf(z).padding(.horizontal, breit ? 24 : 12) }
            aktionen(z)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { aktionH = $0 }
        }
        .padding(.top, 4).padding(.bottom, 4)
        .frame(maxWidth: .infinity)
    }

    private func quer(_ z: Spielzustand, _ size: CGSize) -> some View {
        let w = max(300, min(size.height - 16, size.width * 0.58))   // quer füllt das Brett schon die Höhe
        return HStack(alignment: .top, spacing: 20) {
            brettKarte(z).frame(width: w, height: w + 40).padding(.top, 4)
            VStack(spacing: 10) {
                NeuSpielerLeiste(z: z, senkrecht: true)
                rest(z).frame(maxHeight: .infinity, alignment: .top)
                wuerfelKnopf(z)
                aktionen(z)
            }
            .frame(maxWidth: 440)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
    }

    private func brettKarte(_ z: Spielzustand) -> some View {
        BrettMitNamen(z: z).id(store.partieID)
            .padding(10)
            .frame(maxWidth: .infinity)
            .tischFlaeche(Theme.cardRadius)
    }

    // MARK: Rest

    /// Hinweis oder Eingabeleiste (echter Würfel) oder Siegerbanner, darunter der Verlauf, soweit Platz ist
    private func rest(_ z: Spielzustand) -> some View {
        VStack(spacing: Design.Abstand.s) {
            if let sieger = spiel.feiert {
                SiegerBanner(z: z, sieger: sieger)
            } else if z.erwartetEingabe && !spiel.beschaeftigt {
                EingabeLeiste(z: z)
            } else {
                HinweisZeile()
            }
            if let t = tippText { Text(verbatim: t).font(.footnote).multilineTextAlignment(.center).tischHinweis(sonst: nil) }
            NeuVerlauf(z: z)
        }
    }

    private func wuerfelKnopf(_ z: Spielzustand) -> some View {
        let kann = z.phase == .vorWurf && !spiel.beschaeftigt && !z.aktuellerSpieler.wuerfeltEcht && !z.aktuellerSpieler.istComputer
        let titel: LocalizedStringKey = z.phase == .vorbei ? "Partie vorbei" : (z.aktuellerSpieler.istComputer ? "Computer spielt …" : (z.erwartetEingabe ? "Zahl eintippen" : (kann ? "Würfeln" : "Figur wählen")))
        return Button { spiel.wuerfelnTippen() } label: { Text(titel).frame(maxWidth: .infinity) }
            .buttonStyle(HauptKnopfStil())
            .disabled(!kann)
            .accessibilityIdentifier("rauswurf-neu-wuerfeln")
    }

    private func aktionen(_ z: Spielzustand) -> AnyView {
        let tippOK = z.partie.spielzug.stand == .wahl && !z.partie.spielzug.erlaubt.isEmpty && z.menschen.contains(z.amZug)
        if art == .tinte {
            // Große Tinte-Runde, Punkt 10: runde Knöpfe auf dem Filz; bei großer Schrift untereinander statt nebeneinander
            let knoepfe = Group {
                Button { spiel.zuruecknehmen() } label: { Label(LocalizedStringKey(L("knopf.rueckgaengig")), systemImage: "arrow.uturn.backward") }
                    .tischNebenKnopf().disabled(!spiel.kannZuruecknehmen)
                Button { tipp(z) } label: { Label("Tipp", systemImage: "lightbulb") }
                    .tischNebenKnopf().disabled(!tippOK)
                Button { showWuerfel = true } label: { Label(LocalizedStringKey(L("wuerfel.titel")), systemImage: "chart.bar") }
                    .tischNebenKnopf()
            }
            return AnyView(
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { knoepfe }
                    VStack(spacing: 8) { knoepfe }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
            )
        }
        return AnyView(AktionsLeiste(eintraege: [
            AktionsEintrag(symbol: "arrow.uturn.backward", titel: LocalizedStringKey(L("knopf.rueckgaengig")), gesperrt: !spiel.kannZuruecknehmen) { spiel.zuruecknehmen() },
            AktionsEintrag(symbol: "lightbulb", titel: "Tipp", gesperrt: !tippOK) { tipp(z) },
            AktionsEintrag(symbol: "chart.bar", titel: LocalizedStringKey(L("wuerfel.titel"))) { showWuerfel = true },
        ])
        .dynamicTypeSize(...DynamicTypeSize.accessibility1))
    }

    /// Der „gute“ Computer wählt, der Text nennt Figur und Ziel
    private func tipp(_ z: Spielzustand) {
        guard z.partie.spielzug.stand == .wahl else { return }
        let zug = Computer.entscheide(.gut, z.lage, z.amZug, z.partie.spielzug.erlaubt, menschen: z.menschen)
        let figur = (0 ..< 4).first { z.zug(fuer: FigurID(spieler: z.amZug, figur: $0)) == zug }.map { $0 + 1 } ?? 0
        let ziel = zug.nach >= Brettmass.zielErstes ? String(localized: "ins Ziel") : String(localized: "auf Feld \(zug.nach + 1)")
        let text = zug.von == Brettmass.haus ? String(localized: "Tipp: Figur \(figur) aus dem Haus setzen.") : String(localized: "Tipp: Figur \(figur) \(ziel) ziehen\(zug.schlaegt == nil ? "." : String(localized: " – wirft raus!"))")
        tippText = text
        UIAccessibility.post(notification: .announcement, argument: text)
    }

    // MARK: Kopf

    private var kopf: some View {
        let text = z.map { $0.phase == .vorbei ? L("hinweis.vorbei") : Spielernamen.dranText($0.aktuellerSpieler.name) } ?? ""
        return SpielKopf(mitte: text, linksAktion: abbrechen) {
            RundKnopfMenue(beschriftung: LocalizedStringKey(L("a11y.menue"))) {
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                Button(L("wuerfel.titel"), systemImage: "chart.bar") { showWuerfel = true }
                Button(L("menu.abbrechen"), systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
        .padding(.vertical, 4)
    }

    /// Startspieler (ausgelost) groß in der Mitte, bevor ein Computer loslegt
    @ViewBuilder private var startEinblendung: some View {
        if let e = spiel.startEinblendung, let l = e.links {
            HStack(spacing: Design.Abstand.m) {
                AvatarBadge(avatar: l.avatar, sitz: l.sitz, size: 44)
                Text(e.text).font(.system(.title2, design: Design.zahlDesign, weight: .bold)).multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 22).padding(.vertical, 16)
            .tischFlaeche(Theme.cardRadius)
            .padding(24)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Spielerleiste: je Spieler Zeichen, Name und „Haus 2 · Ziel 1“; der Spieler am Zug ist hinterlegt. Bei großer Schrift untereinander.
struct NeuSpielerLeiste: View {
    @Environment(SpielController.self) private var spiel
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    @Namespace private var rahmenRaum
    let z: Spielzustand
    var senkrecht = false

    var body: some View {
        if art == .tinte { tinteLeiste } else { klassischeLeiste }
    }

    /// Große Tinte-Runde, Punkt 6: die runde Spielerleiste aus KlarGlas mit Bild und eigener Farbe je Spieler (wie in Mäxchen), statt Emoji-Zellen.
    @ViewBuilder private var tinteLeiste: some View {
        if typeSize.isAccessibilitySize { grosseTinteLeiste } else { rundeTinteLeiste }
    }

    /// Größte Schrift: eine Zeile je Spieler, Name und „Haus 2 · Ziel 1“ brechen um, statt zu enden wie „Haus 4 · Zi…“.
    private var grosseTinteLeiste: some View {
        VStack(spacing: 6) {
            ForEach(Array(z.spieler.enumerated()), id: \.offset) { i, s in
                let dran = z.amZug == i && z.phase != .vorbei
                let (haus, ziel) = NeuLogik.hausZiel(spiel.lage.figuren[i])
                let platz = z.partie.platzierung.firstIndex(of: i).map { L("ende.platz", $0 + 1) + " · " } ?? ""
                HStack(spacing: 10) {
                    AvatarBadge(avatar: s.avatar, sitz: s.sitz, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.name).font(.headline).foregroundStyle(Tisch.elfenbein)
                        Text(verbatim: platz + String(localized: "Haus \(haus) · Ziel \(ziel)")).font(.subheadline).foregroundStyle(Tisch.hinweis)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8).padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(dran ? 0.22 : 0.08)))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(dran ? 0.5 : 0), lineWidth: 1.5))
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(dran ? .isSelected : [])
            }
        }
        .animation(spiel.bewegungReduziert ? nil : .easeInOut(duration: 0.3), value: z.amZug)
    }

    private var rundeTinteLeiste: some View {
        let eintraege: [SpielerLeiste.Eintrag] = Array(z.spieler.enumerated()).map { i, s in
            let (haus, ziel) = NeuLogik.hausZiel(spiel.lage.figuren[i])
            let platz = z.partie.platzierung.firstIndex(of: i).map { L("ende.platz", $0 + 1) + " · " } ?? ""
            return SpielerLeiste.Eintrag(id: "\(i)", name: s.name, farbe: SpieleKern.Spieler.farbe(i), wert: platz + String(localized: "Haus \(haus) · Ziel \(ziel)"))
        }
        return SpielerLeiste(eintraege: eintraege, aktiv: z.phase == .vorbei ? nil : "\(z.amZug)")
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .animation(spiel.bewegungReduziert ? nil : .easeInOut(duration: 0.3), value: z.amZug)
    }

    @ViewBuilder private var klassischeLeiste: some View {
        let untereinander = senkrecht || typeSize >= .xxxLarge
        let layout = untereinander ? AnyLayout(VStackLayout(spacing: 6)) : AnyLayout(HStackLayout(alignment: .center, spacing: Design.Abstand.xs))
        layout {
            ForEach(Array(z.spieler.enumerated()), id: \.offset) { i, s in zelle(i, s, breit: untereinander) }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .padding(4)
        .tischFlaeche(14)
        .animation(spiel.bewegungReduziert ? nil : .easeInOut(duration: 0.3), value: z.amZug)
    }

    private func zelle(_ i: Int, _ s: Spieler, breit: Bool) -> some View {
        let dran = z.amZug == i && z.phase != .vorbei
        let platz = z.partie.platzierung.firstIndex(of: i).map { $0 + 1 }
        let (haus, ziel) = NeuLogik.hausZiel(spiel.lage.figuren[i])
        let theme = BrettTheme.standard
        return HStack(spacing: 6) {
            AvatarBadge(avatar: s.avatar, sitz: s.sitz, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    if let platz { Text(L("ende.platz", platz)).font(.caption2.weight(.heavy)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText) }
                    Text(s.name).font(.footnote.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
                    if s.istComputer { Image(systemName: "cpu").font(.caption2).foregroundStyle(.secondary) }
                }
                .foregroundStyle(theme.textfarbe(s.sitz))
                Text("Haus \(haus) · Ziel \(ziel)").font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
            }
            if breit { Spacer(minLength: 0) }
        }
        .padding(.vertical, 5).padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if dran {
                RoundedRectangle(cornerRadius: 11).fill(Color.accentSoft).matchedGeometryEffect(id: "dranRahmen", in: rahmenRaum)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("a11y.mitSitz", s.name, theme.name(s.sitz)) + ", " + L("ende.imZielVon", ziel, z.lage.figuren[i].count)
                            + (s.istComputer ? ", " + L(s.strategie == .gut ? "computer.gut" : (s.strategie == .lieb ? "computer.lieb" : "computer.einfach")) : ""))
        .accessibilityAddTraits(dran ? .isSelected : [])
    }
}

/// Verlauf: die letzten Spielzüge; so viele, wie Platz ist (nichts, wenn nur die Hinweiszeile hineinpasst).
struct NeuVerlauf: View {
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    let z: Spielzustand

    var body: some View {
        ViewThatFits(in: .vertical) {
            liste(5)
            liste(3)
            liste(1)
            Color.clear.frame(height: 0)
        }
    }

    @ViewBuilder
    private func liste(_ n: Int) -> some View {
        let eintraege = Array(z.partie.verlauf.suffix(n).reversed())
        if eintraege.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                ForEach(Array(eintraege.enumerated()), id: \.offset) { i, e in
                    HStack(spacing: 6) {
                        AvatarBadge(avatar: z.spieler[safe: e.spieler]?.avatar ?? "", sitz: z.spieler[safe: e.spieler]?.sitz ?? 0, size: 18)
                        Text(verbatim: NeuLogik.verlaufText(e, z)).font(.footnote).lineLimit(1).minimumScaleFactor(0.8)
                            .foregroundStyle(i == 0 ? AnyShapeStyle(Color.primary) : (art == .tinte ? AnyShapeStyle(Tisch.hinweis) : AnyShapeStyle(Color.secondary)))   // Punkt 11: auf dem Filz heller
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tischFlaeche(14)
            .accessibilityElement(children: .combine)
        }
    }
}

/// Aufbau nach der Fenstergröße, nicht nach dem Gerät: unter 700 pt Breite immer iPhone-Aufbau, quer erst ab 1000 pt.
enum NeuLayout: Equatable {
    case kompakt, breitHoch, breitQuer
    var breit: Bool { self != .kompakt }

    static func entscheide(breite: CGFloat, hoehe: CGFloat, sizeClass: UserInterfaceSizeClass?, grosseSchrift: Bool = false) -> NeuLayout {
        if sizeClass == .compact || breite < 700 { return .kompakt }
        if grosseSchrift { return .breitHoch }
        return breite > hoehe && breite >= 1000 ? .breitQuer : .breitHoch
    }
}
