// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Spielregeln vor dem Start: oben drei Vorlagen, darunter jede Regel einzeln mit Erklärung und Beispiel.
struct RuleSettingsView: View {
    @Binding var rules: GameRules

    var body: some View {
        Form {
            presetsSection

            Section {
                Picker("Würfel", selection: $rules.diceCount) {
                    Text("5 Würfel").tag(5)
                    Text("6 Würfel").tag(6)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                if rules.diceCount == 6 {
                    Picker("Straße", selection: $rules.straight6) {
                        Text("5er-Straße (1.000)").tag(Straight6.five)
                        Text("Große Straße 1–6 (\(Theme.points(Scoring.bigStraightPoints)))").tag(Straight6.full)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            } header: {
                Text("Anzahl der Würfel")
            } footer: {
                Text(diceFooter)
            }

            Section {
                Stepper(value: $rules.goal, in: 1_000...50_000, step: 1_000) {
                    LabeledContent("Zielpunkte", value: Theme.points(rules.goal))
                }
            } header: {
                Text("Ziel")
            } footer: {
                Text((rules.finalRound ? String(localized: "Wer zuerst so viele Punkte hat, löst die Schlussrunde aus. ") : String(localized: "Wer zuerst so viele Punkte hat, gewinnt sofort. ")) + String(localized: "Beispiel: Mit 5.000 dauert ein Spiel etwa halb so lang wie mit 10.000."))
            }

            Section {
                Stepper(value: $rules.roundLimit, in: 0...50) {
                    LabeledContent("Rundenlimit", value: rules.roundLimit == 0 ? String(localized: "Keins") : String(localized: "\(rules.roundLimit) Runden"))
                }
                Toggle("Stechen bei Gleichstand", isOn: $rules.tiebreak)
                    .disabled(rules.roundLimit == 0 && !rules.finalRound)
            } header: {
                Text("Runden")
            } footer: {
                Text(roundsFooter)
            }

            Section {
                Stepper(value: $rules.penalty, in: 0...2_000, step: 50) {
                    LabeledContent("Strafe", value: rules.penalty == 0 ? String(localized: "Keine") : "−\(Theme.points(rules.penalty))")
                }
            } header: {
                Text("Strafe bei 3 Nieten in Folge")
            } footer: {
                Text(penaltyFooter)
            }

            Section {
                Picker("Drillinge", selection: $rules.triples) {
                    Text("Alle Drillinge").tag(TripleRule.all)
                    Text("Nur Einsen und Fünfen").tag(TripleRule.onesAndFives)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Drillinge")
            } footer: {
                Text(triplesFooter)
            }

            Section {
                Toggle("Übernahme mit allen \(rules.diceCount)", isOn: $rules.inheritAllFive)
            } header: {
                Text("Übernehmen")
            } footer: {
                Text(inheritFooter)
            }

            Section {
                Toggle("Faire Schlussrunde", isOn: $rules.finalRound)
            } header: {
                Text("Spielende")
            } footer: {
                Text(rules.finalRound
                     ? String(localized: "Erreicht jemand das Ziel, spielen die anderen die Runde noch zu Ende – so haben alle gleich viele Züge. Danach gewinnt, wer vorne liegt; bei Gleichstand gibt es ein Stechen. Beispiel: Anna erreicht 10.050, Ben und Cem haben noch je einen Zug, Cem kommt auf 10.200 und gewinnt.")
                     : String(localized: "Wer zuerst das Ziel erreicht, gewinnt sofort. Mit „Faire Schlussrunde“ spielen die anderen die Runde noch zu Ende."))
            }
        }
        .wideReadableWidth()
        .navigationTitle("Spielregeln")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Vorlagen

    private var presetsSection: some View {
        Section {
            ForEach(RulePreset.allCases) { preset in
                Button {
                    withAnimation { rules = preset.apply(to: rules) }
                } label: {
                    HStack(spacing: Design.Abstand.m) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.title)
                                .foregroundStyle(.primary)
                            Text(preset.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 8)
                        if preset.matches(rules) {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(.rect)
                }
                .accessibilityAddTraits(preset.matches(rules) ? .isSelected : [])
            }
        } header: {
            Text("Vorlagen")
        } footer: {
            Text(RulePreset.matching(rules) == nil
                 ? String(localized: "Eigene Regeln: \(RulesSummary.text(rules)). Eine Vorlage setzt alle Regeln auf einmal zurück.")
                 : String(localized: "Eine Vorlage setzt alle Regeln auf einmal. Darunter kannst du jede Regel einzeln ändern."))
        }
    }

    // MARK: - Erklärungen

    private var roundsFooter: String {
        var text = String(localized: "Nach so vielen Runden endet das Spiel, und wer vorne liegt, gewinnt – auch ohne das Ziel zu erreichen. „Keins“: Es wird gespielt, bis jemand das Ziel erreicht.")
        if rules.roundLimit > 0 {
            text += rules.tiebreak
                ? String(localized: " Stechen: Liegen am Ende mehrere gleichauf, haben sie noch je einen Zug. Wer dabei mehr Punkte holt, gewinnt.")
                : String(localized: " Ohne Stechen gewinnen bei Gleichstand alle Führenden gemeinsam.")
        } else if rules.finalRound {
            text += rules.tiebreak
                ? String(localized: " Bei Gleichstand nach der Schlussrunde gibt es ein Stechen.")
                : String(localized: " Ohne Stechen gewinnen bei Gleichstand alle Führenden gemeinsam.")
        } else {
            text += String(localized: " Stechen gibt es nur mit Rundenlimit oder fairer Schlussrunde.")
        }
        return text
    }

    private var penaltyFooter: String {
        if rules.penalty == 0 {
            return String(localized: "Keine Strafe: Wer dreimal hintereinander keine Punkte schafft, verliert nichts.")
        }
        let example = Theme.points(2_300 - rules.penalty)
        return String(localized: "Wer dreimal hintereinander keine Punkte schafft, bekommt \(Theme.points(rules.penalty)) Punkte abgezogen. Danach zählt es wieder von vorn. Beispiel: Aus 2.300 werden \(example).")
    }

    private var triplesFooter: String {
        switch rules.triples {
        case .all:
            String(localized: "Drei Einsen = 1.000, drei gleiche andere Würfel = Augenzahl × 100. Beispiel: drei Vieren = 400. Einzelne Einsen zählen 100, einzelne Fünfen 50.")
        case .onesAndFives:
            String(localized: "Nur drei Einsen (500) und drei Fünfen (500) zählen als Drilling. Drei Vieren bringen nichts. Einzelne Einsen zählen 100, einzelne Fünfen 50.")
        }
    }

    private var inheritFooter: String {
        let n = rules.diceCount
        let base = String(localized: "Hört jemand auf und lässt Würfel liegen, darf die nächste Person diese Würfel samt Punkten übernehmen und weiterwürfeln.")
        return rules.inheritAllFive
            ? base + String(localized: " Sind alle \(n) Würfel mit Punkten rausgelegt, übernimmst du mit allen \(n). Beispiel: Anna hört mit 650 auf, Ben startet mit 650 und würfelt alle \(n).")
            : base + String(localized: " Sind alle \(n) Würfel rausgelegt, gibt es nichts zu übernehmen.")
    }

    private var diceFooter: String {
        guard rules.diceCount == 6 else {
            return String(localized: "Gespielt wird mit 5 Würfeln. Straße: 1-2-3-4-5 oder 2-3-4-5-6 = 1.000, nur wenn alle 5 in einem Wurf fallen.")
        }
        let base = String(localized: "Mit 6 Würfeln gibt es öfter Punkte. Bei vier bis sechs Gleichen zählt der Drilling, weitere Würfel nur als Einsen oder Fünfen (vier Vieren = 400); zwei Drillinge in einem Wurf zählen beide.")
        switch rules.straight6 {
        case .five:
            return base + String(localized: " 5er-Straße: 1-2-3-4-5 oder 2-3-4-5-6 = 1.000, nur im Wurf mit allen 6. Ist der sechste Würfel eine 1 oder 5, zählt er dazu – Beispiel: 1-2-3-4-5-5 = 1.050.")
        case .full:
            return base + String(localized: " Große Straße: nur 1-2-3-4-5-6 = \(Theme.points(Scoring.bigStraightPoints)), nur im Wurf mit allen 6. Eine 5er-Straße zählt dann nicht.")
        }
    }
}
