// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Ungleichung: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielUngleichung",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielUngleichung", targets: ["SpielUngleichung"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "UngleichungKern"),
        .target(name: "SpielUngleichung", dependencies: ["UngleichungKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "UngleichungKernTests", dependencies: ["UngleichungKern"]),
    ],
    swiftLanguageModes: [.v5]
)
