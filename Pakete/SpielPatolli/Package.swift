// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Patolli: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielPatolli",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielPatolli", targets: ["SpielPatolli"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "PatolliKern"),
        .target(name: "SpielPatolli", dependencies: ["PatolliKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "PatolliKernTests", dependencies: ["PatolliKern"]),
    ],
    swiftLanguageModes: [.v5]
)
