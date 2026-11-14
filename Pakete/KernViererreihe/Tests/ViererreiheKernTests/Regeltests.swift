// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielViererreihe

/// Lädt die gemeinsamen Regeltests aus `Shared/regeltests` (dieselben wie bei Android).
/// Der Ordner wird über `#filePath` bis zur Repo-Wurzel gesucht. Fehlt er, ist das ein Fehler und kein Überspringen.
enum Regeltests {
    typealias JSON = [String: Any]

    struct OrdnerFehlt: Error, CustomStringConvertible {
        var description: String { "Shared/regeltests nicht gefunden (von \(#filePath) aus aufwärts gesucht)" }
    }

    static func ordner(datei: String = #filePath) throws -> URL {
        if let pfad = ProcessInfo.processInfo.environment["REGELTESTS_ORDNER"] { return URL(fileURLWithPath: pfad) }
        var url = URL(fileURLWithPath: datei).deletingLastPathComponent()
        for _ in 0..<8 {
            let kandidat = url.appending(path: "Shared/regeltests")
            if FileManager.default.fileExists(atPath: kandidat.path) { return kandidat }
            url = url.deletingLastPathComponent()
        }
        throw OrdnerFehlt()
    }

    static func laden(_ name: String) throws -> JSON {
        let daten = try Data(contentsOf: try ordner().appending(path: name))
        return try #require(JSONSerialization.jsonObject(with: daten) as? JSON)
    }

    static func partien() throws -> [(name: String, json: JSON)] {
        let dateien = try FileManager.default.contentsOfDirectory(at: try ordner().appending(path: "partien"),
                                                                  includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.sorted { $0.path < $1.path }
        return try dateien.map { ($0.lastPathComponent, try laden("partien/" + $0.lastPathComponent)) }
    }

    static func faelle(_ root: JSON) -> [JSON] { (root["faelle"] as? [JSON]) ?? [] }

    static func ints(_ any: Any?) -> [Int] { (any as? [Int]) ?? [] }

    static func partie(_ f: JSON) throws -> Partie {
        try Partie(beginner: f["beginner"] as! Int, zuege: ints(f["zuege"]))
    }

    static func zellen(_ any: Any?) -> [Zelle] {
        ((any as? [[Int]]) ?? []).map { Zelle(spalte: $0[0], zeile: $0[1]) }
    }
}

/// Prüft eine Partie gegen das `erwartet` einer Datei (ohne das Text-Bild, das nur zum Lesen da ist).
func pruefe(_ p: Partie, gegen e: [String: Any], _ name: String, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(p.status.rawValue == e["status"] as? String, "\(name): status", sourceLocation: sourceLocation)
    #expect(p.gewinner == e["gewinner"] as? Int, "\(name): gewinner", sourceLocation: sourceLocation)
    #expect(p.gewinnZellen == Regeltests.zellen(e["gewinnZellen"]), "\(name): gewinnZellen", sourceLocation: sourceLocation)
    #expect(p.amZug == e["amZug"] as? Int, "\(name): amZug", sourceLocation: sourceLocation)
    #expect(p.hoehen == Regeltests.ints(e["hoehen"]), "\(name): hoehen", sourceLocation: sourceLocation)
    #expect(p.legaleSpalten == Regeltests.ints(e["legaleSpalten"]), "\(name): legaleSpalten", sourceLocation: sourceLocation)
    if let bild = e["bild"] as? [String] {
        #expect(p.bild == bild, "\(name): bild", sourceLocation: sourceLocation)
    }
}

@Suite("Regeltests")
struct RegeltestsTests {
    typealias JSON = Regeltests.JSON

    @Test func ordnerGefunden() throws {
        _ = try Regeltests.ordner()
    }

    @Test func brett() throws {
        let faelle = Regeltests.faelle(try Regeltests.laden("brett.json"))
        #expect(faelle.count >= 20)
        for f in faelle {
            let name = f["name"] as! String
            let p = try Regeltests.partie(f)
            pruefe(p, gegen: f["erwartet"] as! JSON, name)
        }
    }

    @Test func fehler() throws {
        let faelle = Regeltests.faelle(try Regeltests.laden("fehler.json"))
        #expect(faelle.count >= 4)
        for f in faelle {
            let name = f["name"] as! String
            var p = try Regeltests.partie(f)
            let vorher = p
            let erwartet = (f["erwartet"] as! JSON)["fehler"] as! String
            do {
                try p.einwerfen(f["spalte"] as! Int)
                Issue.record("\(name): kein Fehler")
            } catch let fehler as PartieFehler {
                #expect(fehler.rawValue == erwartet, "\(name)")
            }
            #expect(p == vorher, "\(name): Partie unverändert")
            #expect(p.zuege == Regeltests.ints(f["zuege"]), "\(name): zuege")
        }
    }

