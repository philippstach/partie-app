// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Verweis auf eine Übung des Lernwegs (Technik-Nummer und Übungsnummer)
public struct SudokuUebungRef: Codable, Equatable, Sendable {
    public var technik: Int
    public var nummer: Int
    public init(technik: Int, nummer: Int) { self.technik = technik; self.nummer = nummer }
}

/// Änderung an einer Zelle mit altem und neuem Stand
public struct SudokuAenderung: Codable, Equatable, Sendable {
    public var zelle: Int
    public var altWert: UInt8
    public var altNotizen: UInt16
    public var neuWert: UInt8
    public var neuNotizen: UInt16
}

/// Eine Aktion des Spielers mit allen betroffenen Zellen (für Rückgängig und Wiederholen)
public struct SudokuZug: Codable, Equatable, Sendable {
    public var aenderungen: [SudokuAenderung]
}

/// Eine laufende oder beendete Partie. Alle Felder außer dem Rätsel sind freiwillig lesbar, damit Spielstände nach Updates laden.
public struct SudokuPartie: Codable, Equatable, Sendable {
    public static let fehlerLimit = 3

    public var raetsel: SudokuRaetsel
    public var werte: [UInt8]
    public var notizen: [UInt16]
    public var fehler = 0
    public var tipps = 0
    /// Gespielte Sekunden bis zum letzten Speichern
    public var verstrichen: Double = 0
    public var zuege: [SudokuZug] = []
    public var wiederholZuege: [SudokuZug] = []
    public var limitBestaetigt = false
    /// Das Rätsel des Tages: „2026-11-09“, sonst nil
    public var tagesschluessel: String?
    public var uebung: SudokuUebungRef?
    /// Selbst eingegebenes Rätsel (zählt nicht als Stufe)
    public var eigen = false
    public var fertig = false

    public init(raetsel: SudokuRaetsel, tagesschluessel: String? = nil, uebung: SudokuUebungRef? = nil, eigen: Bool = false, startNotizen: [UInt16]? = nil) {
        self.raetsel = raetsel
        werte = raetsel.vorgaben
        notizen = startNotizen ?? [UInt16](repeating: 0, count: raetsel.form.zellen)
        self.tagesschluessel = tagesschluessel
        self.uebung = uebung
        self.eigen = eigen
    }

    public var form: SudokuForm { raetsel.form }

    private enum CodingKeys: String, CodingKey {
        case raetsel, werte, notizen, fehler, tipps, verstrichen, zuege, wiederholZuege, limitBestaetigt, tagesschluessel, uebung, eigen, fertig
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let r = try c.decode(SudokuRaetsel.self, forKey: .raetsel)
        raetsel = r
        werte = (try? c.decode([UInt8].self, forKey: .werte)) ?? r.vorgaben
        notizen = (try? c.decode([UInt16].self, forKey: .notizen)) ?? [UInt16](repeating: 0, count: r.form.zellen)
        fehler = (try? c.decode(Int.self, forKey: .fehler)) ?? 0
        tipps = (try? c.decode(Int.self, forKey: .tipps)) ?? 0
        verstrichen = (try? c.decode(Double.self, forKey: .verstrichen)) ?? 0
        zuege = (try? c.decode([SudokuZug].self, forKey: .zuege)) ?? []
        wiederholZuege = (try? c.decode([SudokuZug].self, forKey: .wiederholZuege)) ?? []
        limitBestaetigt = (try? c.decode(Bool.self, forKey: .limitBestaetigt)) ?? false
        tagesschluessel = try? c.decodeIfPresent(String.self, forKey: .tagesschluessel)
        uebung = try? c.decodeIfPresent(SudokuUebungRef.self, forKey: .uebung)
        eigen = (try? c.decode(Bool.self, forKey: .eigen)) ?? false
        fertig = (try? c.decode(Bool.self, forKey: .fertig)) ?? false
    }

