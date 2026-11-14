// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import SpielViererreihe

/// Designwechsel D.4: Viererreihe-Spielbild (neue Fassung) in drei Designs, hell und dunkel (nur mit `DESIGN_BILDER`).
@MainActor
final class DesignViererBilder: XCTestCase {
    func testSpielbild() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        KlarGlasHaken.spielart = { .brett }
        KlarGlasHaken.flaeche = { Gattung.brett.farbe.color }
        KlarGlasHaken.accentText = { Gattung.brett.farbe.textFarbe }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = ViererNeuSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}, bilanz: { (siege: 3, partien: 7) })
                    .frame(width: 390, height: 844).background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-vierer-spiel.png"))
            }
        }
        Design.art = .klar
    }

    /// Partie mitten im Spiel (8 Steine, gegen den Computer wie auf dem Gerät), drei Designs, hell und dunkel.
    func testMitteSpiel() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        KlarGlasHaken.spielart = { .brett }
        KlarGlasHaken.flaeche = { Gattung.brett.farbe.color }
        KlarGlasHaken.accentText = { Gattung.brett.farbe.textFarbe }
        var vorgabe = NeuSpiel(zweiSpieler: false, stufe: .mittel)
        vorgabe.partie = try Partie(beginner: 1, zuege: [3, 3, 4, 2, 3, 4, 2, 4])
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = ViererNeuSpiel(teilnehmer: [SpielTeilnehmer(name: "Philipp"), SpielTeilnehmer(name: "Computer", computer: true)], ende: { _ in }, abbrechen: {}, bilanz: { (siege: 3, partien: 7) }, vorgabe: vorgabe)
                    .frame(width: 390, height: 844).background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-vierer-mitte.png"))
            }
        }
        Design.art = .klar
    }

    /// Glasplatte (Runde 2, Aufgabe G): Spielmitte mit 12 Steinen in Tinte und Salon, hell und dunkel; dazu Salon dunkel mit Gewinnreihe.
    func testGlas() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        KlarGlasHaken.spielart = { .brett }
        KlarGlasHaken.flaeche = { Gattung.brett.farbe.color }
        KlarGlasHaken.accentText = { Gattung.brett.farbe.textFarbe }
        func bild(_ zuege: [Int], _ design: DesignArt, _ dunkel: Bool, _ name: String) throws {
            var vorgabe = NeuSpiel(zweiSpieler: true, stufe: .mittel)
            vorgabe.partie = try Partie(beginner: 1, zuege: zuege)
            Design.art = design
            let v = ViererNeuSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}, bilanz: { (siege: 3, partien: 7) }, vorgabe: vorgabe)
                .frame(width: 390, height: 844).background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
            let r = ImageRenderer(content: v); r.scale = 2
            try XCTUnwrap(r.uiImage?.pngData()).write(to: URL(fileURLWithPath: ziel).appendingPathComponent(name + ".png"))
        }
        let mitte = [3, 3, 4, 2, 3, 4, 2, 4, 1, 5, 6, 0]
        for d in [DesignArt.tinte, .salon] { for dunkel in [false, true] { try bild(mitte, d, dunkel, "glas-\(d.rawValue)-\(dunkel ? "dunkel" : "hell")") } }
        try bild([3, 0, 3, 0, 3, 0, 3], .salon, true, "glas-salon-dunkel-sieg")
        Design.art = .klar
    }
}
#endif
