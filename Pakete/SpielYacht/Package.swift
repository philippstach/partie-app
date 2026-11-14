// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielYacht",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielYacht", targets: ["SpielYacht"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../WuerfelScan"),
        .package(path: "../SpielHilfen"),   // 1.0 (P5): Tageskarte mit Serie
    ],
    targets: [
        .target(name: "SpielYacht", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
            .product(name: "WuerfelScan", package: "WuerfelScan"),
            .product(name: "SpielHilfen", package: "SpielHilfen"),
        ]),
        .testTarget(name: "SpielYachtTests", dependencies: ["SpielYacht"]),
    ]
)
