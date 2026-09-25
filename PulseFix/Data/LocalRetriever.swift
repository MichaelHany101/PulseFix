//
//  LocalRetriever.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import Foundation

struct LexicalChunkRetriever: ChunkRetrieving {
    private let bilingualTerms: [String: [String]] = [
        "pump": ["مضخة", "مضخه", "المضخة", "المضخه"],
        "compressor": ["ضاغط", "الضاغط", "كمبروسر"],
        "conveyor": ["سير", "السير", "ناقل", "الناقل", "belt"],
        "boiler": ["غلاية", "الغلاية", "مرجل", "المرجل"],
        "motor": ["محرك", "المحرك", "موتور"],
        "drift": ["drifts", "tracking", "انحراف", "ينحرف", "ينحرفان"],
        "flame": ["burner", "ignition", "لهب", "اللهب", "شعلة", "اشتعال"],
        "low": ["منخفض", "انخفاض", "ضعيف"],
        "noise": ["ضوضاء", "صوت", "ضجيج"],
        "overheat": ["overheating", "temperature", "حرارة", "سخونة", "ارتفاع", "الحرارة", "حراره", "الحراره"],
        "vibration": ["vibrate", "bearing", "اهتزاز", "رولمان", "محمل"],
        "leak": ["leakage", "seal", "تسريب", "تسرب", "مانع"],
        "pressure": ["ضغط", "compressor", "ضاغط"],
        "shutdown": ["trip", "stop", "فصل", "توقف"],
        "safety": ["lockout", "isolate", "ppe", "سلامة", "عزل", "معدات الوقاية"]
    ]

    func retrieve(query: String, from chunks: [ManualChunk], limit: Int = 5) async -> [RetrievedChunk] {
        let queryTerms = expandedTerms(for: query)
        let codes = ["px200", "ac50", "cv10", "bl20", "mt75"]
        let compactQuery = normalize(query).filter { $0.isLetter || $0.isNumber }
        let specifiedCodes = codes.filter { compactQuery.contains($0) }
        return chunks.compactMap { chunk in
            let compactName = normalize(chunk.manualName).filter { $0.isLetter || $0.isNumber }
            guard specifiedCodes.isEmpty || specifiedCodes.contains(where: compactName.contains) else { return nil }
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
        let stopWords: Set<String> = ["the", "and", "with", "what", "why", "does", "please", "manual", "لدي", "عندي", "يوجد", "كيف", "لماذا", "على", "هذا", "هذه", "هناك"]
        var base = Set(raw).subtracting(stopWords)
        for word in raw where word.hasPrefix("ال") && word.count > 4 { base.insert(String(word.dropFirst(2))) }
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
