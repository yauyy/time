// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Time",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TimeCore", targets: ["TimeCore"]),
        .executable(name: "Time", targets: ["TimeApp"])
    ],
    targets: [
        .target(name: "TimeCore"),
        .executableTarget(name: "TimeApp", dependencies: ["TimeCore"]),
        .testTarget(name: "TimeCoreTests", dependencies: ["TimeCore"])
    ]
)
