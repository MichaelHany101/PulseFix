//
//  DocumentIngestor.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import Foundation
import PDFKit

struct PDFTextIngestor: ManualIngesting {
    func ingest(url: URL) async throws -> (ManualDocument, [ManualChunk]) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let ext = url.pathExtension.lowercased()
        let manualID = UUID()
        let originalName = url.lastPathComponent
        let stableURL = try persistLocally(url: url, id: manualID)
        let pages: [String]

        if ext == "pdf" {
            guard let document = PDFDocument(url: stableURL) else { throw PulseFixError.unreadableDocument }
            pages = (0..<document.pageCount).map { document.page(at: $0)?.string ?? "" }
        } else if ext == "txt" {
            pages = try [String(contentsOf: stableURL, encoding: .utf8)]
        } else {
            throw PulseFixError.unsupportedDocument
        }

        let chunks = pages.enumerated().flatMap { pageIndex, pageText in
            chunk(text: pageText, manualID: manualID, manualName: originalName, page: pageIndex + 1)
        }
        let manual = ManualDocument(id: manualID, name: originalName, localURL: stableURL,
                                    pageCount: pages.count, chunkCount: chunks.count)
        return (manual, chunks)
    }

    private func persistLocally(url: URL, id: UUID) throws -> URL {
        let manager = FileManager.default
        let root = try manager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Manuals", isDirectory: true)
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        let destination = root.appendingPathComponent("\(id.uuidString).\(url.pathExtension.lowercased())")
        try manager.copyItem(at: url, to: destination)
        return destination
    }

    private func chunk(text: String, manualID: UUID, manualName: String, page: Int) -> [ManualChunk] {
        let paragraphs = text.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var output: [ManualChunk] = []
        var buffer = ""
        var index = 0
        for paragraph in paragraphs {
            if buffer.count + paragraph.count > 1_000, !buffer.isEmpty {
                output.append(makeChunk(buffer, manualID, manualName, page, index)); index += 1
                buffer = String(buffer.suffix(150))
            }
            buffer += (buffer.isEmpty ? "" : "\n\n") + paragraph
        }
        if !buffer.isEmpty { output.append(makeChunk(buffer, manualID, manualName, page, index)) }
        return output
    }

    private func makeChunk(_ content: String, _ manualID: UUID, _ name: String, _ page: Int, _ index: Int) -> ManualChunk {
        let section = content.split(separator: "\n").first.map(String.init) ?? "Section"
        return ManualChunk(id: "\(manualID.uuidString)-p\(page)-c\(index)", manualID: manualID,
                           manualName: name, pageNumber: page, section: section, content: content)
    }
}
