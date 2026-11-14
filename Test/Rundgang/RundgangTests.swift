// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest

/// UI-Rundgang: erzeugt per `xcodebuild test` automatisch Screenshots (XCTAttachment) aller Spiele, Einstellungen und Startseiten.
/// Variationen laufen über Launch-Argumente (siehe App/Rundgang.swift). Dateiname je Bild: Spiel_Design_Modus_Schrift_Schritt.
/// Umfang steuert die Umgebungsvariable RUNDGANG_UMFANG: "voll" (Standard), "kurz" (nur Klar & Glas hell, normale Schrift).
/// Export nach ~/Ergebnisse: Werkzeug/rundgang.sh.
final class RundgangTests: XCTestCase {
    struct Variante {
        let design: String, dunkel: Bool, gross: Bool
        var name: String { "\(design)_\(dunkel ? "dunkel" : "hell")_\(gross ? "gross" : "normal")" }
        var schriftKuerzel: String { gross ? "gross" : "normal" }
    }

    static let spiele = ["solitaer", "maumau", "schwimmen", "elferraus", "romme", "mogeln", "siebzehnundvier", "herzensjagd",
                         "yacht", "schocken", "10k", "maexchen", "chicago", "pokerwurf", "koenigsweg",
                         "sudoku", "minensuche", "kakuro", "schiebepuzzle", "irrgang", "farbflut",
                         "viererreihe", "rauswurf", "muehle", "galgenmaennchen", "wortpfeil"]
    /// Spiele, die im Katalog unter einer Speicherkennung „…-neu“ stehen (SpielKatalog.frueher); `-startetMit` braucht diese Kennung.
    static let neuKennung: Set<String> = ["yacht", "schocken", "rauswurf", "sudoku", "viererreihe", "galgenmaennchen", "solitaer",
                                          "10k", "fuchsjagd", "elferraus", "maumau", "schwimmen"]
    static func katalogID(_ id: String) -> String { neuKennung.contains(id) ? id + "-neu" : id }

    /// RUNDGANG_DESIGN=klar|tinte|salon schränkt auf ein Design ein (Läufe je Design nach einem gemeinsamen Bau).
    static var designs: [String] {
        let alle = ["klar", "tinte", "salon"]
        if let d = ProcessInfo.processInfo.environment["RUNDGANG_DESIGN"], alle.contains(d) { return [d] }
        return alle
    }

    static var kurz: Bool { ProcessInfo.processInfo.environment["RUNDGANG_UMFANG"] == "kurz" }

    /// Spiele: 3 Designs x hell/dunkel in normaler Schrift, dazu größte Schrift in Klar & Glas (hell) und Salon (dunkel).
    static var spielVarianten: [Variante] {
        if kurz { return [Variante(design: designs[0], dunkel: false, gross: false)] }
        var v = designs.flatMap { d in [false, true].map { Variante(design: d, dunkel: $0, gross: false) } }
        v.append(Variante(design: designs.contains("klar") ? "klar" : designs[0], dunkel: false, gross: true))
        if designs.count > 1 { v.append(Variante(design: "salon", dunkel: true, gross: true)) }
        return v
    }
    /// Startseiten und Einstellungen: alle 12 Kombinationen.
    static var alleVarianten: [Variante] {
        if kurz { return [Variante(design: "klar", dunkel: false, gross: false)] }
        return designs.flatMap { d in [false, true].flatMap { h in [false, true].map { Variante(design: d, dunkel: h, gross: $0) } } }
    }

    override func setUp() { continueAfterFailure = true; bericht = [] }

    /// Ergebnis je Schritt: OK oder FEHLT (mit Testfehler, damit der Lauf rot wird). Am Ende als Text `bericht_<Test>` angehängt.
    var bericht: [String] = []
    func erwarte(_ ok: Bool, _ schritt: String, _ was: String) {
        bericht.append("\(ok ? "OK    " : "FEHLT ") \(schritt): \(was)")
        if !ok { XCTFail("\(schritt): \(was)") }
    }
    override func tearDown() {
        let a = XCTAttachment(string: bericht.joined(separator: "\n"))
        a.name = "bericht_\(name.replacingOccurrences(of: " ", with: "_").filter { $0.isLetter || $0.isNumber || $0 == "_" })"
        a.lifetime = .keepAlways
        add(a)
    }

    // MARK: Werkzeug

