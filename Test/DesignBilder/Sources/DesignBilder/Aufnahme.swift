// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import UIKit
import KlarGlas
import Fangen

/// Zeichnet eine Ansicht ohne Simulator als PNG (Mac Catalyst). Standard: 390 × 844 pt, Maßstab 2.
/// Zwei Wege: `ImageRenderer` (schnell, zeichnet aber keine UIKit-gestützten Ansichten wie ScrollView oder Listen)
/// und ein unsichtbares Fenster mit `UIHostingController` (zeichnet alles, was UIKit darstellen kann).
@MainActor
public enum Aufnahme {
    public static let telefon = CGSize(width: 390, height: 844)

    /// Welche Darstellungen `alle` zeichnet (false = hell, true = dunkel).
    public static var toene = [false, true]

    // Große Schrift lässt sich auf diesem Weg nicht aufnehmen: Unter Mac Catalyst hat die Schriftgröße des Geräts keine Wirkung
    // (geprüft am 10.11.2026: SwiftUI-Text mit `dynamicTypeSize` und `UIFont.preferredFont` bleiben bei jeder Stufe gleich groß).

    /// Zielordner: Umgebungsvariable `DESIGN_BILDER`, sonst `Partie/DesignWechsel/Bilder` neben dem Worktree.
    public static var ordner: URL {
        if let o = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !o.isEmpty { return URL(fileURLWithPath: o) }
        // …/Arbeit/Test/DesignBilder/Sources/DesignBilder/Aufnahme.swift → fünf Ebenen hoch ist der Worktree
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { u.deleteLastPathComponent() }
        return u.deletingLastPathComponent().appendingPathComponent("Bilder")
    }

    /// Die Ansicht im gewünschten Design und in heller oder dunkler Darstellung, auf dem Seitengrund des Designs.
    public static func rahmen<V: View>(_ ansicht: V, dunkel: Bool, groesse: CGSize, klasse: UserInterfaceSizeClass? = nil) -> some View {
        ansicht
            .frame(width: groesse.width, height: groesse.height)
            .background(Color.seitenGrund)
            .designWurzel()
            .environment(\.horizontalSizeClass, klasse)   // außerhalb der Wurzel: die Wurzel liest die Größenklasse wie in der App
            .environment(\.colorScheme, dunkel ? .dark : .light)
    }

    /// Zeichnet mit `ImageRenderer`.
    public static func bild<V: View>(_ ansicht: V, design: DesignArt, dunkel: Bool, groesse: CGSize = telefon, klasse: UserInterfaceSizeClass? = nil) -> UIImage? {
        Design.art = design
        let r = ImageRenderer(content: rahmen(ansicht, dunkel: dunkel, groesse: groesse, klasse: klasse))
        r.scale = 2
        r.proposedSize = ProposedViewSize(groesse)
        return r.uiImage
    }

    /// Ein einziges Fenster für alle Aufnahmen. Es bleibt bis zum Ende des Testlaufs bestehen: Wird ein Fenster verworfen,
    /// erklärt UIKit (ohne laufende App) die Szene für ungültig, und jedes weitere Fenster scheitert.
    private static var fenster: UIWindow?

