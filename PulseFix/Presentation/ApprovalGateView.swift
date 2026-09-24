//
//  ApprovalGateView.swift
//  PulseFix
//
//  Created by Michael Hany on 24/09/2026.
//

import SwiftUI
import SwiftData

struct ApprovalGateView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var draft: WorkOrderDraft?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("approval.title") {
                    Label("approval.reject", systemImage: "person.badge.shield.checkmark").foregroundStyle(.orange)
                }
                if let draftBinding = Binding($draft) {
                    Section("editable_work_order") {
                        TextField("Title", text: draftBinding.title)
                        TextField("equipment", text: draftBinding.equipment)
                        TextField("priority", text: draftBinding.priority)
                        ForEach(draftBinding.steps.indices, id: \.self) { index in TextField("Step \(index + 1)", text: draftBinding.steps[index]) }
                    }
                    Section("supervisor_note") { TextField("optional_note", text: $note, axis: .vertical) }
                    Section {
                        Button("approval.approve") { app.decide(.approved, editedDraft: draftBinding.wrappedValue, note: note, context: context); dismiss() }
                            .foregroundStyle(.green)
                        Button("save_edited_version") { app.decide(.edited, editedDraft: draftBinding.wrappedValue, note: note, context: context); dismiss() }
                        Button("reject") { app.decide(.rejected, editedDraft: draftBinding.wrappedValue, note: note, context: context); dismiss() }
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("supervisor_approval")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } } }
            .onAppear { draft = app.diagnosis?.workOrder }
        }
    }
}