    /// Sieht der Stand stimmig aus? (Größen, Ziffern, Züge mit gültigen Zellen). Sonst wird er beim Fortsetzen verworfen.
    public var stimmig: Bool {
        let n = form.zellen
        return raetsel.stimmig && werte.count == n && notizen.count == n
            && werte.allSatisfy { Int($0) <= form.n } && notizen.allSatisfy { $0 <= form.alle }
            && (zuege + wiederholZuege).allSatisfy { $0.aenderungen.allSatisfy { (0..<n).contains($0.zelle) } }
    }

    // MARK: Abfragen

    public func istVorgabe(_ z: Int) -> Bool { raetsel.vorgaben[z] != 0 }
    public var geloest: Bool { werte == raetsel.loesung }
    public var limitErreicht: Bool { fehler >= Self.fehlerLimit && !limitBestaetigt }
    public var kannZurueck: Bool { !zuege.isEmpty }
    public var kannWiederholen: Bool { !wiederholZuege.isEmpty }

    /// Anteil der gefüllten leeren Zellen (0…1)
    public var fortschritt: Double {
        let offen = (0..<form.zellen).filter { raetsel.vorgaben[$0] == 0 }
        guard !offen.isEmpty else { return 1 }
        return Double(offen.filter { werte[$0] != 0 }.count) / Double(offen.count)
    }

    /// Wie oft die Ziffer im Feld steht
    public func anzahl(_ ziffer: Int) -> Int { werte.filter { Int($0) == ziffer }.count }
    /// Wie oft die Ziffer noch fehlt (nie unter 0)
    public func fehltNoch(_ ziffer: Int) -> Int { max(0, form.n - anzahl(ziffer)) }

    /// Zellen mit einer Zahl, die in einer Einheit doppelt vorkommt
    public func konflikte() -> Set<Int> { SudokuPruefung.doppelte(form, werte) }
    /// Zellen mit einer Zahl, die nicht zur Lösung passt
    public func falsche() -> Set<Int> { Set((0..<form.zellen).filter { werte[$0] != 0 && werte[$0] != raetsel.loesung[$0] }) }
    /// Mögliche Ziffern einer leeren Zelle nach den Regeln
    public func kandidaten(_ z: Int) -> UInt16 { SudokuLoeser.kandidaten(form, werte)[z] }

    public func hinweis(bevorzugt: Int? = nil) -> SudokuHinweis? {
        SudokuHinweis.naechster(form, werte: werte, loesung: raetsel.loesung, bevorzugt: bevorzugt)
    }

    // MARK: Eingaben

    public enum Ergebnis: Equatable, Sendable { case nichts, gesetzt, falsch, geloescht, notiz }

    /// Trägt eine Zahl ein. Dieselbe Zahl noch einmal löscht sie. Falsche Zahlen zählen als Fehler.
    @discardableResult
    public mutating func setze(_ z: Int, _ ziffer: Int, notizenStreichen: Bool = true) -> Ergebnis {
        guard (0..<form.zellen).contains(z), (1...form.n).contains(ziffer), !istVorgabe(z), !fertig else { return .nichts }
        if werte[z] == UInt8(ziffer) { return loesche(z) }
        var aenderungen = [SudokuAenderung]()
        aenderungen.append(SudokuAenderung(zelle: z, altWert: werte[z], altNotizen: notizen[z], neuWert: UInt8(ziffer), neuNotizen: 0))
        if notizenStreichen {
            let bit = SudokuForm.bit(ziffer)
            for p in form.geometrie.nachbarn[z] where notizen[p] & bit != 0 {
                aenderungen.append(SudokuAenderung(zelle: p, altWert: werte[p], altNotizen: notizen[p], neuWert: werte[p], neuNotizen: notizen[p] & ~bit))
            }
        }
        anwenden(SudokuZug(aenderungen: aenderungen))
        let falsch = ziffer != Int(raetsel.loesung[z]) && uebung == nil
        if falsch { fehler += 1 }
        if geloest { fertig = true }
        return falsch ? .falsch : .gesetzt
    }

