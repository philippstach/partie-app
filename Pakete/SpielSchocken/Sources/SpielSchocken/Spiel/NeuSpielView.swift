// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielbildschirm von „Schocken“: kein Scrollen, die Becher-Zone nimmt die Resthöhe.
/// iPhone und iPad hoch von oben: Kopf · Spielerleiste mit Deckeln · Tischkarte · Becher-Zone · feste Knöpfe.
/// iPad quer: links Spielerkarten, Tischkarte und die Würfe der Runde, rechts die Becher-Zone mit den Knöpfen.
struct NeuSpielView: View {
    let abbrechen: () -> Void
    let ende: () -> Void
    @Environment(GameStore.self) private var store
    @Environment(AppPreferences.self) private var preferences
    @Environment(AbendStore.self) private var abendStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var e = NeuEingabe()
    @State private var size: CGSize = .zero
    @State private var showRegeln = false
    @Environment(\.regelnOeffnen) private var regelnOeffnen   // T-091: „Regeln“ im Menü öffnet die Regelseite des Rahmens
    @State private var showHausregeln = false
    @State private var showVerlauf = false
    @State private var showAbend = false
    @State private var letzteSchuettel = Date.distantPast

    private var gross: Bool { typeSize.isAccessibilitySize }
    private var ohneBewegung: Bool { preferences.reduceAnimations || systemReduceMotion }
    private var regular: Bool { sizeClass == .regular }
    /// Größte Schrift auf dem Tisch: in Tinte wachsen Hinweise und Wertung nur begrenzt (Punkt 4), sonst wie bisher.
    private var tischSchrift: DynamicTypeSize { Tisch.aktiv ? .xxxLarge : .accessibility5 }
    private var aufbau: NeuLogik.Aufbau { NeuLogik.aufbau(breite: size.width, hoehe: size.height, regular: regular) }

    var body: some View {
        Group {
            if let z = store.zustand {
                switch z.phase {
                case .partieVorbei: NeuEndeKarte(z: z, ende: ende, abend: { showAbend = true })
                case .haelfteVorbei: HalfOverView(zustand: z)
                default: spiel(z)
                }
            } else {
                Color.clear
            }
        }
        .environment(e)
        .sheet(isPresented: $showAbend) { AbendAbschlussView() }
        .onAppear { ShakeDetector.shared.start() }
        .onDisappear { ShakeDetector.shared.stop() }
    }

    // MARK: Aufbau

    private func spiel(_ z: Spielzustand) -> some View {
        Group {
            switch aufbau {
            case .spalte: spalte(z)
            case .quer: quer(z)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .safeAreaInset(edge: .top, spacing: 0) { kopf(z) }
        .aufTisch()   // Design-Runde 3: Tinte = Filz bis in die Ecken, sonst Seitengrund (nach den Leisten)
        .sheet(isPresented: $showRegeln) { RulesView() }
        .sheet(isPresented: $showHausregeln) { NeuRegelnBlatt() }
        .sheet(isPresented: $showVerlauf) { VerlaufView(zustand: z) }
        .onChange(of: wurfSchluessel(z)) { _, _ in nachWurf(z) }
        .onChange(of: z.phase) { _, neu in
            if neu != .computer { e.ueberspringen = false }
            if neu == .rundenwertung, let t = z.bannerText { AccessibilityNotification.Announcement(t).post() }
            if neu == .vorWurf || neu == .rundenwertung { e.zuruecksetzen() }
        }
        .task(id: antrieb(z)) { await computerAntrieb(z) }
        .task(id: wurfSchluessel(z)) { await e.hilfeBerechnen(z, an: preferences.hilfen) }
        .onReceive(NotificationCenter.default.publisher(for: .schockenGeschuettelt)) { _ in schuettel(z) }
    }

    /// iPhone und iPad hoch: eine Spalte, Breite begrenzt und mittig.
    private func spalte(_ z: Spielzustand) -> some View {
        let klein = size.height < NeuLogik.hoeheMittel || gross
        let inhalt = VStack(spacing: Design.Abstand.s) {
            NeuSpielerLeiste(z: z, hoehe: size.height) { showVerlauf = true }.dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // B18 N-015
            NeuTischKarte(z: z, kompakt: klein).dynamicTypeSize(...tischSchrift)
            // M-026: bei großer Schrift behält der Becher Mindesthöhe (die Würfel bleiben groß), die Seite scrollt
            // Tinte (Punkt 4): Würfel und Knopf haben Vorrang. Texte im Becher wachsen begrenzt, der Becher füllt die Resthöhe, keine Seite zum Scrollen.
            NeuBecher(z: z, hoechsteKante: NeuLogik.wuerfelKante(hoehe: size.height, grosseSchrift: gross && !Tisch.aktiv, regular: regular))
                .dynamicTypeSize(...tischSchrift)
                .frame(minHeight: gross && !Tisch.aktiv ? 520 : 0)
        }
        .padding(.horizontal, regular && Tisch.aktiv ? 20 : 12)   // Blatt 16 / T2: iPad hoch in Tinte ganze Breite mit 20 pt Rand
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(maxWidth: regular ? (Tisch.aktiv ? CGFloat.infinity : 680) : 520)
        .frame(maxWidth: .infinity)
        return Group { if gross && !Tisch.aktiv { ScrollView { inhalt } } else { inhalt } }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if regular && Tisch.aktiv {
                    // Blatt 16 / T2: Knopfleiste auf dem iPad in Tinte über die ganze Breite mit 20 pt Rand (BottomBar deckelt sie auf die schmale Spalte)
                    NeuLeiste(z: z).padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 6).frame(maxWidth: .infinity).tischLeiste()
                } else {
                    BottomBar { NeuLeiste(z: z) }.tischLeiste()
                }
            }
    }

