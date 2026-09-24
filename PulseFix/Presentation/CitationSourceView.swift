//
//  CitationSourceView.swift
//  PulseFix
//
//  Created by Michael Hany on 24/09/2026.
//

import SwiftUI
import PDFKit

struct CitationSourceView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let citation: Citation

    var manual: ManualDocument? { app.manuals.first { $0.name == citation.manualName } }
    var evidence: ManualChunk? { app.chunks.first { $0.id == citation.sourceID } }

    var body: some View {
        NavigationStack {
            Group {
                if let manual, manual.localURL.pathExtension.lowercased() == "pdf" {
                    PDFPageView(url: manual.localURL, page: citation.pageNumber)
                } else {
                    ScrollView { Text(evidence?.content ?? String(localized: "Source text unavailable", locale: app.locale)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding() }
                }
            }
            .navigationTitle("\(citation.manualName) • p. \(citation.pageNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
        }
    }
}

private struct PDFPageView: UIViewRepresentable {
    let url: URL; let page: Int
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView(); view.autoScales = true; view.displayMode = .singlePageContinuous
        if let document = PDFDocument(url: url) { view.document = document; if let target = document.page(at: max(0, page - 1)) { view.go(to: target) } }
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
