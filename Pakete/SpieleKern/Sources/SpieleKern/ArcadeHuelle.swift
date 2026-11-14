// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import ArcadeKern

/// Gemeinsame Hülle aller Arcade-Spiele (ARCADE-KONZEPT.md): Kopf mit Punkten, Pause, „Tippe zum Starten“, „Aus“-Anzeige
/// und der feste Takt. Das Spiel liefert nur Zustand (`phase`, `punkte`), seinen Schritt und die Zeichnung.
/// Ablauf: bereit → (Tipp) → läuft ⇄ Pause → vorbei → kurze „Aus“-Anzeige → `beenden` (Ergebnisbildschirm des Rahmens).
public struct ArcadeHuelle<Feld: View, Unten: View>: View {
    let punkte: Int
    let status: String?
    let kopf: String?
    let rekord: Int?
    let phase: ArcadePhase
    /// Duelle (Ballwechsel): gewonnen (`true`) oder verloren (`false`) am Ende; `nil` bei Punktespielen (dann entscheidet der Rekord).
    let endeGewonnen: Bool?
    let bereitText: LocalizedStringKey
    let hinweis: LocalizedStringKey?
    /// Für VoiceOver: Stand in ganzen Worten (Punkte, Leben); sonst wird der Kopftext vorgelesen.
    let ansage: String?
    /// Zähler der verlorenen Leben/Punkte gegen den Spieler (steigt bei jedem Verlust): löst die Verlust-Rückmeldung aus.
    let verloren: Int?
    let schritt: (Double) -> Void
    let beginnen: () -> Void
    let neu: () -> Void
    let abbrechen: () -> Void
    let beenden: () -> Void
    let feld: Feld
    let unten: Unten

    @State private var pause = ArcadePause()
    @State private var rueckmeldung = ArcadeRueckmeldung()
    @State private var gemeldet = false
    @Environment(\.scenePhase) private var szene
    @Environment(\.regelnOeffnen) private var regelnOeffnen

    public init(punkte: Int, status: String? = nil, kopf: String? = nil, rekord: Int? = nil, ansage: String? = nil, verloren: Int? = nil, phase: ArcadePhase,
                bereitText: LocalizedStringKey = "Tippe zum Starten", hinweis: LocalizedStringKey? = nil,
                schritt: @escaping (Double) -> Void, beginnen: @escaping () -> Void, neu: @escaping () -> Void,
                abbrechen: @escaping () -> Void, beenden: @escaping () -> Void, endeGewonnen: Bool? = nil,
                @ViewBuilder feld: () -> Feld, @ViewBuilder unten: () -> Unten) {
        self.punkte = punkte; self.status = status; self.kopf = kopf; self.rekord = rekord; self.ansage = ansage; self.verloren = verloren; self.phase = phase; self.endeGewonnen = endeGewonnen
        self.bereitText = bereitText; self.hinweis = hinweis; self.schritt = schritt; self.beginnen = beginnen
        self.neu = neu; self.abbrechen = abbrechen; self.beenden = beenden; self.feld = feld(); self.unten = unten()
    }

