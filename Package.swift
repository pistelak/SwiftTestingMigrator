// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "XCTestMigrator",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "SwiftTestingMigrator",
      targets: ["SwiftTestingMigrator"]
    ),
    .library(
      name: "SwiftTestingMigratorKit",
      targets: ["SwiftTestingMigratorKit"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")
  ],
  targets: [
    .executableTarget(
      name: "SwiftTestingMigrator",
      dependencies: [
        "SwiftTestingMigratorKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
      ]
    ),
    .target(
      name: "SwiftTestingMigratorKit",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftBasicFormat", package: "swift-syntax")
      ],
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
      ]
    ),
    .testTarget(
      name: "SwiftTestingMigratorKitTests",
      dependencies: [
        "SwiftTestingMigratorKit",
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing")
      ],
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
      ]
    )
  ]
)