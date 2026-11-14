// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Schiffsfracht: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSchiffsfracht",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchiffsfracht", targets: ["SpielSchiffsfracht"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "SchiffsfrachtKern", dependencies: [.product(name: "SpieleKern", package: "SpieleKern")]),
        .target(name: "SpielSchiffsfracht", dependencies: ["SchiffsfrachtKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "SchiffsfrachtKernTests", dependencies: ["SchiffsfrachtKern"]),
    ],
    swiftLanguageModes: [.v5]
)
