//
//  AppModel.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import Foundation
import Observation
import SwiftData

@MainActor @Observable
final class AppModel {
    enum Tab: Hashable { case manuals, diagnose, orders, trace }

    var language: AppLanguage = .english
    var selectedTab: Tab = .manuals
    var query = ""
    var manuals: [ManualDocument] = []
    var chunks: [ManualChunk] = []
    var retrieved: [RetrievedChunk] = []
    var streamedText = ""
    var diagnosis: DiagnosticResult?
    var isRunning = false
    var errorMessage: String?
    var traces: [RunTrace] = []
    var selectedCitation: Citation?
    var showingApproval = false

    let ingestor: any ManualIngesting
    let retriever: any ChunkRetrieving
    let provider: any DiagnosticProviding

    init(ingestor: any ManualIngesting = PDFTextIngestor(),
         retriever: any ChunkRetrieving = LexicalChunkRetriever(),
         provider: any DiagnosticProviding = GeminiDiagnosticProvider()) {
        self.ingestor = ingestor; self.retriever = retriever; self.provider = provider
    }

    var locale: Locale { Locale(identifier: language.rawValue) }

    func restore(from context: ModelContext) throws {
        chunks = try context.fetch(FetchDescriptor<StoredChunk>()).map(\.domain)
        manuals = try context.fetch(FetchDescriptor<StoredManual>()).map {
            ManualDocument(id: $0.id, name: $0.name, localURL: URL(fileURLWithPath: $0.localPath), pageCount: $0.pageCount, chunkCount: $0.chunkCount)
        }
        trace("ready", "Loaded \(manuals.count) manuals and \(chunks.count) chunks")
    }

    func importManual(_ url: URL, context: ModelContext) async {
        do {
            trace("ingestion.started", url.lastPathComponent)
            let (manual, newChunks) = try await ingestor.ingest(url: url)
            manuals.append(manual); chunks.append(contentsOf: newChunks)
            context.insert(StoredManual(id: manual.id, name: manual.name, localPath: manual.localURL.path, pageCount: manual.pageCount, chunkCount: manual.chunkCount))
            newChunks.forEach { context.insert(StoredChunk($0)) }
            try context.save(); trace("ingestion.completed", "\(newChunks.count) chunks")
        } catch { fail(error) }
    }

    func loadSeedManuals(context: ModelContext) async {
        guard manuals.isEmpty else { return }
        for name in ["Pump_PX200", "Conveyor_CV10", "Compressor_AC50", "Boiler_BL20", "Motor_MT75"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "txt", subdirectory: "SeedManuals") {
                await importManual(url, context: context)
            }
        }
    }

    func diagnose() async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isRunning = true; streamedText = ""; diagnosis = nil; errorMessage = nil
        trace("retrieval.started", query)
        retrieved = await retriever.retrieve(query: query, from: chunks, limit: 5)
        trace("retrieval.completed", "Top \(retrieved.count); prompt context \(retrieved.reduce(0) { $0 + $1.chunk.content.count }) characters")
        guard !retrieved.isEmpty else {
            diagnosis = DiagnosticResult(status: .insufficientEvidence,
                summary: language == .arabic ? "المعلومات غير كافية في الأدلة المتاحة" : "Not enough information in manuals",
                safetyPrerequisites: [], recommendedActions: [], citations: [], workOrder: nil)
            trace("guard.refused", "No relevant local evidence"); isRunning = false; return
        }
        let safetyText = retrieved.map(\.chunk.content).joined(separator: " ").lowercased()
        let safetyTerms = ["lockout", "isolate", "zero energy", "ppe", "سلامة", "عزل", "معدات الوقاية"]
        guard safetyTerms.contains(where: safetyText.contains) else {
            diagnosis = DiagnosticResult(status: .missingSafetyPrerequisites,
                summary: language == .arabic ? "متطلبات السلامة غير موجودة في الأدلة المسترجعة، لذلك تم رفض التشخيص." : "Safety prerequisites are missing from the retrieved manual evidence, so diagnosis was refused.",
                safetyPrerequisites: [], recommendedActions: [], citations: [], workOrder: nil)
            trace("guard.refused", "Safety prerequisites missing"); isRunning = false; return
        }
        let clock = ContinuousClock(); let started = clock.now; var firstToken: ContinuousClock.Instant?
        trace("llm.streaming", "Gemini request started")
        do {
            for try await event in provider.streamDiagnosis(query: query, evidence: retrieved, language: language) {
                switch event {
                case .text(let text):
                    if firstToken == nil { firstToken = clock.now; trace("stream.firstToken", "Received") }
                    streamedText += text
                case .completed(let result): diagnosis = result
                }
            }
            trace("llm.completed", "Elapsed \(started.duration(to: clock.now))")
        } catch { fail(error) }
        isRunning = false
    }

    func decide(_ decision: WorkOrderDecision, editedDraft: WorkOrderDraft, note: String, context: ModelContext) {
        context.insert(StoredWorkOrder(draft: editedDraft, decision: decision, supervisorNote: note))
        do { try context.save(); trace("approval.\(decision.rawValue)", editedDraft.title); showingApproval = false; selectedTab = .orders }
        catch { fail(error) }
    }

    private func trace(_ state: String, _ details: String) { traces.append(.init(timestamp: .now, state: state, details: details)) }
    private func fail(_ error: Error) { errorMessage = error.localizedDescription; trace("error", error.localizedDescription); isRunning = false }
}
