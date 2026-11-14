// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpieleKern

/// KI-1: Regel-Chat-Gerüst ohne Modell (Attrappe). Das echte Modell prüft nur ein Lauf am Gerät.
private func beispielWissen(zusatz: (@Sendable (String) -> String?)? = nil,
                            direkt: (@Sendable (String) -> String?)? = nil,
                            lang: Bool = false) -> RegelWissenEinfach {
    let fuell = lang ? String(repeating: "Dieser Satz füllt den Abschnitt mit Text. ", count: 120) : ""
    return RegelWissenEinfach(
        spielID: "beispiel", name: "Beispielspiel",
        abschnitte: [
            RegelAbschnitt(titel: "Ziel", text: "Wer als Erstes 500 Punkte erreicht, gewinnt. " + fuell),
            RegelAbschnitt(titel: "Übernehmen", text: "Wer aufhört, lässt Karten liegen; die nächste Person darf sie übernehmen. " + fuell,
                           stichwoerter: ["stehen lassen", "Vorgänger"]),
            RegelAbschnitt(titel: "Niete", text: "Ein Wurf ohne Punkte ist eine Niete. Alle Punkte des Zugs sind weg. " + fuell,
                           stichwoerter: ["Zonk", "Farkle"]),
            RegelAbschnitt(titel: "Strafe", text: "Drei Nieten in Folge kosten 300 Punkte. " + fuell),
        ],
        aktiveRegeln: "- Ziel: 500 Punkte.\n- Strafe: 300 Punkte.",
        begriffe: "- Zonk = Niete.",
        beispiele: "F: Was ist ein Zonk? A: Eine Niete.",
        direkt: direkt, fakten: zusatz)
}

/// KI-3: `RegelChatUmgebung.statusVorgabe` und `RegelWissenKatalog.lieferant` sind prozessweit. Swift Testing führt verschiedene Suiten
/// parallel aus, daher laufen alle Tests, die sie setzen, in dieser einen seriellen Suite (die Untersuite erbt `.serialized`).
@Suite(.serialized) enum RegelChatGlobaleTests {}

extension RegelChatGlobaleTests {
struct RegelChatStatusTests {
    @Test func entscheidung() {
        func s(_ m: RegelChatStatus.ModellZustand, deutsch: Bool = true, app: Bool = true, nur: Bool = true) -> RegelChatStatus {
            RegelChatStatus.bestimmen(modell: m, modellKannDeutsch: deutsch, appSpracheDeutsch: app, nurDeutscheApp: nur)
        }
        #expect(s(.verfuegbar) == .available)
        #expect(s(.verfuegbar, deutsch: false) == .hidden)
        #expect(s(.laedt) == .notReady)
        #expect(s(.appleIntelligenceAus) == .notEnabled)
        #expect(s(.nichtUnterstuetzt) == .hidden)
        // App nicht auf Deutsch: verborgen, auch wenn das Modell bereit ist (außer die Prüfung ist aus)
        #expect(s(.verfuegbar, app: false) == .hidden)
        #expect(s(.laedt, app: false) == .hidden)
        #expect(s(.verfuegbar, app: false, nur: false) == .available)
    }

    @Test func sichtbarkeit() {
        #expect(RegelChatStatus.available.zeigtEinstieg && RegelChatStatus.available.kannFragen)
        #expect(RegelChatStatus.notEnabled.zeigtEinstieg && !RegelChatStatus.notEnabled.kannFragen)
        #expect(!RegelChatStatus.hidden.zeigtEinstieg)
    }

    @Test func vorgabeUeberschreibtSystem() {
        RegelChatUmgebung.statusVorgabe = .notEnabled
        defer { RegelChatUmgebung.statusVorgabe = nil }
        #expect(RegelChatStatus.aktuell() == .notEnabled)
    }

    /// Ohne Apple-Modell (Simulator ohne Apple Intelligence) nie sichtbar, ohne Absturz.
    @Test func ohneVorgabeFragtDasSystem() {
        RegelChatUmgebung.statusVorgabe = nil
        let status = RegelChatStatus.aktuell(nurDeutscheApp: false)
        #expect([RegelChatStatus.available, .notReady, .notEnabled, .hidden].contains(status))
    }
}
}

