//
//  DiagnosisWorkspaceView.swift
//  PulseFix
//
//  Created by Michael Hany on 24/09/2026.
//

import SwiftUI

struct DiagnosisWorkspaceView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        ScrollView {
            VStack(spacing: 16) {
                PulseCard {
                    Text("equipment_description").font(.headline)
                    TextEditor(text: $app.query).frame(minHeight: 110).padding(8).background(PulseTheme.background, in: RoundedRectangle(cornerRadius: 12))
                    Button { Task { await app.diagnose() } } label: {
                        HStack { if app.isRunning { ProgressView().tint(.white) }; Label("run_grounded_diagnosis", systemImage: "sparkles") }.frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).disabled(app.isRunning || app.chunks.isEmpty)
                }
                if !app.retrieved.isEmpty { RetrievedEvidenceView() }
                if let result = app.diagnosis { DiagnosticResultView(result: result) }
                else if app.isRunning || !app.streamedText.isEmpty { PulseCard { Text("streaming_response").font(.headline); Text(app.streamedText).textSelection(.enabled) } }
            }.padding()
        }
        .background(PulseTheme.background)
        .navigationTitle("industrial_diagnosis")
        .toolbar { AppToolbar() }
        .sheet(isPresented: $app.showingApproval) { ApprovalGateView() }
        .sheet(item: $app.selectedCitation) { citation in CitationSourceView(citation: citation) }
    }
}

private struct RetrievedEvidenceView: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        PulseCard {
            Text("retrieved_evidence").font(.headline)
            ForEach(app.retrieved) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(item.chunk.manualName).font(.subheadline.bold()); Spacer(); Text("p. \(item.chunk.pageNumber) • \(item.score, specifier: "%.1f")").font(.caption) }
                    Text(item.chunk.content).lineLimit(3).font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 5)
            }
        }
    }
}

private struct DiagnosticResultView: View {
    @Environment(AppModel.self) private var app
    let result: DiagnosticResult
    var statusColor: Color { result.status == .grounded ? .green : .orange }
    var body: some View {
        PulseCard {
            HStack { Text("diagnostic.result").font(.headline); Spacer(); StatusPill(text: "status.\(result.status.rawValue)", color: statusColor) }
            Text(result.summary).padding(.vertical, 4).textSelection(.enabled)
            if !result.safetyPrerequisites.isEmpty {
                Label("safety_prerequisites", systemImage: "exclamationmark.shield.fill").font(.subheadline.bold()).foregroundStyle(.orange)
                ForEach(result.safetyPrerequisites, id: \.self) { Text("• \($0)") }
            }
            if !result.recommendedActions.isEmpty {
                Text("recommended_actions").font(.subheadline.bold()).padding(.top, 4)
                ForEach(result.recommendedActions, id: \.self) { Text("• \($0)") }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack { ForEach(result.citations) { citation in Button("\(citation.manualName) • p.\(citation.pageNumber)") { app.selectedCitation = citation }.buttonStyle(.bordered) } }
            }
            if result.status == .grounded, result.workOrder != nil {
                Button("open_supervisor_approval_gate") { app.showingApproval = true }.buttonStyle(.borderedProminent).tint(PulseTheme.gold).foregroundStyle(PulseTheme.navy).padding(.top, 6)
            }
        }
    }
}
