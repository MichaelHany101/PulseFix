//
//  AppModel.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import Foundation
import Observation


@MainActor @Observable
final class AppModel {
    enum Tab: Hashable { case manuals, diagnose, orders, trace }

    var language: AppLanguage = .english {
        didSet {
            guard language != oldValue else { return }
            languageRevision = UUID()
            diagnosis = nil
            streamedText = ""
            errorMessage = nil
            showingApproval = false
            selectedCitation = nil
        }
    }
    private var languageRevision = UUID()
    var selectedTab: Tab = .manuals
    var query = ""
    var manuals: [ManualDocument] = []
    var orders: [WorkOrderRecord] = []
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

    init(ingestor: any ManualIngesting,
         retriever: any ChunkRetrieving,
         provider: any DiagnosticProviding) {
        self.ingestor = ingestor; self.retriever = retriever; self.provider = provider
    }

    private var repository: (any ManualRepository)?
    var firstTextSeconds: Double?
    var totalSeconds: Double?
    var promptCharacters = 0
    var streamedCharacters = 0
    var responseCharactersPerSecond: Double? {
        guard let seconds = totalSeconds, seconds > 0 else { return nil }
        return Double(streamedCharacters) / seconds
    }

    var locale: Locale { Locale(identifier: language.rawValue) }

    func restore(using repository: any ManualRepository) throws {
        self.repository = repository
        let library = try repository.load()
        manuals = library.manuals
        chunks = library.chunks
        orders = try repository.loadWorkOrders()
        trace("ready", "")
    }

    func importManual(_ url: URL) async {
        do {
            guard let repository else { throw PulseFixError.storageUnavailable }
            trace("ingestion.started", url.lastPathComponent)
            let (manual, newChunks) = try await ingestor.ingest(url: url)
            try repository.save(manual: manual, chunks: newChunks)
            manuals.append(manual)
            chunks.append(contentsOf: newChunks)
            trace("ingestion.completed", "\(newChunks.count)")
        } catch { fail(error) }
    }

    func loadSeedManuals() async {
        for name in ["AC-50_Air_Compressor_Manual", "BL-20_Industrial_Boiler_Manual", "CV-10_Belt_Conveyor_Manual", "MT-75_Three_Phase_Motor_Manual", "PX-200_Centrifugal_Pump_Manual"] {
            guard !manuals.contains(where: { $0.name == name + ".pdf" }) else { continue }
            // Xcode may flatten synchronized resource folders into the bundle root.
            guard let url = Bundle.main.url(forResource: name, withExtension: "pdf", subdirectory: "SeedManuals")
                ?? Bundle.main.url(forResource: name, withExtension: "pdf") else {
                fail(PulseFixError.missingSeedManual)
                continue
            }
            await importManual(url)
        }
    }

    func diagnose() async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isRunning else { return }
        let requestLanguage = language
        let requestRevision = languageRevision
        isRunning = true; streamedText = ""; diagnosis = nil; errorMessage = nil
        trace("retrieval.started", query)
        firstTextSeconds = nil; totalSeconds = nil; promptCharacters = 0; streamedCharacters = 0
        let useCase = DiagnosisUseCase(retriever: retriever)
        retrieved = await useCase.retrieve(query: query, chunks: chunks)
        guard languageRevision == requestRevision else { isRunning = false; return }
        trace("retrieval.completed", "\(retrieved.count)")
        guard !retrieved.isEmpty else {
            diagnosis = DiagnosisUseCase.refusal(.insufficientEvidence, language: requestLanguage)
            trace("guard.noEvidence", ""); isRunning = false; return
        }
        guard DiagnosisUseCase.hasSafetyPrerequisites(retrieved) else {
            diagnosis = DiagnosisUseCase.refusal(.missingSafetyPrerequisites, language: requestLanguage)
            trace("guard.noSafety", ""); isRunning = false; return
        }
        let clock = ContinuousClock(); let started = clock.now; var firstToken: ContinuousClock.Instant?
        trace("llm.streaming", "")
        var rawResponse = ""
        do {
            for try await event in provider.streamDiagnosis(query: query, evidence: retrieved, language: requestLanguage) {
                guard languageRevision == requestRevision else { break }
                switch event {
                case .requestPrepared(let count): promptCharacters = count
                case .text(let text):
                    if firstToken == nil {
                        firstToken = clock.now
                        firstTextSeconds = Self.seconds(started.duration(to: clock.now))
                        trace("stream.firstToken", "")
                    }
                    rawResponse += text
                    streamedCharacters = rawResponse.count
                    streamedText = StreamingSummary.extract(from: rawResponse)
                case .completed(let result): diagnosis = try DiagnosisUseCase.validate(result, evidence: retrieved, language: requestLanguage)
                }
            }
            totalSeconds = Self.seconds(started.duration(to: clock.now))
            trace(languageRevision == requestRevision ? "llm.completed" : "llm.cancelled", "")
        } catch {
            totalSeconds = Self.seconds(started.duration(to: clock.now))
            if languageRevision == requestRevision { streamedText = ""; fail(error) }
        }
        isRunning = false
    }

    func decide(_ decision: WorkOrderDecision, editedDraft: WorkOrderDraft, note: String) {
        do {
            guard let repository else { throw PulseFixError.storageUnavailable }
            try repository.save(draft: editedDraft, decision: decision, note: note)
            orders = try repository.loadWorkOrders()
            trace("approval.\(decision.rawValue)", editedDraft.title)
            showingApproval = false; selectedTab = .orders
        } catch { fail(error) }
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    private func trace(_ state: String, _ details: String) { traces.append(.init(timestamp: .now, state: state, details: details)) }
    private func fail(_ error: Error) {
        let message: String
        if let error = error as? any AppLocalizedError { message = error.message(language: language) }
        else { message = language == .arabic ? "تعذر إكمال العملية. تحقق من الملف أو الاتصال ثم حاول مجددًا." : "The operation could not be completed. Check the file or connection and retry." }
        errorMessage = message; trace("error", message); isRunning = false
    }
}