struct RegelChatAuswahlTests {
    @Test func waehltPassendenAbschnitt() {
        let w = beispielWissen()
        let a = RegelChatAuswahl.waehle(frage: "Wie funktioniert Übernehmen?", aus: w.abschnitte)
        #expect(a.first?.titel == "Übernehmen")
    }

    @Test func umgangssprachePerStichwort() {
        let w = beispielWissen()
        #expect(RegelChatAuswahl.waehle(frage: "Ich habe einen Zonk geworfen", aus: w.abschnitte).first?.titel == "Niete")
        #expect(RegelChatAuswahl.waehle(frage: "Darf der Vorgänger stehen lassen?", aus: w.abschnitte).first?.titel == "Übernehmen")
    }

    @Test func wortformenPassen() {
        let w = beispielWissen()
        // „übernommen“ gegen „Übernehmen“, „Punkten“ gegen „Punkte“
        #expect(RegelChatAuswahl.waehle(frage: "Was ist übernommen?", aus: w.abschnitte).first?.titel == "Übernehmen")
        #expect(RegelChatAuswahl.waehle(frage: "Wie viele Punkten Strafe?", aus: w.abschnitte).first?.titel == "Strafe")
    }

    @Test func hoechstensDreiUndZeichengrenze() {
        let w = beispielWissen(lang: true)
        let a = RegelChatAuswahl.waehle(frage: "Ziel Übernehmen Niete Strafe Punkte", aus: w.abschnitte, maxAnzahl: 3, maxZeichen: 3200)
        #expect(a.count <= 3)
        #expect(a.reduce(0) { $0 + $1.titel.count + $1.text.count + 2 } <= 3200)
        #expect(!a.isEmpty)
    }

    @Test func zuLangerErsterTrefferWirdGekuerzt() {
        let w = beispielWissen(lang: true)
        let a = RegelChatAuswahl.waehle(frage: "Übernehmen", aus: w.abschnitte, maxAnzahl: 1, maxZeichen: 500)
        #expect(a.count == 1)
        #expect(a[0].text.count <= 500)
    }

    @Test func ohneTrefferErsatzOderLeer() {
        let w = beispielWissen()
        #expect(RegelChatAuswahl.waehle(frage: "Quatsch xyzzy", aus: w.abschnitte).first?.titel == "Ziel")
        #expect(RegelChatAuswahl.waehle(frage: "Quatsch xyzzy", aus: w.abschnitte, ersatzErster: false).isEmpty)
    }

    @Test func zahlenWaechter() {
        #expect(RegelChatZahlen.zahlen(in: "Das sind 1.000 Punkte, −500 bei Strafe") == [1000, 500])
        #expect(RegelChatZahlen.ok(antwort: "Ziel sind 500 Punkte.", quellen: ["Ziel: 500 Punkte"]))
        #expect(!RegelChatZahlen.ok(antwort: "Ziel sind 700 Punkte.", quellen: ["Ziel: 500 Punkte"]))
        #expect(RegelChatZahlen.ok(antwort: "Du spielst 3 Runden.", quellen: []))   // 0 bis 12 immer erlaubt
    }
}

struct RegelChatPromptTests {
    @Test func enthaeltGeruestRegelnUndFrage() {
        let w = beispielWissen()
        let e = RegelChatPrompt.bauen(frage: "Was ist ein Zonk?", wissen: w)
        #expect(e.anweisungen.contains("Beispielspiel"))
        #expect(e.anweisungen.contains("höchstens vier Sätze"))
        #expect(e.anweisungen.contains("Erfinde keine Regeln"))
        #expect(e.anweisungen.contains("EINGESTELLTE REGELN"))
        #expect(e.anweisungen.contains("## Niete"))
        #expect(e.quellen.first == "Niete")
        #expect(e.prompt == "Was ist ein Zonk?")
    }

