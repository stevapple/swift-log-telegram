// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-log-telegram",
  platforms: [
    .macOS(.v12)
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "LoggingTelegram", targets: ["LoggingTelegram"])
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "LoggingTelegram",
      dependencies: [
        .product(name: "Logging", package: "swift-log")
      ]),
    .testTarget(
      name: "LoggingTelegramTests",
      dependencies: [
        .target(name: "LoggingTelegram")
      ]),
  ]
)
