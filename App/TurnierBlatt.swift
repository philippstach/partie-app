// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import Charts
import KlarGlas
import SpieleKern

/// Spieleabend-Turnier (B1): Spieler und Spiele wählen, nacheinander spielen, Gesamtwertung am Ende teilen.
struct TurnierBlatt: View {
    let oeffnen: (String) -> Void
    @Environment(TurnierDienst.self) private var dienst
    @Environment(SpielerVerzeichnis.self) private var verzeichnis
    @Environment(\.dismiss) private var dismiss
    @State private var gewaehlt: Set<UUID> = []
    @State private var spiele: [String] = []
    @State private var spielWahl = false
    @State private var spielerOffen = false   // Fund 24: Direktweg zu „Spieler“
    @State private var abbruchFrage = false
    @State private var art: Turnier.Art = .abend
    @State private var modus: DuellModus = .zufall
    @State private var anzahl = 10

    enum DuellModus: String, CaseIterable, Identifiable {
        case zufall, auswahlZufall, auswahlReihenfolge
        var id: String { rawValue }
        var titel: LocalizedStringKey {
            switch self { case .zufall: "Zufällige Spiele, zufällige Reihenfolge"; case .auswahlZufall: "Eigene Spiele, zufällige Reihenfolge"; case .auswahlReihenfolge: "Eigene Spiele, eigene Reihenfolge" }
        }
    }

