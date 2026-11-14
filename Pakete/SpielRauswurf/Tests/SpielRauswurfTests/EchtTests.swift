// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

/// Echte Würfel (SPEZIFIKATION 8.1): eingetippte Zahlen verhalten sich genau wie App-Würfe, die App-Quelle bleibt unberührt.
@Suite("Echte Würfel")
struct EchtTests {
    typealias JSON = Regeltests.JSON

    /// Spielt eine Partie nach. `arten[p] == .echt`: Würfe aus `eingaben`; sonst aus `quelle`. Wählt mit den Strategien oder aufgezeichnet.
    static func spiele(name: String, json p: JSON, arten: [Wuerfelart], appWuerfel: [Int], eingaben: [Int], computer: Bool) throws {
        let opt = try Regeltests.optionen(p["optionen"])
        let sitze = p["sitze"] as! [Int]
        let strategien = (p["strategien"] as! [String]).map { Strategie(rawValue: $0)! }
        var quelle = ListenQuelle(appWuerfel)
        var eingabe = ListenQuelle(eingaben)
        let erwartet = p["erwartet"] as! JSON
        var partie = Partie.neu(sitze: sitze, beginner: p["beginner"] as! Int, optionen: opt)
        var eingetipptGesamt = 0

        for (i, e) in [JSON](erwartet["zuege"]).enumerated() {
            let kopf = "\(name), Spielzug \(i)"
            let spieler = e["spieler"] as! Int
            let soll = try Regeltests.decode([Wurf].self, e["wuerfe"])
            guard partie.amZug == spieler else { Issue.record("\(kopf): am Zug ist \(partie.amZug), erwartet \(spieler)"); return }
            let vorher = partie.verlauf.count
            var n = 0
            while partie.verlauf.count == vorher && n < 100 {
                if arten[spieler] == .echt {
                    partie.eintippen(eingabe.naechster())
                    eingetipptGesamt += 1
                } else {
                    partie.wuerfeln(&quelle)
                }
                switch partie.spielzug.stand {
                case .wahl:
                    let erlaubt = partie.spielzug.erlaubt
                    let zug: Zug
                    if computer {
                        zug = Computer.entscheide(strategien[spieler], partie.lage, spieler, erlaubt)
                    } else {
                        guard n < soll.count, let z = soll[n].zug else { Issue.record("\(kopf): Wurf \(n) ohne aufgezeichneten Zug"); return }
                        zug = z
                    }
                    guard erlaubt.contains(zug) else { Issue.record("\(kopf): Zug nicht erlaubt"); return }
                    partie.waehle(zug)
                case .verfallen: partie.weiter()
                default: Issue.record("\(kopf): unerwarteter Stand"); return
                }
                n += 1
            }
            let sollEintrag = Verlaufseintrag(spieler: spieler, wuerfe: soll, figuren: try Regeltests.decode([[Int]].self, e["figuren"]))
            guard partie.verlauf.count == vorher + 1, let ist = partie.verlauf.last, ist.gleichWieRegeltest(sollEintrag) else {
                Issue.record("\(kopf): weicht ab"); return
            }
            #expect(ist.eingetippt == (arten[spieler] == .echt ? soll.count : 0), "\(kopf): eingetippt gezählt")
        }
        #expect(partie.platzierung == erwartet["platzierung"] as? [Int], "\(name): Platzierung")
        #expect(partie.vorbei)
        #expect(quelle.verbraucht == appWuerfel.count && !quelle.ueberzogen, "\(name): App-Würfel genau aufgebraucht")
        #expect(eingabe.verbraucht == eingaben.count && !eingabe.ueberzogen, "\(name): Eingaben genau aufgebraucht")
        let stat = Wuerfelstatistik.zaehle(partie)
        #expect(stat.reduce(0) { $0 + $1.eingetippt } == eingetipptGesamt)
    }

    /// Alle Partien aus `partien/*.json`, alle Spieler auf „echt“: dieselben Würfel einzeln eingetippt, die App-Quelle bleibt leer.
    @Test func allePartienMitAllenSpielernEcht() throws {
        for (name, p) in try Regeltests.partien() {
            let n = (p["sitze"] as! [Int]).count
            for computer in [false, true] {
                try Self.spiele(name: "\(name) alle echt (\(computer ? "Strategien" : "Aufzeichnung"))", json: p,
                                arten: Array(repeating: .echt, count: n), appWuerfel: [], eingaben: p["wuerfel"] as! [Int], computer: computer)
            }
        }
    }

    /// Gemischte Partien aus `echt.json`: beide Würfellisten müssen genau aufgehen.
    @Test func gemischtePartienAusEchtJson() throws {
        let faelle = [JSON](try Regeltests.laden("echt.json")["faelle"])
        #expect(faelle.count >= 2)
        #expect(faelle.contains { f in (f["wuerfelArten"] as! [String]).contains("app") }, "mindestens eine gemischte Partie")
        for f in faelle {
            let arten = (f["wuerfelArten"] as! [String]).map { Wuerfelart(rawValue: $0)! }
            #expect(arten.contains(.echt))
            for computer in [false, true] {
                try Self.spiele(name: "\(f["name"] ?? "echt") (\(computer ? "Strategien" : "Aufzeichnung"))", json: f, arten: arten,
                                appWuerfel: f["appWuerfel"] as! [Int], eingaben: f["eingaben"] as! [Int], computer: computer)
            }
        }
    }
}

