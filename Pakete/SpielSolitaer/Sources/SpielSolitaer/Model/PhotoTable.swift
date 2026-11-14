// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UIKit

/// Eigenes Foto als Tisch (BACKLOG N5): höchstens 1.600 px, weichgezeichnet (20 pt), abgedunkelt (35 %), als JPEG im App-Ordner.
enum PhotoTable {
    static let maxSide: CGFloat = 1600
    static let blurPoints: CGFloat = 20
    static let darkening: CGFloat = 0.35
    /// Breite eines iPhone-Bildschirms in Punkten; daraus ergibt sich der Weichzeichner-Radius in Pixeln
    static let referenceWidth: CGFloat = 393

    nonisolated static func url(in folder: URL = AppModel.standardFolder) -> URL { folder.appending(path: "tisch-foto.jpg") }

    /// Aus einem beliebigen Foto das fertige Tischbild machen (JPEG-Daten); nil, wenn das Foto nicht lesbar ist
    nonisolated static func process(_ data: Data) -> Data? {
        // Gleich beim Lesen auf höchstens 1.600 px an der langen Seite verkleinern und die EXIF-Ausrichtung anwenden (ImageIO):
        // das Originalfoto (bei 48 MP rund 190 MB entpackt) wird nie in voller Größe in den Speicher geholt.
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceShouldCacheImmediately: true, kCGImageSourceThumbnailMaxPixelSize: maxSide]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let small = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let size = CGSize(width: small.width, height: small.height)
        let input = CIImage(cgImage: small)
        // Weichzeichnen: 20 pt eines Bildschirms; der Rand wird fortgesetzt, damit er nicht ausblutet
        let radius = blurPoints * size.width / referenceWidth
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = input.clampedToExtent()
        blur.radius = Float(radius)
        guard let blurred = blur.outputImage?.cropped(to: input.extent) else { return nil }
        // Abdunkeln: Farben mit 65 % multiplizieren (= 35 % Schwarz darüber)
        let dark = CIFilter.colorMatrix()
        dark.inputImage = blurred
        let k = 1 - darkening
        dark.rVector = CIVector(x: k, y: 0, z: 0, w: 0)
        dark.gVector = CIVector(x: 0, y: k, z: 0, w: 0)
        dark.bVector = CIVector(x: 0, y: 0, z: k, w: 0)
        dark.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        guard let out = dark.outputImage?.cropped(to: input.extent),
              let cg = CIContext(options: [.workingColorSpace: NSNull()]).createCGImage(out, from: input.extent) else { return nil }
        return UIImage(cgImage: cg).jpegData(compressionQuality: 0.8)
    }

    nonisolated static func save(_ data: Data, in folder: URL = AppModel.standardFolder) -> Bool {
        guard let jpeg = process(data) else { return false }
        return (try? jpeg.write(to: url(in: folder), options: .atomic)) != nil
    }

    static func load(in folder: URL = AppModel.standardFolder) -> UIImage? {
        UIImage(contentsOfFile: url(in: folder).path)
    }

    static func remove(in folder: URL = AppModel.standardFolder) {
        try? FileManager.default.removeItem(at: url(in: folder))
    }
}
