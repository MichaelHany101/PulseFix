//
//  Domain.swift
//  PulseFix
//
//  Created by Michael Hany on 22/09/2026.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"
    var id: String { rawValue }
    var title: String { self == .english ? "English" : "العربية" }
}

struct ManualDocument: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let localURL: URL
    let pageCount: Int
    let chunkCount: Int
}

struct ManualChunk: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let manualID: UUID
    let manualName: String
    let pageNumber: Int
    let section: String
    let content: String
}

struct RetrievedChunk: Identifiable, Hashable, Sendable {
    let chunk: ManualChunk
    let score: Double
    var id: String { chunk.id }
}

struct Citation: Identifiable, Hashable, Codable, Sendable {
    let sourceID: String
    let manualName: String
    let pageNumber: Int
    var id: String { sourceID }
}

enum DiagnosticStatus: String, Codable, Sendable {
    case grounded
    case insufficientEvidence = "insufficient_evidence"
    case missingSafetyPrerequisites = "missing_safety_prerequisites"
}

struct WorkOrderDraft: Codable, Hashable, Sendable {
    var title: String
    var equipment: String
    var priority: String
    var steps: [String]
}

struct DiagnosticResult: Codable, Hashable, Sendable {
    let status: DiagnosticStatus
    let summary: String
    let safetyPrerequisites: [String]
    let recommendedActions: [String]
    let citations: [Citation]
    let workOrder: WorkOrderDraft?
}

enum StreamEvent: Sendable {
    case text(String)
    case completed(DiagnosticResult)
}

struct RunTrace: Identifiable, Hashable, Sendable {
    let id = UUID()
    let timestamp: Date
    let state: String
    let details: String
}

protocol ManualIngesting: Sendable {
    func ingest(url: URL) async throws -> (ManualDocument, [ManualChunk])
}

protocol ChunkRetrieving: Sendable {
    func retrieve(query: String, from chunks: [ManualChunk], limit: Int) async -> [RetrievedChunk]
}

protocol DiagnosticProviding: Sendable {
    func streamDiagnosis(query: String, evidence: [RetrievedChunk], language: AppLanguage) -> AsyncThrowingStream<StreamEvent, Error>
}

enum PulseFixError: LocalizedError {
    case unreadableDocument, unsupportedDocument, missingAPIKey, invalidResponse, ungroundedCitation
    var errorDescription: String? {
        switch self {
        case .unreadableDocument: "The selected manual could not be read."
        case .unsupportedDocument: "Only PDF and TXT manuals are supported."
        case .missingAPIKey: "Add GEMINI_API_KEY to Config/Secrets.xcconfig."
        case .invalidResponse: "Gemini returned an invalid response."
        case .ungroundedCitation: "The response contained a citation outside the retrieved evidence."
        }
    }
}