    @Test func rueckgaengig() throws {
        let faelle = Regeltests.faelle(try Regeltests.laden("rueckgaengig.json"))
        #expect(faelle.count >= 8)
        for f in faelle {
            let name = f["name"] as! String
            let p = try Regeltests.partie(f)
            let computer = f["computer"] as? Int
            let e = f["erwartet"] as! JSON
            if e["moeglich"] as? Bool == true {
                let neu = try p.rueckgaengig(computer: computer)
                #expect(neu.zuege == Regeltests.ints(e["zuege"]), "\(name): zuege")
                #expect(neu.amZug == e["amZug"] as? Int, "\(name): amZug")
                #expect(p.kannRueckgaengig(computer: computer), "\(name)")
            } else {
                #expect(throws: PartieFehler.nichtMoeglich) { try p.rueckgaengig(computer: computer) }
                #expect(!p.kannRueckgaengig(computer: computer), "\(name)")
            }
        }
    }

    @Test func bewertung() throws {
        let faelle = Regeltests.faelle(try Regeltests.laden("bewertung.json"))
        #expect(faelle.count >= 10)
        #expect(Bewertung.fenster.count == 69)
        for f in faelle {
            let name = f["name"] as! String
            let p = try Regeltests.partie(f)
            let e = f["erwartet"] as! JSON
            let b1 = Bewertung.wert(p, fuer: 1), b2 = Bewertung.wert(p, fuer: 2)
            #expect(b1 == e["spieler1"] as? Int, "\(name): spieler1")
            #expect(b2 == e["spieler2"] as? Int, "\(name): spieler2")
            #expect(b1 == -b2, "\(name): Symmetrie")
        }
    }

    @Test func computer() throws {
        let faelle = Regeltests.faelle(try Regeltests.laden("computer.json"))
        #expect(faelle.count >= 10)
        var mittelFaelle = 0
        for f in faelle {
            let name = f["name"] as! String
            let p = try Regeltests.partie(f)
            let e = f["erwartet"] as! JSON
            var quelle = ListenQuelle(Regeltests.ints(f["zufall"]))
            let stufe = Stufe(rawValue: f["stufe"] as! String)!
            let spalte = Computer.waehle(stufe, p, zufall: &quelle)
            #expect(spalte == e["spalte"] as? Int, "\(name): spalte")
            #expect(quelle.index == e["zufallGezogen"] as? Int, "\(name): zufallGezogen")
            #expect(!quelle.ueberzogen, "\(name): Zufall überzogen")
            if stufe == .mittel {
                mittelFaelle += 1
                let erwartet = (e["werte"] as! [Any]).map { $0 as? Int }
                #expect(Computer.mittelWerte(p) == erwartet, "\(name): werte")
            }
        }
        #expect(mittelFaelle >= 3)
    }

    @Test func zufall() throws {
        let faelle = Regeltests.faelle(try Regeltests.laden("zufall.json"))
        #expect(faelle.count >= 3)
        for f in faelle {
            let seed = try #require(UInt64(f["seed"] as! String))
            let e = f["erwartet"] as! JSON
            var q = SplitMix64(seed: seed)
            for soll in e["weiter"] as! [String] {
                #expect(q.weiter() == UInt64(soll), "seed \(seed)")
            }
            var q2 = SplitMix64(seed: seed)
            let ist = (0..<10).map { _ in q2.naechste(7) }
            #expect(ist == Regeltests.ints(e["naechste7"]), "seed \(seed): naechste7")
            #expect(String(q2.zustand) == e["zustandDanach"] as? String, "seed \(seed): zustandDanach")
        }
    }

    @Test func partien() throws {
        let dateien = try Regeltests.partien()
        #expect(dateien.count >= 5)
        for (name, json) in dateien {
            let e = json["erwartet"] as! JSON
            let zuege = Regeltests.ints(e["zuege"])
            let beginner = json["beginner"] as! Int
            // (a) Nachspielen mit den aufgezeichneten Zügen
            let nachgespielt = try Partie(beginner: beginner, zuege: zuege)
            pruefe(nachgespielt, gegen: e, name + " (a)")
            #expect(nachgespielt.zuege == zuege, "\(name) (a)")
            // (b) Nachspielen mit den Strategien und einer gemeinsamen ListenQuelle
            let strategien = (json["strategien"] as! [String]).map { Stufe(rawValue: $0)! }
            var quelle = ListenQuelle(Regeltests.ints(json["zufall"]))
            var p = try Partie(beginner: beginner)
            var gezogen: [Int] = []
            while p.status == .laeuft && gezogen.count <= 42 {
                let s = Computer.waehle(strategien[p.naechsterSpieler - 1], p, zufall: &quelle)
                try p.einwerfen(s)
                gezogen.append(s)
            }
            #expect(gezogen == zuege, "\(name) (b): Züge")
            pruefe(p, gegen: e, name + " (b)")
            #expect(quelle.aufgebraucht, "\(name) (b): Zufall muss genau aufgehen")
            #expect(!quelle.ueberzogen, "\(name) (b): Zufall überzogen")
        }
    }
}
