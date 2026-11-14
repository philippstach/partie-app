// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Truco: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielTruco",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielTruco", targets: ["SpielTruco"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "TrucoKern"),
        .target(name: "SpielTruco", dependencies: ["TrucoKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "TrucoKernTests", dependencies: ["TrucoKern"]),
    ],
    swiftLanguageModes: [.v5]
)
