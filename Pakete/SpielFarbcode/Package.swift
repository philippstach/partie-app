// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Farbcode: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielFarbcode",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielFarbcode", targets: ["SpielFarbcode"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "FarbcodeKern"),
        .target(name: "SpielFarbcode", dependencies: ["FarbcodeKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "FarbcodeKernTests", dependencies: ["FarbcodeKern"]),
    ],
    swiftLanguageModes: [.v5]
)
