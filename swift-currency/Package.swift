// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-currency",
    platforms: [
        .macOS(.v14)  // Add this line to specify macOS 14 (Sonoma) requirement
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "swift-currency",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "MySQLNIO", package: "mysql-nio"),
                .product(name: "MySQLKit", package: "mysql-kit"),
            ]
        ),
        .testTarget(name: "CurrencyTests", dependencies: ["swift-currency"]),
    ]
)
