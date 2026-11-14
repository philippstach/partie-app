// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SwiftUI
@testable import Spiel10k

@MainActor
struct ViewHelperTests {
    /// Achse im Spielverlauf: 1.000 und 1.150 dürfen nicht beide „1k“ heißen.
    @Test func chartAxisLabels() {
        #expect(ScoreChart.axisLabel(500) == "500")
        #expect(ScoreChart.axisLabel(1000) == "1k")
        #expect(ScoreChart.axisLabel(1500) == "1,5k")
        #expect(ScoreChart.axisLabel(10_000) == "10k")
        #expect(ScoreChart.axisLabel(-500) == "-500")
    }
}

/// Einführung: einmal für neue Nutzer, nicht für Nutzer mit Spielständen.
struct OnboardingTests {
    @Test func showsOnceForNewUsers() {
        let d = UserDefaults(suiteName: UUID().uuidString)!
        #expect(OnboardingView.shouldShow(defaults: d, hasGames: false))
        #expect(!OnboardingView.shouldShow(defaults: d, hasGames: true))
        OnboardingView.markSeen(defaults: d)
        #expect(!OnboardingView.shouldShow(defaults: d, hasGames: false))
        #expect(!OnboardingView.shouldHintNew(defaults: d, hasGames: true))
    }

    /// 1.0.1: Wer die alte Einführung kennt oder schon spielt, bekommt einmal den Hinweis, nicht die Einführung.
    @Test func newIntroHintForExistingUsers() {
        let d = UserDefaults(suiteName: UUID().uuidString)!
        #expect(!OnboardingView.shouldHintNew(defaults: d, hasGames: false))   // ganz neu: Einführung statt Hinweis
        #expect(OnboardingView.shouldHintNew(defaults: d, hasGames: true))
        d.set(true, forKey: OnboardingView.seenKey)                            // alte Einführung gesehen
        #expect(!OnboardingView.shouldShow(defaults: d, hasGames: false))
        #expect(OnboardingView.shouldHintNew(defaults: d, hasGames: false))
        OnboardingView.markSeen(defaults: d)
        #expect(!OnboardingView.shouldHintNew(defaults: d, hasGames: true))
    }

    /// 8 Seiten; Zahlen folgen den Regeln (6 Würfel, nur Einsen und Fünfen, keine Strafe).
    @Test func introPagesFollowRules() {
        #expect(OnboardingPage.pages(for: GameRules()).count == 8)
        #expect(OnboardingPage.pages(for: GameRules()).first?.title == "Wer holt zuerst 10.000?")
        var r = GameRules()
        r.diceCount = 6
        r.triples = .onesAndFives
        r.penalty = 0
        r.goal = 5_000
        let pages = OnboardingPage.pages(for: r)
        #expect(pages[0].title == "Wer holt zuerst 5.000?")
        #expect(pages[1].text.contains("je 500"))
        #expect(pages[5].example.contains("allen 6"))
        #expect(pages[7].text.contains("keine Strafe") || pages[7].text.contains("nicht"))
        #expect(OnboardingPage.chapters(for: r).map(\.index) == Array(0..<8))
    }
}

/// iPad: Layout nach Breite (SPEC-1.1 §2), Gerätename (§6)
struct TischLayoutTests {
    private func l(_ b: CGFloat, _ h: CGFloat, _ sc: UserInterfaceSizeClass? = .regular, gross: Bool = false) -> TischLayout {
        TischLayout.layout(breite: b, hoehe: h, sizeClass: sc, grosseSchrift: gross)
    }

    @Test func iPadFullScreen() {
        #expect(l(1032, 1376) == .breitHoch)     // 13″ hoch
        #expect(l(1376, 1032) == .breitQuer)     // 13″ quer
        #expect(l(834, 1194) == .breitHoch)      // 11″ hoch
        #expect(l(1194, 834) == .breitQuer)      // 11″ quer
    }

    @Test func splitViewAndStageManager() {
        #expect(l(375, 1024, .compact) == .kompakt)   // ⅓
        #expect(l(678, 1024) == .kompakt)             // ½ auf 11″ quer (unter 700)
        #expect(l(683, 1024, .compact) == .kompakt)   // ½ auf 13″ quer
        #expect(l(907, 1024) == .breitHoch)           // ⅔ auf 13″ quer
        #expect(l(800, 600) == .breitHoch)            // Stage Manager 800×600: breiter als hoch, aber < 1000
    }

    @Test func iPhoneAndAccessibility() {
        #expect(l(440, 956, .compact) == .kompakt)
        #expect(l(956, 440, .compact) == .kompakt)
        #expect(l(1376, 1032, gross: true) == .breitHoch)
        #expect(TischLayout.breitQuer.breit && !TischLayout.kompakt.breit)
    }

    @Test func deviceNames() {
        #expect(Geraet.name(.iPad) == "iPad")
        #expect(Geraet.name(.iPhone) == "iPhone")
        #expect(OnboardingPage.pages(for: GameRules(), geraet: .iPad).first?.example.contains("iPad") == true)
        #expect(!RegelZusammenfassung.text(GameRules()).contains("iPhone"))
    }
}

