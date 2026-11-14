// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// SpitSpeed: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielSpitSpeed",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSpitSpeed", targets: ["SpielSpitSpeed"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "SpitSpeedKern", dependencies: [.product(name: "SpieleKern", package: "SpieleKern")]),
        .target(name: "SpielSpitSpeed", dependencies: ["SpitSpeedKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "SpitSpeedKernTests", dependencies: ["SpitSpeedKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
