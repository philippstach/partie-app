// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import WuerfelScan

/// Ein Würfel, wie ihn die Erkennung in einem einzelnen Bild sieht.
public struct GesehenerWuerfel: Equatable, Sendable {
    public let augen: Int
    /// Lage im Bild, normiert 0…1, Ursprung oben links.
    public let rahmen: CGRect
    /// Wie sicher die Erkennung ist (0…1); Verfahren ohne eigene Angabe melden 1.
    public let sicherheit: Double
    public init(augen: Int, rahmen: CGRect, sicherheit: Double = 1) { self.augen = augen; self.rahmen = rahmen; self.sicherheit = sicherheit }

    /// Höchstens `anzahl` Würfel: die sichersten bleiben (ein Spiel weiß, wie viele Würfel es gibt; was darüber hinausgeht, sind Fehlfunde).
    public static func dieSichersten(_ liste: [GesehenerWuerfel], hoechstens anzahl: Int?) -> [GesehenerWuerfel] {
        guard let anzahl, anzahl > 0, liste.count > anzahl else { return liste }
        let grenze = liste.map(\.sicherheit).sorted(by: >)[anzahl - 1]
        var frei = anzahl
        return liste.filter { w in
            guard frei > 0, w.sicherheit >= grenze else { return false }
            frei -= 1; return true
        }
    }
}

/// Die Erkennung hinter einem Protokoll: später durch ein anderes Verfahren (z. B. ein trainiertes Modell) ersetzbar.
public protocol WuerfelErkennung: Sendable {
    func erkenne(in bild: CGImage) throws -> [GesehenerWuerfel]
    /// Prüft nur die Umgebung einer angetippten Stelle noch einmal (für einen Würfel, den die Gesamtsuche übersehen hat).
    /// - punkt: Stelle im Bild, normiert 0…1, Ursprung oben links.
    /// - ueblicheKante: Kantenlänge der anderen Würfel als Anteil der kurzen Bildseite (`nil`: unbekannt).
    func erkenneNah(in bild: CGImage, um punkt: CGPoint, ueblicheKante: Double?) throws -> GesehenerWuerfel?
    /// Live-Suche mit dem Wissen aus den vorigen Bildern (Kamera-Seite).
    /// - verfolgt: Rahmen der Würfel, die schon verfolgt werden (normiert 0…1, Ursprung oben links). Dort genügt eine niedrigere Sicherheit,
    ///   damit ein bekannter Würfel nicht für ein Bild verschwindet.
    /// - ganzesBild: `false` erlaubt, nur den Bereich um die verfolgten Würfel abzusuchen (schneller); `true` sucht überall (neue Würfel).
    func erkenne(in bild: CGImage, verfolgt: [CGRect], ganzesBild: Bool) throws -> [GesehenerWuerfel]
}

public extension WuerfelErkennung {
    /// Verfahren ohne Vorwissen suchen jedes Bild ganz ab.
    func erkenne(in bild: CGImage, verfolgt: [CGRect], ganzesBild: Bool) throws -> [GesehenerWuerfel] { try erkenne(in: bild) }

    /// Verfahren ohne eigene Nahprüfung finden nichts.
    func erkenneNah(in bild: CGImage, um punkt: CGPoint, ueblicheKante: Double?) throws -> GesehenerWuerfel? { nil }
}

/// Standard: die Vision-Augenzählung aus F6 (`WuerfelErkenner`).
public struct VisionWuerfelErkennung: WuerfelErkennung {
    public init() {}
    public func erkenne(in bild: CGImage) throws -> [GesehenerWuerfel] {
        try WuerfelErkenner.erkenne(in: bild).wuerfel.map { GesehenerWuerfel(augen: $0.augen, rahmen: $0.rahmen) }
    }
}
