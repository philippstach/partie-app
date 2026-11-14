// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Mac-Werkzeug: misst, ob ein Fragetext in ein Fragefeld passt – mit derselben Satzlogik wie die App
// (Kreuzwortraetsel/Model/ClueMeasure.swift: schmale Schrift, deutsche Silbentrennung, Mindestgrößen,
// Zeilenabstand −2, Platz für den Pfeil).
//
// Aufruf (baut beim ersten Mal, danach sofort):
//   Tools/fragefeld_messen.sh < ein.tsv > aus.tsv
//
// Eingabe je Zeile (Tabulator-getrennt):  Text <TAB> Feldgröße in pt <TAB> geteilt (0/1) [<TAB> richtung]
//   richtung = rechts | unten (optional). Fehlt sie, gilt bei geteilt=1 „unten“ (strenger, Pfeil unten),
//   sonst „rechts“.
// Ausgabe je Zeile:  Text <TAB> Feldgröße <TAB> geteilt <TAB> passt (0/1) <TAB> Schriftgröße [<TAB> richtung]
//   Schriftgröße = größte passende in pt; passt es nicht, steht die Mindestschrift (8 pt einzeln / 7 pt geteilt).
// Leere Zeilen und Zeilen mit # am Anfang werden übersprungen. Zeile mit „Text“ in der ersten Spalte = Kopf, wird mitgeführt.
import Foundation

@main
struct FragefeldMessen {
    static func main() {
        var count = 0
        while let line = readLine(strippingNewline: true) {
            if line.isEmpty || line.hasPrefix("#") { continue }
            let cols = line.components(separatedBy: "\t")
            guard cols.count >= 3, let cell = Double(cols[1].replacingOccurrences(of: ",", with: ".")), cell > 0 else {
                if cols.first == "Text" { print(line + "\tpasst\tSchriftgröße") }
                continue
            }
            let text = cols[0]
            let split = cols[2] == "1"
            let richtung = cols.count > 3 ? cols[3] : nil
            let bottom = richtung.map { $0 == "unten" } ?? split
            let r = ClueFit.fitField(text, cell: CGFloat(cell), bottom: bottom, split: split)
            let size = r.fits ? r.size : ClueFit.minimum(split: split)
            var out = "\(text)\t\(cols[1])\t\(cols[2])\t\(r.fits ? 1 : 0)\t\(String(format: "%.1f", Double(size)))"
            if let richtung { out += "\t\(richtung)" }
            print(out)
            count += 1
        }
        FileHandle.standardError.write(Data("\(count) Zeilen gemessen\n".utf8))
    }
}
