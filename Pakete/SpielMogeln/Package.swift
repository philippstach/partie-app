// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription
import Foundation

// Mogeln: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
// „NEU“: die Mogeln-Handkarte ist eine eigene Ansicht (`MHandKarte`); im älteren Stand steht die Zeichnung noch in `MogelnSpiel`.
let neu = ((try? String(contentsOfFile: Context.packageDirectory + "/Sources/SpielMogeln/Mogeln.swift", encoding: .utf8)) ?? "").contains("struct MHandKarte")

let package = Package(
    name: "SpielMogeln",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielMogeln", targets: ["SpielMogeln"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "MogelnKern"),
        .target(name: "SpielMogeln", dependencies: ["MogelnKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "MogelnKernTests", dependencies: ["MogelnKern"]),
        // Designwechsel: Klar-Vergleich der selbst gezeichneten Karten (Werkzeug/designwechsel_klar_vergleich_davor.sh)
        .testTarget(name: "MogelnKartenBilderTests", dependencies: ["SpielMogeln", "MogelnKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")],
                    path: "Tests/MogelnKartenBilderTests", swiftSettings: neu ? [.define("NEU")] : []),
    ],
    swiftLanguageModes: [.v5]
)
