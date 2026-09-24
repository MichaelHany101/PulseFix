//
//  TraceInspectorView.swift
//  PulseFix
//
//  Created by Michael Hany on 24/09/2026.
//

import SwiftUI

struct TraceInspectorView: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        List {
            Section("live_metrics") {
                LabeledContent("manual_chunks", value: "\(app.chunks.count)")
                LabeledContent("retrieved_chunks", value: "\(app.retrieved.count)")
                LabeledContent("context.characters", value: "\(app.retrieved.reduce(0) { $0 + $1.chunk.content.count })")
                LabeledContent("streamed.characters", value: "\(app.streamedText.count)")
            }
            Section("state_transitions") {
                ForEach(app.traces.reversed()) { trace in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack { Text(trace.state).font(.subheadline.monospaced().bold()); Spacer(); Text(trace.timestamp, style: .time).font(.caption).foregroundStyle(.secondary) }
                        Text(trace.details).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    }.padding(.vertical, 3)
                }
            }
        }
        .navigationTitle("run_trace_inspector")
        .toolbar { AppToolbar() }
    }
}
