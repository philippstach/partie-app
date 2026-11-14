// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Schiebepuzzle: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSchiebepuzzle",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchiebepuzzle", targets: ["SpielSchiebepuzzle"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "SchiebepuzzleKern"),
        .target(name: "SpielSchiebepuzzle", dependencies: ["SchiebepuzzleKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "SchiebepuzzleKernTests", dependencies: ["SchiebepuzzleKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
    ],
    swiftLanguageModes: [.v5]
)