    /// iPad quer: links 40 % Tisch, rechts die Becher-Zone.
    private func quer(_ z: Spielzustand) -> some View {
        HStack(alignment: .top, spacing: Design.Abstand.l) {
            VStack(spacing: 10) {
                NeuTischKarte(z: z)
                NeuSpielerLeiste(z: z, hoehe: size.height, senkrecht: true) { showVerlauf = true }.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                NeuRundeUebersicht(z: z)
                Spacer(minLength: 0)
            }
            .frame(width: size.width * 0.4)
            NeuBecher(z: z, hoechsteKante: NeuLogik.wuerfelKante(hoehe: size.height, grosseSchrift: gross, regular: true))
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .safeAreaInset(edge: .bottom, spacing: 0) { BottomBar { NeuLeiste(z: z) }.tischLeiste() }
    }

    private func kopf(_ z: Spielzustand) -> some View {
        SpielKopf(mitte: "\(z.haelfte.art.titel) · \(String(localized: "Runde")) \(z.rundenNummer)", linksAktion: abbrechen) {
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                NeuePartieMenuePunkt()   // G-019
                Button("Verlauf", systemImage: "list.bullet.rectangle") { showVerlauf = true }
                if store.vorErstemZug { Button("Hausregeln ändern", systemImage: "slider.horizontal.3") { showHausregeln = true } }
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                Button("Regeln", systemImage: "book") { if let regelnOeffnen { regelnOeffnen() } else { showRegeln = true } }
                Button("Euer Abend", systemImage: "moon.stars") { showAbend = true }
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
    }

    // MARK: Wurf-Gefühl

    /// Ändert sich bei jedem Wurf (und bei jedem Zugende).
    private struct WurfSchluessel: Hashable {
        var runden: Int, position: Int, wuerfe: Int, wurf: [Int], draussen: [Int]
    }

    private func wurfSchluessel(_ z: Spielzustand) -> WurfSchluessel {
        WurfSchluessel(runden: z.haelfte.runden, position: z.runde.position, wuerfe: z.runde.zug?.wuerfe ?? 0,
                       wurf: z.runde.zug?.wurf ?? [], draussen: z.runde.zug?.draussen ?? [])
    }

    private func istEcht(_ z: Spielzustand) -> Bool {
        guard let s = z.aktuellerSpieler else { return false }
        return z.strategien[s] == .mensch && z.wuerfelModus.indices.contains(s) && z.wuerfelModus[s] == .echt
    }

    private func nachWurf(_ z: Spielzustand) {
        guard let zug = z.runde.zug, zug.wuerfe > 0, !zug.wurf.isEmpty else { return }
        e.auswahl = []
        e.umdrehen = 0
        let echt = istEcht(z)
        if !echt { Sound.roll.play() }
        let wertung = zug.wertung()
        let wer = z.aktuellerSpieler.flatMap { z.strategien[$0] != .mensch ? z.namen[$0] + ": " : nil } ?? ""
        let landen = {
            switch wertung.art {
            case .schockAus:
                Sound.schockaus.play()
                SpielHaptik.success()
            case .schock, .general, .jule:
                Sound.good.play()
                if wertung.art == .schock { SpielHaptik.medium() }
            case .strasse:
                Sound.good.play()
            case .zahl: break
            }
            AccessibilityNotification.Announcement(wer + "\(wertung.name), " + String(localized: "Wurf \(zug.wuerfe) von \(zug.maxWuerfe)")).post()
        }
        guard !ohneBewegung, !e.ueberspringen, !echt else {
            if !echt { SpielHaptik.tap() }
            landen()
            return
        }
        // Rollen, dann einzeln versetzt landen (kleiner Klack und leichter Tap je Würfel)
        e.wirbelt = true
        e.gelandet = []
        let anzahl = zug.wurf.count
        Task { @MainActor in
            for _ in 0..<5 {
                e.gezeigt = (0..<3).map { _ in Int.random(in: 1...6) }
                try? await Task.sleep(for: .milliseconds(70))
            }
            for i in 0..<anzahl {
                withAnimation(.spring(duration: 0.28, bounce: 0.35)) { _ = e.gelandet.insert(i) }
                Sound.klack.play()
                SpielHaptik.tap()
                try? await Task.sleep(for: .milliseconds(50))
            }
            withAnimation(.spring(duration: 0.3)) { e.wirbelt = false }
            landen()
        }
    }

    private func schuettel(_ z: Spielzustand) {
        guard preferences.schuetteln, SpieleSchuetteln.erlaubt, !istEcht(z), !UIAccessibility.isVoiceOverRunning, !e.wirbelt,
              Date().timeIntervalSince(letzteSchuettel) > 0.8 else { return }
        letzteSchuettel = Date()
        switch z.phase {
        case .vorWurf: store.wuerfeln()
        case .nachWurf:
            guard let zug = z.runde.zug, zug.darfWeiter else { return }
            let werte = e.auswahl.map { zug.wurf[$0] }.sorted()
            if store.weiter(herauslegen: werte, umdrehen: e.umdrehen) { e.zuruecksetzen() }
        default: break
        }
    }

    // MARK: Computer

    private struct Antrieb: Hashable {
        var phase: Phase, runden: Int, position: Int, wuerfe: Int, zuege: Int, ueberspringen: Bool, wirbelt: Bool
    }

    private func antrieb(_ z: Spielzustand) -> Antrieb {
        Antrieb(phase: z.phase, runden: z.haelfte.runden, position: z.runde.position, wuerfe: z.runde.zug?.wuerfe ?? 0,
                zuege: z.runde.zuege.count, ueberspringen: e.ueberspringen, wirbelt: e.wirbelt)
    }

    private func computerAntrieb(_ z: Spielzustand) async {
        let computerZugEnde = z.phase == .zugEnde && (z.aktuellerSpieler.map { z.strategien[$0] != .mensch } ?? false)
        guard z.phase == .computer || computerZugEnde, !e.wirbelt else { return }
        if computerZugEnde {
            // Der letzte Wurf bleibt stehen: Pause je Tempo, „Überspringen“ kürzt sie ab
            if !e.ueberspringen { try? await Task.sleep(for: preferences.tempo.zugEndePause) }
            guard !Task.isCancelled else { return }
            store.zugWeiter()
            return
        }
        if !e.ueberspringen {
            try? await Task.sleep(for: preferences.tempo.pause * (z.zugLaeuft ? 0.8 : 0.5))
        } else {
            await Task.yield()
        }
        guard !Task.isCancelled else { return }
        await store.computerSchritt()
    }
}

/// iPad quer: „Diese Runde“ – die Würfe aller Spieler bisher, in Spielreihenfolge.
struct NeuRundeUebersicht: View {
    let z: Spielzustand

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TischUeberschrift("Diese Runde")
            ForEach(z.runde.reihenfolge, id: \.self) { s in
                HStack {
                    Text(z.avatare[s])
                    Text(z.namen[s]).font(.subheadline)
                    Spacer()
                    Text(z.rundenText(s) ?? "–").font(.subheadline.monospacedDigit()).foregroundStyle(z.rundenText(s) == nil ? (Tisch.aktiv ? AnyShapeStyle(Tisch.hinweisLeise) : AnyShapeStyle(HierarchicalShapeStyle.tertiary)) : AnyShapeStyle(HierarchicalShapeStyle.primary))
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tischFlaeche(16)
    }
}

/// Partie entschieden: Verlierer, Stand, „Ergebnis“ (weiter zum Rahmen) und – als Blatt – der Abend.
struct NeuEndeKarte: View {
    let z: Spielzustand
    let ende: () -> Void
    let abend: () -> Void

    var body: some View {
        let v = z.partieVerlierer ?? 0
        VStack(spacing: Design.Abstand.l) {
            Spacer(minLength: 0)
            AvatarAbzeichen(avatar: z.avatare[v], farbe: Theme.color(v), groesse: 96)
            Text(z.istDu(v) ? String(localized: "Du verlierst die Partie") : String(localized: "\(z.namen[v]) verliert die Partie"))
                .font(.title2.weight(.bold)).multilineTextAlignment(.center)
            VStack(spacing: 6) {
                ForEach(z.namen.indices, id: \.self) { i in
                    HStack {
                        Text(z.avatare[i])
                        Text(z.namen[i]).font(.subheadline.weight(.semibold))
                        Spacer()
                        let n = z.zaehler.haelftenVerloren[i]
                        (n == 1 ? Text("1 Hälfte verloren") : Text("\(n) Hälften verloren")).font(.subheadline).tischHinweis(zeilen: 1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(14)
            .tischFlaeche(16)
            Spacer(minLength: 0)
            VStack(spacing: Design.Abstand.s) {
                Button(action: ende) { Text("Ergebnis").font(.headline).frame(maxWidth: .infinity) }
                    .hauptKnopf()
                    .accessibilityIdentifier("ergebnis")
                Button(action: abend) { Label("Abend ansehen", systemImage: "moon.stars").frame(maxWidth: .infinity) }
                    .zweitKnopf()
                    .accessibilityIdentifier("abendAnsehen")
            }
        }
        .padding()
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aufTisch()   // Design-Runde 3: Tinte = Filz, sonst Seitengrund
    }
}
