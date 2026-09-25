// swift-tools-version: 6.2
import PackageDescription

// Compile the app's real logic files, not copies. UI/PDFKit/SwiftData/API adapters
// remain in the iOS app; these tests exercise their protocol boundaries with fakes.
let package = Package(
    name: "PulseFixLogic",
    platforms: [.macOS(.v14), .iOS(.v26)],
    products: [.library(name: "PulseFixCore", targets: ["PulseFixCore"])],
    targets: [
        .target(
            name: "PulseFixCore",
            path: "PulseFix",
            exclude: [
                "Presentation", "Resources", "Assets.xcassets", "Info.plist",
                "ContentView.swift", "PulseFixApp.swift", "App/Theme.swift",
                "Data/DocumentIngestor.swift", "Data/GeminiDiagnosticProvider.swift",
                "Data/PersistenceModels.swift", "Data/SwiftDataManualRepository.swift"
            ],
            sources: [
                "Domain/Domain.swift", "Domain/DiagnosisUseCase.swift",
                "Domain/ManualRepository.swift", "Data/LocalRetriever.swift",
                "App/AppModel.swift", "App/StreamingSummary.swift"
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "PulseFixCoreTests",
            dependencies: ["PulseFixCore"],
            path: "PulseFixTests",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ],
    swiftLanguageModes: [.v5]
)
