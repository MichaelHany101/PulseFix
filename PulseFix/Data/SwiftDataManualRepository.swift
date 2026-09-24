import Foundation
import SwiftData

@MainActor
struct SwiftDataManualRepository: ManualRepository {
    let context: ModelContext

    func load() throws -> ManualLibrary {
        let manuals = try context.fetch(FetchDescriptor<StoredManual>()).map {
            ManualDocument(id: $0.id, name: $0.name, localURL: URL(fileURLWithPath: $0.localPath), pageCount: $0.pageCount, chunkCount: $0.chunkCount)
        }
        return ManualLibrary(manuals: manuals, chunks: try context.fetch(FetchDescriptor<StoredChunk>()).map(\.domain))
    }

    func loadWorkOrders() throws -> [WorkOrderRecord] {
        try context.fetch(FetchDescriptor<StoredWorkOrder>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).map {
            WorkOrderRecord(id: $0.id, title: $0.title, equipment: $0.equipment, decision: $0.decision, createdAt: $0.createdAt, supervisorNote: $0.supervisorNote)
        }
    }

    func save(manual: ManualDocument, chunks: [ManualChunk]) throws {
        context.insert(StoredManual(id: manual.id, name: manual.name, localPath: manual.localURL.path, pageCount: manual.pageCount, chunkCount: manual.chunkCount))
        chunks.forEach { context.insert(StoredChunk($0)) }
        do { try context.save() } catch { context.rollback(); throw error }
    }

    func save(draft: WorkOrderDraft, decision: WorkOrderDecision, note: String) throws {
        context.insert(StoredWorkOrder(draft: draft, decision: decision, supervisorNote: note))
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
