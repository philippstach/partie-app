// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

/// Lädt die gemeinsamen Regeltests aus `Shared/regeltests` (dieselben wie bei Android).
/// Fehlt der Ordner, ist das ein Fehler und kein Überspringen.
enum Regeltests {
    typealias JSON = [String: Any]

    /// `iOS/LudoTests/Regeltests.swift` → drei Ebenen hoch ist die Repo-Wurzel.
    static var ordner: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Shared/regeltests")
    }

    static func laden(_ name: String) throws -> JSON {
        let url = ordner.appending(path: name)
        let daten = try Data(contentsOf: url)
        return try #require(JSONSerialization.jsonObject(with: daten) as? JSON)
    }

    static func partien() throws -> [(name: String, json: JSON)] {
        let dateien = try FileManager.default.contentsOfDirectory(at: ordner.appending(path: "partien"),
                                                                  includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.sorted { $0.path < $1.path }
        return try dateien.map { ($0.lastPathComponent, try laden("partien/" + $0.lastPathComponent)) }
    }

    static func decode<T: Decodable>(_ typ: T.Type, _ d: Any?) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: try #require(d), options: [.fragmentsAllowed]))
    }

    static func optionen(_ d: Any?) throws -> Optionen {
        try decode(Optionen.self, d ?? [String: Any]())
    }
}

extension Array where Element == [String: Any] {
    init(_ any: Any?) { self = (any as? [[String: Any]]) ?? [] }
}

@Suite("Regeltests")
struct RegeltestsTests {
    typealias JSON = Regeltests.JSON

    @Test func ordnerVorhanden() throws {
        #expect(FileManager.default.fileExists(atPath: Regeltests.ordner.appending(path: "zuege.json").path))
    }

    @Test func zuege() throws {
        let root = try Regeltests.laden("zuege.json")
        let faelle = [JSON](root["faelle"])
        #expect(faelle.count >= 30)
        for f in faelle {
            let lage = try Regeltests.decode(Lage.self, f["lage"])
            let opt = try Regeltests.optionen(f["optionen"])
            let p = f["spieler"] as! Int, w = f["augen"] as! Int
            let soll = f["erwartet"] as! JSON
            #expect(lage.alleZuege(p, w, opt) == (try Regeltests.decode([Zug].self, soll["alle"])), "alle: \(f["name"] ?? "")")
            #expect(lage.moeglicheZuege(p, w, opt) == (try Regeltests.decode([Zug].self, soll["erlaubt"])), "erlaubt: \(f["name"] ?? "")")
        }
        let bl = [JSON](root["blockiert"])
        #expect(bl.count >= 7)
        for f in bl {
            let lage = try Regeltests.decode(Lage.self, f["lage"])
            let opt = try Regeltests.optionen(f["optionen"])
            #expect(lage.blockiert(f["spieler"] as! Int, opt) == (f["erwartet"] as! Bool), "blockiert: \(f["name"] ?? "")")
        }
    }

    @Test func spielzug() throws {
        let faelle = [JSON](try Regeltests.laden("spielzug.json")["faelle"])
        #expect(faelle.count >= 10)
        for f in faelle {
            var lage = try Regeltests.decode(Lage.self, f["lage"])
            let opt = try Regeltests.optionen(f["optionen"])
            let p = f["spieler"] as! Int
            var quelle = ListenQuelle(f["wuerfel"] as! [Int])
            var zug = Spielzug(spieler: p)
            // Gewählt wird immer der erste erlaubte Zug.
            var schritte = 0
            while zug.stand != .ende && schritte < 100 {
                schritte += 1
                if zug.stand == .vorWurf { zug.wuerfeln(lage, opt, &quelle) }
                else if zug.stand == .verfallen { zug.weiter() }
                else { zug.waehle(zug.erlaubt[0], &lage, opt) }
            }
            let soll = f["erwartet"] as! JSON
            let name = "\(f["name"] ?? "")"
            #expect(zug.wuerfe == (try Regeltests.decode([Wurf].self, soll["wuerfe"])), "wuerfe: \(name)")
            #expect(quelle.verbraucht == soll["verbraucht"] as? Int, "verbraucht: \(name)")
            #expect(lage.figuren == (try Regeltests.decode([[Int]].self, soll["figuren"])), "figuren: \(name)")
            #expect(lage.fertig(p) == (soll["fertig"] as? Bool), "fertig: \(name)")
            #expect(!quelle.ueberzogen, "\(name)")
        }
    }

    @Test func computer() throws {
        let faelle = [JSON](try Regeltests.laden("computer.json")["faelle"])
        #expect(faelle.count >= 40)
        for f in faelle {
            let lage = try Regeltests.decode(Lage.self, f["lage"])
            let opt = try Regeltests.optionen(f["optionen"])
            let p = f["spieler"] as! Int, w = f["augen"] as! Int
            let soll = f["erwartet"] as! JSON
            let name = "\(f["name"] ?? "")"
            let erlaubt = lage.moeglicheZuege(p, w, opt)
            #expect(erlaubt == (try Regeltests.decode([Zug].self, soll["erlaubt"])), "erlaubt: \(name)")
            #expect(erlaubt.map { Computer.bewerteGut(lage, p, $0) } == soll["gutWerte"] as? [Int], "gutWerte: \(name)")
            #expect(Computer.entscheide(.einfach, lage, p, erlaubt) == (try Regeltests.decode(Zug.self, soll["einfach"])), "einfach: \(name)")
            #expect(Computer.entscheide(.gut, lage, p, erlaubt) == (try Regeltests.decode(Zug.self, soll["gut"])), "gut: \(name)")
        }
    }

    @Test func brett() throws {
        let b = try Regeltests.laden("brett.json")
        #expect(b["raster"] as? Int == Brettgeometrie.raster)
        func punkte(_ a: Any?) -> [Rasterpunkt] { (a as! [[Int]]).map { Rasterpunkt(x: $0[0], y: $0[1]) } }
        #expect(punkte(b["laufbahn"]) == Brettgeometrie.laufbahn)
        let haus = b["haus"] as! [[[Int]]], ziel = b["ziel"] as! [[[Int]]]
        for s in 0 ..< 4 {
            #expect(punkte(haus[s]) == Brettgeometrie.haus[s])
            #expect(punkte(ziel[s]) == Brettgeometrie.ziel[s])
        }
        #expect(b["start"] as? [Int] == Brettgeometrie.start)
        #expect(Set(Brettgeometrie.laufbahn).count == 40)
    }
}
