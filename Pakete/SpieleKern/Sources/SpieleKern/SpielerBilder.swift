// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Fotos der Personen im Verzeichnis. Liegen als kleine JPEG-Dateien im Programmordner (nicht in den Standard-Einstellungen),
/// bleiben auf dem Gerät und werden mit der Person gelöscht.
public enum SpielerBilder {
    static var ordner: URL {
        let u = (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Spielerbilder", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
    static func datei(_ id: UUID) -> URL { ordner.appendingPathComponent(id.uuidString + ".jpg") }

    /// Größte Kantenlänge des gespeicherten Bildes in Pixeln (reicht für 44-pt-Kreise bis zur Statistik-Ansicht).
    public static let kante: CGFloat = 320

    /// Gespeicherte JPEG-Daten des Fotos (für Listen, die Bilder als Daten brauchen); `nil` ohne Foto.
    public static func daten(_ id: UUID) -> Data? { try? Data(contentsOf: datei(id)) }

    /// Legt fertige Bilddaten (aus einer Sicherung) unverändert ab. `false` bei leeren Daten.
    @discardableResult
    public static func ablegen(_ daten: Data, fuer id: UUID) -> Bool {
        guard !daten.isEmpty, (try? daten.write(to: datei(id), options: .atomic)) != nil else { return false }
        #if canImport(UIKit)
        zwischenspeicher.removeObject(forKey: id.uuidString as NSString)
        #endif
        return true
    }

    /// Quadratischer Mittelausschnitt: Zielkante (nie größer als `kante`, nie hochgerechnet) und Skalierung der kürzeren Seite.
    static func ausschnitt(breite: CGFloat, hoehe: CGFloat) -> (ziel: CGFloat, faktor: CGFloat)? {
        guard breite > 0, hoehe > 0 else { return nil }
        let seite = min(breite, hoehe)
        let ziel = min(kante, seite)
        return (ziel, ziel / seite)
    }

    public static func loeschen(_ id: UUID) {
        try? FileManager.default.removeItem(at: datei(id))
        #if canImport(UIKit)
        zwischenspeicher.removeObject(forKey: id.uuidString as NSString)
        #endif
    }

    #if canImport(UIKit)
    nonisolated(unsafe) private static let zwischenspeicher = NSCache<NSString, UIImage>()

    /// Skaliert auf einen quadratischen Ausschnitt (Mitte) und sichert als JPEG. `false`, wenn die Daten kein Bild sind.
    @discardableResult
    public static func sichern(_ daten: Data, fuer id: UUID) -> Bool {
        guard let bild = UIImage(data: daten), bild.size.width > 0, bild.size.height > 0 else { return false }
        guard let (ziel, f) = ausschnitt(breite: bild.size.width, hoehe: bild.size.height) else { return false }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let neu = UIGraphicsImageRenderer(size: CGSize(width: ziel, height: ziel), format: format).image { _ in
            let b = CGSize(width: bild.size.width * f, height: bild.size.height * f)
            bild.draw(in: CGRect(x: (ziel - b.width) / 2, y: (ziel - b.height) / 2, width: b.width, height: b.height))
        }
        guard let jpg = neu.jpegData(compressionQuality: 0.82) else { return false }
        do { try jpg.write(to: datei(id), options: .atomic) } catch { return false }
        zwischenspeicher.removeObject(forKey: id.uuidString as NSString)
        return true
    }

    public static func bild(_ id: UUID) -> UIImage? {
        if let b = zwischenspeicher.object(forKey: id.uuidString as NSString) { return b }
        guard let d = try? Data(contentsOf: datei(id)), let b = UIImage(data: d) else { return nil }
        zwischenspeicher.setObject(b, forKey: id.uuidString as NSString)
        return b
    }
    #else
    @discardableResult public static func sichern(_ daten: Data, fuer id: UUID) -> Bool { false }
    #endif
}
