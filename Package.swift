// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "CTLabel",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "CTLabel", targets: ["CTLabel"]),
    ],
    targets: [
        .target(name: "CTLabel"),
    ]
)