@MainActor
@Suite("Echte Würfel im Store")
struct EchtStoreTests {
    static func store(seed: UInt64 = 21, optionen: Optionen = .standard) -> (GameStore, GameRepository) {
        let repo = StoreTests.tempRepo()
        let store = GameStore(repository: repo, seed: { seed })
        let spieler = [Spieler(name: "A", avatar: "a", strategie: .mensch, sitz: 0, wuerfel: .echt),
                       Spieler(name: "B", avatar: "b", strategie: .mensch, sitz: 2, wuerfel: .app)]
        store.neuePartie(spieler: spieler, optionen: optionen, beginner: 0)
        return (store, repo)
    }

    @Test func eingabeAendernAndereEingabe() throws {
        let (store, _) = Self.store()
        let start = try #require(store.zustand)
        #expect(start.erwartetEingabe)
        let quelleVorher = start.quelle
        store.wuerfeln()                                   // bei „echt“ wirkungslos
        #expect(store.zustand == start)

        store.eintippen(6)
        let nach6 = try #require(store.zustand)
        #expect(nach6.partie.spielzug.augen == 6 && nach6.phase == .wahl)
        #expect(nach6.partie.spielzug.eingetippt == 1)
        #expect(nach6.quelle == quelleVorher, "App-Würfelquelle bleibt unberührt")
        #expect(store.kannZuruecknehmen)

        store.zuruecknehmen()                              // „Ändern“
        let zurueck = try #require(store.zustand)
        #expect(zurueck == start)
        #expect(zurueck.erwartetEingabe && zurueck.partie.spielzug.augen == nil, "Eingabe steht wieder da, ohne vorgewählten Wert")

        store.eintippen(3)
        let nach3 = try #require(store.zustand)
        #expect(nach3.partie.spielzug.augen == 3)
        #expect(nach3.phase == .verfallen, "mit 3 und allen im Haus geht nichts")
        #expect(nach3.partie.spielzug.fehlversuche == 1)
        #expect(nach3.quelle == quelleVorher)
        // andere Eingabe ergibt anderen Zustand als die erste
        #expect(nach3 != nach6)
    }

    @Test func eingabeNurWennErwartet() throws {
        let (store, _) = Self.store()
        store.eintippen(0)
        store.eintippen(7)
        #expect(store.zustand?.partie.spielzug.augen == nil)
        store.eintippen(6)
        let danach = store.zustand
        store.eintippen(2)                                 // schon gewürfelt: ignoriert
        #expect(store.zustand == danach)
    }

    @Test func speichernZwischenEingabeUndZug() throws {
        let (store, repo) = Self.store()
        store.eintippen(6)
        let vorher = try #require(store.zustand)
        #expect(vorher.phase == .wahl)
        let geladen = GameStore(repository: repo)
        #expect(geladen.zustand == vorher)
        #expect(geladen.zustand?.spieler.first?.wuerfel == .echt)
        // beide ziehen gleich weiter
        for s in [store, geladen] {
            let z = try #require(s.zustand)
            s.ziehe(z.partie.spielzug.erlaubt[0])
        }
        #expect(geladen.zustand == store.zustand)
        // nach dem Zug (6 → nochmal) wartet wieder die Eingabe
        #expect(store.zustand?.erwartetEingabe == true)
    }

    @Test func alteDateiOhneWuerfelartLaedtMitApp() throws {
        let (store, repo) = Self.store()
        let daten = try Data(contentsOf: repo.url)
        var json = try #require(JSONSerialization.jsonObject(with: daten) as? [String: Any])
        var z = json["zustand"] as! [String: Any]
        var spieler = z["spieler"] as! [[String: Any]]
        for i in spieler.indices { spieler[i].removeValue(forKey: "wuerfel") }
        z["spieler"] = spieler
        json["zustand"] = z
        try JSONSerialization.data(withJSONObject: json).write(to: repo.url)
        let geladen = GameStore(repository: repo)
        #expect(geladen.zustand?.spieler.allSatisfy { $0.wuerfel == .app } == true)
        _ = store
    }

    @Test func computerWuerfelnImmerInDerApp() {
        let s = Spieler(name: "C", avatar: "c", strategie: .gut, sitz: 1, wuerfel: .echt)
        #expect(!s.wuerfeltEcht)
        #expect(Spieler(name: "M", avatar: "m", strategie: .mensch, sitz: 0, wuerfel: .echt).wuerfeltEcht)
    }

    @Test func wuerfelstatistikZaehltEingetipptes() throws {
        let (store, _) = Self.store()
        for w in [2, 4, 5] {                               // A: drei Versuche, alle verfallen
            store.eintippen(w)
            store.verfallenWeiter()
        }
        let z = try #require(store.zustand)
        #expect(z.amZug == 1, "nach drei Versuchen ist B dran")
        let stat = Wuerfelstatistik.zaehle(z.partie)
        #expect(stat[0].eingetippt == 3 && stat[0].wuerfe == 3)
        #expect(stat[1].eingetippt == 0)
        // Rückgängig nimmt Würfe von B zurück, aber nicht As eingetippte Würfe
        store.wuerfeln()                                   // B (App) würfelt
        store.zuruecknehmen()
        let danach = Wuerfelstatistik.zaehle(store.zustand!.partie)
        #expect(danach[0].eingetippt == 3 && danach[1].wuerfe == 0)
    }
}
