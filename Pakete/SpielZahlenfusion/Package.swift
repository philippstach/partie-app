// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Zahlenfusion: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielZahlenfusion",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielZahlenfusion", targets: ["SpielZahlenfusion"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "ZahlenfusionKern"),
        .target(name: "SpielZahlenfusion", dependencies: ["ZahlenfusionKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "ZahlenfusionKernTests", dependencies: ["ZahlenfusionKern"]),
    ],
    swiftLanguageModes: [.v5]
)