    public var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: kopfText, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if phase.laeuft { Button(pause.pausiert ? "Weiter" : "Pause", systemImage: pause.pausiert ? "play" : "pause") { pause.umschalten(phase: phase) } }
                    if let regelnOeffnen { Button("Regeln", systemImage: "book") { pause.verlassen(phase: phase); regelnOeffnen() } }   // Anleitung jederzeit, das Spiel pausiert dabei
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { pause.zuruecksetzen(); gemeldet = false; neu() }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            .environment(\.regelnKnopf, false)   // Regeln stehen schon im Menü
            feld
                .overlay { overlay }
                .padding(.horizontal, Theme.seitenRand)
                .accessibilityElement(children: .ignore)   // G1: Spielfeld als ein Element, Stand aus dem Kopf
                .accessibilityLabel(Text("Spielfeld"))
                .accessibilityValue(Text(verbatim: pause.pausiert ? String(localized: "Pause") : (phase.istVorbei ? String(localized: "Aus") : (ansage ?? kopfText))))
                .accessibilityHint(Text(pause.pausiert ? "Doppeltippen zum Weiterspielen." : ""))
            unten
                .allowsHitTesting(pause.nimmtEingabe)       // keine Knopfdrücke während der Pause
            if let hinweis { Text(hinweis).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, Theme.seitenRand) }
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)          // Menü und Kopf wachsen mit, aber nicht über das Spielfeld hinaus
        .weicheAnimation(bei: phase)                           // Ein-/Ausblenden der Anzeigen; respektiert „Bewegung reduzieren“
        .weicheAnimation(bei: pause.pausiert)
        .arcadeTakt(aktiv: pause.uhrLaeuft(phase: phase)) { dt in schritt(dt) }
        .onChange(of: szene) { _, s in pause.szene(aktiv: s == .active, phase: phase) }
        .onDisappear { pause.verlassen(phase: phase) }
        .onAppear { pause.verlassen(phase: phase) }   // fortgesetzte Partie beginnt in der Pause
        .onChange(of: punkte) { alt, neu in if neu > alt { sende(.treffer) } }
        .onChange(of: kopf) { alt, neu in if verloren == nil, alt != nil, neu != nil, phase.laeuft { sende(.treffer) } }
        .onChange(of: verloren) { alt, neu in if let alt, let neu, neu > alt, phase.laeuft { sende(.lebenVerloren) } }
        .onChange(of: phase) { _, p in
            if p.istVorbei {
                let ereignis: ArcadeEreignis = endeGewonnen.map { $0 ? .rekord : .verlust } ?? ArcadeRueckmeldung.endeEreignis(punkte: punkte, bisherigerRekord: rekord)
                sende(ereignis)
                // VoiceOver: das Ende ansagen (die Anzeige „Aus!“ verschwindet nach 1,3 s)
                var ansage = endeGewonnen != nil ? (ereignis == .rekord ? String(localized: "Gewonnen!") : String(localized: "Verloren"))
                    : (ereignis == .rekord ? String(localized: "Neuer Rekord!") : String(localized: "Aus!"))
                if endeGewonnen == nil, ereignis == .verlust, case .vorbei(let grund) = p { ansage += " " + String(localized: String.LocalizationValue(grund)) }
                AccessibilityNotification.Announcement(ansage).post()
            }
            if p.istVorbei, !gemeldet {
                gemeldet = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.3))
                    if gemeldet { beenden() }
                }
            }
        }
    }

    private func sende(_ e: ArcadeEreignis) {
        let jetzt = ProcessInfo.processInfo.systemUptime
        if let a = rueckmeldung.melden(e, zeit: jetzt, haptikAn: SpieleHaptik.erlaubt, tonAn: SpieleTon.erlaubt, pausiert: pause.pausiert) {
            ArcadeFeedback.abspielen(a)
        }
    }

    private var kopfText: String {
        if let kopf { return kopf }
        var t = "\(punkte)"
        if let status { t += " · \(status)" }
        return t
    }

    @ViewBuilder private var overlay: some View {
        if phase == .bereit {
            Button(action: beginnen) {
                VStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill").font(.title)
                    Text(bereitText).font(.headline)
                    if let rekord { Text("Rekord: \(rekord)").font(.footnote).foregroundStyle(.secondary) }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: Design.Ecke.karte, style: .continuous))
            }.buttonStyle(.plain)
        } else if pause.pausiert && phase.laeuft {
            Button { pause.weiter() } label: {
                VStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill").font(.largeTitle)
                    Text("Pause – tippen zum Weiterspielen").font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: Design.Ecke.karte, style: .continuous))
            }.buttonStyle(.plain)
        } else if case .vorbei(let grund) = phase {
            Button { if gemeldet { gemeldet = false; beenden() } } label: {
                VStack(spacing: 6) {
                    Text("Aus!").font(.largeTitle.bold())
                    Text(LocalizedStringKey(grund)).font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: Design.Ecke.karte, style: .continuous))
            }.buttonStyle(.plain).transition(.opacity)
        }
    }
}

public extension ArcadeHuelle where Unten == EmptyView {
    init(punkte: Int, status: String? = nil, kopf: String? = nil, rekord: Int? = nil, ansage: String? = nil, verloren: Int? = nil, phase: ArcadePhase,
         bereitText: LocalizedStringKey = "Tippe zum Starten", hinweis: LocalizedStringKey? = nil,
         schritt: @escaping (Double) -> Void, beginnen: @escaping () -> Void, neu: @escaping () -> Void,
         abbrechen: @escaping () -> Void, beenden: @escaping () -> Void, endeGewonnen: Bool? = nil, @ViewBuilder feld: () -> Feld) {
        self.init(punkte: punkte, status: status, kopf: kopf, rekord: rekord, ansage: ansage, verloren: verloren, phase: phase, bereitText: bereitText, hinweis: hinweis,
                  schritt: schritt, beginnen: beginnen, neu: neu, abbrechen: abbrechen, beenden: beenden, endeGewonnen: endeGewonnen, feld: feld, unten: { EmptyView() })
    }
}
#endif
