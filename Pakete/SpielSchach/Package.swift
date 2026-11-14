// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Schach: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSchach",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchach", targets: ["SpielSchach"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "SchachKern"),
        .target(name: "SpielSchach", dependencies: ["SchachKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "SchachKernTests", dependencies: ["SchachKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
