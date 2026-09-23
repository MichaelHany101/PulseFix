//
//  LocalRetriever.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import Foundation

struct LexicalChunkRetriever: ChunkRetrieving {
    private let bilingualTerms: [String: [String]] = [
        "overheat": ["overheating", "temperature", "حرارة", "سخونة", "ارتفاع"],
        "vibration": ["vibrate", "bearing", "اهتزاز", "رولمان", "محمل"],
        "leak": ["leakage", "seal", "تسريب", "تسرب", "مانع"],
        "pressure": ["ضغط", "compressor", "ضاغط"],
        "shutdown": ["trip", "stop", "فصل", "توقف"],
        "safety": ["lockout", "isolate", "ppe", "سلامة", "عزل", "معدات الوقاية"]
    ]

    func retrieve(query: String, from chunks: [ManualChunk], limit: Int = 5) async -> [RetrievedChunk] {
        let queryTerms = expandedTerms(for: query)
        return chunks.compactMap { chunk in
            let body = normalize(chunk.content)
            let heading = normalize(chunk.section)
            let score = queryTerms.reduce(0.0) { result, term in
                let bodyMatches = body.components(separatedBy: term).count - 1
                let headingBonus = heading.contains(term) ? 3.0 : 0.0
                return result + Double(bodyMatches) + headingBonus
            }
            return score > 0 ? RetrievedChunk(chunk: chunk, score: score) : nil
        }
        .sorted { $0.score > $1.score }
        .prefix(limit)
        .map { $0 }
    }

    private func expandedTerms(for query: String) -> Set<String> {
        let raw = normalize(query).split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map(String.init).filter { $0.count > 2 }
        var base = Set(raw)
        raw.filter { $0.hasPrefix("و") && $0.count > 3 }.forEach { base.insert(String($0.dropFirst())) }
        var result = base
        for (key, values) in bilingualTerms where base.contains(key) || !base.isDisjoint(with: values) {
            result.insert(key); values.forEach { result.insert(normalize($0)) }
        }
        return result
    }

    private func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "ـ", with: "")
    }
}
