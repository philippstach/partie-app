// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielSchocken",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielSchocken", targets: ["SpielSchocken"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
    ],
    targets: [
        .target(name: "SpielSchocken", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        .testTarget(name: "SpielSchockenTests", dependencies: ["SpielSchocken"]),
    ]
)
