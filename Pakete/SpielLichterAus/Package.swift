// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// LichterAus: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielLichterAus",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielLichterAus", targets: ["SpielLichterAus"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "LichterAusKern"),
        .target(name: "SpielLichterAus", dependencies: ["LichterAusKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "LichterAusKernTests", dependencies: ["LichterAusKern"]),
    ],
    swiftLanguageModes: [.v5]
)
