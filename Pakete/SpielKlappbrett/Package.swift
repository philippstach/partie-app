// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Klappbrett: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielKlappbrett",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielKlappbrett", targets: ["SpielKlappbrett"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "KlappbrettKern"),
        .target(name: "SpielKlappbrett", dependencies: ["KlappbrettKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "KlappbrettKernTests", dependencies: ["KlappbrettKern"]),
    ],
    swiftLanguageModes: [.v5]
)
