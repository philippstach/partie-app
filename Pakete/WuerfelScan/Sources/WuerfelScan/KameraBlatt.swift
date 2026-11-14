// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Kamera für ein Foto der Würfel. Das Bild bleibt im Speicher: es wird nicht gespeichert und nicht gesendet.
struct KameraAufnahme: UIViewControllerRepresentable {
    let onBild: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let c = UIImagePickerController()
        c.sourceType = .camera
        c.cameraCaptureMode = .photo
        c.delegate = context.coordinator
        return c
    }
    func updateUIViewController(_ c: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Koordinator { Koordinator(onBild: onBild) }

    final class Koordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onBild: (UIImage?) -> Void
        init(onBild: @escaping (UIImage?) -> Void) { self.onBild = onBild }
        func imagePickerController(_ p: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onBild(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ p: UIImagePickerController) { onBild(nil) }
    }
}

public enum WuerfelKamera {
    /// Ob dieses Gerät eine Kamera hat (der Simulator hat keine).
    public static var verfuegbar: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    /// Eigene Auswertung des Fotos (Augen in Lesereihenfolge). Die App setzt hier das trainierte Modell aus `WuerfelLive` ein;
    /// ohne Eintrag gilt die Umriss-Erkennung dieses Pakets.
    nonisolated(unsafe) public static var leser: (@Sendable (CGImage) -> [Int])?

    /// Eigene Kamera-Seite statt des System-Fotos (die App setzt hier die Live-Erkennung aus `WuerfelLive` ein).
    /// Sie bekommt die erwartete Würfelzahl (falls bekannt) und die Obergrenze (so viele Würfel hat das Spiel) und meldet die Augen in Lesereihenfolge, `nil` bei Abbruch.
    nonisolated(unsafe) public static var seite: ((_ erwartet: Int?, _ hoechstens: Int?, _ fertig: @escaping ([Int]?) -> Void) -> AnyView)?

    /// Zweites Gerät als Würfelscanner: Die App setzt hier die Empfangsseite aus `WuerfelFunk` ein. Sie meldet die Augen des nächsten Wurfs, `nil` bei Abbruch.
    /// Ohne Eintrag bieten die Spiele den Weg nicht an.
    nonisolated(unsafe) public static var scannerEmpfang: ((_ fertig: @escaping ([Int]?) -> Void) -> AnyView)?

    /// Fotografiert die Würfel und liefert die erkannten Augen (leer, wenn nichts zu erkennen war).
    static func lies(_ bild: UIImage) -> [Int] {
        // Ausrichtung festschreiben: Kamerafotos tragen die Drehung nur als Metadatum.
        let fest = UIGraphicsImageRenderer(size: bild.size).image { _ in bild.draw(at: .zero) }
        guard let cg = fest.cgImage else { return [] }
        if let leser { return leser(cg) }
        guard let e = try? WuerfelErkenner.erkenne(in: cg) else { return [] }
        return e.augen
    }
}

public extension View {
    /// Zeigt die Empfangsseite für das zweite Gerät als Blatt und liefert den ersten ankommenden Wurf.
    func wuerfelScannerEmpfang(isPresented: Binding<Bool>, onErgebnis: @escaping ([Int]?) -> Void) -> some View {
        sheet(isPresented: isPresented) {
            if let seite = WuerfelKamera.scannerEmpfang {
                seite { augen in
                    isPresented.wrappedValue = false
                    onErgebnis(augen)
                }
            }
        }
    }

    /// Zeigt die Kamera als Vollbild; danach kommen die erkannten Augen (Lesereihenfolge), bei Fehlschlag eine leere Liste.
    /// `nil` heißt: abgebrochen.
    func wuerfelKamera(isPresented: Binding<Bool>, erwartet: Int? = nil, hoechstens: Int? = nil, onErgebnis: @escaping ([Int]?) -> Void) -> some View {
        fullScreenCover(isPresented: isPresented) {
            if let seite = WuerfelKamera.seite {
                seite(erwartet, hoechstens) { augen in
                    isPresented.wrappedValue = false
                    onErgebnis(augen)
                }
            } else {
            KameraAufnahme { bild in
                isPresented.wrappedValue = false
                guard let bild else { onErgebnis(nil); return }
                DispatchQueue.global(qos: .userInitiated).async {
                    let augen = WuerfelKamera.lies(bild)
                    DispatchQueue.main.async { onErgebnis(augen) }
                }
            }
            .ignoresSafeArea()
            }
        }
    }
}

/// Die Kamera als eigene Seite für Aufrufer, die selbst präsentieren (zum Beispiel `WuerfelEingabeHaken.kamera` in SpieleKern):
/// die Live-Erkennung, wenn die App sie eingesetzt hat, sonst das System-Foto mit der Auswertung dieses Pakets.
/// Meldet die Augen in Lesereihenfolge, `nil` bei Abbruch.
public struct WuerfelKameraSeite: View {
    let erwartet: Int?
    let hoechstens: Int?
    let fertig: ([Int]?) -> Void

    public init(erwartet: Int?, hoechstens: Int?, fertig: @escaping ([Int]?) -> Void) {
        self.erwartet = erwartet; self.hoechstens = hoechstens; self.fertig = fertig
    }

    public var body: some View {
        if let seite = WuerfelKamera.seite {
            seite(erwartet, hoechstens, fertig)
        } else {
            KameraAufnahme { bild in
                guard let bild else { fertig(nil); return }
                DispatchQueue.global(qos: .userInitiated).async {
                    let augen = WuerfelKamera.lies(bild)
                    DispatchQueue.main.async { fertig(augen) }
                }
            }
            .ignoresSafeArea()
        }
    }
}
#endif

#if !canImport(UIKit)
import SwiftUI

public enum WuerfelKamera {
    public static var verfuegbar: Bool { false }
}

public extension View {
    func wuerfelKamera(isPresented: Binding<Bool>, erwartet: Int? = nil, hoechstens: Int? = nil, onErgebnis: @escaping ([Int]?) -> Void) -> some View { self }
    func wuerfelScannerEmpfang(isPresented: Binding<Bool>, onErgebnis: @escaping ([Int]?) -> Void) -> some View { self }
}
#endif
