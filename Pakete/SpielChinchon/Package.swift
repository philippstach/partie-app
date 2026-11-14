// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Chinchon: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielChinchon",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielChinchon", targets: ["SpielChinchon"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "ChinchonKern"),
        .target(name: "SpielChinchon", dependencies: ["ChinchonKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "ChinchonKernTests", dependencies: ["ChinchonKern"]),
    ],
    swiftLanguageModes: [.v5]
)
