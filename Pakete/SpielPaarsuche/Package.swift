// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Paarsuche: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielPaarsuche",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielPaarsuche", targets: ["SpielPaarsuche"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "PaarsucheKern"),
        .target(name: "SpielPaarsuche", dependencies: ["PaarsucheKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "PaarsucheKernTests", dependencies: ["PaarsucheKern"]),
    ],
    swiftLanguageModes: [.v5]
)
