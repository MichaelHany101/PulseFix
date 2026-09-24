import Foundation

/// Conservative evidence gate for this training application, not a safety certification.
struct DiagnosisUseCase: Sendable {
    let retriever: any ChunkRetrieving

    func retrieve(query: String, chunks: [ManualChunk]) async -> [RetrievedChunk] {
        await retriever.retrieve(query: query, from: chunks, limit: 5)
    }

    static func hasSafetyPrerequisites(_ evidence: [RetrievedChunk]) -> Bool {
        guard !evidence.isEmpty else { return false }
        // Every represented manual must carry its own explicit safety block.
        return Dictionary(grouping: evidence, by: { $0.chunk.manualID }).values.allSatisfy { items in
            items.contains { item in
                let text = item.chunk.content.lowercased()
                guard let start = text.range(of: "safety prerequisites") ?? text.range(of: "متطلبات السلامة") else { return false }
                var block = String(text[start.upperBound...])
                for end in ["observed symptoms", "possible causes", "inspection guidance", "step 1", "الأعراض", "الأسباب", "الخطوة 1"] {
                    if let range = block.range(of: end) { block = String(block[..<range.lowerBound]) }
                }
                let groups = [
                    ["isolate", "disconnect", "عزل", "افصل"],
                    ["lockout", "lock out", "القفل", "قفل"],
                    ["zero energy", "zero stored pressure", "zero pressure", "absence of voltage", "cannot start", "انعدام", "صفر", "عدم وجود جهد"],
                    ["ppe", "eye protection", "معدات الوقاية", "وقاية"]
                ]
                return groups.allSatisfy { group in group.contains(where: block.contains) }
            }
        }
    }

    static func refusal(_ status: DiagnosticStatus, language: AppLanguage) -> DiagnosticResult {
        let summary: String
        if status == .missingSafetyPrerequisites {
            summary = language == .arabic ? "متطلبات السلامة غير موجودة أو غير مكتملة في الأدلة المسترجعة، لذلك تم رفض التشخيص." : "Safety prerequisites are missing or incomplete in the retrieved evidence, so diagnosis was refused."
        } else {
            summary = language == .arabic ? "المعلومات غير كافية في الأدلة المتاحة" : "Not enough information in manuals"
        }
        return DiagnosticResult(status: status, summary: summary, safetyPrerequisites: [], recommendedActions: [], citations: [], workOrder: nil)
    }

    static func validate(_ result: DiagnosticResult, evidence: [RetrievedChunk], language: AppLanguage) throws -> DiagnosticResult {
        let sources = Dictionary(evidence.map { ($0.chunk.id, $0.chunk) }, uniquingKeysWith: { first, _ in first })
        var seen = Set<String>()
        let citations = try result.citations.compactMap { citation -> Citation? in
            guard let chunk = sources[citation.sourceID] else { throw PulseFixError.ungroundedCitation }
            guard seen.insert(chunk.id).inserted else { return nil }
            return Citation(sourceID: chunk.id, manualName: chunk.manualName, pageNumber: chunk.pageNumber)
        }
        guard result.status == .grounded else { return refusal(result.status, language: language) }
        guard !citations.isEmpty, !result.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PulseFixError.ungroundedCitation
        }
        let citedManuals = Set(citations.compactMap { sources[$0.sourceID]?.manualID })
        let citedEvidence = evidence.filter { citedManuals.contains($0.chunk.manualID) }
        guard hasSafetyPrerequisites(citedEvidence), result.safetyPrerequisites.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return refusal(.missingSafetyPrerequisites, language: language)
        }
        return DiagnosticResult(status: .grounded, summary: result.summary, safetyPrerequisites: result.safetyPrerequisites,
                                recommendedActions: result.recommendedActions, citations: citations, workOrder: result.workOrder)
    }
}
