// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSchocken

/// Lädt die gemeinsamen Regeltests aus `Shared/regeltests` (dieselben wie bei Android).
/// Fehlt der Ordner, ist das ein Fehler und kein Überspringen.
enum Regeltests {
    typealias JSON = [String: Any]

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

    static func optionen(_ d: Any?) throws -> Optionen {
        let daten = try JSONSerialization.data(withJSONObject: d ?? [:])
        return try JSONDecoder().decode(Optionen.self, from: daten)
    }

    static func decode<T: Decodable>(_ typ: T.Type, _ d: Any) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
    }

    static func wertung(_ d: Any?) throws -> Wertung { try decode(Wertung.self, try #require(d)) }
}

extension Array where Element == [String: Any] {
    init(_ any: Any?) { self = (any as? [[String: Any]]) ?? [] }
}

@Suite("Regeltests")
struct RegeltestsTests {
    typealias JSON = Regeltests.JSON

    @Test func wertung() throws {
        let root = try Regeltests.laden("wertung.json")
        let faelle = [JSON](root["faelle"])
        #expect(faelle.count >= 100)
        for f in faelle {
            let opt = try Regeltests.optionen(f["optionen"])
            let ist = werte(f["wuerfel"] as! [Int], ausEinemWurf: f["ausEinemWurf"] as! Bool, optionen: opt)
            #expect(ist == (try Regeltests.wertung(f["erwartet"])), "\(f)")
        }
        // Rangfolge: aus einem Wurf von schlecht nach gut
        let rang = try #require(root["rangfolge"] as? JSON)
        for (schluessel, opt) in [("standard", Optionen.standard), ("jule", Optionen(jule: true))] {
            let liste = [JSON](rang[schluessel])
            #expect(!liste.isEmpty)
            var vorher: Schluessel?
            for e in liste {
                let w = werte(e["beispiel"] as! [Int], ausEinemWurf: true, optionen: opt)
                #expect(w.art.rawValue == e["art"] as? String && w.hoehe == e["hoehe"] as? Int && w.deckel == e["deckel"] as? Int)
                if let v = vorher { #expect(v < w.schluessel) }
                vorher = w.schluessel
            }
        }
    }

    @Test func vergleich() throws {
        let faelle = [JSON](try Regeltests.laden("vergleich.json")["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            let a = try Regeltests.decode(Ergebnis.self, f["a"]!)
            let b = try Regeltests.decode(Ergebnis.self, f["b"]!)
            #expect(istBesser(a, b) == (f["aBesser"] as! Bool), "\(f["name"] ?? "")")
            #expect(!istBesser(b, a) || !(f["aBesser"] as! Bool), "\(f["name"] ?? "")")
        }
    }

    @Test func zug() throws {
        let root = try Regeltests.laden("zug.json")
        let faelle = [JSON](root["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            let opt = try Regeltests.optionen(f["optionen"])
            let ist = weiterErlaubt(draussen: f["draussen"] as! [Int], wurf: f["wurf"] as! [Int],
                                    wuerfe: f["wuerfe"] as! Int, maxWuerfe: f["maxWuerfe"] as! Int,
                                    herauslegen: (f["herauslegen"] as! [Int]).sorted(), umdrehen: f["umdrehen"] as! Int, optionen: opt)
            #expect(ist == (f["erlaubt"] as! Bool), "\(f["name"] ?? "")")
        }
        let listen = [JSON](root["moeglicheZuege"])
        #expect(!listen.isEmpty)
        for f in listen {
            let opt = try Regeltests.optionen(f["optionen"])
            let ist = moeglicheZuege(draussen: f["draussen"] as! [Int], wurf: f["wurf"] as! [Int],
                                     wuerfe: f["wuerfe"] as! Int, maxWuerfe: f["maxWuerfe"] as! Int, optionen: opt)
            let soll = [JSON](f["zuege"]).map { Zugwahl(herauslegen: $0["herauslegen"] as! [Int], umdrehen: $0["umdrehen"] as! Int) }
            #expect(ist == soll, "\(f)")
        }
    }

    @Test func runde() throws {
        let faelle = [JSON](try Regeltests.laden("runde.json")["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            let name = f["name"] as? String ?? ""
            let opt = try Regeltests.optionen(f["optionen"])
            let vorher = f["vorher"] as! JSON
            let deckel = vorher["deckel"] as! [Int]
            var h = Haelfte(art: .haelfte1, spieler: Array(deckel.indices), beginner: 0, optionen: opt)
            h.stock = vorher["stock"] as! Int
            h.deckel = deckel
            let ergebnisse: [(spieler: Int, ergebnis: Ergebnis)] = [JSON](f["ergebnisse"]).enumerated().map { i, e in
                let w = werte(e["wuerfel"] as! [Int], ausEinemWurf: e["ausEinemWurf"] as! Bool, optionen: opt)
                return (i, Ergebnis(wertung: w, wuerfe: e["wuerfe"] as! Int, position: i))
            }
            let soll = f["erwartet"] as! JSON
            let a = werteRunde(ergebnisse, haelfte: h)
            h.wendeAn(a)
            #expect(a.verlierer == soll["verlierer"] as? Int, "\(name)")
            #expect(a.gewinner == soll["gewinner"] as? Int, "\(name)")
            #expect(a.deckel == soll["deckel"] as? Int, "\(name)")
            #expect(a.ausStock == soll["ausStock"] as? Bool, "\(name)")
            #expect(a.schockAus == soll["schockAus"] as? Bool, "\(name)")
            #expect(h.stock == soll["stock"] as? Int, "\(name)")
            #expect(h.stand == soll["stand"] as? [Int], "\(name)")
            #expect(h.raus == soll["raus"] as? [Int], "\(name)")
            #expect(h.verlierer == soll["haelfteVerlierer"] as? Int, "\(name)")
        }
    }

    @Test func ablauf() throws {
        let faelle = [JSON](try Regeltests.laden("ablauf.json")["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            let opt = try Regeltests.optionen(f["optionen"])
            let soll = f["erwartet"] as! JSON
            let ist = partieAblauf(haelftenVerlierer: f["haelftenVerlierer"] as! [Int], optionen: opt)
            #expect(ist.naechste?.rawValue == soll["naechste"] as? String, "\(f)")
            #expect(ist.verlierer == soll["verlierer"] as? Int, "\(f)")
            #expect(ist.finaleSpieler == soll["finaleSpieler"] as? [Int], "\(f)")
        }
    }

    static func lage(_ f: JSON) throws -> Lage {
        let opt = try Regeltests.optionen(f["optionen"])
        let ref = try (f["zuSchlagen"] as? JSON).map { try Regeltests.decode(Ergebnis.self, $0) }
        return Lage(draussen: f["draussen"] as! [Int], wurf: f["wurf"] as! [Int], wuerfe: f["wuerfe"] as! Int,
                    maxWuerfe: f["maxWuerfe"] as! Int, ziel: Ziel(ref: ref, position: f["position"] as! Int), optionen: opt)
    }

    @Test func computer() throws {
        let root = try Regeltests.laden("computer.json")
        let faelle = [JSON](root["faelle"])
        #expect(!faelle.isEmpty)
        for f in faelle {
            let lage = try Self.lage(f)
            let einfach = try Regeltests.decode(Aktion.self, f["einfach"]!)
            let gut = try Regeltests.decode(Aktion.self, f["gut"]!)
            #expect(Computer.entscheide(.einfach, lage) == einfach, "einfach \(f)")
            #expect(Computer.entscheide(.gut, lage) == gut, "gut \(f)")
            let werte = Computer.bewerteGut(lage)
            let besterWert = werte.map(\.nutzen).max()!
            #expect(abs(besterWert - (f["gutWert"] as! Double)) < 1e-6, "gutWert \(f)")
        }
        for p in [JSON](root["perzentil"]) {
            let s = p["schluessel"] as! JSON
            let art = try #require(WertungsArt(rawValue: s["art"] as! String))
            let ist = Computer.perzentil(Schluessel(rang: art.rang, hoehe: s["hoehe"] as! Int), optionen: .standard)
            #expect(abs(ist - (p["perzentil"] as! Double)) < 1e-9, "\(p)")
        }
    }
}
