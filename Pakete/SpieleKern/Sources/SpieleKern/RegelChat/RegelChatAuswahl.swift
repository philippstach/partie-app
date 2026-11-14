// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Textwerkzeuge für den Regel-Chat: Wörter zerlegen, Abschnitte nach Stichwörtern auswählen, kürzen.
public enum RegelChatAuswahl {
    /// Füllwörter, die bei der Suche nichts sagen (ohne Umlaute, so wie `woerter` sie liefert)
    private static let fuellwoerter: Set<String> = [
        "der", "die", "das", "den", "dem", "des", "ein", "eine", "einen", "einem", "einer", "und", "oder", "aber",
        "wie", "was", "wer", "wann", "wo", "warum", "wieso", "wird", "werden", "wurde", "ist", "sind", "war", "hat",
        "haben", "kann", "kannst", "konnen", "darf", "darfst", "durfen", "muss", "musst", "mussen", "ich", "du",
        "wir", "ihr", "sie", "man", "mir", "mich", "dich", "uns", "nicht", "kein", "keine", "mit", "von", "vom",
        "zum", "zur", "bei", "nach", "fur", "auf", "aus", "wenn", "dann", "auch", "noch", "nur", "mal", "bitte",
        "gibt", "gilt", "mein", "meine", "dein", "deine", "sich", "dass", "als", "ob", "im", "in", "am", "an",
    ]

    /// Kleinbuchstaben, ohne Akzente und Umlautpunkte, nur Wörter mit mindestens 3 Zeichen ohne Füllwörter.
    public static func woerter(_ text: String) -> [String] {
        let glatt = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
        return glatt.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !fuellwoerter.contains($0) }
    }

    /// Zwei Wörter passen, wenn sie gleich sind oder (ab 5 Zeichen) mit denselben 5 Zeichen beginnen
    /// („übernehmen“ und „übernommen“, „Punkte“ und „Punkten“). Grob, aber ohne Wörterbuch.
    static func passt(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        guard a.count >= 5, b.count >= 5 else { return false }
        return a.commonPrefix(with: b).count >= 5
    }

    /// Wie gut passt der Abschnitt zu den Wörtern der Frage? Titel und Stichwörter zählen 3, Text 1 je Wort.
    public static func punkte(frageWoerter: [String], abschnitt: RegelAbschnitt) -> Int {
        let titel = woerter(abschnitt.titel)
        let stichwort = abschnitt.stichwoerter.flatMap(woerter)
        let text = Set(woerter(abschnitt.text))
        var summe = 0
        for wort in Set(frageWoerter) {
            if titel.contains(where: { passt(wort, $0) }) { summe += 3 }
            if stichwort.contains(where: { passt(wort, $0) }) { summe += 3 }
            if text.contains(where: { passt(wort, $0) }) { summe += 1 }
        }
        return summe
    }

    /// Kürzt an einem Satzende, sonst hart mit „…“.
    public static func kuerzen(_ text: String, auf grenze: Int) -> String {
        guard grenze > 0, text.count > grenze else { return text }
        let schnitt = String(text.prefix(grenze))
        if let ende = schnitt.range(of: ". ", options: .backwards),
           schnitt.distance(from: schnitt.startIndex, to: ende.upperBound) > grenze / 2 {
            return String(schnitt[..<ende.lowerBound]) + "."
        }
        return String(text.prefix(max(grenze - 1, 1))) + "…"
    }

    /// Die passenden Abschnitte zur Frage, beste zuerst: höchstens `maxAnzahl` und zusammen höchstens `maxZeichen`
    /// Zeichen (ein zu langer erster Treffer wird gekürzt, weitere, die nicht mehr passen, entfallen).
    /// Trifft nichts, kommt mit `ersatzErster` der erste Abschnitt (meist die Übersicht), sonst nichts.
    public static func waehle(frage: String, aus abschnitte: [RegelAbschnitt], maxAnzahl: Int = 3,
                              maxZeichen: Int = 3200, ersatzErster: Bool = true) -> [RegelAbschnitt] {
        guard maxAnzahl > 0, !abschnitte.isEmpty else { return [] }
        let frageWoerter = woerter(frage)
        let bewertet = abschnitte.enumerated()
            .map { (index: $0.offset, punkte: punkte(frageWoerter: frageWoerter, abschnitt: $0.element), abschnitt: $0.element) }
            .filter { $0.punkte > 0 }
            .sorted { $0.punkte != $1.punkte ? $0.punkte > $1.punkte : $0.index < $1.index }
        var kandidaten = bewertet.map { $0.abschnitt }
        if kandidaten.isEmpty && ersatzErster { kandidaten = [abschnitte[0]] }

        var gewaehlt: [RegelAbschnitt] = []
        var zeichen = 0
        for abschnitt in kandidaten {
            if gewaehlt.count >= maxAnzahl { break }
            let laenge = abschnitt.titel.count + abschnitt.text.count + 2
            if zeichen + laenge <= maxZeichen {
                gewaehlt.append(abschnitt)
                zeichen += laenge
            } else if gewaehlt.isEmpty {
                let platz = max(maxZeichen - abschnitt.titel.count - 2, 1)
                gewaehlt.append(RegelAbschnitt(titel: abschnitt.titel, text: kuerzen(abschnitt.text, auf: platz)))
                zeichen = maxZeichen
            }
        }
        return gewaehlt
    }
}

/// Zahlen-Wächter: Nennt die Antwort des Modells eine Zahl, die weder in der Frage noch in den Regeln, Fakten
/// oder Beispielen steht, wird sie nicht gezeigt. So erfindet das Modell keine Punkte, Fristen oder Mengen.
public enum RegelChatZahlen {
    /// Ganze Zahlen in einem Text (1.000 wird 1000, „−500“ wird 500)
    public static func zahlen(in text: String) -> [Int] {
        let bereinigt = text.replacingOccurrences(of: #"(?<=\d)\.(?=\d{3})"#, with: "", options: .regularExpression)
        guard let re = try? NSRegularExpression(pattern: #"\d+"#) else { return [] }
        return re.matches(in: bereinigt, range: NSRange(bereinigt.startIndex..., in: bereinigt)).compactMap { treffer in
            Range(treffer.range, in: bereinigt).flatMap { Int(bereinigt[$0]) }
        }
    }

    /// Erlaubt sind alle Zahlen aus den Quellen, dazu 0 bis 12.
    public static func erlaubt(quellen: [String]) -> Set<Int> {
        Set(quellen.flatMap { zahlen(in: $0) }).union(0...12)
    }

    public static func ok(antwort: String, quellen: [String]) -> Bool {
        let erlaubteZahlen = erlaubt(quellen: quellen)
        return zahlen(in: antwort).allSatisfy(erlaubteZahlen.contains)
    }
}
