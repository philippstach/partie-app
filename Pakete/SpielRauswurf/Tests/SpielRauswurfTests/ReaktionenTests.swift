// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

@Suite("Computer-Reaktionen")
struct ReaktionenTests {
    typealias JSON = Regeltests.JSON

    /// `reaktionen.json`: Für 5 Partien aus `partien/` die Blasen je Spielzug (SPEZ 7.4).
    @Test func regeltestReaktionen() throws {
        let root = try Regeltests.laden("reaktionen.json")
        let faelle = [JSON](root["faelle"])
        #expect(faelle.count >= 5)
        for f in faelle {
            let pfad = f["partie"] as! String
            let p = try Regeltests.laden(pfad)
            let erwartet = [JSON](f["blasen"])
            let zuege = [JSON]((p["erwartet"] as! JSON)["zuege"])
            #expect(erwartet.count == zuege.count, "\(pfad): ein Eintrag je Spielzug")
            let opt = try Regeltests.optionen(p["optionen"])
            var lage = Lage.neu(sitze: p["sitze"] as! [Int], opt)
            var letzte: [Int: String] = [:]
            var gesamt = 0
            for (i, z) in zuege.enumerated() {
                let spieler = z["spieler"] as! Int
                let wuerfe = try Regeltests.decode([Wurf].self, z["wuerfe"])
                let ist = Reaktionen.nachSpielzug(lageVorher: lage, spieler: spieler, wuerfe: wuerfe, letzte: letzte)
                if let e = ist[spieler] { letzte[spieler] = e }
                let soll = (erwartet[i] as [String: Any]).reduce(into: [Int: String]()) { $0[Int($1.key)!] = $1.value as? String }
                #expect(ist == soll, "\(pfad), Spielzug \(i): \(ist) statt \(soll)")
                gesamt += ist.count
                // Lage nach dem Spielzug (aus der Aufzeichnung) für den nächsten
                lage = Lage(sitze: lage.sitze, figuren: try Regeltests.decode([[Int]].self, z["figuren"]))
            }
            #expect(gesamt > 0, "\(pfad): es gibt Blasen")
        }
    }

    @Test func einzelregeln() {
        // 🎉 nur mit gezogener 6, 🙄 nur nach drei Fehlversuchen, Vorrang und keine Wiederholung
        let lage = Lage(sitze: [0, 2], figuren: [[-1, -1, -1, -1], [-1, -1, -1, -1]])
        let sechsGezogen = [Wurf(augen: 6, zug: Zug(von: -1, nach: 0, schlaegt: nil)), Wurf(augen: 3, zug: Zug(von: 0, nach: 3, schlaegt: nil))]
        #expect(Reaktionen.nachSpielzug(lageVorher: lage, spieler: 0, wuerfe: sechsGezogen)[0] == "🎉")
        // dieselbe Blase direkt wieder: keine
        #expect(Reaktionen.nachSpielzug(lageVorher: lage, spieler: 0, wuerfe: sechsGezogen, letzte: [0: "🎉"])[0] == nil)
        let verfallen = [Wurf(augen: 6, zug: nil), Wurf(augen: 2, zug: nil), Wurf(augen: 1, zug: nil)]
        #expect(Reaktionen.nachSpielzug(lageVorher: lage, spieler: 0, wuerfe: verfallen)[0] == "🙄", "verfallene 6 zählt nicht als 🎉")
        let zwei = [Wurf(augen: 2, zug: nil), Wurf(augen: 1, zug: nil)]
        #expect(Reaktionen.nachSpielzug(lageVorher: lage, spieler: 0, wuerfe: zwei).isEmpty)
        // 😎 hat Vorrang vor 🎉, der Geschlagene bekommt immer 😤
        let l2 = Lage(sitze: [0, 1], figuren: [[10, -1, -1, -1], [-1, -1, -1, -1]])
        let l3 = Lage(sitze: [0, 1], figuren: [[10, -1, -1, -1], [30, -1, -1, -1]])
        let schlag = [Wurf(augen: 6, zug: Zug(von: -1, nach: 0, schlaegt: 1))]
        let r = Reaktionen.nachSpielzug(lageVorher: l3, spieler: 0, wuerfe: schlag, letzte: [1: "😤"])
        #expect(r[0] == "😎" && r[1] == "😤")
        _ = l2
    }
}
