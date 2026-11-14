// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Dame: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielDame",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielDame", targets: ["SpielDame"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "DameKern"),
        .target(name: "SpielDame", dependencies: ["DameKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "DameKernTests", dependencies: ["DameKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
