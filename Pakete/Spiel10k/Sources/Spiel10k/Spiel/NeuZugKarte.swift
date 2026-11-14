// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Karte des laufenden Zugs: wer dran ist, Zugpunkte groß, Gesamt, Rest bis zum Ziel und Nieten-Zähler.
struct NeuZugKarte: View {
    let game: GameState
    let zugPunkte: Int
    var kompakt = false
    @ScaledMetric(relativeTo: .largeTitle) private var zahl: CGFloat = 40

    var body: some View {
        let p = game.players[game.current]
        HStack(alignment: .center, spacing: 10) {
            // Tinte (Punkt 6): Name und Bild stehen schon in der runden Spielerleiste, hier nicht noch einmal
            if !NeuSpielerLeiste.tinte(game) { Text(p.avatar).font(.system(size: kompakt ? 26 : 32)) }   // design:spielinhalt
            VStack(alignment: .leading, spacing: 1) {
                if !NeuSpielerLeiste.tinte(game) {
                    Text(p.name)
                        .font(.system(kompakt ? .headline : .title3, design: Design.zahlDesign, weight: .heavy))
                        .foregroundStyle(p.textColor)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                Text(CurrentPlayerCard.gesamtText(score: p.score, goal: game.settings.goal))
                    .font(.caption).monospacedDigit().tischHinweis(zeilen: 1)
                    .lineLimit(1).minimumScaleFactor(0.7)
                zeile(p)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 0) {
                Text(Theme.points(zugPunkte))
                    .font(.system(size: kompakt ? zahl * 0.8 : zahl, weight: .heavy, design: Design.zahlDesign))   // design:spielinhalt
                    .monospacedDigit()
                    .foregroundStyle(.spielAkzent)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: zugPunkte)
                Text("in diesem Zug").font(.caption2).tischHinweis(zeilen: 1)
            }
            .fixedSize()
        }
        .padding(.horizontal, 12).padding(.vertical, kompakt ? 6 : 10)
        .frame(maxWidth: .infinity)
        .tischFlaeche(16)
        .overlay { if Design.ist(.klar) { RoundedRectangle(cornerRadius: 16).strokeBorder(p.color.opacity(0.35)) } }   // Tinte und Salon: keine runde Farbumrandung, die Fläche ist die Zeile mit Haarlinie
        .accessibilityElement(children: .ignore)   // F21-012: .combine ließ „A“, „Anna“, „0“ als Kinder im Baum; das Label trägt alles
        .accessibilityLabel(Text("\(p.name) ist dran, \(Theme.points(zugPunkte)) Punkte in diesem Zug, insgesamt \(Theme.points(p.score)) von \(Theme.points(game.settings.goal))"))
    }

    /// Nieten-Zähler (drei Punkte) und, solange nötig, die Einstiegshürde.
    @ViewBuilder
    private func zeile(_ p: Player) -> some View {
        HStack(spacing: 6) {
            if game.settings.penalty > 0, game.tiebreak == nil {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { d in
                        Circle().fill(d < p.streak ? Color.meldungRot : .clear)
                            .strokeBorder(d < p.streak ? Color.meldungRot : (Design.ist(.klar) ? Color.primary.opacity(0.25) : Color.linieStark))
                            .frame(width: 8, height: 8)
                    }
                }
                .accessibilityHidden(true)
                if game.penaltyThreatened(game.current) {
                    Text("Niete = −\(Theme.points(game.settings.penalty))").font(.caption2.weight(.bold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.meldungRot)
                } else {
                    Text(p.streak == 0 ? String(localized: "keine Nieten") : String(localized: "\(p.streak) in Folge")).font(.caption2).tischHinweis(zeilen: 1)
                }
            }
            if game.entryNeeded > 0 {
                Label("Einstieg ab \(Theme.points(game.entryNeeded))", systemImage: "door.left.hand.open")
                    .font(.caption2.weight(.semibold)).foregroundStyle(.spielAkzent)
                    .labelStyle(.titleAndIcon)
            }
        }
        .lineLimit(1)
        .frame(minHeight: 12)
    }
}

/// Karte „Frühere Runden“ unter dem Würfelfeld: je Runde alle Personen (der letzte Zug steht schon in der Spielerleiste).
struct NeuFruehereRunden: View {
    let game: GameState
    let anzahl: Int

    var body: some View {
        let runden = NeuLogik.fruehereRunden(game, anzahl: anzahl)
        if !runden.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text("Frühere Runden").font(.caption.weight(.semibold)).tischHinweis(zeilen: 1)
                Grid(alignment: .trailing, horizontalSpacing: 6, verticalSpacing: 2) {
                    GridRow {
                        Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)   // B18 N-011: kein unbeschrifteter Knopf für VoiceOver
                        ForEach(game.players.indices, id: \.self) { i in Text(game.players[i].avatar).font(.caption2) }
                    }
                    .accessibilityHidden(true)
                    ForEach(Array(runden.reversed().enumerated()), id: \.offset) { _, r in
                        GridRow {
                            Text(verbatim: "\(r.runde)").font(.caption2.weight(.bold)).foregroundStyle(Tisch.aktiv ? AnyShapeStyle(Tisch.hinweisLeise) : AnyShapeStyle(HierarchicalShapeStyle.tertiary)).gridColumnAlignment(.leading)
                            ForEach(Array(r.zellen.enumerated()), id: \.offset) { i, z in
                                zelle(z).foregroundStyle(farbe(z))
                                    .accessibilityLabel(Text("Runde \(r.runde), \(game.players[i].name): \(sprech(z))"))
                            }
                        }
                    }
                }
                .font(.caption.monospacedDigit())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tisch.aktiv ? Color.white.opacity(0.10) : Color.feldGrund, in: .rect(cornerRadius: Design.Ecke.feld))
        }
    }

    @ViewBuilder
    private func zelle(_ z: NeuZelle) -> some View {
        switch z {
        case .leer: Text(verbatim: "·")
        case .punkte(let n): Text(verbatim: Theme.points(n))
        case .niete: Text("Niete")
        case .strafe(let n): Text(verbatim: "−\(Theme.points(n))")
        }
    }

    private func farbe(_ z: NeuZelle) -> Color {
        switch z {
        case .leer: Tisch.aktiv ? Tisch.hinweisLeise : Color.secondary.opacity(0.5)
        case .punkte: .primary
        case .niete, .strafe: Tisch.aktiv ? Tisch.elfenbein : Color.meldungRot
        }
    }

    private func sprech(_ z: NeuZelle) -> String {
        switch z {
        case .leer: String(localized: "noch nicht gespielt")
        case .punkte(let n): Theme.points(n)
        case .niete: String(localized: "Niete")
        case .strafe(let n): String(localized: "Strafe minus \(Theme.points(n))")
        }
    }
}
