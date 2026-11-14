// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import Foundation
import CoreGraphics
@testable import SpieleKern

@Suite("Foto-Zuschnitt und Ich/Andere")
struct FotoZuschnittTests {
    @Test func zoomEinsZeigtMittelausschnittDerKuerzerenSeite() throws {
        let z = try #require(FotoZuschnitt(bild: CGSize(width: 400, height: 200), kasten: 100))
        let q = z.quelle(zoom: 1, versatz: .zero)
        #expect(q == CGRect(x: 100, y: 0, width: 200, height: 200))
    }
    @Test func zoomVerkleinertAusschnittUndBleibtImBild() throws {
        let z = try #require(FotoZuschnitt(bild: CGSize(width: 400, height: 200), kasten: 100))
        let q = z.quelle(zoom: 2, versatz: CGSize(width: 10_000, height: -10_000))
        #expect(q.width == 100 && q.height == 100)
        #expect(q.minX >= 0 && q.maxX <= 400 && q.minY >= 0 && q.maxY <= 200)
    }
    @Test func versatzNachRechtsZeigtLinkenBildteil() throws {
        let z = try #require(FotoZuschnitt(bild: CGSize(width: 200, height: 200), kasten: 100))
        let mitte = z.quelle(zoom: 2, versatz: .zero)
        let rechts = z.quelle(zoom: 2, versatz: CGSize(width: 20, height: 0))
        #expect(rechts.minX < mitte.minX)
    }
    @Test func zoomWirdBegrenzt() {
        #expect(FotoZuschnitt.zoomBegrenzen(0.2) == 1)
        #expect(FotoZuschnitt.zoomBegrenzen(99) == FotoZuschnitt.hoechsterZoom)
        #expect(FotoZuschnitt(bild: .zero, kasten: 10) == nil)
    }

    @MainActor @Test func andereAnlegenOhneIchMachtNieIchUndIchSetztNurEinen() throws {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = try #require(v.speichern(name: "Anna", avatar: "", farbeIndex: 0, ich: false))
        #expect(!anna.ich && v.ich == nil)
        let ich = try #require(v.speichern(name: "Philipp", avatar: "", farbeIndex: 1, ich: true))
        #expect(ich.ich && v.alle.filter(\.ich).count == 1)
        let ben = try #require(v.speichern(name: "Ben", avatar: "", farbeIndex: 2, ich: false))
        #expect(!ben.ich && v.ich?.name == "Philipp")
        // Altes Verhalten ohne Angabe: erste Person ist Ich
        let w = SpielerVerzeichnis(ablage: SpeicherAblage())
        #expect(w.speichern(name: "Eva", avatar: "", farbeIndex: 0)?.ich == true)
    }
}
