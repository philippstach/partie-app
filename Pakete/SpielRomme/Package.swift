// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Romme: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielRomme",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielRomme", targets: ["SpielRomme"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../../Test/DesignBilder")],
    targets: [
        .target(name: "RommeKern"),
        .target(name: "SpielRomme", dependencies: ["RommeKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "RommeKernTests", dependencies: ["RommeKern"]),
        // Designwechsel: Klar-Vergleich der selbst gezeichneten Karten (Werkzeug/designwechsel_klar_vergleich_davor.sh)
        .testTarget(name: "RommeKartenBilderTests", dependencies: ["SpielRomme", "RommeKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "DesignBilder", package: "DesignBilder")], path: "Tests/RommeKartenBilderTests"),
    ],
    swiftLanguageModes: [.v5]
)