    /// Schaltet eine Notiz in einer leeren Zelle um
    @discardableResult
    public mutating func notiz(_ z: Int, _ ziffer: Int) -> Ergebnis {
        guard (0..<form.zellen).contains(z), (1...form.n).contains(ziffer), werte[z] == 0, !istVorgabe(z), !fertig else { return .nichts }
        let neu = notizen[z] ^ SudokuForm.bit(ziffer)
        anwenden(SudokuZug(aenderungen: [SudokuAenderung(zelle: z, altWert: 0, altNotizen: notizen[z], neuWert: 0, neuNotizen: neu)]))
        return .notiz
    }

    @discardableResult
    public mutating func loesche(_ z: Int) -> Ergebnis {
        guard (0..<form.zellen).contains(z), !istVorgabe(z), !fertig, werte[z] != 0 || notizen[z] != 0 else { return .nichts }
        anwenden(SudokuZug(aenderungen: [SudokuAenderung(zelle: z, altWert: werte[z], altNotizen: notizen[z], neuWert: 0, neuNotizen: 0)]))
        return .geloescht
    }

    /// Trägt in alle leeren Zellen die möglichen Ziffern als Notizen ein
    public mutating func notizenFuellen() {
        guard !fertig else { return }
        let k = SudokuLoeser.kandidaten(form, werte)
        let aend = (0..<form.zellen).compactMap { z -> SudokuAenderung? in
            guard werte[z] == 0, notizen[z] != k[z] else { return nil }
            return SudokuAenderung(zelle: z, altWert: 0, altNotizen: notizen[z], neuWert: 0, neuNotizen: k[z])
        }
        if !aend.isEmpty { anwenden(SudokuZug(aenderungen: aend)) }
    }

    /// Trägt die Zahl eines Tipps ein (zählt als Tipp, nicht als Fehler)
    public mutating func tippEintragen(_ z: Int) {
        guard (0..<form.zellen).contains(z), !istVorgabe(z), !fertig else { return }
        let ziffer = raetsel.loesung[z]
        var aend = [SudokuAenderung(zelle: z, altWert: werte[z], altNotizen: notizen[z], neuWert: ziffer, neuNotizen: 0)]
        let bit = SudokuForm.bit(Int(ziffer))
        for p in form.geometrie.nachbarn[z] where notizen[p] & bit != 0 {
            aend.append(SudokuAenderung(zelle: p, altWert: werte[p], altNotizen: notizen[p], neuWert: werte[p], neuNotizen: notizen[p] & ~bit))
        }
        anwenden(SudokuZug(aenderungen: aend))
        tipps += 1
        if geloest { fertig = true }
    }

    public mutating func zurueck() {
        guard !fertig, let zug = zuege.popLast() else { return }
        for a in zug.aenderungen { werte[a.zelle] = a.altWert; notizen[a.zelle] = a.altNotizen }
        wiederholZuege.append(zug)
    }

    public mutating func wiederholen() {
        guard let zug = wiederholZuege.popLast(), !fertig else { return }
        for a in zug.aenderungen { werte[a.zelle] = a.neuWert; notizen[a.zelle] = a.neuNotizen }
        zuege.append(zug)
    }

    /// Nach dem Fehlerlimit: zurück zum letzten Stand ohne falsche Zahl, Fehlerzähler auf null
    public mutating func zuruecksetzen() {
        while !falsche().isEmpty, let zug = zuege.popLast() {
            for a in zug.aenderungen { werte[a.zelle] = a.altWert; notizen[a.zelle] = a.altNotizen }
        }
        wiederholZuege = []
        fehler = 0
        limitBestaetigt = false
    }

    private mutating func anwenden(_ zug: SudokuZug) {
        for a in zug.aenderungen { werte[a.zelle] = a.neuWert; notizen[a.zelle] = a.neuNotizen }
        zuege.append(zug)
        wiederholZuege = []
    }
}
