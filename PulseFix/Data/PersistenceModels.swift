//
//  PersistenceModels.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import Foundation
import SwiftData

@Model
final class StoredManual {
    @Attribute(.unique) var id: UUID
    var name: String
    var localPath: String
    var pageCount: Int
    var chunkCount: Int
    var createdAt: Date

    init(id: UUID, name: String, localPath: String, pageCount: Int, chunkCount: Int) {
        self.id = id; self.name = name; self.localPath = localPath
        self.pageCount = pageCount; self.chunkCount = chunkCount; self.createdAt = .now
    }
}

@Model
final class StoredChunk {
    @Attribute(.unique) var id: String
    var manualID: UUID
    var manualName: String
    var pageNumber: Int
    var section: String
    var content: String

    init(_ chunk: ManualChunk) {
        id = chunk.id; manualID = chunk.manualID; manualName = chunk.manualName
        pageNumber = chunk.pageNumber; section = chunk.section; content = chunk.content
    }

    var domain: ManualChunk {
        ManualChunk(id: id, manualID: manualID, manualName: manualName, pageNumber: pageNumber, section: section, content: content)
    }
}



@Model
final class StoredWorkOrder {
    @Attribute(.unique) var id: UUID
    var title: String
    var equipment: String
    var priority: String
    var steps: [String]
    var decisionRaw: String
    var createdAt: Date
    var supervisorNote: String

    init(draft: WorkOrderDraft, decision: WorkOrderDecision, supervisorNote: String) {
        id = UUID(); title = draft.title; equipment = draft.equipment; priority = draft.priority
        steps = draft.steps; decisionRaw = decision.rawValue; createdAt = .now; self.supervisorNote = supervisorNote
    }

    var decision: WorkOrderDecision { WorkOrderDecision(rawValue: decisionRaw) ?? .rejected }
}
