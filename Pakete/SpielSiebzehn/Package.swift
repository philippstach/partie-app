// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Siebzehn: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSiebzehn",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSiebzehn", targets: ["SpielSiebzehn"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "SiebzehnKern"),
        .target(name: "SpielSiebzehn", dependencies: ["SiebzehnKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "SiebzehnKernTests", dependencies: ["SiebzehnKern"]),
    ],
    swiftLanguageModes: [.v5]
)
