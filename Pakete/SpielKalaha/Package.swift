// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Kalaha: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielKalaha",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielKalaha", targets: ["SpielKalaha"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "KalahaKern"),
        .target(name: "SpielKalaha", dependencies: ["KalahaKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "KalahaKernTests", dependencies: ["KalahaKern"]),
    ],
    swiftLanguageModes: [.v5]
)
