// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import Observation

/// Beim Wurf-für-Wurf-Eingeben: Was vor dem nächsten Wurf herausgelegt oder umgedreht wird.
struct NeuEchtAuftrag: Equatable {
    var herauslegen: [Int]
    var umdrehen: Int
}

/// Hilfen für den Menschen: Chance, Perzentil und Tipp (Zahlen von Computer „gut“).
struct NeuHilfe: Equatable {
    var chance: Int?
    var perzentil: Int?
    var vorn: Bool
    var tipp: Aktion
}

/// Was der Mensch im Becher gerade angetippt hat (Auswahl, Umdrehen) und die Zustände der Wurf-Animation.
/// Die Rechenregeln stehen in `NeuLogik`; hier hängen nur Töne, Haptik und Zustände daran.
@MainActor
@Observable
final class NeuEingabe {
    var auswahl: Set<Int> = []
    var umdrehen = 0
    var wackeln = 0
    var wirbelt = false
    var gezeigt = [1, 1, 1]
    var gelandet: Set<Int> = []
    var ueberspringen = false
    var hilfe: NeuHilfe?
    var tippSichtbar = false
    var echtAuftrag: NeuEchtAuftrag?
    var getippt: String?
    var getipptNr = 0

    func zuruecksetzen() {
        auswahl = []
        umdrehen = 0
        echtAuftrag = nil
    }

    func tippe(_ z: Spielzustand, _ i: Int, preferences p: AppPreferences) {
        guard z.phase == .nachWurf, let zug = z.runde.zug, zug.darfWeiter else { return }
        if auswahl.contains(i) {
            auswahl.remove(i)
            SpielHaptik.select()
            return
        }
        if NeuLogik.darfWaehlen(zug: zug, auswahl: auswahl, umdrehen: umdrehen, index: i) {
            auswahl.insert(i)
            Sound.select.play()
            SpielHaptik.select()
        } else {
            wackeln += 1
            SpielHaptik.error()
        }
    }

    func umdrehenSchalten(_ zug: Zug, preferences p: AppPreferences) {
        guard let neu = NeuLogik.umdrehenWechsel(zug: zug, auswahl: auswahl, umdrehen: umdrehen) else {
            wackeln += 1
            SpielHaptik.error()
            umdrehen = 0
            return
        }
        auswahl = neu.auswahl
        umdrehen = neu.umdrehen
        if umdrehen > 0 {
            Sound.flip.play()
            SpielHaptik.select()
        }
    }

    /// Welche Würfel im Becher der Tipp herauslegen bzw. umdrehen würde.
    func tippIndizes(_ zug: Zug) -> Set<Int> {
        guard case let .weiter(h, u)? = hilfe?.tipp else { return [] }
        var rest = h
        var erg = Set<Int>()
        for (i, w) in zug.wurf.enumerated() {
            if let k = rest.firstIndex(of: w) { rest.remove(at: k); erg.insert(i) }
        }
        var sechsen = u
        for (i, w) in zug.wurf.enumerated() where w == 6 && sechsen > 0 && !erg.contains(i) { erg.insert(i); sechsen -= 1 }
        return erg
    }

    func hilfeBerechnen(_ z: Spielzustand, an: Bool) async {
        hilfe = nil
        tippSichtbar = false
        guard an, z.phase == .nachWurf, let lage = z.lage, let zug = z.runde.zug, zug.darfWeiter else { return }
        let schluessel = zug.wertung().schluessel
        let ergebnis = await Task.detached(priority: .userInitiated) { () -> NeuHilfe in
            let tipp = Computer.entscheideGut(lage)
            if lage.ziel.ref != nil {
                let beste = Computer.bewerteGut(lage).map(\.nutzen).max() ?? 0
                return NeuHilfe(chance: Int((beste * 100).rounded()), perzentil: nil, vorn: beste > 0.999_999, tipp: tipp)
            }
            let p = Computer.perzentil(schluessel, optionen: lage.optionen)
            return NeuHilfe(chance: nil, perzentil: Int((p * 100).rounded()), vorn: false, tipp: tipp)
        }.value
        guard !Task.isCancelled else { return }
        hilfe = ergebnis
    }

    func hilfeText(_ z: Spielzustand) -> String? {
        guard let h = hilfe else { return nil }
        if let p = h.perzentil { return String(localized: "Besser als \("\(p) %") aller Würfe") }
        guard let c = h.chance, let ref = z.zuSchlagen else { return nil }
        if h.vorn { return String(localized: "Damit verlierst du die Runde nicht") }
        return String(localized: "Chance, \(ref.wertung.name) zu schlagen: \("\(c) %")")
    }

    func tippText(_ a: Aktion) -> String {
        switch a {
        case .stehen:
            return String(localized: "Tipp: Stehen lassen")
        case let .weiter(h, u):
            var teile: [String] = []
            if !h.isEmpty { teile.append(String(localized: "herauslegen: \(h.map(String.init).joined(separator: ", "))")) }
            if u > 0 { teile.append(String(localized: "\(u) Sechs umdrehen")) }
            if teile.isEmpty { return String(localized: "Tipp: Weiter würfeln, nichts herauslegen") }
            return String(localized: "Tipp: \(teile.joined(separator: ", ")), dann weiter würfeln")
        }
    }
}

func neuZahlWort(_ n: Int) -> String {
    [String(localized: "Eins"), String(localized: "Zwei"), String(localized: "Drei"),
     String(localized: "Vier"), String(localized: "Fünf"), String(localized: "Sechs")][max(0, min(5, n - 1))]
}