/// Tastenkürzel: eindeutig, alle mit Titel (SPEC-1.1 §5)
struct KuerzelTests {
    @Test func uniqueAndTitled() {
        let schluessel = Kuerzel.alle.map { "\($0.befehl)\($0.taste)" }
        #expect(Set(schluessel).count == Kuerzel.alle.count)
        #expect(Kuerzel.alle.allSatisfy { !$0.titel.isEmpty })
        #expect(Kuerzel.neuesSpiel.taste == "n" && Kuerzel.neuesSpiel.befehl)
    }
}

/// Build 10: Würfelreihe rechnet aus dem Platzangebot – nie breiter als das Angebot
struct WuerfelReiheTests {
    @Test func neverWiderThanOffer() {
        for n in [5, 6] {
            for breite in [200.0, 311, 343, 375, 500, 680, 830, 984, 1300] as [CGFloat] {
                for hoechstens in [64.0, 96, 128, 200] as [CGFloat] {
                    let k = WuerfelReihe.kante(breite: breite, n: n, abstand: 14, hoechstens: hoechstens)
                    #expect(WuerfelReihe.breite(kante: k, n: n, abstand: 14) <= breite + 0.001, "n \(n), \(breite)")
                    #expect(k <= hoechstens)
                }
            }
        }
    }

    @Test func iPadSizes() {
        // iPad 13″ quer, rechte Spalte ca. 830 pt minus Innenabstand 2 × 28: 5 Würfel
        #expect(WuerfelReihe.kante(breite: 774, n: 5, abstand: 14, hoechstens: 200) == 143.6)
        // iPad hoch, Tisch 1000 pt minus Innenabstand: bis 200
        #expect(WuerfelReihe.kante(breite: 944, n: 5, abstand: 14, hoechstens: 200) == 177.6)
        #expect(WuerfelReihe.kante(breite: 1200, n: 5, abstand: 14, hoechstens: 200) == 200)
        // ohne Angebot: Höchstgröße
        #expect(WuerfelReihe.kante(breite: nil, n: 6, abstand: 10, hoechstens: 96) == 96)
        #expect(WuerfelReihe.kante(breite: 300, n: 0, abstand: 10, hoechstens: 96) == 0)
    }

    @MainActor @Test func headerTotal() {
        #expect(CurrentPlayerCard.gesamtText(score: 0, goal: 10_000) == "Gesamt 0 · Ziel 10.000")
        #expect(CurrentPlayerCard.gesamtText(score: 1_950, goal: 10_000) == "Gesamt 1.950 · noch 8.050 bis 10.000")
    }
}

/// Build 11: Größenprüfung kleine iPhones – feste Werte für iPhone SE (375 × 667) und 13 mini (375 × 812)
struct KleineGeraeteTests {
    @Test func seIsCompactAndDiceFit() {
        #expect(TischLayout.layout(breite: 375, hoehe: 667, sizeClass: .compact) == .kompakt)
        #expect(TischLayout.layout(breite: 375, hoehe: 812, sizeClass: .compact) == .kompakt)
        // Würfelkarte auf dem SE: 375 − 2 × 16 Seitenrand − 2 × 16 Karte = 311 pt
        for (n, abstand) in [(5, 10.0), (6, 10.0)] as [(Int, CGFloat)] {
            let k = WuerfelReihe.kante(breite: 311, n: n, abstand: abstand, hoechstens: 96)
            #expect(WuerfelReihe.breite(kante: k, n: n, abstand: abstand) <= 311)
            #expect(k >= 40, "\(n) Würfel auf dem SE nur \(k) pt")
        }
        // Augen-Tasten in der Leiste: 375 − 2 × 16 = 343 pt, 6 Tasten
        let taste = WuerfelReihe.kante(breite: 343, n: 6, abstand: 8, hoechstens: 64)
        #expect(taste >= 44, "Augen-Taste \(taste) pt – unter der Mindest-Tippfläche")
    }
}

/// Build 11: VoiceOver-Ansagen im Zug
struct VoiceOverTextTests {
    @Test func texts() {
        #expect(VoiceOverText.wurf([1, 5, 3, 3, 6], beste: 150) == "Geworfen: 1, 5, 3, 3, 6. Beste Auswahl 150 Punkte.")
        #expect(VoiceOverText.wurf([2, 3, 4, 6, 6], beste: 0) == "Geworfen: 2, 3, 4, 6, 6. Keine Punkte.")
        #expect(VoiceOverText.niete(verloren: 1_250, strafe: 0) == "Niete! 1.250 Punkte sind weg.")
        #expect(VoiceOverText.niete(verloren: 0, strafe: 500) == "Niete! Kein Würfel bringt Punkte. Strafe: minus 500 Punkte.")
        #expect(VoiceOverText.amZug("Oma Gerda", punkte: 1_950) == "Jetzt am Zug: Oma Gerda, 1.950 Punkte.")
    }
}