    @Test func ueberbleibtUnterGrenzeAuchBeiLangenRegeln() {
        let w = beispielWissen(lang: true)
        for frage in ["Ziel Übernehmen Niete Strafe", "Was ist ein Zonk?", "Wie viele Punkte?"] {
            let e = RegelChatPrompt.bauen(frage: frage, wissen: w)
            #expect(e.zeichen <= RegelChatGrenzen.standard.maxZeichenGesamt, "\(frage): \(e.zeichen)")
            let k = RegelChatPrompt.bauen(frage: frage, wissen: w, grenzen: .knapp)
            #expect(k.zeichen <= RegelChatGrenzen.knapp.maxZeichenGesamt, "\(frage) knapp: \(k.zeichen)")
            #expect(k.zeichen <= e.zeichen)
        }
    }

    @Test func nurPassendeAbschnitteImPrompt() {
        let w = beispielWissen()
        let e = RegelChatPrompt.bauen(frage: "Zonk", wissen: w, grenzen: RegelChatGrenzen(maxAbschnitte: 1))
        #expect(e.anweisungen.contains("## Niete"))
        #expect(!e.anweisungen.contains("## Strafe"))
    }

    @Test func rueckfrageFaktenUndZug() {
        let w = beispielWissen()
        let e = RegelChatPrompt.bauen(frage: "Und dann?", wissen: w, vorige: ("Was ist ein Zonk?", "Eine Niete."),
                                      zug: "AKTUELLER ZUG: 100 Punkte", zusatz: "ERGEBNIS 5")
        #expect(e.prompt.contains("Vorige Frage: Was ist ein Zonk?"))
        #expect(e.prompt.contains("Neue Frage: Und dann?"))
        #expect(e.prompt.contains("FAKTEN\nERGEBNIS 5"))
        #expect(e.prompt.hasSuffix("AKTUELLER ZUG: 100 Punkte"))
    }
}

struct RegelChatMotorTests {
    @Test func direktAntwortOhneModell() async throws {
        let w = beispielWissen(direkt: { $0.contains("Ziel") ? "Ziel sind 500 Punkte." : nil })
        let modell = RegelChatAttrappe()
        let a = try await RegelChatMotor.antworten(frage: "Wie ist das Ziel?", wissen: w, modell: modell)
        #expect(a.weg == .direkt)
        #expect(a.text == "Ziel sind 500 Punkte.")
        #expect(modell.anfragen.isEmpty)
    }

    @Test func modellAntwortMitQuelle() async throws {
        let w = beispielWissen()
        let modell = RegelChatAttrappe(antworten: [.init(stichwort: "zonk", text: "Ein Zonk ist eine Niete: Alle Punkte des Zugs sind weg.")])
        let a = try await RegelChatMotor.antworten(frage: "Was ist ein Zonk?", wissen: w, modell: modell)
        #expect(a.weg == .modell)
        #expect(a.quellen.first == "Niete")
        #expect(modell.anfragen.count == 1)
        #expect(modell.anfragen[0].prompt.contains("Zonk"))
    }

    @Test func faktenKommenInDenPrompt() async throws {
        let w = beispielWissen(zusatz: { _ in "ERGEBNIS 250 Punkte." })
        let modell = RegelChatAttrappe(standard: "Das sind 250 Punkte.")
        let a = try await RegelChatMotor.antworten(frage: "Was zählt das?", wissen: w, modell: modell)
        #expect(a.weg == .modell)
        #expect(modell.anfragen[0].prompt.contains("ERGEBNIS 250 Punkte."))
    }

    @Test func waechterErsetztErfundeneZahl() async throws {
        let w = beispielWissen()
        let modell = RegelChatAttrappe(standard: "Die Strafe beträgt 777 Punkte.")
        let a = try await RegelChatMotor.antworten(frage: "Wie hoch ist die Strafe?", wissen: w, modell: modell)
        #expect(a.weg == .waechter)
        #expect(!a.text.contains("777"))
        #expect(a.text.contains("300"))
        #expect(a.quellen == ["Strafe"])
    }

    @Test func kontextZuGrossWiederholtKnapp() async throws {
        let w = beispielWissen(lang: true)
        let modell = RegelChatAttrappe(standard: "Eine Niete ist ein Wurf ohne Punkte.", fehlerFolge: [.kontextZuGross])
        let a = try await RegelChatMotor.antworten(frage: "Was ist eine Niete?", wissen: w, modell: modell)
        #expect(a.weg == .modell)
        #expect(modell.anfragen.count == 2)
        #expect(modell.anfragen[1].anweisungen.count < modell.anfragen[0].anweisungen.count)
        #expect(modell.anfragen[1].anweisungen.count <= RegelChatGrenzen.knapp.maxZeichenGesamt)
    }

