// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Lagerplatz: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielLagerplatz",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielLagerplatz", targets: ["SpielLagerplatz"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "LagerplatzKern"),
        .target(name: "SpielLagerplatz", dependencies: ["LagerplatzKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "LagerplatzKernTests", dependencies: ["LagerplatzKern"]),
    ],
    swiftLanguageModes: [.v5]
)
