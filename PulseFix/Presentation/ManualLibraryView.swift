//
//  ManualLibraryView.swift
//  PulseFix
//
//  Created by Michael Hany on 24/09/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ManualLibraryView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @State private var showingImporter = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                PulseCard {
                    Label("manual_base", systemImage: "internaldrive")
                        .font(.headline)
                    Text("PDF and text extraction, chunking, and search happen on this iPhone.").font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(app.manuals) { manual in
                    PulseCard {
                        HStack {
                            Image(systemName: manual.name.hasSuffix("pdf") ? "doc.richtext" : "doc.text").font(.title2).foregroundStyle(PulseTheme.blue)
                            VStack(alignment: .leading) {
                                Text(manual.name).font(.headline)
                                Text("\(manual.pageCount) pages • \(manual.chunkCount) chunks").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(); StatusPill(text: "LOCAL", color: .green)
                        }
                    }
                }
            }.padding()
        }
        .background(PulseTheme.background)
        .navigationTitle("manuals.title")
        .toolbar { AppToolbar(); ToolbarItem(placement: .topBarLeading) { Button { showingImporter = true } label: { Label("import", systemImage: "plus") } } }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf, .plainText]) { result in
            if case .success(let url) = result { Task { await app.importManual(url) } }
            if case .failure(let error) = result { app.errorMessage = app.language == .arabic ? "تعذر فتح الملف المحدد." : error.localizedDescription }
        }
    }
}