    @Test func inhaltsfilterFaelltAufRegeltextZurueck() async throws {
        let w = beispielWissen()
        let modell = RegelChatAttrappe(fehlerFolge: [.inhaltsfilter])
        let a = try await RegelChatMotor.antworten(frage: "Was kostet die Strafe?", wissen: w, modell: modell)
        #expect(a.weg == .regeltext)
        #expect(a.text.hasPrefix("Laut den Regeln:"))
        #expect(a.text.contains("300"))
    }

    @Test func ohneTrefferUndFehlerWirdGeworfen() async {
        let w = beispielWissen()
        let modell = RegelChatAttrappe(fehlerFolge: [.sonstiger])
        do {
            _ = try await RegelChatMotor.antworten(frage: "xyzzy plugh", wissen: w, modell: modell)
            Issue.record("Fehler erwartet")
        } catch {
            #expect(error as? RegelChatFehler == .sonstiger)
        }
    }

    @Test func spracheWirdWeitergereicht() async {
        let modell = RegelChatAttrappe(fehlerFolge: [.spracheNichtUnterstuetzt])
        do {
            _ = try await RegelChatMotor.antworten(frage: "Was ist ein Zonk?", wissen: beispielWissen(), modell: modell)
            Issue.record("Fehler erwartet")
        } catch {
            #expect(error as? RegelChatFehler == .spracheNichtUnterstuetzt)
            #expect(RegelChatFehler.freundlich(error).contains("Deutsch"))
        }
    }
}

@MainActor
struct RegelChatSitzungTests {
    @Test func fragenUndRueckfrage() async {
        let modell = RegelChatAttrappe(antworten: [.init(stichwort: "zonk", text: "Ein Zonk ist eine Niete.")], standard: "Alle Punkte sind weg.")
        let s = RegelChatSitzung(wissen: beispielWissen(), modell: modell)
        await s.frage("Was ist ein Zonk?")
        await s.frage("  ")
        #expect(s.nachrichten.count == 2)
        #expect(s.nachrichten[1].text == "Ein Zonk ist eine Niete.")
        #expect(s.nachrichten[1].quellen == ["Niete"])
        await s.frage("Und dann?")
        #expect(s.nachrichten.count == 4)
        #expect(modell.anfragen[1].prompt.contains("Vorige Frage: Was ist ein Zonk?"))
        #expect(!s.beschaeftigt)
    }

    @Test func fehlerWirdFreundlichUndNichtAlsVorigeGenutzt() async {
        let modell = RegelChatAttrappe(standard: "Ein Zonk ist eine Niete.", fehlerFolge: [.sonstiger, .sonstiger])
        let s = RegelChatSitzung(wissen: beispielWissen(), modell: modell)
        await s.frage("xyzzy")
        #expect(s.nachrichten.last?.istFehler == true)
        await s.frage("Was ist ein Zonk?")
        #expect(modell.anfragen.last?.prompt.contains("Vorige Frage") == false)
    }
}

struct RegelChatTestlaufTests {
    private let json = """
    {"_hinweis": "x", "fragen": [
      {"id": "a01", "frage": "Was ist ein Zonk?", "regeln": {"ziel": 500, "streng": true},
       "erwartet": "Eine Niete.", "muss_enthalten": ["niete"], "darf_nicht_enthalten": ["777"], "kategorie": "begriff", "abschnitt": "Niete"},
      {"id": "a02", "frage": "Wie hoch ist die Strafe?", "erwartet": "300",
       "muss_enthalten": ["300"], "darf_nicht_enthalten": [], "kategorie": "zahl", "abschnitt": "Strafe"}
    ]}
    """

    @Test func laden() throws {
        let f = try RegelChatTestlauf.laden(data: Data(json.utf8))
        #expect(f.count == 2)
        #expect(f[0].regeln["ziel"] == .int(500))
        #expect(f[0].regeln["streng"] == .bool(true))
        #expect(f[1].regeln.isEmpty)
        #expect(f[1].mussEnthalten == ["300"])
        #expect(f[0].abschnitt == "Niete")
    }

