// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import Foundation

/// „Rauswurf“: Logik zwischen Rahmen und dem Spielkern (Spielerliste aus den Teilnehmern, Computer-Stärke, Ende, Verlaufszeilen).
/// Der Kern (Regeln, Computer, `GameStore`, `SpielController`) liegt im selben Paket.
enum NeuLogik {
    static let id = "rauswurf-neu"

    /// Computer-Stärke der Wahl: Leicht → einfach, Mittel und Schwer → gut, „Lieb“ lässt Menschen gewinnen.
    /// (Eine eigene Stufe „Schwer“ mit Vorausschau kommt später; der Kern kennt heute drei Strategien.)
    static func strategie(stufe: ComputerStufe, lieb: Bool) -> Strategie {
        if lieb { return .lieb }
        return stufe == .leicht ? .einfach : .gut
    }

    /// Sitze am Brett: zu zweit gegenüber (0 und 2), sonst der Reihe nach.
    static func sitze(_ anzahl: Int) -> [Int] { anzahl == 2 ? [0, 2] : Array(0 ..< min(anzahl, Brettmass.sitze)) }

    /// Spieler aus den Teilnehmern des Rahmens. Bekannte Personen behalten ihr Zeichen, jeder Platz bekommt ein eigenes.
    /// `buchstaben` (nur Tinte): Wer kein eigenes Zeichen hat, auch der Computer, bekommt den Anfangsbuchstaben des Namens
    /// (`Spieler.abzeichen`, wie die runde Spielerleiste der anderen Spiele); die Farbe des Sitzes unterscheidet die Plätze.
    /// Klar und Salon (`false`) behalten das Emoji aus `Avatare.standard`.
    static func spieler(_ t: [SpielTeilnehmer], computer: Strategie, echteWuerfel: Bool, buchstaben: Bool = false,
                        bekannt: [(name: String, avatar: String, farbeHex: UInt32)] = SpielerQuelle.bekannt) -> [Spieler] {
        let sitze = sitze(t.count)
        var benutzt = Set<String>()
        return t.prefix(sitze.count).enumerated().map { i, p in
            var avatar = p.computer ? nil : bekannt.first { $0.name.caseInsensitiveCompare(p.name) == .orderedSame }?.avatar
            if let a = avatar, a.isEmpty || benutzt.contains(a) { avatar = nil }
            let wahl = avatar ?? (buchstaben
                ? SpieleKern.Spieler.abzeichen(name: p.name, zeichen: nil)
                : ((0 ..< Avatare.alle.count).map { Avatare.standard(i + $0 * 4) }.first { !benutzt.contains($0) } ?? Avatare.standard(i)))
            benutzt.insert(wahl)
            return Spieler(name: p.name, avatar: wahl, strategie: p.computer ? computer : .mensch, sitz: sitze[i],
                           wuerfel: !p.computer && echteWuerfel ? .echt : .app)
        }
    }

    /// Ende für den Rahmen: Platzierung zuerst, die übrigen nach Fortschritt (viele Figuren im Ziel zuerst).
    static func ende(_ z: Spielzustand) -> SpielEnde {
        var e = endeOhneWuerfel(z)
        // 1.0 (M4): „So fielen die Würfel“ von selbst am Ende (vorher nur über das Menü)
        let zahlen = Wuerfelstatistik.zaehle(z.partie)
        var b = WuerfelBilanz(namen: z.spieler.map(\.name))
        for (i, zz) in zahlen.enumerated() where i < b.augen.count { b.augen[i] = zz.augen; b.eingetippt[i] = zz.eingetippt }
        e.wuerfel = b
        // Blatt 22 (EB-3): Spielzüge und Geschlagen als Werte (das Würfelbild kommt vom Kern aus `e.wuerfel`)
        let geschlagen = PartieZaehlung.zaehle(z.partie).reduce(0) { $0 + $1.geschlagen }
        e.werte = [EndeWert("Spielzüge", "\(z.partie.verlauf.count)"), EndeWert("Geschlagen", "\(geschlagen)")]
        return e
    }

    private static func endeOhneWuerfel(_ z: Spielzustand) -> SpielEnde {
        let fertig = z.partie.platzierung
        let rest = z.spieler.indices.filter { !fertig.contains($0) }
            .sorted { SpielerFortschritt.punkte(z.lage.figuren[$0]) > SpielerFortschritt.punkte(z.lage.figuren[$1]) }
        // Teams 2 gegen 2 (B6): Das Gewinnerteam teilt Platz 1, das andere Platz 2. Beide Partner zählen als Sieger bzw. Verlierer.
        if z.partie.teamsAktiv, let erster = fertig.first {
            let gewinner = Partie.team(von: erster)
            let alle = fertig + rest
            let sortiert = alle.filter { Partie.team(von: $0) == gewinner } + alle.filter { Partie.team(von: $0) != gewinner }
            let namen = sortiert.prefix(2).map { z.spieler[$0].name }.joined(separator: " + ")
            return SpielEnde(reihenfolge: sortiert.map { z.spieler[$0].name }, plaetze: sortiert.map { Partie.team(von: $0) == gewinner ? 1 : 2 },
                             info: String(localized: "Team \(namen) gewinnt"))   // Blatt 22: „Spielzüge“ ist jetzt ein Wert
        }
        let reihenfolge = (fertig + rest).map { z.spieler[$0].name }
        return SpielEnde(reihenfolge: reihenfolge)   // Blatt 22: ohne Teams kein Satz mehr, „Spielzüge“ ist jetzt ein Wert
    }

    /// Anzahl Figuren im Haus und im Ziel („Haus 2 · Ziel 1“)
    static func hausZiel(_ figuren: [Int]) -> (haus: Int, ziel: Int) {
        (figuren.filter { $0 == Brettmass.haus }.count, figuren.filter { $0 >= Brettmass.zielErstes }.count)
    }

    /// Eine Zeile im Verlauf: „Anna: 6, 3 – wirft Ben raus“
    static func verlaufText(_ e: Verlaufseintrag, _ z: Spielzustand) -> String {
        let name = z.spieler[safe: e.spieler]?.name ?? "?"
        let augen = e.wuerfe.map { String($0.augen) }.joined(separator: ", ")
        var text = "\(name): \(augen)"
        if let opfer = e.wuerfe.compactMap({ $0.zug?.schlaegt }).first, let o = z.spieler[safe: opfer] {
            text += " – " + String(localized: "wirft \(o.name) raus")
        } else if e.wuerfe.last?.zug == nil {
            text += " – " + String(localized: "kein Zug")
        } else if let letzter = e.wuerfe.last?.zug, letzter.nach >= Brettmass.zielErstes {
            text += " – " + String(localized: "ins Ziel")
        }
        return text
    }
}

/// Fortschrittspunkte einer Seite wie in der Spielerleiste: Haus 0, Laufbahn rel+1, Ziel 44
enum SpielerFortschritt {
    static func punkte(_ figuren: [Int]) -> Int {
        figuren.reduce(0) { $0 + ($1 < 0 ? 0 : ($1 >= Brettmass.zielErstes ? 44 : $1 + 1)) }
    }
}
