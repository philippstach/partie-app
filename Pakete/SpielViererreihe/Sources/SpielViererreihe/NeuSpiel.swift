// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Spielzustand der neuen Viererreihe (Partie, Stufe, Zufall) – reine Logik ohne Oberfläche, mit `swift test` prüfbar.
/// Wird vom Rahmen (`fortsetzbar`, Schlüssel `viererreihe-neu`) gespeichert: eigene Spielstände.
struct NeuSpiel: Codable, Equatable {
    var partie: Partie
    var stufe: Stufe
    var zufall: SplitMix64
    var zweiSpieler: Bool
    var tippBenutzt = false

    /// Mensch ist Spieler 1, der Computer Spieler 2 (`Spielzustand.computerSpieler`).
    /// 1.0 (M7): `beginner` (1 oder 2) legt fest, wer den ersten Stein wirft; Standard bleibt Spieler 1.
    init(zweiSpieler: Bool, stufe: Stufe, beginner: Int = 1, zufall: SplitMix64 = .ausSystemzeit()) {
        self.partie = (try? Partie(beginner: beginner == 2 ? 2 : 1, zuege: [])) ?? (try! Partie(beginner: 1, zuege: []))
        self.stufe = stufe; self.zufall = zufall; self.zweiSpieler = zweiSpieler
    }

    var computerSpieler: Int? { zweiSpieler ? nil : Spielzustand.computerSpieler }
    var laeuft: Bool { partie.status == .laeuft }
    var computerDran: Bool { laeuft && partie.naechsterSpieler == computerSpieler }
    /// Index in `teilnehmer` (0/1) des Spielers am Zug.
    var dran: Int { partie.naechsterSpieler - 1 }

    /// Wirft einen Stein ein. Gibt `false` zurück, wenn der Zug nicht geht (Spalte voll, Spiel vorbei).
    @discardableResult
    mutating func wirf(_ spalte: Int) -> Bool { (try? partie.einwerfen(spalte)) != nil }

    var kannZurueck: Bool { partie.kannRueckgaengig(computer: computerSpieler) }

    /// Nimmt den letzten Zug zurück (gegen den Computer samt seiner Antwort).
    @discardableResult
    mutating func zurueck() -> Bool {
        guard let neu = try? partie.rueckgaengig(computer: computerSpieler) else { return false }
        partie = neu; return true
    }

    /// Stimmigkeit eines geladenen Stands: nur laufende Partien werden fortgesetzt.
    var istFortsetzbar: Bool { laeuft && partie.zuege.count < Partie.felder }
}

/// Ein Eintrag der Karte „Letzte Züge“.
struct NeuZug: Identifiable, Equatable {
    let nummer: Int      // 1-basiert
    let spieler: Int     // 1 oder 2
    let spalte: Int      // 0-basiert; angezeigt wird spalte + 1
    var id: Int { nummer }
}

enum NeuVerlauf {
    /// Die letzten `anzahl` Züge, ältester zuerst.
    static func letzte(_ partie: Partie, anzahl: Int) -> [NeuZug] {
        let alle = partie.zuege.enumerated().map { NeuZug(nummer: $0.offset + 1, spieler: Partie.spieler(zug: $0.offset, beginner: partie.beginner), spalte: $0.element) }
        return Array(alle.suffix(max(anzahl, 0)))
    }
}

/// Maße des Spielbildschirms: das Brett ist breitenbegrenzt, der Rest gehört den Karten (Bewertung viererreihe.md, Abschnitt 4/5).
struct NeuMasse: Equatable {
    var kante: CGFloat            // Zellenkante
    var brettBreite: CGFloat { kante * CGFloat(Partie.spalten) }
    var brettHoehe: CGFloat { kante * CGFloat(Partie.zeilen) }
    var einwurfHoehe: CGFloat { kante * 0.9 }
    /// Höhe, die unter dem Brett für Karten bleibt.
    var rest: CGFloat

    enum Karte: Hashable { case verlauf, stand, quote }

    /// Feste Höhen um das Brett: Kopf, Spielerleiste, Knöpfe, Abstände.
    static let kopf: CGFloat = 52, leiste: CGFloat = 84, knoepfe: CGFloat = 50, abstand: CGFloat = 12

    /// iPhone und schmale Fenster: Brett über die volle Breite (minus Rand), Karten im verbleibenden Platz.
    /// `hoeheBegrenzt` (iPad hoch, Tinte): die Kante darf höchstens so groß werden, dass Brett, Einwurf, feste Höhen und mindestens 180 pt (120 pt Schwelle plus Reserve, die festen Höhen sind Schätzwerte) für die Karten darunter in die Höhe passen.
    static func hochformat(breite: CGFloat, hoehe: CGFloat, rand: CGFloat = 16, hoechsteKante: CGFloat = 97, hoeheBegrenzt: Bool = false) -> NeuMasse {
        var kante = min(max((breite - 2 * rand) / CGFloat(Partie.spalten), 20), hoechsteKante)
        if hoeheBegrenzt {
            let fest = Self.kopf + Self.leiste + Self.knoepfe + Self.abstand * 5 + 180   // 180 pt bleiben für „Verlauf“ und „Stand“ (nichts fällt weg)
            kante = max(min(kante, (hoehe - fest) / (CGFloat(Partie.zeilen) + 0.9)), 20)
        }
        var m = NeuMasse(kante: kante, rest: 0)
        let belegt = kopf + leiste + m.einwurfHoehe + m.brettHoehe + knoepfe + abstand * 5
        m.rest = max(hoehe - belegt, 0)
        return m
    }

    /// iPad quer: Brett links, so groß wie die Höhe und die Breite neben der Seitenleiste erlauben.
    static func quer(breite: CGFloat, hoehe: CGFloat, seitenleiste: CGFloat) -> NeuMasse {
        let ausBreite = (breite - seitenleiste - 48) / CGFloat(Partie.spalten)
        let ausHoehe = (hoehe - kopf - 2 * abstand) / (CGFloat(Partie.zeilen) + 0.9)
        return NeuMasse(kante: max(min(ausBreite, ausHoehe), 20), rest: 0)
    }

    /// Welche Karten unter dem Brett Platz haben. Bei großer Schrift fallen zuerst „Stand“, dann „Verlauf“ weg.
    /// `schrift`: 0 normal, 1 = ab xxxLarge, 2 = ab accessibility1.
    func karten(schrift: Int) -> [Karte] {
        var k: [Karte] = []
        if rest >= 120, schrift < 2 { k.append(.verlauf) }
        if rest >= 120, schrift < 1 { k.append(.stand) }
        if rest >= 200, schrift < 1 { k.append(.quote) }
        return k
    }
}

/// Siegquote für den Balken: nil ohne Partien.
func neuQuote(siege: Int, partien: Int) -> Double? { partien > 0 ? Double(siege) / Double(partien) : nil }