    @Test func bewertung() {
        #expect(RegelChatBewertung.besteht("Das sind 1.000 Punkte.", muss: ["1000"], darfNicht: ["500"]))
        #expect(!RegelChatBewertung.besteht("Das sind 1.250 Punkte.", muss: ["250"], darfNicht: []))
        #expect(RegelChatBewertung.besteht("Nein, das zählt nicht.", muss: ["nein|nicht"], darfNicht: ["ja,"]))
        #expect(!RegelChatBewertung.besteht("Ja, 400 Punkte", muss: ["400"], darfNicht: ["ja,"]))
    }

    @Test func abnahmeGrenze() {
        #expect(RegelChatTestlauf.mindestBestanden(gesamt: 40) == 38)
        #expect(RegelChatTestlauf.mindestBestanden(gesamt: 30) == 29)
    }

    @Test func abschnittsPruefungOhneModell() throws {
        let f = try RegelChatTestlauf.laden(data: Data(json.utf8))
        let r = RegelChatTestlauf.abschnittsPruefung(fragen: f, wissen: { _ in beispielWissen() })
        #expect(r.count == 2)
        #expect(r.allSatisfy { $0.ok }, "\(r)")
    }

    @Test func laufMitAttrappe() async throws {
        let f = try RegelChatTestlauf.laden(data: Data(json.utf8))
        let modell = RegelChatAttrappe(antworten: [.init(stichwort: "zonk", text: "Ein Zonk ist eine Niete."),
                                                   .init(stichwort: "strafe", text: "Die Strafe sind 300 Punkte.")])
        let b = await RegelChatTestlauf.lauf(fragen: f, wissen: { _ in beispielWissen() }, modell: modell)
        #expect(b.gesamt == 2 && b.bestanden == 2)
        #expect(b.zahlenfehler == 0)
        #expect(b.ergebnisse.allSatisfy { $0.quelleRichtig == true })
        #expect(b.tabelle.contains("Bestanden: 2/2"))

        let falsch = RegelChatAttrappe(standard: "Keine Ahnung.")
        let b2 = await RegelChatTestlauf.lauf(fragen: f, wissen: { _ in beispielWissen() }, modell: falsch)
        #expect(b2.bestanden == 0)
        #expect(b2.zahlenfehler == 1)   // a02 (Kategorie „zahl“) verlangt eine Zahl
        #expect(!b2.abnahmeErreicht)
    }
}

struct RegelWissenMarkdownTests {
    @Test func zerlegtAbschnitte() {
        let md = """
        # Spiel (id: x)
        Quellen: a
        ## Ziel
        Wer 500 erreicht, gewinnt.

        ## Niete
        Stichwörter: Zonk, Farkle
        Wurf ohne Punkte.
        """
        let a = RegelWissenMarkdown.abschnitte(aus: md)
        #expect(a.map(\.titel) == ["Ziel", "Niete"])
        #expect(a[0].text == "Wer 500 erreicht, gewinnt.")
        #expect(a[1].stichwoerter == ["Zonk", "Farkle"])
        #expect(a[1].text == "Wurf ohne Punkte.")
    }
}

struct RegelChatWortgleichTests {
    @Test func eigeneAnweisungenGehenWortgleichInDenPrompt() {
        let w = RegelWissenWortgleich()
        let e = RegelChatPrompt.bauen(frage: "Frage?", wissen: w, zusatz: "FAKTEN DER APP: x")
        #expect(e.anweisungen == "EIGEN\n\nREGELN-KURZ\n\nBEGRIFFE\n- a\n\nBEISPIELE\n- b")
        #expect(e.prompt == "Frage?\n\nFAKTEN DER APP: x")
    }
}

private struct RegelWissenWortgleich: RegelWissen {
    let spielID = "w"
    let name = "W"
    let abschnitte: [RegelAbschnitt] = []
    let eigeneAnweisungen: String? = "EIGEN"
    let aktiveRegeln = "REGELN-KURZ"
    let begriffe = "BEGRIFFE\n- a"
    let beispiele = "BEISPIELE\n- b"
}
