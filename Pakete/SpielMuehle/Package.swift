// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Muehle: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielMuehle",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielMuehle", targets: ["SpielMuehle"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen"), .package(path: "../../Test/DesignBilder")],
    targets: [
        .target(name: "MuehleKern"),
        .target(name: "SpielMuehle", dependencies: ["MuehleKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "MuehleKernTests", dependencies: ["MuehleKern", .product(name: "SpieleKern", package: "SpieleKern")]),
        .testTarget(name: "MuehleKlarTests", dependencies: ["SpielMuehle", "MuehleKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v5]
)
