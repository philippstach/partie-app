// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Regeln der Partie vor dem ersten Zug: oben die neuen Zusatzregeln, darunter die bekannten Spielregeln (Vorlagen, Würfel, Ziel …).
struct NeuRegelnBlatt: View {
    @Binding var rules: GameRules
    var fertig: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Einstieg", selection: $rules.entryThreshold) {
                        Text("Aus").tag(0)
                        ForEach(GameRules.entryThresholds.dropFirst(), id: \.self) { Text("ab \(Theme.points($0))").tag($0) }
                    }
                } header: {
                    Text("Einstiegshürde")
                } footer: {
                    Text(rules.entryThreshold == 0
                         ? String(localized: "Jeder darf mit jedem Zug anschreiben.")
                         : String(localized: "Wer noch nicht angeschrieben hat, darf erst aufhören, wenn der Zug mindestens \(Theme.points(rules.entryThreshold)) Punkte bringt."))
                }

                Section {
                    Picker("Vier bis sechs Gleiche", selection: $rules.multiples) {
                        Text("Drilling plus Einzelne").tag(MultiplesRule.standard)
                        Text("Drilling verdoppelt sich").tag(MultiplesRule.doubling)
                        Text("Feste Werte 1.000 / 2.000 / 3.000").tag(MultiplesRule.fixed)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Mehrfache")
                } footer: {
                    switch rules.multiples {
                    case .standard: Text("Es zählt der Drilling, weitere Würfel nur als Einsen oder Fünfen (vier Vieren = 400).")
                    case .doubling: Text("Jeder weitere gleiche Würfel verdoppelt den Drilling: vier Vieren = 800, fünf Vieren = 1.600.")
                    case .fixed: Text("Vier gleiche Würfel = 1.000, fünf = 2.000, sechs = 3.000.")
                    }
                }

                Section {
                    Toggle("Drei Paare = \(Theme.points(Scoring.threePairsPoints))", isOn: $rules.threePairs)
                        .disabled(rules.diceCount != 6)
                } footer: {
                    Text(rules.diceCount == 6
                         ? String(localized: "Drei verschiedene Paare im Wurf mit allen 6 Würfeln.")
                         : String(localized: "Gilt nur mit 6 Würfeln. Wähle sie unter „Weitere Regeln“."))
                }

                Section {
                    NavigationLink("Weitere Regeln") { RuleSettingsView(rules: $rules) }
                } footer: {
                    Text(RulesSummary.text(rules))
                }
            }
            .navigationTitle("Regeln dieser Partie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig", action: fertig) } }
        }
    }
}

/// Zeile über dem Spielfeld vor dem ersten Zug: kurze Regelübersicht und „Ändern“.
struct NeuRegelZeile: View {
    let rules: GameRules
    var aendern: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: aendern) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                Text(RulesSummary.text(rules)).lineLimit(typeSize.isAccessibilitySize ? 8 : 2).minimumScaleFactor(0.8)   // N-016: bei großer Schrift nicht kürzen.fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Text("Ändern").fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: Design.Ecke.feld))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Regeln dieser Partie ändern"))
        .accessibilityValue(Text(RulesSummary.text(rules)))
    }
}

extension GameStore {
    /// Regeln ändern, solange noch kein Zug gespielt ist (Würfelmodus bleibt).
    func regelnVorStart(_ neu: GameRules) {
        guard var g = game, g.log.isEmpty, !g.turn.hasRolled, g.offer == nil else { return }
        var r = neu
        r.diceMode = g.settings.diceMode
        guard r != g.settings.rules else { return }
        g.settings.rules = r
        g.turn = DiceTurn(count: r.diceCount)
        game = g
    }

    /// Noch vor dem ersten Zug der Partie?
    var vorErstemZug: Bool {
        guard let g = game else { return false }
        return g.log.isEmpty && !g.turn.hasRolled && g.turn.banked == 0 && g.offer == nil && !g.finished && g.tiebreak == nil
    }
}
