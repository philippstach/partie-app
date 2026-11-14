// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Bedienleiste unten: je nach Phase Würfeln, Stehen lassen / Weiter würfeln, Eingabe der echten Würfel oder Weiter.
struct NeuLeiste: View {
    let z: Spielzustand
    @Environment(GameStore.self) private var store
    @Environment(NeuEingabe.self) private var e
    @Environment(AppPreferences.self) private var preferences

    private var istEcht: Bool {
        guard let s = z.aktuellerSpieler else { return false }
        return z.strategien[s] == .mensch && z.wuerfelModus.indices.contains(s) && z.wuerfelModus[s] == .echt
    }

    var body: some View {
        VStack(spacing: Design.Abstand.s) {
            if let g = e.getippt {
                HStack {
                    Text("Eingetippt: \(g)").font(.footnote.weight(.semibold)).foregroundStyle((Tisch.aktiv ? Tisch.elfenbein : Color.accentText))
                    Spacer()
                    Button("Ändern") { store.eingabeAendern(); e.getippt = nil; e.echtAuftrag = nil }
                        .font(.footnote.weight(.semibold)).frame(minHeight: Theme.tapSize)
                        .accessibilityIdentifier("aendern")
                }
            }
            inhalt
        }
    }

    @ViewBuilder private var inhalt: some View {
        switch z.phase {
        case .vorWurf where istEcht:
            if let s = z.aktuellerSpieler { echteEingabe(s) }
        case .nachWurf where e.echtAuftrag != nil:
            if let s = z.aktuellerSpieler { echteEingabe(s) }
        case .zugEnde:
            zugEnde
        case .vorWurf:
            VStack(spacing: 6) {
                if let s = z.aktuellerSpieler, z.strategien.filter({ $0 == .mensch }).count >= 2 {
                    Text(z.istDran(s)).font(.footnote.weight(.semibold)).tischHinweis(zeilen: 1)
                }
                Button { store.wuerfeln() } label: { Text("Würfeln").font(.headline).frame(maxWidth: .infinity) }
                    .hauptKnopf()
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(e.wirbelt)
                    .accessibilityIdentifier("wuerfeln")
            }
        case .nachWurf:
            nachWurf
        case .computer:
            computer
        case .rundenwertung:
            Button { store.rundeWeiter(); e.zuruecksetzen() } label: { Text("Weiter").font(.headline).frame(maxWidth: .infinity) }
                .hauptKnopf()
                .keyboardShortcut(.space, modifiers: [])
                .accessibilityIdentifier("rundeWeiter")
        default:
            EmptyView()
        }
    }

    private var computer: some View {
        VStack(spacing: 6) {
            if let s = z.aktuellerSpieler {
                // N-027: heißt die Person schon „Computer“, nicht „Computer (Computer)“
                (z.namen[s] == String(localized: "Computer") ? Text("Computer würfelt …") : Text("\(z.namen[s]) (Computer) würfelt …")).font(.subheadline.weight(.semibold)).tischHinweis(zeilen: 1)
            }
            Button { e.ueberspringen = true } label: { Text("Überspringen").frame(maxWidth: .infinity) }
                .zweitKnopf()
                .disabled(e.ueberspringen)
        }
    }

    private var zugEnde: some View {
        let mensch = z.aktuellerSpieler.map { z.strategien[$0] == .mensch } ?? true
        return Group {
            if mensch {
                VStack(spacing: 6) {
                    Text("Zug beendet: \(z.runde.zug?.wertung().name ?? "")").font(.subheadline.weight(.semibold)).tischHinweis(zeilen: 1)
                    Button { store.zugWeiter() } label: { Text("Weiter").font(.headline).frame(maxWidth: .infinity) }
                        .hauptKnopf()
                        .keyboardShortcut(.space, modifiers: [])
                        .accessibilityIdentifier("zugWeiter")
                }
            } else {
                computer
            }
        }
    }

