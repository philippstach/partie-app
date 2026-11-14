// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSchocken

/// Zusatzfunktionen aus SPEZIFIKATION 13: Hinweise (F6), Spieleabend (F8), Würfel-Stile (F9).
@Suite("Zusatz")
struct ZusatzTests {
    typealias JSON = Regeltests.JSON

    @Test func hinweise() throws {
        let root = try Regeltests.laden("hinweise.json")
        #expect(Hinweise.ids == root["reihenfolge"] as? [String])
        #expect(Hinweise.gefuehrtStart == root["gefuehrtStart"] as? [Int])
        let faelle = [JSON](root["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            var gezeigt = Set<String>()
            for (i, schritt) in [JSON](f["schritte"]).enumerated() {
                let e = try Regeltests.decode(HinweisEreignis.self, schritt["ereignis"]!)
                let ist = Hinweise.naechster(e, gezeigt: gezeigt, an: schritt["an"] as? Bool ?? true)
                #expect(ist == schritt["erwartet"] as? String, "\(f["name"] ?? "") Schritt \(i)")
                if let ist { gezeigt.insert(ist) }
            }
        }
    }

    @Test func abend() throws {
        let root = try Regeltests.laden("abend.json")
        #expect(root["pauseSekunden"] as? Int == Abend.pauseSekunden)
        let faelle = [JSON](root["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            var a = Abend()
            for (i, s) in [JSON](f["schritte"]).enumerated() {
                let tag = "\(f["name"] ?? "") Schritt \(i)"
                if s["typ"] as? String == "neuerAbend" {
                    a.neu()
                } else {
                    a.partieBeendet(zeit: s["zeit"] as! Int, spieler: s["spieler"] as! [String],
                                    verlierer: s["verlierer"] as! String, haelftenVerlierer: s["haelftenVerlierer"] as! [String])
                }
                let soll = s["erwartet"] as! JSON
                #expect(a.partien == soll["partien"] as? Int, "\(tag)")
                #expect(a.karteZeigen == soll["karteZeigen"] as? Bool, "\(tag)")
                let bilanz = [JSON](soll["bilanz"]).map {
                    Abend.Zeile(name: $0["name"] as! String, partien: $0["partien"] as! Int,
                                partienVerloren: $0["partienVerloren"] as! Int, haelftenVerloren: $0["haelftenVerloren"] as! Int)
                }
                #expect(a.bilanz == bilanz, "\(tag)")
            }
        }
    }

    @Test func abendFehlendeFelderUndRundreise() throws {
        let leer = try JSONDecoder().decode(Abend.self, from: Data("{}".utf8))
        #expect(leer == Abend())
        var a = Abend()
        a.partieBeendet(zeit: 10, spieler: ["A", "B"], verlierer: "A", haelftenVerlierer: ["A", "B"])
        #expect(try JSONDecoder().decode(Abend.self, from: JSONEncoder().encode(a)) == a)
    }

    @Test func stilUnbekanntWirdKlassisch() {
        #expect(WuerfelStil(rawValue: "irgendwas") == nil)
        #expect(WuerfelStil(rawValue: "gold") == .gold)
        let defaults = UserDefaults(suiteName: "schocken-test-stil")!
        defaults.removePersistentDomain(forName: "schocken-test-stil")
        defaults.set("unbekannt", forKey: "wuerfelStil")
        #expect(AppPreferences(defaults: defaults).wuerfelStil == .klassisch)
    }

    /// Standard bei frischer Installation: Töne, Vibration, Schütteln, Hilfen und Hinweise an, Animationen nicht reduziert.
    @Test func einstellungenStandardwerte() {
        let defaults = UserDefaults(suiteName: "schocken-test-standard")!
        defaults.removePersistentDomain(forName: "schocken-test-standard")
        let p = AppPreferences(defaults: defaults)
        #expect(p.schuetteln && p.hilfen && p.hinweise)
        #expect(!p.reduceAnimations)
        #expect(p.tempo == .normal && p.wuerfelStil == .klassisch && p.hausregeln == .standard)
    }
}

@Suite("Auszeichnungen")
struct AuszeichnungenTests {
    typealias JSON = Regeltests.JSON

    /// `auszeichnungen.json` (SPEZIFIKATION 14.2)
    @Test func auszeichnungenFaelle() throws {
        let faelle = [JSON](try Regeltests.laden("auszeichnungen.json")["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            var werte: [String: (schockAus: Int, deckel: Int)] = [:]
            for (name, w) in f["werte"] as! [String: JSON] { werte[name] = (w["schockAus"] as! Int, w["deckel"] as! Int) }
            let ist = Abend.auszeichnungen(werte: werte, partien: f["partien"] as! Int)
            let soll = [JSON](f["erwartet"]).map { Abend.Auszeichnung(id: $0["id"] as! String, namen: $0["namen"] as! [String], wert: $0["wert"] as! Int) }
            #expect(ist == soll, "\(f["name"] ?? "")")
        }
    }

    @Test func abendZaehltSchockAusUndDeckel() {
        var a = Abend()
        a.partieBeendet(zeit: 0, spieler: ["A", "B"], verlierer: "A", haelftenVerlierer: ["A"], schockAus: ["B": 1], deckel: ["A": 13, "B": 4])
        a.partieBeendet(zeit: 60, spieler: ["A", "B"], verlierer: "B", haelftenVerlierer: ["B"], schockAus: ["B": 1], deckel: ["A": 2, "B": 13])
        #expect(a.eintraege["B"]?.schockAus == 2 && a.eintraege["A"]?.deckel == 15)
        #expect(a.auszeichnungen.map(\.id) == ["schockKoenig", "pechvogel", "glueckspilz"])
        #expect(a.auszeichnungen[0].namen == ["B"])
        // alte Datei ohne die neuen Felder lädt mit 0
        let alt = try? JSONDecoder().decode(Abend.Eintrag.self, from: Data(#"{"partien":2}"#.utf8))
        #expect(alt?.schockAus == 0 && alt?.deckel == 0)
    }
}

@Suite("Hälfte vorbei")
struct HaelfteGeschichteTests {
    @Test func kurveUndHintenAb() {
        func runde(_ stand: [Int]) -> RundenEintrag {
            RundenEintrag(beginner: 0, zuege: [], verlierer: 0, gewinner: 0, deckel: 1, ausStock: true, stock: 0, stand: stand, raus: [])
        }
        let v = HaelftenVerlauf(art: .haelfte1, spieler: [0, 1, 2],
                                runden: [runde([1, 0, 0]), runde([1, 2, 0]), runde([1, 4, 3]), runde([2, 4, 7]), runde([2, 4, 13])])
        #expect(v.kurve(2) == [0, 0, 0, 3, 7, 13])
        #expect(v.liegtHintenAb(2) == 4)          // ab Runde 4 ununterbrochen die meisten Deckel
    }
}
