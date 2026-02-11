// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JengaClaude",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "JengaClaude",
            path: "Sources/JengaClaude"
        ),
        .testTarget(
            name: "JengaClaudeTests",
            dependencies: ["JengaClaude"],
            path: "Tests/JengaClaudeTests"
        ),
    ]
)