    /// Spiele, die sich zu zweit gegeneinander spielen lassen (ohne Rätsel).
    private var duellVorrat: [String] { SpielKatalog.sichtbar.filter { $0.spielerzahl.contains(2) && $0.gattung != .raetsel }.map(\.id) }
    private var eigeneWahl: Bool { art == .abend || modus != .zufall }
    private var startBereit: Bool {
        art == .abend ? (gewaehlt.count >= 2 && !spiele.isEmpty)
                      : (gewaehlt.count == 2 && (modus == .zufall || (3...15).contains(spiele.count)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    if let t = dienst.aktuell { laufend(t) } else { einrichten }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle(dienst.aktuell?.art == .duell ? "Duell" : "Spieleabend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { SchliessenKnopf() } }
        }
        .sheet(isPresented: $spielerOffen) { SpielerSeite().formSheet().designWurzel() }
        .sheet(isPresented: $spielWahl) {
            KachelWahlBlatt(schon: Set(spiele), nurMehrspieler: true, dabeiText: "Im Spieleabend") { id in spiele.append(id) }.formSheet()
        }
    }

    // MARK: Einrichten

    private var einrichten: some View {
        VStack(spacing: Theme.kartenAbstand) {
            Picker("Art", selection: $art) { Text("Spieleabend").tag(Turnier.Art.abend); Text("Duell").tag(Turnier.Art.duell) }
                .pickerStyle(.segmented)
            Text(art == .abend
                 ? "Mehrere Spiele nacheinander, eine Gesamtwertung. Platz 1 bekommt so viele Punkte wie Mitspieler, der Letzte einen."
                 : "Zwei Personen, bis zu 15 Spiele. Das erste Spiel bringt einen Punkt, das zweite zwei, das dritte drei und so weiter. Wer nicht mehr einzuholen ist, hat gewonnen.")
                .font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf("Wer spielt mit?", zusatz: art == .duell ? String(localized: "genau zwei") : String(localized: "mindestens zwei"))
                if verzeichnis.menschen.count < 2 {
                    Text("Lege zuerst zwei Personen unter „Spieler“ an.").font(.subheadline).foregroundStyle(.secondary)
                    Button("Spieler anlegen", systemImage: "person.badge.plus") { spielerOffen = true }   // Fund 24
                }
                ForEach(verzeichnis.menschen) { s in
                    Toggle(isOn: Binding(get: { gewaehlt.contains(s.id) }, set: { if $0 { gewaehlt.insert(s.id) } else { gewaehlt.remove(s.id) } })) {
                        HStack(spacing: 10) { SpielerBildKreis(s, groesse: 32); Text(verbatim: s.name) }
                    }
                }
            }.card()
            if art == .duell {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Spiele und Reihenfolge", selection: $modus) { ForEach(DuellModus.allCases) { Text($0.titel).fixedSize(horizontal: false, vertical: true).tag($0) } }
                        .pickerStyle(.menu)
                    if modus == .zufall { Stepper(value: $anzahl, in: 5...15) { Text("Anzahl der Spiele: \(anzahl)") } }
                }.card()
            }
            if eigeneWahl {
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf("Welche Spiele?", zusatz: art == .duell && modus == .auswahlZufall ? String(localized: "Reihenfolge wird gelost") : String(localized: "in dieser Reihenfolge"))
                ForEach(Array(spiele.enumerated()), id: \.offset) { i, id in
                    HStack {
                        Text("\(i + 1).").foregroundStyle(.secondary).monospacedDigit()
                        Text(verbatim: SpielKatalog.modul(id)?.name ?? id)
                        Spacer()
                        if !(art == .duell && modus == .auswahlZufall), i > 0 {
                            Button { spiele.swapAt(i, i - 1) } label: { Image(systemName: "arrow.up") }
                                .frame(minWidth: 44, minHeight: 44).accessibilityLabel(Text("Nach oben"))
                        }
                        Button { spiele.remove(at: i) } label: { Image(systemName: "minus.circle") }
                            .frame(minWidth: 44, minHeight: 44).accessibilityLabel(Text("Entfernen"))
                    }
                }
                Button { spielWahl = true } label: { Label("Spiel hinzufügen", systemImage: "plus") }.frame(minHeight: 44)
            }.card()
            }
            Button(art == .duell ? "Duell starten" : "Spieleabend starten") {
                let namen = verzeichnis.menschen.filter { gewaehlt.contains($0.id) }.map(\.name)
                var liste = spiele
                if art == .duell {
                    switch modus {
                    case .zufall: liste = Turnier.zufallsSpiele(aus: duellVorrat, anzahl: anzahl)
                    case .auswahlZufall: liste = spiele.shuffled()
                    case .auswahlReihenfolge: break
                    }
                }
                dienst.starten(Turnier(spieler: namen, spiele: liste, art: art))
                vorbereiten()
            }
            .buttonStyle(HauptKnopfStil()).disabled(!startBereit)
        }
    }

    // MARK: Laufend und Ende

    private func laufend(_ t: Turnier) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            if t.art == .duell { duellZaehler(t) }
            if t.fertig, let sieger = t.rangliste.first {
                VStack(spacing: 6) {
                    Image(systemName: "trophy.fill").font(.largeTitle).accessibilityHidden(true)
                    // T-3: Gleichstand an der Spitze (0:0, beide Platz 1) hat keinen Sieger, wie bei Mau-Mau und Elfer raus
                    let spitze = t.rangliste.filter { $0.punkte == sieger.punkte }
                    if spitze.count > 1 {
                        Text("Unentschieden").font(.largeTitle.bold())
                        Text(verbatim: spitze.map(\.name).joined(separator: ", ")).foregroundStyle(.secondary)
                    } else {
                        Text(verbatim: sieger.name).font(.largeTitle.bold())
                        Text(t.art == .duell ? "gewinnt das Duell" : "gewinnt den Spieleabend").foregroundStyle(.secondary)
                    }
                }.frame(maxWidth: .infinity).card()
            } else {
                if t.art == .abend {
                    Text("Runde \(t.gespielteRunden + 1) von \(t.runden.count)").font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if t.art == .duell { duellDiagramme(t) }
            if t.art == .abend {
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf("Gesamtwertung", zusatz: String(localized: "Punkte"))
                ForEach(t.rangliste) { s in
                    HStack {
                        Text("\(s.platz).").monospacedDigit().foregroundStyle(.secondary).frame(minWidth: 28, alignment: .leading)
                        Text(verbatim: s.name).font(.headline)
                        Spacer()
                        Text("\(s.punkte)").font(.system(.title3, design: Design.zahlDesign).bold().monospacedDigit())
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Platz \(s.platz): \(s.name), \(s.punkte) Punkte"))
                }
            }.card()
            }
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf("Spiele", zusatz: String(localized: "\(t.gespielteRunden) von \(t.runden.count) gespielt"))
                ForEach(Array(t.runden.enumerated()), id: \.element.id) { i, r in
                    HStack {
                        Image(systemName: r.gespielt ? "checkmark.circle.fill" : "circle").foregroundStyle(r.gespielt ? Color.accentText : .secondary).accessibilityHidden(true)
                        Text(verbatim: SpielKatalog.modul(r.spiel)?.name ?? r.spiel)
                        if t.art == .duell { Text("+\(Turnier.duellGewicht(i))").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
                        Spacer()
                        if let p = r.plaetze, let sieger = p.filter({ $0.value == 1 }).keys.sorted().first {
                            Text(verbatim: sieger).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }.card()
            if t.fertig {
                Button("Ergebnis teilen") { ErgebnisTeilen.zeigen(Self.text(t)) }.buttonStyle(HauptKnopfStil())
                Button(t.art == .duell ? "Neues Duell einrichten" : "Neuen Spieleabend einrichten") { dienst.beenden() }.frame(minHeight: 44)
            } else if let n = t.naechsteRunde, let m = SpielKatalog.modul(n.spiel) {
                Button { vorbereiten(); dismiss(); oeffnen(m.id) } label: { Text("Weiter mit \(m.name)") }.buttonStyle(HauptKnopfStil())
                Button("Diese Runde überspringen") { dienst.ueberspringen() }.frame(minHeight: 44)
                Button(t.art == .duell ? "Duell abbrechen" : "Spieleabend abbrechen", role: .destructive) { abbruchFrage = true }.frame(minHeight: 44)
                    .confirmationDialog(t.art == .duell ? "Duell wirklich abbrechen?" : "Spieleabend wirklich abbrechen?", isPresented: $abbruchFrage, titleVisibility: .visible) {
                        Button(t.art == .duell ? "Duell abbrechen" : "Spieleabend abbrechen", role: .destructive) { dienst.beenden() }
                        Button("Weiterspielen", role: .cancel) {}
                    } message: { Text("Die bisherige Wertung geht verloren.") }
            }
        }
    }

    // MARK: Duell

    /// Zähler zwischen den Spielen: Stand groß, darunter wie viele Punkte noch zu holen sind.
    private func duellZaehler(_ t: Turnier) -> some View {
        let r = t.rangliste
        let a = r.first { $0.name == t.spieler[0] }?.punkte ?? 0, b = r.first { $0.name == t.spieler[1] }?.punkte ?? 0
        return VStack(spacing: 8) {
            HStack {
                VStack { Text("\(a)").font(.system(.largeTitle, design: Design.zahlDesign).bold().monospacedDigit()).minimumScaleFactor(0.5); Text(verbatim: t.spieler[0]).font(.caption).lineLimit(1) }.frame(maxWidth: .infinity)
                Text(verbatim: ":").font(.title2).foregroundStyle(.secondary)
                VStack { Text("\(b)").font(.system(.largeTitle, design: Design.zahlDesign).bold().monospacedDigit()).minimumScaleFactor(0.5); Text(verbatim: t.spieler[1]).font(.caption).lineLimit(1) }.frame(maxWidth: .infinity)
            }
            if t.fertig && t.naechsteRunde != nil {
                Text("Vorzeitig entschieden: Der Vorsprung ist nicht mehr einzuholen.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            } else if let n = t.naechsteRunde {
                Text("Noch \(t.restPunkte) Punkte zu holen · nächstes Spiel zählt \(Turnier.duellGewicht(t.runden.firstIndex { !$0.gespielt } ?? 0))").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .accessibilityLabel(Text("Stand \(a) zu \(b), noch \(t.restPunkte) Punkte zu holen, nächstes Spiel \(SpielKatalog.modul(n.spiel)?.name ?? n.spiel)"))
            }
        }
        .frame(maxWidth: .infinity).card()
        .accessibilityElement(children: .combine)
    }

    /// Verlauf (Linien) und Punkteanteile (Torte).
    @ViewBuilder private func duellDiagramme(_ t: Turnier) -> some View {
        if t.gespielteRunden > 0 {
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf("Verlauf", zusatz: String(localized: "Punkte nach jedem Spiel"))
                Chart(t.verlauf) { v in
                    LineMark(x: .value("Spiel", v.runde), y: .value("Punkte", v.punkte)).foregroundStyle(by: .value("Person", v.name))
                    PointMark(x: .value("Spiel", v.runde), y: .value("Punkte", v.punkte)).foregroundStyle(by: .value("Person", v.name))
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) }
                .frame(height: 180)
                .accessibilityLabel(Text("Verlauf")).accessibilityValue(Text(t.rangliste.map { "\($0.name) \($0.punkte)" }.joined(separator: ", ")))
            }.card()
            let gesamt = max(1, t.rangliste.reduce(0) { $0 + $1.punkte })
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf("Punkteanteile", zusatz: String(localized: "von \(t.gesamtPunkte) möglichen"))
                Chart {
                    ForEach(t.rangliste) { s in SectorMark(angle: .value("Punkte", s.punkte), innerRadius: .ratio(0.55)).foregroundStyle(by: .value("Person", s.name)) }
                    SectorMark(angle: .value("Punkte", max(0, t.gesamtPunkte - gesamt + (gesamt == 1 && t.rangliste.allSatisfy { $0.punkte == 0 } ? 1 : 0))), innerRadius: .ratio(0.55)).foregroundStyle(.gray.opacity(0.25))
                }
                .frame(height: 180)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Punkteanteile")).accessibilityValue(Text(t.rangliste.map { "\($0.name) \($0.punkte)" }.joined(separator: ", ")))
            }.card()
        }
    }

    /// Trägt die Turnierspieler als „Letzte Runde“ des nächsten Spiels ein, damit der Start mit einem Tipp geht.
    private func vorbereiten() {
        guard let t = dienst.aktuell, let n = t.naechsteRunde else { return }
        LetzteRunde(plaetze: t.spieler.map { .init(name: $0, computer: false) }).speichern(n.spiel)
        // C-011: Ein alter Spielstand dieses Spiels passt nicht zu den Turnierspielern („Partie fortsetzen“ würde ihn mit falschen Namen laden)
        SpielStand.loeschen(n.spiel)
    }

    static func text(_ t: Turnier) -> String {
        let kopf = String(localized: "Spieleabend in Partie")
        let zeilen = t.rangliste.map { "\($0.platz). \($0.name) – \($0.punkte)" }
        let spiele = t.runden.compactMap { SpielKatalog.modul($0.spiel)?.name }.joined(separator: ", ")
        return ([kopf] + zeilen + [spiele]).joined(separator: "\n")
    }
}

/// Karte auf der Startseite, solange ein Spieleabend läuft.
struct TurnierKarte: View {
    let turnier: Turnier
    let aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            HStack {
                Image(systemName: "trophy").accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(turnier.art == .duell ? "Duell läuft" : "Spieleabend läuft").font(.headline)
                    Text(turnier.fertig ? "Fertig – Ergebnis ansehen" : "Runde \(turnier.gespielteRunden + 1) von \(turnier.runden.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary).accessibilityHidden(true)
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain).card()
    }
}

/// Karte auf der Startseite, wenn kein Spieleabend läuft: macht den Einstieg sichtbar (Build 10).
struct SpieleabendStartKarte: View {
    let aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            HStack {
                Image(systemName: "trophy").accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spieleabend starten").font(.headline)
                    Text("Mehrere Spiele, ein Sieger").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary).accessibilityHidden(true)
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain).card()
    }
}
