import Foundation

struct ManualLibrary {
    let manuals: [ManualDocument]
    let chunks: [ManualChunk]
}

struct WorkOrderRecord: Identifiable {
    let id: UUID
    let title: String
    let equipment: String
    let decision: WorkOrderDecision
    let createdAt: Date
    let supervisorNote: String
}

enum WorkOrderDecision: String, Codable, CaseIterable { case approved, rejected, edited }

@MainActor
protocol ManualRepository {
    func load() throws -> ManualLibrary
    func loadWorkOrders() throws -> [WorkOrderRecord]
    func save(manual: ManualDocument, chunks: [ManualChunk]) throws
    func save(draft: WorkOrderDraft, decision: WorkOrderDecision, note: String) throws
}
