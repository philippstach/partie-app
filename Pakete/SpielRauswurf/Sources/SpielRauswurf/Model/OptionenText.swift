// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

extension Optionen {
    /// Eine Zeile mit den Abweichungen vom Standard („Standard“ oder „Schlagpflicht: an · Drei Versuche: aus“).
    var kurzfassung: String {
        let std = Optionen.standard
        var teile: [String] = []
        func pruefe(_ wert: Bool, _ standard: Bool, _ schluessel: String) {
            if wert != standard { teile.append("\(L(schluessel)): \(L(wert ? "regeln.ein" : "regeln.aus"))") }
        }
        pruefe(rausPflicht, std.rausPflicht, "regel.rausPflicht")
        pruefe(startfeldRaeumen, std.startfeldRaeumen, "regel.startfeldRaeumen")
        pruefe(schlagpflicht, std.schlagpflicht, "regel.schlagpflicht")
        pruefe(dreiVersuche, std.dreiVersuche, "regel.dreiVersuche")
        pruefe(sechsNochmal, std.sechsNochmal, "regel.sechsNochmal")
        pruefe(zielUeberspringen, std.zielUeberspringen, "regel.zielUeberspringen")
        pruefe(startMitFigur, std.startMitFigur, "regel.startMitFigur")
        pruefe(rauswerfen, std.rauswerfen, "regel.rauswerfen")
        pruefe(teams, std.teams, "regel.teams")
        if figuren != std.figuren { teile.append("\(L("regel.figuren")): \(figuren)") }
        if spielende != std.spielende { teile.append(L("regel.spielende.\(spielende.rawValue)")) }
        return teile.isEmpty ? L("setup.standard") : teile.joined(separator: " · ")
    }
}
