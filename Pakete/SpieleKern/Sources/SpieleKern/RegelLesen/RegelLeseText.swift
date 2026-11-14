// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Bauplan RL-K, Punkt 3: Zerlegt den Lesetext (`## `, `### `, `- `, `1. `, `*Beispiel:*`, `|`-Tabellen, `@form`) in Blöcke. Reine Rechnung, ohne Oberfläche.
public enum RegelBlock: Equatable, Sendable {
    public struct Punkt: Equatable, Sendable { public let text: String; public let ebene: Int }
    public struct Nummer: Equatable, Sendable { public let text: String; public let beispiel: String? }
    public enum Form: String, Equatable, Sendable { case zwei, a, b, c }
    case abschnitt(id: Int, titel: String)
    case zwischentitel(String)
    case absatz(String)
    case liste([Punkt])
    case nummern([Nummer])
    case beispiel(String)
    case tabelle(kopf: [String], zeilen: [[String]], form: Form)

    public static func bloecke(aus quelle: String) -> [RegelBlock] {
        var aus: [RegelBlock] = []
        let zeilen = quelle.components(separatedBy: "\n")
        var n = 0, abschnittNr = 0
        var absatz: [String] = []
        var form: Form?
        func absatzSchliessen() { if !absatz.isEmpty { aus.append(.absatz(absatz.joined(separator: " "))); absatz = [] } }
        func zellen(_ z: String) -> [String] {
            var t = z.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("|") { t.removeFirst() }
            if t.hasSuffix("|") { t.removeLast() }
            return t.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        func nummerPrefix(_ z: String) -> String? {
            guard let punkt = z.firstIndex(of: "."), punkt != z.startIndex, z[z.startIndex..<punkt].allSatisfy(\.isNumber) else { return nil }
            let rest = z[z.index(after: punkt)...]
            guard rest.first == " " else { return nil }
            return String(rest.dropFirst())
        }
        while n < zeilen.count {
            let roh = zeilen[n]
            let z = roh.trimmingCharacters(in: .whitespaces)
            n += 1
            if z.isEmpty { absatzSchliessen(); continue }
            if z.hasPrefix("@form ") {
                form = Form(rawValue: z.dropFirst(6).trimmingCharacters(in: .whitespaces).lowercased()); continue
            }
            if z.hasPrefix("### ") { absatzSchliessen(); aus.append(.zwischentitel(String(z.dropFirst(4)))); continue }
            if z.hasPrefix("## ") { absatzSchliessen(); aus.append(.abschnitt(id: abschnittNr, titel: String(z.dropFirst(3)))); abschnittNr += 1; continue }
            if z.count > 4, z.hasPrefix("**"), z.hasSuffix("**"), !z.dropFirst(2).dropLast(2).contains("**") {
                absatzSchliessen(); aus.append(.zwischentitel(String(z.dropFirst(2).dropLast(2)))); continue
            }
            if z.hasPrefix("*Beispiel:*") { absatzSchliessen(); aus.append(.beispiel(z.dropFirst(11).trimmingCharacters(in: .whitespaces))); continue }
            if z.hasPrefix("|") {
                absatzSchliessen()
                let kopf = zellen(z)
                if n < zeilen.count, zellen(zeilen[n]).allSatisfy({ $0.count >= 2 && $0.allSatisfy { "-:".contains($0) } }) { n += 1 }
                var reihen: [[String]] = []
                while n < zeilen.count, zeilen[n].trimmingCharacters(in: .whitespaces).hasPrefix("|") { reihen.append(zellen(zeilen[n])); n += 1 }
                aus.append(.tabelle(kopf: kopf, zeilen: reihen, form: kopf.count == 2 ? .zwei : (form ?? .c)))
                form = nil; continue
            }
            if z.hasPrefix("- ") {
                absatzSchliessen()
                var punkte: [Punkt] = []
                var k = n - 1
                while k < zeilen.count {
                    let r = zeilen[k]; let t = r.trimmingCharacters(in: .whitespaces)
                    guard t.hasPrefix("- ") else { break }
                    let eingerueckt = r.prefix(while: { $0 == " " }).count >= 2
                    punkte.append(Punkt(text: String(t.dropFirst(2)), ebene: eingerueckt ? 1 : 0)); k += 1
                }
                aus.append(.liste(punkte)); n = k; continue
            }
            if nummerPrefix(z) != nil {
                absatzSchliessen()
                var punkte: [Nummer] = []
                var k = n - 1
                while k < zeilen.count, let t = nummerPrefix(zeilen[k].trimmingCharacters(in: .whitespaces)) {
                    k += 1
                    var beispiel: String?
                    if k < zeilen.count, zeilen[k].hasPrefix(" "), zeilen[k].trimmingCharacters(in: .whitespaces).hasPrefix("*Beispiel:*") {
                        beispiel = zeilen[k].trimmingCharacters(in: .whitespaces).dropFirst(11).trimmingCharacters(in: .whitespaces); k += 1
                    }
                    punkte.append(Nummer(text: t, beispiel: beispiel))
                }
                aus.append(.nummern(punkte)); n = k; continue
            }
            absatz.append(z)
        }
        absatzSchliessen()
        return aus
    }

    /// Titel der Abschnitte für das Menü „Inhalt“.
    public static func abschnitte(in bloecke: [RegelBlock]) -> [(id: Int, titel: String)] {
        bloecke.compactMap { if case let .abschnitt(id, titel) = $0 { return (id, titel) } else { return nil } }
    }
}
