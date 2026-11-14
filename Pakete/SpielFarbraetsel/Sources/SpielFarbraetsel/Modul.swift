// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Farbrätsel im `SpielRahmen`: Start, Spielregeln, Statistik, Neues-Spiel-Blatt, Fortsetzen und Ende kommen vom Rahmen.
/// Hier liegen nur Brett, Stufen, Tagesrätsel, Bestwerte und die Markierung richtiger Kacheln.
@MainActor
public struct FarbraetselModul: SpielModul {
    public init() {}
    public let id = "farbraetsel"
    public let name = "Farbrätsel"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.limette
    public let symbol = "paintpalette.fill"
    public let spielerzahl = 1...1
    public let stufenNamen = ["Leicht", "Mittel", "Schwer"]
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Bring die Farben in Ordnung.", farbe: farbe, spieler: 1...1,
                        regeln: "Die Kacheln bilden einen sanften Farbverlauf zwischen den vier Ecken. Jemand hat sie durcheinandergebracht. Stelle den Verlauf wieder her. Tippe eine Kachel an und dann eine zweite. Beide tauschen die Plätze. Kacheln mit weißem Punkt sind fest. Je weniger Züge, desto besser. Der Tipp bringt eine Kachel an ihren Platz und zählt als Zug; mit Tipp gelöste Rätsel zählen aber nicht für den Bestwert. Jeden Tag gibt es ein Rätsel für alle. Löse es an mehreren Tagen hintereinander für eine Serie.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                FarbraetselNeuSpiel(name: teilnehmer.first?.name ?? "", ende: ende, abbrechen: abbrechen)
            }
            .mitZiel("Tausche die Kacheln, bis sie wieder den sanften Farbverlauf bilden, mit möglichst wenigen Zügen.")
            .mitAnleitung(Array(FarbraetselAnleitung.schritte.dropFirst()))
            .mitStartOptionen { _ in FarbraetselOptionen() }
        )
    }
}

enum FarbraetselWahl {
    /// 0 bis 2 = Stufe (leicht, mittel, schwer), 3 = Tagesrätsel
    static let schluessel = "farbraetsel.wahl"
}

/// Karten im Neues-Spiel-Blatt: Stufe oder Tagesrätsel und die Markierung richtiger Kacheln.
struct FarbraetselOptionen: View {
    @AppStorage(FarbraetselWahl.schluessel) private var wahl = 1
    @AppStorage("richtigeMarkieren") private var richtigeMarkieren = true
    @State private var statistik = Ablage.standard.laden().statistik

    var body: some View {
        let erledigt = statistik.tage.contains(Tageskennung.text(.now))
        let serie = statistik.serie(heute: .now)
        VStack(spacing: Theme.kartenAbstand) {
            VStack(alignment: .leading, spacing: 6) {
                KartenKopf("Tagesrätsel", zusatz: erledigt ? nil : (wahl == 3 ? "✓" : nil))
                Text(verbatim: erledigt ? String(localized: "Heute geschafft · Serie \(serie)") : String(localized: "Heute noch offen · Serie \(serie)"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .card()
            .opacity(erledigt ? 0.55 : 1)
            .kartenAktion { if !erledigt { wahl = 3 } }

            ForEach(Array(Stufe.allCases.enumerated()), id: \.offset) { i, stufe in
                let werte = statistik.werte(stufe)
                VStack(alignment: .leading, spacing: Design.Abstand.s) {
                    KartenKopf(LocalizedStringKey(String(localized: stufe.name)), zusatz: (wahl == i ? "✓ " : "") + "\(stufe.spalten) × \(stufe.zeilen)")
                    Text(stufe.beschreibung).font(.subheadline).foregroundStyle(.secondary)
                    if let best = werte.bestZuege {
                        Text("Bestwert: \(best) Züge · \(werte.geloest)× gelöst")
                            .font(.system(.footnote, design: Design.zahlDesign).weight(.semibold))
                            .foregroundStyle(Color.accentText)
                    }
                }
                .card()
                .kartenAktion { wahl = i }
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Richtige Kacheln markieren", isOn: $richtigeMarkieren)
                Text("Ein kleiner Punkt zeigt, welche Kachel schon an ihrem Platz liegt.").font(.footnote).foregroundStyle(.secondary)
            }
            .card()
        }
        .onAppear {
            statistik = Ablage.standard.laden().statistik
            if wahl == 3, statistik.tage.contains(Tageskennung.text(.now)) { wahl = 1 }
        }
    }
}

/// Die laufende Partie im Rahmen: baut je nach Wahl ein neues Rätsel (oder setzt den gespeicherten Stand fort) und meldet das Ende.
struct FarbraetselNeuSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var store = GameStore()
    @State private var gestartet = false
    @State private var gemeldet = false
    @AppStorage(FarbraetselWahl.schluessel) private var wahl = 1

    var body: some View {
        SpielView(abbrechen: abbrechen)
            .environment(store)
            .onAppear(perform: starten)
            .onDisappear { store.uhrAnhalten(); store.speichern() }
            .onChange(of: store.ergebnis) { _, _ in melden() }
            .modifier(SzeneWeitergabe(store: store))
    }

    /// Fortsetzen (Stand liegt schon im Store), Tagesrätsel oder neues Rätsel der gewählten Stufe.
    private func starten() {
        guard !gestartet else { return }
        gestartet = true
        if store.partie != nil { store.uhrStarten(); return }
        if wahl == 3, !store.tagesraetselErledigt { store.neuesTagesraetsel(); return }
        store.neu(stufe: Stufe.allCases[min(max(wahl == 3 ? 1 : wahl, 0), Stufe.allCases.count - 1)])
    }

    private func melden() {
        guard let e = store.ergebnis, !gemeldet else { return }
        gemeldet = true
        let teile: [String] = [
            "\(e.zuege) \(String(localized: "Züge")) · \(Zeitformat.text(e.sekunden))",
            e.neuerBestwert ? String(localized: "Neuer Bestwert auf „\(String(localized: e.stufe.name))“") : nil,
            e.tagesraetsel ? String(localized: "Tagesrätsel erledigt. Morgen gibt es ein neues.") : nil,
        ].compactMap { $0 }
        var ausgang = SpielEnde(reihenfolge: [name], info: teile.joined(separator: " "), einzel: .gewonnen)
        ausgang.dauer = e.sekunden
        // Statistik je Stufe im Kern; das Tagesrätsel zählt eigens
        if e.tagesraetsel { ausgang.kennzahlen["tages"] = 1 }
        else if let i = Stufe.allCases.firstIndex(of: e.stufe) { ausgang.kennzahlen["stufe"] = Double(i) }
        store.ergebnisSchliessen()
        ende(ausgang)
    }
}

/// Hält die Uhr beim Wechsel in den Hintergrund an (und speichert), beim Zurückkommen läuft sie weiter.
private struct SzeneWeitergabe: ViewModifier {
    let store: GameStore
    @Environment(\.scenePhase) private var phase
    func body(content: Content) -> some View {
        content.onChange(of: phase) { _, neu in store.szenePhase(aktiv: neu == .active) }
    }
}
#endif