    /// Zeichnet über ein Fenster mit `UIHostingController` (auch ScrollView, Listen, Formulare).
    /// Ohne laufende App wirft UIKit beim ersten Zugriff auf das Fenster einmal eine Ausnahme; sie wird abgefangen und der Schritt wiederholt.
    public static func fensterBild<V: View>(_ ansicht: V, design: DesignArt, dunkel: Bool, groesse: CGSize = telefon, klasse: UserInterfaceSizeClass? = nil) -> UIImage? {
        Design.art = design
        let host = UIHostingController(rootView: rahmen(ansicht, dunkel: dunkel, groesse: groesse, klasse: klasse))
        host.overrideUserInterfaceStyle = dunkel ? .dark : .light
        var bild: UIImage?
        let schritt = {
            let f: UIWindow
            if let vorhanden = fenster { f = vorhanden } else {
                f = UIWindow(frame: CGRect(origin: .zero, size: groesse))
                fenster = f
            }
            if f.isHidden { f.isHidden = false }
            f.frame = CGRect(origin: .zero, size: groesse)
            f.overrideUserInterfaceStyle = dunkel ? .dark : .light
            f.rootViewController = host
            host.view.frame = f.bounds
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.25))
            let format = UIGraphicsImageRendererFormat(); format.scale = 2
            bild = UIGraphicsImageRenderer(size: groesse, format: format).image { kontext in
                if !host.view.drawHierarchy(in: CGRect(origin: .zero, size: groesse), afterScreenUpdates: true) {
                    host.view.layer.render(in: kontext.cgContext)
                }
            }
        }
        for _ in 0..<3 where bild == nil { _ = DesignBilderVersuche(schritt) }
        return bild
    }

    /// Ganze Seite: erst über das Fenster (zeichnet auch ScrollView); bleibt das Bild leer, mit `ImageRenderer`.
    /// Rückgabe: das Bild und das benutzte Verfahren („fenster“ oder „renderer“).
    public static func seite<V: View>(_ ansicht: V, design: DesignArt, dunkel: Bool, groesse: CGSize = telefon, klasse: UserInterfaceSizeClass? = nil) -> (bild: UIImage?, verfahren: String) {
        let f = fensterBild(ansicht, design: design, dunkel: dunkel, groesse: groesse, klasse: klasse)
        if inhaltAnteil(f) >= 0.01 { return (f, "fenster") }
        return (bild(ansicht, design: design, dunkel: dunkel, groesse: groesse, klasse: klasse), "renderer")
    }

    /// Zeichnet eine Szene in allen drei Designs, hell und dunkel, und schreibt sie als `<design>-<hell|dunkel>-<szene>.png`.
    /// Rückgabe: Namen der Bilder, die leer geblieben sind.
    public static func alle<V: View>(_ szene: String, groesse: CGSize = telefon, vorher: (DesignArt) -> Void = { _ in }, _ ansicht: () -> V) -> [String] {
        var leer: [String] = []
        for design in DesignArt.allCases {
            for dunkel in toene {
                Design.art = design
                vorher(design)
                let n = name(design, dunkel: dunkel, szene)
                let e = seite(ansicht(), design: design, dunkel: dunkel, groesse: groesse)
                if !schreiben(e.bild, name: n) || inhaltAnteil(e.bild) < 0.01 { leer.append(n) }
                print("BILD \(n) [\(e.verfahren)] Inhalt \(String(format: "%.3f", inhaltAnteil(e.bild)))")
            }
        }
        Design.art = .klar
        return leer
    }

    @discardableResult
    public static func schreiben(_ bild: UIImage?, name: String) -> Bool {
        guard let daten = bild?.pngData() else { return false }
        try? FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        return (try? daten.write(to: ordner.appendingPathComponent(name + ".png"))) != nil
    }

    /// Dateiname nach dem Muster `<design>-<hell|dunkel>-<szene>`.
    public static func name(_ design: DesignArt, dunkel: Bool, _ szene: String) -> String {
        "\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-\(szene)"
    }

    /// Anteil der Bildpunkte, die nicht die Farbe der linken oberen Ecke haben (0 = einfarbig, also nichts gezeichnet).
    public static func inhaltAnteil(_ bild: UIImage?) -> Double {
        guard let cg = bild?.cgImage, let daten = cg.dataProvider?.data, let p = CFDataGetBytePtr(daten) else { return 0 }
        let bpp = cg.bitsPerPixel / 8, zeile = cg.bytesPerRow
        guard bpp >= 3 else { return 0 }
        var anders = 0, gesamt = 0
        let schritt = 4
        for y in stride(from: 0, to: cg.height, by: schritt) {
            for x in stride(from: 0, to: cg.width, by: schritt) {
                let i = y * zeile + x * bpp
                gesamt += 1
                if abs(Int(p[i]) - Int(p[0])) > 6 || abs(Int(p[i + 1]) - Int(p[1])) > 6 || abs(Int(p[i + 2]) - Int(p[2])) > 6 { anders += 1 }
            }
        }
        return gesamt == 0 ? 0 : Double(anders) / Double(gesamt)
    }
}
#endif
