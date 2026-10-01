// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BatHold",
    platforms: [.macOS(.v14)],
    products: [
        // Distinct build name avoids colliding with BatHold on case-insensitive volumes.
        .executable(name: "bathold-cli", targets: ["BatteryCLI"]),
        .executable(name: "BatHold", targets: ["BatteryMenu"])
    ],
    targets: [
        .target(name: "NativeCharge", publicHeadersPath: "include",
                cSettings: [.unsafeFlags(["-fobjc-arc"])],
                linkerSettings: [.linkedFramework("Foundation")]),
        .target(name: "BatteryCore", dependencies: ["NativeCharge"],
                linkerSettings: [.linkedFramework("IOKit")]),
        .executableTarget(name: "BatteryCLI", dependencies: ["BatteryCore"]),
        .executableTarget(name: "BatteryMenu", dependencies: ["BatteryCore"]),
        .testTarget(name: "BatteryCoreTests", dependencies: ["BatteryCore"])
    ]
)