    private var nachWurf: some View {
        let zug = z.runde.zug
        let kannUmdrehen = zug.map { z.optionen.sechsenUmdrehen && maxUmdrehen($0.wurf) > 0 && $0.darfWeiter } ?? false
        return VStack(spacing: Design.Abstand.s) {
            if kannUmdrehen, let zug {
                Button { e.umdrehenSchalten(zug, preferences: preferences) } label: {
                    let max = maxUmdrehen(zug.wurf)
                    Label(max > 1 ? String(localized: "Sechsen umdrehen (\(e.umdrehen) von \(max))") : String(localized: "Sechsen umdrehen"),
                          systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .sichtbarBordered(aktiv: e.umdrehen > 0)
                .keyboardShortcut("u", modifiers: [])
            }
            if preferences.hilfen, let h = e.hilfe {
                HStack(spacing: Design.Abstand.s) {
                    Text(e.tippSichtbar ? e.tippText(h.tipp) : String(localized: "Brauchst du Hilfe?"))
                        .font(.footnote).foregroundStyle(e.tippSichtbar ? (Tisch.aktiv ? Tisch.elfenbein : Color.accentText) : (Tisch.aktiv ? Tisch.hinweis : Color.secondary)).lineLimit(Tisch.aktiv ? 2 : nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button { e.tippSichtbar.toggle() } label: { Label("Tipp", systemImage: "lightbulb") }
                        .buttonStyle(AkzentPilleStil(gefuellt: false)).frame(width: 96)
                        .accessibilityIdentifier("tipp")
                }
            }
            AdaptiveStack {
                Button { stehenLassen() } label: { Text("Stehen lassen").frame(maxWidth: .infinity) }
                    .sichtbarBordered(aktiv: e.tippSichtbar && e.hilfe?.tipp == .stehen)
                    .keyboardShortcut(.return, modifiers: [])
                    .accessibilityIdentifier("stehen")
                Button { weiterWuerfeln() } label: { Text("Weiter würfeln").font(.headline).frame(maxWidth: .infinity) }
                    .hauptKnopf()
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(e.wirbelt)
                    .accessibilityIdentifier("weiterWuerfeln")
            }
            .controlSize(.large)
        }
    }

    // MARK: Aktionen

    func weiterWuerfeln() {
        guard let zug = z.runde.zug else { return }
        let werte = e.auswahl.map { zug.wurf[$0] }.sorted()
        if istEcht {
            guard zug.istErlaubt(herauslegen: werte, umdrehen: e.umdrehen) else {
                e.wackeln += 1
                SpielHaptik.error()
                return
            }
            e.echtAuftrag = NeuEchtAuftrag(herauslegen: werte, umdrehen: e.umdrehen)
            return
        }
        if store.weiter(herauslegen: werte, umdrehen: e.umdrehen) {
            e.zuruecksetzen()
        } else {
            e.wackeln += 1
            SpielHaptik.error()
        }
    }

    private func stehenLassen() {
        e.zuruecksetzen()
        store.stehen()
    }

    // MARK: Echte Würfel

    /// 3 Sekunden lang „Eingetippt: 6-5-3 · Ändern“
    private func zeigeGetippt(_ text: String) {
        e.getippt = text
        e.getipptNr += 1
        let nr = e.getipptNr
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if e.getipptNr == nr { e.getippt = nil; store.eingabeAbschliessen() }
        }
    }

    private func echteEingabe(_ s: Int) -> some View {
        VStack(spacing: 6) {
            if z.schnelleingabe {
                EndergebnisEingabe(spieler: z.namen[s], maxWuerfe: z.runde.maxWuerfe, optionen: z.optionen) { w, n, ein in
                    if store.eingabeEndergebnis(wuerfel: w, wuerfe: n, ausEinemWurf: ein) {
                        zeigeGetippt(w.sorted(by: >).map(String.init).joined(separator: "-") + " · " + wuerfeText(n))
                    }
                }
                .id("\(z.haelftenVerlierer.count)-\(z.haelfte.runden)-\(z.runde.position)")
            } else if let a = e.echtAuftrag, let zug = z.runde.zug {
                let n = 3 - zug.draussen.count - a.herauslegen.count - a.umdrehen
                WuerfelEingabeFeld(titel: String(localized: "\(z.namen[s]): Was hast du geworfen?"), anzahl: n) { w in
                    if store.eingabeWeiter(herauslegen: a.herauslegen, umdrehen: a.umdrehen, werte: w) {
                        zeigeGetippt(w.map(String.init).joined(separator: "-"))
                        e.auswahl = []; e.umdrehen = 0
                    }
                    e.echtAuftrag = nil
                }
                Button("Abbrechen") { e.echtAuftrag = nil }.font(.footnote).frame(minHeight: Theme.tapSize)
            } else {
                WuerfelEingabeFeld(titel: String(localized: "\(z.namen[s]): Was hast du geworfen?"), anzahl: 3) { w in
                    store.eingabeWuerfeln(w)
                    zeigeGetippt(w.map(String.init).joined(separator: "-"))
                }
            }
        }
    }
}
