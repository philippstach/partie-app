// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Schiffe: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSchiffe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchiffe", targets: ["SpielSchiffe"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "SchiffeKern"),
        .target(name: "SpielSchiffe", dependencies: ["SchiffeKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "SchiffeKernTests", dependencies: ["SchiffeKern"]),
    ],
    swiftLanguageModes: [.v5]
)
