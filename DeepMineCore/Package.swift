// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DeepMineCore",
    products: [
        .library(name: "DeepMineCore", targets: ["DeepMineCore"]),
        .executable(name: "DeepMineBalanceCLI", targets: ["DeepMineBalanceCLI"])
    ],
    targets: [
        .target(name: "DeepMineCore"),
        .executableTarget(name: "DeepMineBalanceCLI", dependencies: ["DeepMineCore"]),
        .testTarget(
            name: "DeepMineCoreTests",
            dependencies: ["DeepMineCore", "DeepMineBalanceCLI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