    func starten(_ v: Variante, spiel: String? = nil, einfuehrung: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        var a = ["-rundgang", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE",
                 "-design.art", v.design, "-darstellung", v.dunkel ? "dunkel" : "hell"]
        if v.gross { a += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        if let spiel { a += ["-startetMit", Self.katalogID(spiel)] }
        if einfuehrung { a += ["-rundgangEinfuehrung"] }
        app.launchArguments = a
        app.launch()
        return app
    }

    func foto(_ app: XCUIApplication, _ teile: String...) {
        let name = teile.joined(separator: "_")
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    /// Tippt den ersten vorhandenen Knopf aus der Liste (Beschriftung, auch Teiltreffer), gibt zurück ob etwas getippt wurde.
    @discardableResult
    func tippe(_ app: XCUIApplication, _ titel: [String], warte: TimeInterval = 1.5) -> Bool {
        for t in titel {
            var b = app.buttons[t].firstMatch
            if !b.waitForExistence(timeout: warte) {
                b = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", t)).firstMatch
                if !b.exists { continue }
            }
            if b.isHittable { b.tap() } else { b.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
            return true
        }
        return false
    }

    /// Rückfall: der unterste Knopf im unteren Drittel (der Hauptknopf der Tafel).
    @discardableResult
    func tippeUntersten(_ app: XCUIApplication) -> Bool {
        let grenze = app.frame.height * 0.6
        let kandidaten = app.buttons.allElementsBoundByIndex.filter { $0.exists && $0.frame.minY > grenze && $0.frame.width > app.frame.width * 0.5 }
        guard let k = kandidaten.max(by: { $0.frame.minY < $1.frame.minY }) else { return false }
        k.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return true
    }

    /// Textanhang (billig, ohne Bild): alle Knöpfe und Texte der Ansicht, damit Lücken ohne Fotos zu analysieren sind.
    func protokoll(_ app: XCUIApplication, _ name: String, _ zusatz: String = "") {
        let knoepfe = app.buttons.allElementsBoundByIndex.prefix(40).map { "[\($0.identifier)|\($0.label)] hittable=\($0.isHittable)" }
        let a = XCTAttachment(string: "\(zusatz)\n" + knoepfe.joined(separator: "\n"))
        a.name = "protokoll_" + name
        a.lifetime = .keepAlways
        add(a)
    }

    /// Das Neues-Spiel-Blatt ist offen, solange sein Schließen-Kreuz da ist (im Spiel selbst gibt es keins).
    func blattOffen(_ app: XCUIApplication) -> Bool { app.buttons["Schließen"].exists }

    /// Trägt in das erste leere Namensfeld einen Namen ein; false, wenn es keins gibt.
    func fuelleLeeresNamensfeld(_ app: XCUIApplication, _ name: String) -> Bool {
        for f in app.textFields.allElementsBoundByIndex where f.exists {
            let w = (f.value as? String) ?? ""
            if w.isEmpty || w == "Name" || w == (f.placeholderValue ?? "?") {
                f.tap(); f.typeText(name + "\n"); return true
            }
        }
        return false
    }

    // MARK: Spiele

    /// Tinte (ab Build 23): Die Spielseite hat KEIN „Neues Spiel“-Blatt mehr, sondern unten einen Hauptknopf. Ohne laufende Partie heißt er
    /// „Spielen“. Mit laufender Partie heißt er „Weiterspielen“, darüber steht klein „Neue Partie beginnen“ (fragt „Laufende Partie
    /// verwerfen?“, Antwort „Neu starten“). Spieler und Regeln stehen auf der Seite selbst. Klar und Salon bleiben beim Blatt „Neues Spiel“.
    func spieleStartTinte(_ app: XCUIApplication, _ m: [String], _ tag: String) {
        let weiter = app.buttons["Weiterspielen"]
        if weiter.waitForExistence(timeout: 2) {
            // Eine Partie aus einem früheren Lauf ist noch gespeichert: Weiterspielen-Seite fotografieren, dann bewusst neu beginnen.
            foto(app, (m + ["1b-weiterspielen"]).joined(separator: "_"))
            protokoll(app, (m + ["1b-weiterspielen"]).joined(separator: "_"))
            erwarte(app.buttons["Neue Partie beginnen"].exists, tag + " 1b", "„Neue Partie beginnen“ steht neben „Weiterspielen“")
            erwarte(!app.buttons["Spielen"].exists, tag + " 1b", "nur EIN Hauptknopf (kein „Spielen“ neben „Weiterspielen“)")
            if tippe(app, ["Neue Partie beginnen"], warte: 1) {
                sleep(1)
                foto(app, (m + ["1c-rueckfrage"]).joined(separator: "_"))
                erwarte(tippe(app, ["Neu starten"], warte: 2), tag + " 1c", "Rückfrage „Laufende Partie verwerfen?“ beantwortet")
            }
        } else {
            erwarte(app.buttons["Spielen"].exists, tag + " 2", "Hauptknopf „Spielen“ da")
            erwarte(!app.buttons["Neues Spiel"].exists, tag + " 2", "kein „Neues Spiel“-Knopf mehr (Tinte)")
            if !tippe(app, ["Spielen"], warte: 2) { return }
            sleep(1)
            // Nur wenn doch ein Stand lag (Spielstand ohne Weiterspielen-Knopf wäre ein Fehler): Rückfrage wegtippen und melden.
            if app.buttons["Neu starten"].waitForExistence(timeout: 1) {
                erwarte(false, tag + " 2", "Rückfrage nach „Spielen“, obwohl „Weiterspielen“ nicht angezeigt war")
                tippe(app, ["Neu starten"], warte: 1)
            }
        }
        sleep(2)
        erwarte(!blattOffen(app), tag + " 3", "kein Blatt offen, Spiel läuft")
        erwarte(!app.buttons["Spielen"].exists && !app.buttons["Weiterspielen"].exists, tag + " 3", "Spielseite verlassen (Spielansicht)")
        foto(app, (m + ["3-spielansicht"]).joined(separator: "_"))
        if tippe(app, ["Heute spielen"], warte: 1) { sleep(2); foto(app, (m + ["3b-brett"]).joined(separator: "_")) }
        if tippe(app, ["Bereit", "Ich bin", "Los", "Weiter"], warte: 1) { sleep(1); foto(app, (m + ["4-am-zug"]).joined(separator: "_")) }
        protokoll(app, (m + ["3-spielansicht"]).joined(separator: "_"))
    }

    /// Klar und Salon: Starttafel mit „Neues Spiel“ (Blatt mit Spielern, Stufe, Regeln und „Los geht's“).
    func spieleStartBlatt(_ app: XCUIApplication, _ m: [String], _ tag: String, id: String) {
        if tippe(app, ["Neues Spiel"], warte: 2) || tippe(app, ["Leicht"], warte: 1) || tippeUntersten(app) {
            sleep(1)
            foto(app, (m + ["2-neues-spiel"]).joined(separator: "_"))
            protokoll(app, (m + ["2-neues-spiel"]).joined(separator: "_"))
            erwarte(blattOffen(app) || id == "minensuche" || id == "wortpfeil", tag + " 2", "Neues-Spiel-Blatt erschienen")
            // Mehrstufiges Blatt: „Los geht's“/„Weiter“ tippen; bleibt das Blatt offen, Spieler anlegen/benennen und erneut versuchen
            var versuch = 0
            while versuch < 6 {
                versuch += 1
                guard tippe(app, ["Los geht's", "Los geht’s", "Spiel starten", "Starten", "Spielen", "Weiter", "Los"], warte: 1) else { break }
                sleep(2)
                if !blattOffen(app) { break }
                if versuch == 1 { protokoll(app, (m + ["3-blatt-offen"]).joined(separator: "_"), "Blatt blieb offen, lege Spieler an") }
                if !fuelleLeeresNamensfeld(app, "Spieler\(versuch)") { tippe(app, ["Spieler hinzufügen"], warte: 1) }
            }
            erwarte(!blattOffen(app), tag + " 3", "Blatt geschlossen, Spiel läuft")
            // Weitergabe-Bildschirm („Gerät weitergeben“): bestätigen, dann Spielansicht
            foto(app, (m + ["3-spielansicht"]).joined(separator: "_"))
            // Spiele mit eigener Spielwahl (Solitär: Klondike, Spider …): Tagesspiel „Heute spielen“ starten
            if tippe(app, ["Heute spielen"], warte: 1) { sleep(2); foto(app, (m + ["3b-brett"]).joined(separator: "_")) }
            if tippe(app, ["Bereit", "Ich bin", "Los", "Weiter"], warte: 1) { sleep(1); foto(app, (m + ["4-am-zug"]).joined(separator: "_")) }
            protokoll(app, (m + ["3-spielansicht"]).joined(separator: "_"))
        } else {
            erwarte(false, tag + " 2", "kein Startknopf gefunden")
            protokoll(app, (m + ["x-kein-startknopf"]).joined(separator: "_"), "Weder 'Neues Spiel' noch unterster Knopf gefunden")
        }
    }

    func testSpiele() {
        for v in Self.spielVarianten {
            for id in Self.spiele {
                do {
                    let app = starten(v, spiel: id)
                    _ = app.wait(for: .runningForeground, timeout: 10)
                    sleep(1)
                    foto(app, id, v.design, v.dunkel ? "dunkel" : "hell", v.schriftKuerzel, "1-start")
                    let m = [id, v.design, v.dunkel ? "dunkel" : "hell", v.schriftKuerzel]
                    protokoll(app, (m + ["1-start"]).joined(separator: "_"))
                    let tag = m.joined(separator: " ")
                    // Spiel wirklich offen? Auf der Hauptseite gäbe es „Alle Spiele“ / „Startseite anpassen“.
                    erwarte(!app.buttons["Alle Spiele"].exists && !app.buttons["Startseite anpassen"].exists, tag + " 1", "Spiel geöffnet (nicht die Hauptseite)")
                    if v.design == "tinte" { spieleStartTinte(app, m, tag) } else { spieleStartBlatt(app, m, tag, id: id) }
                    app.terminate()
                }
            }
        }
    }

    /// Tinte: Nach einem Neustart der App zeigt die Spielseite einer begonnenen Partie „Weiterspielen“ (Build 23, große Tinte-Runde Punkt 1).
    /// Es wird kein Zug gespielt. Speichert ein Spiel erst nach dem ersten Zug, ist das Fehlen hier nur „INFO“ und kein Fehler.
    func testWeiterspielenTinte() {
        for id in ["yacht", "sudoku", "viererreihe"] {
            let v = Variante(design: "tinte", dunkel: false, gross: false)
            let m = [id, "tinte", "hell", "normal"]
            let tag = m.joined(separator: " ")
            var app = starten(v, spiel: id)
            sleep(1)
            if app.buttons["Weiterspielen"].waitForExistence(timeout: 1) { tippe(app, ["Neue Partie beginnen"], warte: 1); tippe(app, ["Neu starten"], warte: 2) }
            else { tippe(app, ["Spielen"], warte: 2) }
            sleep(2)
            app.terminate()
            app = starten(v, spiel: id)
            sleep(1)
            if app.buttons["Weiterspielen"].waitForExistence(timeout: 3) {
                foto(app, (m + ["5-weiterspielen-nach-neustart"]).joined(separator: "_"))
                erwarte(app.buttons["Neue Partie beginnen"].exists, tag + " 5", "Weiterspielen mit „Neue Partie beginnen“ nach Neustart")
                tippe(app, ["Weiterspielen"], warte: 1); sleep(2)
                erwarte(!app.buttons["Weiterspielen"].exists, tag + " 5", "Weiterspielen öffnet die Partie")
            } else {
                bericht.append("INFO   \(tag) 5: kein „Weiterspielen“ (Spiel speichert erst nach dem ersten Zug)")
            }
            app.terminate()
        }
    }

    // MARK: Startseite

    func testStartseiten() {
        for v in Self.alleVarianten {
            do {
                let app = starten(v)
                sleep(2)
                let m = [v.design, v.dunkel ? "dunkel" : "hell", v.schriftKuerzel]
                foto(app, ([ "start", ] + m + ["1-hauptseite"]).joined(separator: "_"))
                app.swipeUp(); sleep(1)
                foto(app, (["start"] + m + ["2-unten"]).joined(separator: "_"))
                app.swipeDown()
                // Direkte Knöpfe, dann Einträge des Menüs „Zufall und Vorschlag“ (Würfel-Knopf)
                var ziele: [(String, Bool)] = [("Alle Spiele", false), ("Spiel suchen", false), ("Spieler", false),
                                               ("Was spielen wir?", true), ("Spieleabend", true), ("Glossar", true)]
                if Self.kurz { ziele = Array(ziele.prefix(6)) }
                for (titel, imMenue) in ziele {
                    if imMenue { sleep(1); tippe(app, ["Zufall und Vorschlag"], warte: 2); sleep(1) }
                    var gefunden = tippe(app, [titel], warte: 1)
                    if !gefunden && imMenue {   // zweiter Versuch: Menü neu öffnen
                        protokoll(app, "start_\(titel)_menue-erster-versuch")
                        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap(); sleep(2)
                        tippe(app, ["Zufall und Vorschlag"], warte: 2); sleep(1)
                        gefunden = tippe(app, [titel, "Glossar"], warte: 1)
                    }
                    if gefunden {
                        sleep(1)
                        let slug = titel.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "?", with: "")
                        foto(app, (["start"] + m + ["3-\(slug)"]).joined(separator: "_"))
                        erwarte(true, "start \(v.name)", "\(titel) geöffnet")
                        schliessen(app)
                        sleep(1)
                    } else {
                        erwarte(false, "start \(v.name)", "\(titel) nicht gefunden")
                        if imMenue { app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap() }   // Menü zu
                    }
                }
                app.terminate()
            }
        }
    }

    /// Einführung (vier Seiten zum Wischen), nur Klar & Glas hell, dunkel und größte Schrift.
    func testEinfuehrung() {
        let vs = Self.kurz ? [Variante(design: "klar", dunkel: false, gross: false)]
                           : Self.designs.flatMap { d in [Variante(design: d, dunkel: false, gross: false), Variante(design: d, dunkel: true, gross: false)] }
        for v in vs {
            let app = starten(v, einfuehrung: true)
            sleep(2)
            // Die Einführung ist ein scrollbares Blatt mit „Los geht's“ unten: oben, nach dem Scrollen, am Ende.
            erwarte(app.buttons["Los geht’s"].waitForExistence(timeout: 5) || app.buttons["Los geht's"].exists || app.buttons["Weiter"].exists, "einfuehrung \(v.name)", "Einführung sichtbar (Knopf unten)")
            for s in 1...4 {
                foto(app, "einfuehrung", v.design, v.dunkel ? "dunkel" : "hell", v.schriftKuerzel, "seite\(s)")
                app.swipeUp(); sleep(1)
            }
            app.terminate()
        }
    }

    func schliessen(_ app: XCUIApplication) {
        if tippe(app, ["Schließen", "Fertig", "Abbrechen"], warte: 1) { return }
        app.swipeDown(velocity: .fast)
    }

    // MARK: Einstellungen

    func testEinstellungen() {
        for v in Self.alleVarianten {
            do {
                let app = starten(v)
                sleep(2)
                let m = [v.design, v.dunkel ? "dunkel" : "hell", v.schriftKuerzel]
                guard tippe(app, ["Einstellungen"], warte: 3) else {
                    XCTFail("Einstellungen nicht gefunden (\(v.name))"); app.terminate(); continue
                }
                sleep(1)
                foto(app, (["einstellungen"] + m + ["0-uebersicht"]).joined(separator: "_"))
                // Alle Zeilen der Übersicht der Reihe nach öffnen (sie beschriften sich selbst)
                let anzahl = app.cells.count
                erwarte(anzahl > 0, "einstellungen \(v.name)", "Zeilen in der Übersicht gefunden (\(anzahl))")
                for i in 0..<anzahl {
                    let zelle = app.cells.element(boundBy: i)
                    guard zelle.exists, zelle.isHittable else { continue }
                    let titel = zelle.staticTexts.firstMatch.label
                    zelle.tap(); sleep(1)
                    erwarte(app.navigationBars.count > 0 && app.navigationBars.firstMatch.staticTexts.firstMatch.label != "Einstellungen", "einstellungen \(v.name) Zeile \(i + 1) \(titel)", "Unterseite geöffnet")
                    let slug = titel.lowercased().replacingOccurrences(of: " ", with: "-").filter { $0.isLetter || $0 == "-" }
                    foto(app, (["einstellungen"] + m + ["\(i + 1)-\(slug)"]).joined(separator: "_"))
                    // Seite bis unten durchblättern: ein zweites Bild
                    app.swipeUp(); sleep(1)
                    foto(app, (["einstellungen"] + m + ["\(i + 1)-\(slug)-unten"]).joined(separator: "_"))
                    app.navigationBars.buttons.firstMatch.tap(); sleep(1)
                }
                app.terminate()
            }
        }
    }
}
