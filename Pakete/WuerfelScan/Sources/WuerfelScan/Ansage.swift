// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Liest Würfelaugen aus gesprochenem Text: „drei, fünf, fünf, eins, sechs“, „3 5 5 1 6“, „zwei Sechsen und eine Vier“, „dreimal die Fünf“.
/// Versteht Deutsch, Englisch, Spanisch und Französisch sowie die üblichen Verhörer der Spracherkennung. Reine Textlogik, ohne Mikrofon testbar.
public enum WuerfelAnsage {
    /// Zahlwort → Augen.
    static let werte: [String: Int] = {
        let roh: [Int: [String]] = [
            1: ["eins", "ein", "eine", "einen", "einer", "one", "won", "uno", "una", "un", "une"],
            2: ["zwei", "zwo", "two", "too", "dos", "deux"],
            3: ["drei", "three", "tree", "tres", "trois"],
            4: ["vier", "four", "for", "cuatro", "quatre"],
            5: ["fünf", "five", "cinco", "cinq"],
            6: ["sechs", "sex", "six", "seis"],
        ]
        var d: [String: Int] = [:]
        for (w, liste) in roh { for s in liste { d[falte(s)] = w } }
        return d
    }()
    /// Mehrzahl („Sechsen“, „sixes“): Die Zahl davor ist die Anzahl.
    static let mehrzahl: [String: Int] = {
        let roh: [Int: [String]] = [
            1: ["einsen", "einser", "ones", "unos"],
            2: ["zweien", "zweier", "zweier", "twos", "doses"],
            3: ["dreien", "dreier", "threes", "treses"],
            4: ["vieren", "vierer", "fours", "cuatros"],
            5: ["fünfen", "fünfer", "fives", "cincos"],
            6: ["sechsen", "sechser", "sixes", "seises"],
        ]
        var d: [String: Int] = [:]
        for (w, liste) in roh { for s in liste { d[falte(s)] = w } }
        return d
    }()
    /// „dreimal“, „twice“: Der nächste Wert zählt so oft.
    static let mal: [String: Int] = {
        var d: [String: Int] = [:]
        for (n, liste) in [1: ["einmal", "once"], 2: ["zweimal", "twice", "doppelt"], 3: ["dreimal", "thrice"], 4: ["viermal"], 5: ["fünfmal"]] as [Int: [String]] {
            for s in liste { d[falte(s)] = n }
        }
        return d
    }()
    /// „drei mal fünf“, „three times five“, „tres veces cinco“, „trois fois cinq“.
    static let malWort: Set<String> = ["mal", "times", "veces", "vez", "fois", "x"]

    /// Wörter, die Eins oder Artikel sein können.
    static let artikel: Set<String> = ["eine", "einen", "einer", "une", "una", "a", "an"]

    static func falte(_ s: String) -> String { s.lowercased().folding(options: .diacriticInsensitive, locale: nil) }

    /// Die Augen in gesprochener Reihenfolge. Was keine Augenzahl ist (auch 0, 7, 8, 9), wird übergangen.
    public static func augen(aus text: String) -> [Int] {
        var ergebnis: [Int] = []
        var anzahl: Int?            // „dreimal …“: wartet auf den Wert
        var letzteWarZahl = false   // das zuletzt angehängte Auge kam aus einem einzelnen Zahlwort (kann eine Anzahl gewesen sein)
        func haenge(_ w: Int, _ n: Int) { ergebnis += Array(repeating: w, count: max(1, min(n, 6))) }
        let teile = text.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.map(falte)
        for (i, t) in teile.enumerated() {
            // „eine Vier“, „une six“: Der Artikel vor einem Zahlwort ist keine Eins.
            if artikel.contains(t), i + 1 < teile.count, werte[teile[i + 1]] != nil || mehrzahl[teile[i + 1]] != nil, !artikel.contains(teile[i + 1]) { continue }
            if t.allSatisfy(\.isNumber) {
                let ziffern = t.compactMap { $0.wholeNumberValue }.filter { (1...6).contains($0) }
                if ziffern.count == 1 { haenge(ziffern[0], anzahl ?? 1); letzteWarZahl = anzahl == nil } else { ergebnis += ziffern; letzteWarZahl = false }
                anzahl = nil
            } else if let w = mehrzahl[t] {
                if letzteWarZahl, let n = ergebnis.popLast() { haenge(w, n) } else { haenge(w, anzahl ?? 2) }
                anzahl = nil; letzteWarZahl = false
            } else if let n = mal[t] {
                anzahl = n; letzteWarZahl = false
            } else if malWort.contains(t) {
                if letzteWarZahl, let n = ergebnis.popLast() { anzahl = n }
                letzteWarZahl = false
            } else if let w = werte[t] {
                haenge(w, anzahl ?? 1); letzteWarZahl = anzahl == nil; anzahl = nil
            }
            // Füllwörter („und“, „die“, „eine“ ist oben schon 1) ändern nichts.
        }
        return ergebnis
    }

    /// Wörter, die die Spracherkennung bevorzugt hören soll.
    public static let hoerhilfe = ["eins", "zwei", "drei", "vier", "fünf", "sechs", "one", "two", "three", "four", "five", "six",
                                   "uno", "dos", "tres", "cuatro", "cinco", "seis", "un", "deux", "trois", "quatre", "cinq"]
}
