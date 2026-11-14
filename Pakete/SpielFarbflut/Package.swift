// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Farbflut: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielFarbflut",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielFarbflut", targets: ["SpielFarbflut"]), .library(name: "FarbflutKern", targets: ["FarbflutKern"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "FarbflutKern"),
        .target(name: "SpielFarbflut", dependencies: ["FarbflutKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "FarbflutKernTests", dependencies: ["FarbflutKern"]),
    ],
    swiftLanguageModes: [.v5]
)
