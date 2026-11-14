// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Einführung (1.0.1, Doku/EINFUEHRUNG-1.0.1.md): 8 Seiten mit kleinen Animationen, jederzeit überspringbar.
/// Später unter „Regeln“ erneut aufrufbar, auch einzelne Kapitel. Zahlen kommen aus den Regeln.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page: Int
    private let rules: GameRules

    init(rules: GameRules = GameRules(), startPage: Int = 0) {
        self.rules = rules
        var start = startPage
        #if DEBUG
        // Kontroll-Fotos: `-demoIntroSeite 3` öffnet die Einführung auf dieser Seite
        if start == 0 { start = UserDefaults.standard.integer(forKey: "demoIntroSeite") }
        #endif
        _page = State(initialValue: start)
    }

    /// 1.0 hat die kurze Einführung (3 Seiten) unter diesem Schlüssel gemerkt
    static let seenKey = "tenk.onboarding.v1"
    /// Ausführliche Einführung (1.0.1) gesehen bzw. Hinweis darauf weggetippt
    static let seenV2Key = "tenk.onboarding.v2"

    /// Bei neuen Nutzer*innen einmal zeigen (nicht, wer schon Spiele gespeichert hat – vorläufig)
    static func shouldShow(defaults: UserDefaults = .standard, hasGames: Bool) -> Bool {
        !defaults.bool(forKey: seenKey) && !defaults.bool(forKey: seenV2Key) && !hasGames
    }

    /// Wer die alte Einführung kennt oder schon spielt: einmal auf der Startseite „Neu: ausführliche Einführung“
    static func shouldHintNew(defaults: UserDefaults = .standard, hasGames: Bool) -> Bool {
        !defaults.bool(forKey: seenV2Key) && (defaults.bool(forKey: seenKey) || hasGames)
    }

    static func markSeen(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: seenKey)
        defaults.set(true, forKey: seenV2Key)
    }

    var body: some View {
        let pages = OnboardingPage.pages(for: rules, geraet: Geraet.aktuell)
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Überspringen", action: finish)
                    .padding()
            }
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i], active: page == i).tag(i)
                }
            }
            // Build 11: Seitenpunkte in eigener Zeile – bei großer Schrift lagen sie über dem Text
            .tabViewStyle(.page(indexDisplayMode: .never))
            HStack(spacing: Design.Abstand.s) {
                ForEach(pages.indices, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.accentColor : Color.secondary.opacity(0.35))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Seite \(page + 1) von \(pages.count)")

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? String(localized: "Weiter") : String(localized: "Los geht’s")).frame(maxWidth: 480)
            }
            .keyboardShortcut(.return, modifiers: [])
            .hauptKnopf()
            .controlSize(.large)
            .font(.headline)
            .padding()
        }
        .background(Color.seitenGrund)
    }

    private func pageView(_ p: OnboardingPage, active: Bool) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                // iPad: Motive größer (SPEC-1.1 §4)
                OnboardingMotif(motif: p.motif, rules: rules, active: active)
                    .frame(height: 190)
                    .scaleEffect(Geraet.aktuell == .iPad ? 1.5 : 1)
                    .frame(height: Geraet.aktuell == .iPad ? 300 : 190)
                    .padding(.top, 16)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Bild: \(p.motifDescription)")
                Text(p.title)
                    .font(.system(.title, design: Design.zahlDesign, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(p.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(p.example)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    private func finish() {
        Self.markSeen()
        dismiss()
    }
}

// MARK: - Seiten

/// Eine Seite der Einführung. Zahlen aus den Regeln (Würfelzahl, Ziel, Drillinge, Strafe).
struct OnboardingPage: Equatable {
    enum Motif: Equatable { case goal, scoring, layOut, decide, niete, hotDice, inherit, penalty }

    let title: String
    let text: String
    let motif: Motif
    let motifDescription: String
    let example: String

    static func pages(for rules: GameRules, geraet: Geraet.Art = .iPhone) -> [OnboardingPage] {
        let n = rules.diceCount
        let goal = Theme.points(rules.goal)
        let onlyOnesFives = rules.triples == .onesAndFives
        let scoringText = onlyOnesFives
            ? String(localized: "Jede 1 bringt 100, jede 5 bringt 50. Drei Einsen und drei Fünfen bringen je 500, andere Drillinge zählen nicht. Eine Straße bringt 1.000.")
            : String(localized: "Jede 1 bringt 100, jede 5 bringt 50. Drei Gleiche bringen Augenzahl × 100, drei Einsen 1.000. Eine Straße aus allen Würfeln bringt 1.000.")
        let penalty = rules.penalty > 0
            ? String(localized: "Drei Nieten in Folge kosten \(Theme.points(rules.penalty)) Punkte.")
            : String(localized: "Eine Strafe für Nieten gibt es bei euch nicht.")
        return [
            OnboardingPage(
                title: String(localized: "Wer holt zuerst \(goal)?"),
                text: String(localized: "Ihr würfelt reihum und sammelt Punkte. Wer zuerst das Ziel erreicht, gewinnt. Ihr könnt mit der App würfeln oder mit echten Würfeln am Tisch."),
                motif: .goal, motifDescription: String(localized: "\(n) goldene Würfel, darüber zählt \(goal) hoch"),
                example: String(localized: "2 bis 8 Mitspielende auf einem \(Geraet.name(geraet))")),
            OnboardingPage(
                title: String(localized: "Was zählt?"),
                text: scoringText,
                motif: .scoring, motifDescription: String(localized: "Würfelbilder mit ihren Punkten"),
                example: onlyOnesFives ? String(localized: "1 + 5 + 1-1-1 = 650") : String(localized: "1 + 5 + 4-4-4 = 550")),
            OnboardingPage(
                title: String(localized: "Rauslegen"),
                text: String(localized: "Nach jedem Wurf legst du mindestens einen Würfel mit Punkten raus. Gezählt wird nur, was in einem Wurf fällt."),
                motif: .layOut, motifDescription: String(localized: "Wurf 1, 3, 5, 2, 6 – die 1 und die 5 werden rausgelegt"),
                example: String(localized: "1 und 5 raus: +150")),
            OnboardingPage(
                title: String(localized: "Weiter oder aufhören?"),
                text: String(localized: "Danach entscheidest du: aufhören und die Punkte sichern, oder mit den übrigen Würfeln weiterwürfeln und mehr riskieren."),
                motif: .decide, motifDescription: String(localized: "Zwei Knöpfe: Weiterwürfeln mit \(n - 2) Würfeln oder Aufhören mit 150"),
                example: String(localized: "150 gesichert oder weiterzocken?")),
            OnboardingPage(
                title: String(localized: "Niete"),
                text: String(localized: "Bringt ein Wurf keinen einzigen Punkt, ist es eine Niete. Die Punkte dieses Zugs sind weg, und die nächste Person ist dran."),
                motif: .niete, motifDescription: String(localized: "Wurf ohne Punkte, die Würfel wackeln, rotes Niete"),
                example: String(localized: "Niete: Die 150 aus diesem Zug sind weg")),
            OnboardingPage(
                title: String(localized: "Alle Würfel punkten"),
                text: String(localized: "Hast du alle Würfel rausgelegt, darfst du mit allen wieder würfeln. Die Punkte bleiben dir."),
                motif: .hotDice, motifDescription: String(localized: "Goldener Blitz, alle Würfel kommen zurück"),
                example: String(localized: "Alle punkten: weiter mit allen \(n)!")),
            OnboardingPage(
                title: String(localized: "Übernehmen"),
                text: String(localized: "Hört jemand auf und lässt Würfel liegen, darfst du sie samt Punkten übernehmen und weiterwürfeln. Mit einer Niete ist aber alles weg."),
                motif: .inherit, motifDescription: String(localized: "Karte: Übernehmen, plus 350, 3 Würfel"),
                example: String(localized: "+350 übernommen, du würfelst mit 3 Würfeln")),
            OnboardingPage(
                title: String(localized: "Strafe und eure Regeln"),
                text: String(localized: "\(penalty) Fast alles ist einstellbar: Ziel, Runden, 6 Würfel, Stechen und mehr. Mit echten Würfeln tippst du einfach ein, was du rauslegst."),
                motif: .penalty, motifDescription: rules.penalty > 0 ? String(localized: "Drei rote Punkte, dann minus \(Theme.points(rules.penalty))") : String(localized: "Drei Punkte und die Regel-Karte"),
                example: String(localized: "Viel Glück beim Würfeln!")),
        ]
    }

    /// Kapitel für „Regeln → Einführung“
    static func chapters(for rules: GameRules) -> [(index: Int, title: String)] {
        pages(for: rules).enumerated().map { ($0.offset, $0.element.title) }
    }
}

// MARK: - Motive

/// Kleine Animation je Seite; bei „Bewegung reduzieren“ ein Standbild (Endzustand).
private struct OnboardingMotif: View {
    let motif: OnboardingPage.Motif
    let rules: GameRules
    /// Nur die sichtbare Seite animiert (Neustart beim Hinwischen)
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0

    private var n: Int { rules.diceCount }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: active) {
                guard active else { step = 0; return }
                if reduceMotion { step = 9; return }
                step = 0
                for s in 1...4 {
                    try? await Task.sleep(for: .milliseconds(650))
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) { step = s }
                }
            }
    }

    @ViewBuilder private var content: some View {
        switch motif {
        case .goal:
            VStack(spacing: Design.Abstand.l) {
                Text(Theme.points(step >= 1 ? rules.goal : 0))
                    .font(.system(.largeTitle, design: Design.zahlDesign).weight(.black))
                    .foregroundStyle(.tint)
                    .contentTransition(.numericText())
                dice(Array([1, 5, 1, 5, 1, 5].prefix(n)), state: .selected)
                    .offset(y: step >= 1 ? 0 : -60)
                    .opacity(step >= 1 ? 1 : 0)
            }
        case .scoring:
            let rows: [([Int], String)] = rules.triples == .onesAndFives
                ? [([1], "100"), ([5], "50"), ([1, 1, 1], "500"), ([5, 5, 5], "500"), ([1, 2, 3, 4, 5], "1.000")]
                : [([1], "100"), ([5], "50"), ([4, 4, 4], "400"), ([1, 1, 1], "1.000"), ([1, 2, 3, 4, 5], "1.000")]
            VStack(alignment: .leading, spacing: 6) {
                ForEach(rows.indices, id: \.self) { i in
                    HStack(spacing: Design.Abstand.xs) {
                        ForEach(rows[i].0.indices, id: \.self) { k in
                            DieView(value: rows[i].0[k], state: .free, size: 26)
                        }
                        Spacer(minLength: 12)
                        Text(rows[i].1).font(.headline.monospacedDigit()).foregroundStyle(.tint)
                    }
                    .opacity(step >= min(i, 4) ? 1 : 0.25)
                }
            }
            .frame(maxWidth: 260)
        case .layOut:
            HStack(spacing: Design.Abstand.s) {
                ForEach(Array([1, 3, 5, 2, 6, 4].prefix(n).enumerated()), id: \.offset) { i, v in
                    let out = v == 1 || v == 5
                    DieView(value: v, state: out && step >= 1 ? .selected : .free, size: 48)
                        .offset(y: out && step >= 2 ? -40 : 0)
                }
            }
        case .decide:
            VStack(spacing: Design.Abstand.m) {
                dice([1, 5], state: .locked)
                HStack(spacing: 10) {
                    fakeButton("Weiterwürfeln (\(n - 2))", highlighted: step % 2 == 1, prominent: false)
                    fakeButton("Aufhören +150", highlighted: step % 2 == 0 && step > 0, prominent: true)
                }
            }
        case .niete:
            VStack(spacing: 14) {
                dice(Array([2, 3, 4, 6, 6, 3].prefix(n)), state: .free)
                    .phaseAnimator([0.0, -10, 10, -6, 6, 0], trigger: step == 2) { v, x in v.offset(x: x) }
                        animation: { _ in .easeInOut(duration: 0.06) }
                Text("Niete!")
                    .font(.system(.title, design: Design.zahlDesign, weight: .heavy))
                    .foregroundStyle(.red)
                    .opacity(step >= 2 ? 1 : 0)
            }
        case .hotDice:
            VStack(spacing: 14) {
                Image(systemName: "bolt.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                    .scaleEffect(step >= 2 ? 1 : 0.3)
                    .opacity(step >= 2 ? 1 : 0)
                dice(Array([1, 1, 5, 5, 5, 1].prefix(n)), state: step >= 2 ? .free : .locked)
            }
        case .inherit:
            VStack(spacing: Design.Abstand.s) {
                Text("Übernehmen?").font(.headline)
                Text("+350 · 3 Würfel").font(.system(.title2, design: Design.zahlDesign, weight: .heavy)).foregroundStyle(.tint)
                HStack(spacing: 6) {
                    ForEach(0..<n, id: \.self) { i in
                        DieView(value: [5, 5, 0, 0, 0, 0][i], state: i < 2 ? .locked : .unknown, size: 34)
                    }
                }
            }
            .padding(18)
            .designFlaeche(Design.Ecke.karte)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
            .offset(y: step >= 1 ? 0 : 160)
            .opacity(step >= 1 ? 1 : 0)
        case .penalty:
            VStack(spacing: 14) {
                HStack(spacing: Design.Abstand.m) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle().fill(.red).frame(width: 18, height: 18).opacity(step > i ? 1 : 0.2)
                    }
                }
                Text(rules.penalty > 0 ? "−\(Theme.points(rules.penalty))" : "±0")
                    .font(.system(.largeTitle, design: Design.zahlDesign).weight(.black))
                    .foregroundStyle(.red)
                    .opacity(step >= 4 ? 1 : 0)
            }
        }
    }

    private func dice(_ values: [Int], state: DieView.State) -> some View {
        HStack(spacing: Design.Abstand.s) {
            ForEach(values.indices, id: \.self) { i in
                DieView(value: values[i], state: state, size: values.count > 5 ? 42 : 48)
            }
        }
    }

    private func fakeButton(_ title: String, highlighted: Bool, prominent: Bool) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1).minimumScaleFactor(0.7)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(prominent ? Color.onAccent : Color.accentText)
            .background(prominent ? Color.appFlaeche : Color.accentSoft, in: RoundedRectangle(cornerRadius: 14))
            .scaleEffect(highlighted ? 1.08 : 1)
    }
}
