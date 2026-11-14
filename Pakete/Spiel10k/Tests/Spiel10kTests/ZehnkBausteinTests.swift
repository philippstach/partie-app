// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// KI-3: Tests zu Zehntausend im Baustein „Frag nach den Regeln“. Eigene Datei, im App-Testziel Tests10k ausgeschlossen
// (project.yml), weil dort ZehnkRegelWissen/ZehnkRegelChat nicht sichtbar waren; sie laufen im Paketlauf (swift test).
import Foundation
import Testing
@testable import Spiel10k
import SpieleKern

/// KI-3: Zehntausend im Baustein „Frag nach den Regeln“ (Blatt 12).
struct ZehnkBausteinTests {
    @Test func beispielfragenUndEinstellungen() {
        let grund = ZehnkRegelWissen(rules: GameRules())
        #expect(grund.beispielfragen.count == 3)
        #expect(grund.beispielfragen.contains("Was ist eine Niete?"))
        let imSpiel = ZehnkRegelWissen(rules: GameRules(), imSpiel: true)
        #expect(imSpiel.beispielfragen.count == 3)
        #expect(imSpiel.beispielfragen.first == "Was zählt mein Wurf?")
        // 10k prüft nur das Modell, nicht die App-Sprache; die Eingestellten Regeln gehören zum Chat
        #expect(!grund.nurDeutscheApp)
        #expect(grund.chatGrenzen == ZehnkRegelChat.grenzen)
        #expect(!grund.aktiveRegeln.isEmpty)   // der Satz „Eure Hausregeln zählen mit“ steht deshalb auf dem Blatt
    }

    @Test func attrappeFuerDenSimulator() {
        // Ohne Startargument und ohne Apple-Modell (iOS < 26): kein Modell, kein Chat
        if #unavailable(iOS 26.0) {
            #expect(ZehnkRegelWissen(rules: GameRules()).sprachmodell() == nil)
        }
    }

    @Test func gespeicherteRegelnAusDemSpeicher() throws {
        let name = "ZehnkBausteinTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        // Nichts gespeichert: keine Regeln (der Rahmen nimmt dann die Standardregeln)
        #expect(GameStore.gespeicherteRegeln(defaults: defaults) == nil)
    }
}
