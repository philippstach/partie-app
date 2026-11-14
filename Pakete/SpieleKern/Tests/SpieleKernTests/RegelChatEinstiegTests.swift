// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpieleKern

/// KI-3: Einstieg „Frag nach den Regeln“ ohne Modell: Katalog, Status je Spiel, Beispielfragen, Antwort mit Quelle über die Attrappe.
extension RegelChatGlobaleTests {
struct RegelChatEinstiegTests {
    private static let markdown = """
    # Testspiel (id: test)
    Quellen: nichts

    ## Ziel
    Stichwörter: gewinnen
    Wer als Erster 10 Punkte hat, gewinnt.

    ## Strafe
    Stichwörter: Zonk
    Eine Niete kostet 3 Punkte.
    """

    private static func wissen(aktiv: String = "") -> RegelWissenEinfach {
        RegelWissenEinfach(spielID: "test", name: "Testspiel", abschnitte: RegelWissenMarkdown.abschnitte(aus: markdown),
                           aktiveRegeln: aktiv, beispielfragen: ["Wie gewinne ich?", "Was kostet eine Niete?", "Wer fängt an?"])
    }

    @Test func grundIDOhneNeu() {
        #expect(RegelWissenKatalog.grundID("maumau-neu") == "maumau")
        #expect(RegelWissenKatalog.grundID("10k-neu") == "10k")
        #expect(RegelWissenKatalog.grundID("muehle") == "muehle")
    }

    @Test func katalogLiefertWissenZurGrundID() {
        let vorher = RegelWissenKatalog.lieferant
        defer { RegelWissenKatalog.lieferant = vorher }
        RegelWissenKatalog.lieferant = { id in id == "test" ? Self.wissen() : nil }
        #expect(RegelWissenKatalog.wissen(fuer: "test-neu")?.name == "Testspiel")
        #expect(RegelWissenKatalog.wissen(fuer: "test")?.beispielfragen.count == 3)
        #expect(RegelWissenKatalog.wissen(fuer: "anderes") == nil)
    }

    @Test func statusSichtbarNurMitWissenUndModell() {
        let vorherLieferant = RegelWissenKatalog.lieferant
        let vorherStatus = RegelChatUmgebung.statusVorgabe
        defer { RegelWissenKatalog.lieferant = vorherLieferant; RegelChatUmgebung.statusVorgabe = vorherStatus }
        RegelWissenKatalog.lieferant = { id in id == "test" ? Self.wissen() : nil }

        RegelChatUmgebung.statusVorgabe = .available
        #expect(RegelChatEinstieg.status(spielID: "test-neu") == .available)
        // Spiel ohne Regelwissen: nichts sichtbar, auch wenn das Gerät es könnte
        #expect(RegelChatEinstieg.status(spielID: "ohne") == .hidden)
        // Gerät ohne Apple Intelligence: nichts sichtbar
        RegelChatUmgebung.statusVorgabe = .hidden
        #expect(RegelChatEinstieg.status(spielID: "test") == .hidden)
        #expect(!RegelChatEinstieg.status(spielID: "test").zeigtEinstieg)
        // Apple Intelligence aus oder Modell lädt: Hinweis, aber kein Fragen
        RegelChatUmgebung.statusVorgabe = .notEnabled
        #expect(RegelChatEinstieg.status(spielID: "test") == .notEnabled)
        #expect(RegelChatEinstieg.status(spielID: "test").zeigtEinstieg)
        #expect(!RegelChatEinstieg.status(spielID: "test").kannFragen)
        RegelChatUmgebung.statusVorgabe = .notReady
        #expect(RegelChatEinstieg.status(spielID: "test") == .notReady)
    }

    @Test func eigenesWissenGiltOhneKatalog() {
        let vorherLieferant = RegelWissenKatalog.lieferant
        let vorherStatus = RegelChatUmgebung.statusVorgabe
        defer { RegelWissenKatalog.lieferant = vorherLieferant; RegelChatUmgebung.statusVorgabe = vorherStatus }
        RegelWissenKatalog.lieferant = nil
        RegelChatUmgebung.statusVorgabe = .available
        #expect(RegelChatEinstieg.status(spielID: "test", wissen: Self.wissen()) == .available)
        #expect(RegelChatEinstieg.status(spielID: "test") == .hidden)
    }

    @Test func beispielfragenStandardLeer() {
        let einfach = RegelWissenEinfach(spielID: "x", name: "X", abschnitte: [])
        #expect(einfach.beispielfragen.isEmpty)
        #expect(Self.wissen().beispielfragen == ["Wie gewinne ich?", "Was kostet eine Niete?", "Wer fängt an?"])
    }

    @MainActor
    @Test func antwortMitQuelleUeberDieSitzung() async {
        let modell = RegelChatAttrappe(antworten: [.init(stichwort: "niete", text: "Eine Niete kostet 3 Punkte.")])
        let sitzung = RegelChatSitzung(wissen: Self.wissen(), modell: modell)
        await sitzung.frage("Was kostet eine Niete?")
        #expect(sitzung.nachrichten.count == 2)
        #expect(sitzung.nachrichten.first?.vonSpieler == true)
        let antwort = sitzung.nachrichten.last
        #expect(antwort?.text == "Eine Niete kostet 3 Punkte.")
        #expect(antwort?.quellen.first == "Strafe")   // „aus den Regeln · Strafe“
        // Der Prompt bleibt unter der Grenze (4096 Token je Sitzung)
        #expect((modell.anfragen.first?.anweisungen.count ?? 0) + (modell.anfragen.first?.prompt.count ?? 0) <= RegelChatGrenzen.standard.maxZeichenGesamt)
    }
}
}
