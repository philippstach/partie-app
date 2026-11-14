// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Herzensjagd: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielHerzensjagd",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielHerzensjagd", targets: ["SpielHerzensjagd"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "HerzensjagdKern"),
        .target(name: "SpielHerzensjagd", dependencies: ["HerzensjagdKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "HerzensjagdKernTests", dependencies: ["HerzensjagdKern"]),
        // Designwechsel: Klar-Vergleich der selbst gezeichneten Karten (Werkzeug/designwechsel_klar_vergleich_davor.sh)
        .testTarget(name: "HerzensjagdKartenBilderTests", dependencies: ["SpielHerzensjagd", "HerzensjagdKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")], path: "Tests/HerzensjagdKartenBilderTests"),
    ],
    swiftLanguageModes: [.v5]
)
