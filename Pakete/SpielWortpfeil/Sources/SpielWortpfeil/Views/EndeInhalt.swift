// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Kreuzworträtsel-eigener Inhalt im Ende-Bildschirm des Rahmens (`mitEndeInhalt`): Kennzahlen, Lösungswort, kleines Gitter,
/// neue Erfolge, Stufenvorschlag und Teilen. Überschrift und Knöpfe kommen vom Rahmen.
struct WortpfeilEndeInhalt: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Startet die nächste Partie im Rahmen (wie der Hauptknopf)
    let nochmal: () -> Void
    @State private var revealed = 0
    @State private var medal: String?

    var body: some View {
        if let result = store.letztes?.ergebnis, let g = store.letztes?.spiel {
            VStack(spacing: 14) {
                Text(verbatim: info(result)).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                solutionTiles(g)
                MiniGrid(puzzle: g.puzzle, entries: g.entries).frame(width: 64, height: 64)
                if let s = result.suggestion { suggestionCard(s, nach: result.level) }
                if TeilenFreigabe.erlaubt() { ShareLink(item: ShareText.make(time: result.time, hints: result.hints, streak: result.streak,
                                               isDaily: result.isDaily, date: store.currentDate)) { Text("Teilen") }
                    .zweitKnopf() }
            }
            .overlay(alignment: .top) { medalBanner.offset(y: -58) }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .task(id: result.newAchievements) { await showMedals(result.newAchievements) }
        }
    }

    /// Kennzahlen unter der Überschrift
    private func info(_ r: WinResult) -> String {
        var z: [String] = []
        if r.isNewBest { z.append(String(localized: "Neue Bestzeit")) }
        z.append(r.hints == 0 ? String(localized: "ohne Hilfe") : String(localized: "\(r.hints) Hilfen"))
        z.append(String(localized: "Bestzeit \(store.stats[r.level].bestTime.map { Zeitformat.text($0) } ?? "–")"))
        var text = z.joined(separator: " · ")
        if r.isDaily { text += "\n" + String(localized: "Serie \(r.streak) Tage") }
        if r.levelCompleted { text += "\n" + String(localized: "Alle \(store.totalCount(r.level)) \(levelAdjective(r.level)) Rätsel gelöst!") }
        return text
    }

    /// Neu erreichte Erfolge: eine kleine Medaille gleitet von oben in die Karte, bei mehreren nacheinander
    @ViewBuilder private var medalBanner: some View {
        if let id = medal, let a = Achievements.find(id) {
            HStack(spacing: 10) {
                MedalView(symbol: a.symbol, reached: true, size: 36)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Neuer Erfolg").font(.caption2).foregroundStyle(.secondary)
                    Text(a.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.tinte)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .glasFlaeche(.capsule)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Neuer Erfolg: \(a.name)")
        }
    }

    private func showMedals(_ ids: [String]) async {
        guard !ids.isEmpty else { return }
        try? await Task.sleep(for: .milliseconds(900))        // nach der Gewonnen-Welle
        for id in ids {
            withAnimation(.smooth(duration: 0.35)) { medal = id }
            SpielHaptik.success()
            try? await Task.sleep(for: .milliseconds(2200))
            withAnimation(.smooth(duration: 0.3)) { medal = nil }
            try? await Task.sleep(for: .milliseconds(400))
        }
    }

    /// Lernkurve: ruhiges Angebot, nur ein Vorschlag
    private func suggestionCard(_ level: Level, nach gespielt: Level) -> some View {
        let harder = (Level.allCases.firstIndex(of: level) ?? 0) > (Level.allCases.firstIndex(of: gespielt) ?? 0)
        let name = String(localized: levelName(level))
        return VStack(spacing: Design.Abstand.s) {
            Text(harder ? "Drei ohne Hilfe – Lust auf \(name)?" : "\(name) ist auch schön – mal probieren?")
                .font(.subheadline.weight(.medium)).foregroundStyle(Color.tinte).multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button("Später") { store.dismissSuggestion() }
                    .buttonStyle(.plain).foregroundStyle(Color.kwAkzent).frame(minWidth: 80, minHeight: 44)
                Button("Probieren") { store.vorgemerkt = .stufe(level); nochmal() }
                    .buttonStyle(AkzentPilleStil(gefuellt: true)).frame(width: 140)
            }
        }
        .padding(12).frame(maxWidth: .infinity)
        .background(Color.feldFrage.opacity(0.6), in: .rect(cornerRadius: 16))
    }

    /// Das Lösungswort groß in goldenen Kacheln (nur wenn das Rätsel eins hat)
    @ViewBuilder private func solutionTiles(_ g: Game) -> some View {
        if !g.puzzle.solutionCells.isEmpty {
            let letters = Array(g.puzzle.solutionWordText)
            VStack(spacing: 6) {
                SectionLabel("Lösungswort")
                HStack(spacing: Design.Abstand.xs) {
                    ForEach(Array(letters.enumerated()), id: \.offset) { i, ch in
                        Text(String(ch))
                            .font(.system(.title2, design: Design.zahlDesign, weight: .bold))
                            .foregroundStyle(Color.kwAufAkzent)
                            .frame(maxWidth: 42, minHeight: 46)
                            .background(Color.kwAkzent, in: .rect(cornerRadius: Design.Ecke.klein))
                            // Buchstaben drehen sich nacheinander ein (bei „Bewegung reduzieren“ nur Überblenden)
                            .rotation3DEffect(.degrees(i < revealed || reduceMotion ? 0 : 90), axis: (x: 1, y: 0, z: 0))
                            .opacity(i < revealed ? 1 : 0)
                            .overlay(alignment: .topLeading) {
                                Text("\(i + 1)").font(.system(size: 9, weight: .semibold, design: Design.zahlDesign))  // design:spielinhalt
                                    .foregroundStyle(Color.kwAufAkzent.opacity(0.8)).padding(.leading, 4).padding(.top, 2)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Lösungswort: \(String(letters))")
            .task {
                for i in 1...max(1, letters.count) {
                    try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 120))
                    withAnimation(.snappy(duration: 0.25)) { revealed = i }
                }
            }
        }
    }

}
#endif
