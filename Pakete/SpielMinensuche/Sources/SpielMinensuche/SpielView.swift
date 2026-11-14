// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import Baukasten
import MinensucheKern

struct SpielView: View {
    @Environment(SpielModell.self) private var modell
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    /// Große Tinte-Runde, Punkt 13: auf dem iPad in Tinte steht der Fahnen-Knopf direkt unter dem Feld, das Feld nutzt die Fläche
    private var untenImFeld: Bool { art == .tinte && sizeClass == .regular }
    /// Vom Rahmen: fragt „Spiel wirklich beenden?“ und führt zurück zum Start
    let abbrechen: () -> Void
    /// Nach dem Ende der Partie: weiter zum Ende-Bildschirm des Rahmens
    var weiter: () -> Void = {}

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                SpielKopf(
                    mitte: "\(titel) · \(SpielModell.zeit(modell.dauer(ctx.date)))",
                    linksAktion: abbrechen
                ) {
                    RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {   // B12-S1-024: Mehr-Menü wie in den anderen Spielen
                        FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                        NeuePartieMenuePunkt()   // F21-003: „Neue Partie“ wie in Kakuro, Schwimmen und Zehntausend
                        Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                    }
                }
            }
            if let s = modell.spiel {
                HStack(spacing: Design.Abstand.s) {
                    StatusChip(symbol: "flag.fill", text: Text("\(s.minenRest) Minen übrig"))
                    if s.hinweise > 0 {
                        Text("Hinweise: \(s.hinweise) (+\(s.hinweise * 10) s)").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.seitenRand)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)   // Kopfzeile wächst mit, ohne das Brett zu verdrängen
                // Das Brett bekommt den ganzen Restplatz (kein Spacer daneben, der es halbiert)
                BrettView(untenImFeld: untenImFeld && !s.istZuende ? AnyView(tischKnoepfe) : nil)
                    .padding(.horizontal, 8)
                    .layoutPriority(1)
            } else {
                Spacer(minLength: 0)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if !untenImFeld || modell.spiel?.istZuende == true { unten }
            else { BottomBar { frageStapel }.hidden().accessibilityHidden(true) }   // iPad Tinte: Platz für die Leiste nach der Mine freihalten, das Brett springt nicht
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .onChange(of: phase) { _, neu in
            if neu == .active { modell.fortsetzen() } else { modell.pausieren() }
        }
        .onAppear { modell.fortsetzen() }
        .onDisappear { modell.pausieren() }
        .transaction { if bewegungReduziert { $0.animation = nil } }
        .onChange(of: modell.spiel?.flaggen) { _, neu in
            if let s = modell.spiel, neu != nil { AccessibilityNotification.Announcement(String(localized: "\(s.minenRest) Minen übrig")).post() }
        }
        .onChange(of: modell.spiel?.status) { _, neu in
            if neu == .gewonnen { AccessibilityNotification.Announcement(String(localized: "Geschafft!")).post() }
            else if neu == .verloren { AccessibilityNotification.Announcement(String(localized: "Mine getroffen")).post() }
        }
        .sensoryFeedback(trigger: modell.spiel?.flaggen) { _, _ in SpieleHaptik.erlaubt ? .selection : nil }
        .sensoryFeedback(trigger: modell.spiel?.status) { _, neu in
            guard SpieleHaptik.erlaubt else { return nil }
            return neu == .gewonnen ? .success : (neu == .verloren ? .error : nil)
        }
        #if DEBUG
        .testEndeMelden {   // -testZustand ende: das letzte sichere Feld wird nach dem Laden als normaler Zug aufgedeckt
            guard let s = modell.spiel, s.status == .laeuft,
                  let i = (0..<s.mass.felder).first(where: { !s.istMine(s.mass.position($0)) && s.feld(s.mass.position($0)) == .verdeckt }) else { return }
            modell.aufdecken(s.mass.position(i))
        }
        #endif
    }

    /// Große Tinte-Runde, Punkt 10: „Fahne“ und „Hinweis“ als runde Knöpfe auf dem Filz (Fahne an = helle Fläche, dunkle Schrift)
    private var tischKnoepfe: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Design.Abstand.m) { fahneKnopf; hinweisKnopf }
            VStack(spacing: Design.Abstand.s) { fahneKnopf; hinweisKnopf }
        }
        .frame(maxWidth: .infinity)
    }

    private var fahneKnopf: some View {
        Button { modell.flaggenModus.toggle() } label: { Label("Fahne", systemImage: "flag.fill") }
            .buttonStyle(FahnenKnopfStil(an: modell.flaggenModus))
            .accessibilityAddTraits(modell.flaggenModus ? .isSelected : [])
    }

    private var hinweisKnopf: some View {
        Button { modell.hinweis() } label: { Label("Hinweis", systemImage: "lightbulb.fill") }
            .buttonStyle(TischKnopfStil())
            .disabled(modell.spiel?.status != .laeuft)
    }

    private var titel: String {
        modell.art == .tag ? String(localized: "Tagesrätsel") : modell.stufe.nameText
    }

    /// N-024: Die Leiste nach einer Mine (Frage, zwei Knöpfe). Ihre Höhe wird in jedem Zustand freigehalten (`reserviert`), sonst springt das
    /// Brett um die Differenz, sobald die Frage erscheint.
    private var frageStapel: some View {
        VStack(spacing: Design.Abstand.s) {
            Text("Mine getroffen. Weiterspielen?").font(.headline).multilineTextAlignment(.center)
                .accessibilityAddTraits(.isStaticText)
            Button { modell.zweiteChanceNehmen() } label: { Text("Weiterspielen (+30 s)") }.hauptKnopf()
            Button { modell.minenZeigen() } label: { Text("Aufhören") }.tischNebenKnopf()
        }
    }

    /// Inhalt der Leiste über einer unsichtbaren Kopie der Frage: gleiche Höhe in allen Zuständen.
    private func reserviert<V: View>(@ViewBuilder _ inhalt: () -> V) -> some View {
        ZStack {
            frageStapel.hidden().accessibilityHidden(true)
            inhalt()
        }
    }

    @ViewBuilder
    private var unten: some View {
        if modell.spiel?.istZuende != true {
            BottomBar {
                reserviert {
                    if art == .tinte { tischKnoepfe } else {
                    AktionsLeiste(eintraege: [
                        AktionsEintrag(symbol: "flag.fill", titel: "Fahne", aktiv: modell.flaggenModus) { modell.flaggenModus.toggle() },
                        AktionsEintrag(symbol: "lightbulb.fill", titel: "Hinweis", gesperrt: modell.spiel?.status != .laeuft) { modell.hinweis() },
                    ])
                    }
                }
            }
        } else if modell.spiel?.status == .verloren {
            // Mine getroffen: Das Brett bleibt stehen. Zuerst nur die Frage, ob es weitergeht (30 s Strafe); die übrigen Minen sind noch verdeckt.
            // Erst bei „Aufhören“ (oder ohne zweite Chance) zeigt das Brett alle Minen; dann führt „Zum Ergebnis“ zum Ende-Bildschirm.
            BottomBar {
                reserviert {
                    if modell.zweiteChanceMoeglich {
                        frageStapel
                    } else {
                        Button { weiter() } label: { Text("Zum Ergebnis") }.hauptKnopf()
                    }
                }
            }
        }
    }
}


/// Runder Tisch-Knopf wie `TischKnopfStil`; ist die Fahne an, liegt er als helle Fläche mit dunkler Schrift auf dem Filz.
private struct FahnenKnopfStil: ButtonStyle {
    let an: Bool
    func makeBody(configuration: Configuration) -> some View {
        if an {
            configuration.label
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Tisch.auge)
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .frame(minHeight: Theme.tapSize)
                .background(Capsule().fill(Tisch.elfenbein.opacity(configuration.isPressed ? 0.8 : 1)))
                .contentShape(.capsule)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        } else {
            TischKnopfStil().makeBody(configuration: configuration)
        }
    }
}
