// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import UIKit
@testable import SpielSolitaer

@MainActor
final class FotoTischTests: XCTestCase {
    private func folder() -> URL {
        let u = FileManager.default.temporaryDirectory.appending(path: "foto-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    /// Ein Testfoto: großes Bild mit hartem Streifen (damit man das Weichzeichnen erkennt)
    private func photo(width: CGFloat, height: CGFloat) -> Data {
        let f = UIGraphicsImageRendererFormat.default(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: f).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            UIColor.black.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        }.jpegData(compressionQuality: 1)!
    }

    private func brightness(_ image: UIImage, atX x: CGFloat, y: CGFloat) -> CGFloat {
        guard let cg = image.cgImage, let data = cg.dataProvider?.data, let ptr = CFDataGetBytePtr(data) else { return -1 }
        let bpp = cg.bitsPerPixel / 8, row = cg.bytesPerRow
        let o = Int(y) * row + Int(x) * bpp
        return (CGFloat(ptr[o]) + CGFloat(ptr[o + 1]) + CGFloat(ptr[o + 2])) / (3 * 255)
    }

    func testGroessteSeiteHoechstens1600() throws {
        let jpeg = try XCTUnwrap(PhotoTable.process(photo(width: 4000, height: 3000)))
        let img = try XCTUnwrap(UIImage(data: jpeg))
        XCTAssertEqual(max(img.size.width * img.scale, img.size.height * img.scale), 1600, accuracy: 1)
        let small = try XCTUnwrap(UIImage(data: try XCTUnwrap(PhotoTable.process(photo(width: 800, height: 600)))))
        XCTAssertEqual(small.size.width * small.scale, 800, accuracy: 1)                      // kleine Fotos werden nicht vergrößert
    }

    func testAbgedunkeltUndWeichgezeichnet() throws {
        let out = try XCTUnwrap(PhotoTable.process(photo(width: 1600, height: 800)))
        let img = try XCTUnwrap(UIImage(data: out))
        // helle Seite: Weiß × 0,65 ≈ 0,65
        let light = brightness(img, atX: 1500, y: 400)
        XCTAssertEqual(light, 0.65, accuracy: 0.05)
        // dunkle Seite bleibt dunkel
        XCTAssertLessThan(brightness(img, atX: 100, y: 400), 0.1)
        // weicher Übergang: direkt an der Kante weder ganz hell noch ganz dunkel
        let edge = brightness(img, atX: 800, y: 400)
        XCTAssertGreaterThan(edge, 0.15); XCTAssertLessThan(edge, 0.5)
    }

    func testNichtLesbaresFotoWirdAbgelehnt() {
        XCTAssertNil(PhotoTable.process(Data([1, 2, 3, 4])))
    }

    func testSpeichernLadenEntfernen() throws {
        let dir = folder()
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "ft-\(UUID().uuidString)")!, photoFolder: dir)
        XCTAssertNil(prefs.tablePhoto)
        XCTAssertFalse(prefs.setTablePhoto(data: Data([0, 1, 2])))                            // kaputt: nichts ändert sich
        XCTAssertEqual(prefs.tableStyle, .linen)
        XCTAssertTrue(prefs.setTablePhoto(data: photo(width: 1200, height: 800)))
        XCTAssertEqual(prefs.tableStyle, .photo)
        XCTAssertNotNil(prefs.tablePhoto)
        XCTAssertTrue(FileManager.default.fileExists(atPath: PhotoTable.url(in: dir).path))
        prefs.removeTablePhoto()
        XCTAssertEqual(prefs.tableStyle, .linen)
        XCTAssertNil(prefs.tablePhoto)
        XCTAssertFalse(FileManager.default.fileExists(atPath: PhotoTable.url(in: dir).path))
    }

    func testFotoBleibtNachNeustartUndFehltDieDateiGiltLeinen() throws {
        let dir = folder()
        let d = UserDefaults(suiteName: "ft-\(UUID().uuidString)")!
        let a = AppPreferences(defaults: d, photoFolder: dir)
        XCTAssertTrue(a.setTablePhoto(data: photo(width: 600, height: 600)))
        let b = AppPreferences(defaults: d, photoFolder: dir)
        XCTAssertEqual(b.tableStyle, .photo)
        XCTAssertNotNil(b.tablePhoto)
        PhotoTable.remove(in: dir)
        let c = AppPreferences(defaults: d, photoFolder: dir)                                 // Datei weg, Einstellung steht noch auf Foto
        XCTAssertEqual(c.tableStyle, .linen)
    }

    func testKontrastRegelFuerFoto() {
        for back in CardBackStyle.allCases { XCTAssertTrue(back.needsContrastBorder(on: .photo), back.rawValue) }
        XCTAssertTrue(TableStyle.photo.lightText)
    }
}
